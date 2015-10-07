###Lecture05 —— 真实的物理世界

>**友情提示:**为了方便大家快速上手项目，我上传了课时的教程至[github](https://github.com/colourful987/JustMakeGame-FlappyBird)，请找到**Code文件夹中->L05文件夹->FlappyBird-Start**下载。

游戏的雏形已经基本实现，呈现了背景，地面持续滚动，*Player*上下跳窜以及源源不断的仙人掌。不过细心的你也应当发现有以下几个不足:

1. *Player*可以通过不断点击升高到屏幕外。
2. 仙人掌表示不服:你丫想穿越我就穿越，当我是透明吗？

因此本节的任务是设置场景精灵的物理体，当课时完毕，*Player*一旦触碰到仙人掌就会下落，不能继续游戏。


###01.设置场景内精灵的物体形状

暂且对游戏内容按下不表，先谈谈咱们真实的世界，重力加速度9.8g,非透明的物体之间碰撞会发生形变。而在*Sprite Kit*中的物理世界，首先我需要引出*Physics Shapes* —— 物体形状，就拿人来说，倘若我粗略地来形容一个人的物理体，我就会给出一个`x*y*z`(长宽高计算体积)的长方体，一旦外物触碰轮廓表面，我就说两者发生了接触；不过若已精确角度来说，形容人的物理体以其皮肤表面为轮廓勾勒出一个体积，显然这比先前的立方体来的精确太多了；当然有时候嫌麻烦，指定头部(姑且就当成一个球体吧)作为人的物理体，因此除头部外的身体都相当于是透明的，外物接触了手、腿等都不算发生接触，只有与头部接触才算。

讲了那么多，现在回到游戏，开始塑造真实的物理世界,首先找到`didMoveToView()`方法，在最上方添加一行代码设置场景物理世界的重力为(0,0)，原因是我们打算使用自定义设置的参数:

```swift
override func didMoveToView(view: SKView) {
    physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    //... 以下为早前内容
}
```    

接着咱们要说**physicsBody**，译为物理体。我们可以设置每个节点的物理体，那样它就可以和其他同样设置了物理体的节点发生碰撞、检测接触等，它有三个属性，值均为UInt32类型:

* *categoryBitMask*: 表明当前body属于哪个类别。
* *collisionBitMask*: 当前物体可以与哪些类别发生碰撞。
* *contactTestBitMask*:用于告知当前物体与哪些类别物理发生接触时。

游戏中类似这种，我们往往用二进制数来表示物体，譬如*0b1*表明是*Player*,*0b10*表明障碍物，*0b100*表明地面。想必编程男都不陌生吧。OK，请在`enum Layer:CGFLoat{}`下方新增一个结构体用于表明分类，注意里面均为类型属性:

```swift
struct PhysicsCategory {
  static let None: UInt32 = 0
  static let Player: UInt32 =     0b1 // 1
  static let Obstacle: UInt32 =  0b10 // 2
  static let Ground: UInt32 =   0b100 // 4
}
```
对于类型属性，调用方法形如:`PhysicsCategory.None`，更多关于类型属性，请参看官方文档*Type properties*一节。

接下来我们主要添加以下物理体到场景中:

1. Player，这里我们将借助一个勾勒工具来绘制其物理体。
2. 障碍物,同上。
3. 地面，其实就是一条水平线。

为啥要设置以上三个物理体呢？因为设置完物理体后，我们才能知道谁和谁发生了接触*contact*，如此进行下一步计算。至于`collision`咱们是不关心的，不需要设置。

### 设置地面的物理体

找到`setupBackground()`方法 在方法最下方添加如下内容:

```swift
func setupBackground(){
	//...
	//===以上为早前内容===
	//===以下为新增内容===
   let lowerLeft = CGPoint(x: 0, y: playableStart)//地板表面的最左侧一点
   let lowerRight = CGPoint(x: size.width, y: playableStart) //地板表面的最右侧一点
   // 1
   self.physicsBody = SKPhysicsBody(edgeFromPoint: lowerLeft, toPoint: lowerRight)
   self.physicsBody?.categoryBitMask = PhysicsCategory.Ground
   self.physicsBody?.collisionBitMask = 0
   self.physicsBody?.contactTestBitMask = PhysicsCategory.Player
}
```

对于1中，我们用一条平行线来实例化物理体，然后是三部曲，分别设置了其分类为*Ground*；不予其他任何物理发生碰撞(因为设置了0)；设置了能与其发生接触的物体有*Player*。


### 设置Player的物理体

找到`setupPlayer()`方法 同样新增以下内容到方法最后:

```swift
func setupPlayer(){
   player.position = CGPointMake(size.width * 0.2, playableHeight * 0.4 + playableStart)
   player.zPosition = Layer.Player.rawValue
	// 注意我们将worldNode.addChild(player)移到了最下方。
	
	//=========以下为新增内容===========
   let offsetX = player.size.width * player.anchorPoint.x
   let offsetY = player.size.height * player.anchorPoint.y
   
   let path = CGPathCreateMutable()
   
   CGPathMoveToPoint(path, nil, 17 - offsetX, 23 - offsetY)
   CGPathAddLineToPoint(path, nil, 39 - offsetX, 22 - offsetY)
   CGPathAddLineToPoint(path, nil, 38 - offsetX, 10 - offsetY)
   CGPathAddLineToPoint(path, nil, 21 - offsetX, 0 - offsetY)
   CGPathAddLineToPoint(path, nil, 4 - offsetX, 1 - offsetY)
   CGPathAddLineToPoint(path, nil, 3 - offsetX, 15 - offsetY)
   
   CGPathCloseSubpath(path)
   
   player.physicsBody = SKPhysicsBody(polygonFromPath: path)
   player.physicsBody?.categoryBitMask = PhysicsCategory.Player
   player.physicsBody?.collisionBitMask = 0
   player.physicsBody?.contactTestBitMask = PhysicsCategory.Obstacle | PhysicsCategory.Ground
   
   worldNode.addChild(player)// hey 我现在在这里！！！！
}
```   

我们通过绘制路径来勾勒出*Player*的自定义物理体，别吃惊，我只不过借助了某些工具，地址在[这里](http://stackoverflow.com/questions/19040144/spritekits-skphysicsbody-with-polygon-helper-tool),ps:可能需要翻墙。


### 设置仙人掌的物理体

同理我们只需要在产生仙人掌的实例方法中添加其物理体即可，请定位到`createObstacle()->SKSpriteNode`方法:

```swift
func createObstacle() -> SKSpriteNode {
  let sprite = SKSpriteNode(imageNamed: "Cactus")
  sprite.zPosition = Layer.Obstacle.rawValue
  
  //========以下为新增内容=========
  let offsetX = sprite.size.width * sprite.anchorPoint.x
  let offsetY = sprite.size.height * sprite.anchorPoint.y

  let path = CGPathCreateMutable()

  CGPathMoveToPoint(path, nil, 3 - offsetX, 0 - offsetY)
  CGPathAddLineToPoint(path, nil, 5 - offsetX, 309 - offsetY)
  CGPathAddLineToPoint(path, nil, 16 - offsetX, 315 - offsetY)
  CGPathAddLineToPoint(path, nil, 39 - offsetX, 315 - offsetY)
  CGPathAddLineToPoint(path, nil, 51 - offsetX, 306 - offsetY)
  CGPathAddLineToPoint(path, nil, 49 - offsetX, 1 - offsetY)

  CGPathCloseSubpath(path)
  
  sprite.physicsBody = SKPhysicsBody(polygonFromPath: path)
  sprite.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
  sprite.physicsBody?.collisionBitMask = 0
  sprite.physicsBody?.contactTestBitMask = PhysicsCategory.Player
  
  return sprite
}
```   

注意到不管是哪种方式设置物理体，我们都需要设置其分类，碰撞掩码以及测试接触掩码，不过这里我们并不需要碰撞，所以全部设为0，即None。


最后请点击运行，你会发现场景中的*Player*、*仙人掌*以及地面表层都有一层轮廓。没错！这就是其各自的物理体。我们在*GameViewCOntroller*中通过设置了` skView.showsPhysics = true`来显示的。

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L05/L05-Result.png)

> 下文我将更新如何处理物体与物体之间的接触事件。 倘若觉得文章不错，点击喜欢或者关注我吧。^.^