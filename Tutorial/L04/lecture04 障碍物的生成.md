###Lecture04 障碍物的生成


**本节任务:**

* 随机生成障碍物，且一对障碍物上下相距距离固定，但位置随机。


**几种情况:**

`y position = 0`的情况:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L04/L04-Position1.png)   

`y position = playableStart`的情况:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L04/L04-Position2.png)

`y position = playableStart - 障碍物.size.height/2`的情况:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L04/L04-Position3.png)

推导一般情况下的公式:`y position = playableStart - 障碍物.size.height/2 + (10%~60%)playgroundHeight`:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L04/L04-Position4.png)

上下两个障碍物之间距离固定为3.5倍的*Player*尺寸的高度:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L04/L04-Position5.png)


注意推导公式:`y position = playableStart - 障碍物.size.height/2`此时障碍物的顶部刚好与地面齐平，而`(10%~60%)playgroundHeight`是一个浮动范围，表明障碍物超出地面的高度。显然我们的障碍物的层级关系是在背景上面但是在*Foreground*的下面，因此修改早前的*Layer*:

```swift
enum Layer: CGFloat {
    case Background
    case Obstacle	//添加障碍物层级关系
    case Foreground
    case Player
}
```


###01.产生障碍物的构造方法

我们需要增添一个方法用于实例化一个纹理(图片)为仙人掌的精灵(*SpriteNode*),设置其*zPosition*为*Obstacle*,请在`flapPlayer()`方法上方新增如下方法:

```swift
func createObstacle()->SKSpriteNode{
    let sprite = SKSpriteNode(imageNamed: "Cactus")
    sprite.zPosition = Layer.Obstacle.rawValue
    return sprite
}
```   

注意到实例方法生成一个纹理为*Cactus*的精灵并返回，这是之后源源不断生成障碍物的基础。    

紧接着我们要有一个实例方法，作用是随机产生成对的障碍物到场景中，步骤如下:

1. 使用`createObstacle()`得到下方障碍物的实例，并将其放置紧贴右侧屏幕边线。
2. 障碍物y轴上的放置位置范围为10%~60%,分别计算最小与最大的y轴点位，通过随机函数得到两者之间的一个数作为y值，设置障碍物的*position*,最后添加到*worldNode*节点中。
3. 同理实例化上方障碍物，将其旋转180°后放置距离下方障碍物3.5倍*Player*尺寸的地方，添加到*worldNode*节点中。
4. 给上下障碍物增添一个移动Action,已一定速度自右向左移动，倘若超出屏幕，则从父节点中移除。


```swift
//新增三个常量
let kBottomObstacleMinFraction: CGFloat = 0.1
let kBottomObstacleMaxFraction: CGFloat = 0.6
let kGapMultiplier: CGFloat = 3.5

// 在createObstacle()实例方法下方增添新方法
func spawnObstacle(){
   //1
   let bottomObstacle = createObstacle()	//实例化一个精灵
   let startX = size.width + bottomObstacle.size.width/2//x轴位置为屏幕最右侧
   //2
   let bottomObstacleMin = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMinFraction	//计算障碍物超出地表的最小距离
   let bottomObstacleMax = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMaxFraction //计算障碍物超出地表的最大距离
   bottomObstacle.position = CGPointMake(startX, CGFloat.random(min: bottomObstacleMin, max: bottomObstacleMax))	// 随机生成10%~60%的一个距离赋值给position
   worldNode.addChild(bottomObstacle)	//添加到世界节点中
   //3
   let topObstacle = createObstacle()	//实例化一个精灵
   topObstacle.zRotation = CGFloat(180).degreesToRadians()//翻转180°
   topObstacle.position = CGPoint(x: startX, y: bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + player.size.height * kGapMultiplier)//设置y位置 相距3.5倍的Player尺寸距离
   worldNode.addChild(topObstacle)//添加至世界节点中
   //4 给障碍物添加动作
   let moveX = size.width + topObstacle.size.width
   let moveDuration = moveX / kGroundSpeed
   let sequence = SKAction.sequence([
       SKAction.moveByX(-moveX, y: 0, duration: NSTimeInterval(moveDuration)),
       SKAction.removeFromParent()
       ])
   topObstacle.runAction(sequence)
   bottomObstacle.runAction(sequence)
}
```   

倘若你迫不及待想看看成果，将`spawnObstacle`方法添加至`didMoveToView()`最下方，点击运行。一对障碍物“呼啸而过”，然后就没有然后了...确实目前这个方法仅仅只是产生一对罢了，为此我们还需要新增一个方法用于源源不断的产生障碍物。请添加如下内容到`spawnObstacle()`方法下方

```swift
func startSpawning(){
	//1
    let firstDelay = SKAction.waitForDuration(1.75)
    //2
    let spawn = SKAction.runBlock(spawnObstacle)
    //3
    let everyDelay = SKAction.waitForDuration(1.5)
    //4
    let spawnSequence = SKAction.sequence([
            spawn,everyDelay
        ])
    //5
    let foreverSpawn = SKAction.repeatActionForever(spawnSequence)
    //6
    let overallSequence = SKAction.sequence([firstDelay,foreverSpawn])
    runAction(overallSequence)
}
```

1. 第一个障碍物生成延迟1.75秒
2. 生成障碍物的动作，用到了先前的实例方法`spawnObstacle`.
3. 之后生成障碍物的间隔时间为1.5秒
4. 之后障碍物的生成顺序是:产生障碍物，延迟1.5秒;产生障碍物，延迟1.5秒;产生障碍物，延迟1.5秒...可以看出**[产生障碍物，延迟1.5秒]**为一组重复动作。
5. 使用`SKAction.repeatActionForever`重复4中的动作。
6. 将延迟1.75秒和重复动作整合成一个SKAction的数组，然后让场景来执行该动作组。

请将`didMoveToView()`方法中的`spawnObstacle`替换成`startSpawning()`,点击运行。


> 倘若觉得不错，请点击喜欢并关注我吧.^.^


