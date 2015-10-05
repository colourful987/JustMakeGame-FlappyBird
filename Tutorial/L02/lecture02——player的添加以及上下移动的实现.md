### Lecture02 —— Player的添加以及上下移动的实现



###01.游戏音乐实现

音乐主要有:*Player*挥动翅膀上升的声音、撞击障碍物的声音、坠落至地面的声音、过关得分的声音等等。请打开项目看到*Resource*中的*Sounds*文件夹，包含了上述所有声音，格式为`.wav`。

*SpritKit*提供`playSoundFileNamed(soundFile: , waitForCompletion wait: )->SKAction`方法用于实现音乐的播放，注意播放音乐也是一个*Action*动作。请定位到*GameScene.swift*文件,找到`GameScene`类中的`var playableHeight:CGFloat = 0`，在其下方添加如下代码:


```swift
// MARK: 音乐Action
let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
```    

之后在需要音乐播放的时候调用这些已经定义的动作即可。


###02.添加Player

通过课程一的代码练习，添加一个*Player*只需实例化一个`SKSpriteNode`实例，纹理为*Bird0*这张照片。由于这个精灵之后将在各个函数调用，因此设定了全局变量，请在`var playableHeight: CGFloat = 0`下添加如下代码实例化一个名为"Player"的精灵。如下:

```swift
let player = SKSpriteNode(imageNamed: "Bird0")
```     

注意到此时我们并未添加该精灵到场景中的`worldNode`节点中，因此我们需要实现一个名为`setupPlayer()`的方法，代码如下

```swift
func setupPlayer(){
    player.position = CGPointMake(size.width * 0.2, playableHeight * 0.4 + playableStart)
    player.zPosition = Layer.Player.rawValue
    worldNode.addChild(player)
}
```   

函数中仅设置了*position*以及*zPosition*属性，而锚点*anchorPoint*并未设置，采用默认值(0.5,0.5)。找到`didMoveToView(view:)`中的`setupForeground()`这行代码，将上述方法添加至其下方。

点击运行程序，*Player*出现在场景之中。


###03.update方法

不知道你有没有玩过翻书动画，先准备一个厚厚的小本子，然后在每一页上描画，最后通过快速翻阅组成最简短的动画。如下:


![L02-Animation](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L02/L02-Animation.png)

前文谈及右下角的*30fps*客官可曾记得？*fps*是*Frame Per Second*的缩写，即每秒的帧数，而一帧为一个画面。因此*30fps*意味着在一秒钟时间内，**App**要渲染30次左右，平均每隔0.033333秒就要重新绘制一次画面。而渲染(绘制)完毕立刻跳入`update(currentTime:)`方法中，大约间隔33.33毫秒左右，执行方法内的代码。不妨你在该函数中设个断点感受一下。     

注意到左下角的帧数并不是始终保持在*30fps*,而是不断在上下浮动变化。相邻两帧画面之间的时间并不固定，可能是0.033秒，也可能是0.030秒。不妨测试打印下两帧之间的时间差值,请在`player`下添加两个全局变量:`lastUpdateTime`以及`dt`：

```swift
var lastUpdateTime :NSTimeInterval = 0	//记录上次更新时间
var dt:NSTimeInterval = 0				//两次时间差值
```

接着在`Update(currenTime:)`方法中添加如下方法：

```swift
override func update(currentTime: CFTimeInterval) {
   if lastUpdateTime > 0{
       dt = currentTime - lastUpdateTime
   }else{
       dt = 0
   }
   lastUpdateTime = currentTime
   print("时间差值为:\(dt*1000) 毫秒")
}
```     

可以看到打印结果(注意红色框框处):

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L02/L02-Frame.png)

当应用刚启动时，帧数并不稳定，导致时间间隔略大，不过之后基本稳定在33毫秒左右。


###04.Player的下落公式

这里可能要涉及一些高中的物理知识。地球上的重力加速度为9.8g。物体在半空中静止到下落，每隔dt时间。

* 速度`V = V1 + a * dt`，即**当前速度=初速度 + 加速度 * 时间间隔**。
* dt时间内，下落距离`d =V * dt`,这里采用**平均速度 * 时间差**得到下落距离。

游戏中设定且只有Y轴方向上的重力加速度`kGravity = -1500`,这个值是可调节的，我觉得恰到好处；此外每次玩家点击屏幕，对*Player*要有一个向上的拉力，不妨设为`kImpulse = 400`；最后声明一个变量`playerVelocity`追踪当前*Player*的速度。请添加上述三个全局变量的声明,现在*GameScene*类中的全局变量有以下这些:

```swift
// MARK: - 常量
let kGravity:CGFloat = -1500.0	//重力
let kImpulse:CGFloat = 400		//上升力

let worldNode = SKNode()
var playableStart:CGFloat = 0
var playableHeight:CGFloat = 0
let player = SKSpriteNode(imageNamed: "Bird0")
var lastUpdateTime :NSTimeInterval = 0
var dt:NSTimeInterval = 0
var playerVelocity = CGPoint.zero	//速度 注意变量类型为一个点
//...其他内容
```

请在*GameScene*类中添加一个方法，将先前公式用swift实现更新*player*的*position*。


```swift
func updatePlayer(){
    // 只有Y轴上的重力加速度为-1500
    let gravity = CGPoint(x: 0, y: kGravity)
    let gravityStep = gravity * CGFloat(dt) //计算dt时间下速度的增量
    playerVelocity += gravityStep           //计算当前速度
    
    // 位置计算
    let velocityStep = playerVelocity * CGFloat(dt) //计算dt时间中下落或上升距离
    player.position += velocityStep                 //计算player的位置
    
    // 倘若Player的Y坐标位置在地面上了就不能再下落了 直接设置其位置的y值为地面的表层坐标
    if player.position.y - player.size.height/2 < playableStart {
        player.position = CGPoint(x: player.position.x, y: playableStart + player.size.height/2)
    }
}
```    

将该方法添加至`update(currentTime)`方法中的最下面。意味着每隔33.3毫秒左右就要更新一次*Player*的位置。

点击运行，*Player*自由落地至地面，不错吧！


###05.让Player动起来

游戏中我们点击一次屏幕，*Player*会获得一个向上的牵引力，挥动翅膀向上飞一段距离，倘若之后没有持续的力，则开始自由落体。怎么实现呢？实现机制不难,只需每次玩家点击屏幕，使得*Player*获得向上的速度，具体为先前设定的400即可。

因此，添加一个方法到*GameScene*类中，用于每次用户点击屏幕时调用，作用是让*Player*获得向上的速度！


```swift
func flapPlayer(){
    // 发出一次煽动翅膀的声音
    runAction(flapAction)
    // 重新设定player的速度！！
    playerVelocity  = CGPointMake(0, kImpulse)
}
```    

正如前面谈到的，方法中主要做两件事:1.发出一次挥动翅膀的声音。2.重新设定player的速度。

而用户每次点击都会调用`touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)`方法。不用我多说了吧，把`flapPlayer()`方法添加进去吧。

运行工程，*player*坠落，点击几下，哇靠，飞起来了！






