###Lecture10 —— 优化游戏(终结篇)




Flappy Bird整个项目临近尾声，要做的只是对游戏体验的优化，本文先解决两个，分别是:

1. 实现Player 静态时的动画，修改早前掉落时直上直下的问题。
2. Player撞击障碍物时，给出一个shake摇晃动画。

游戏最后实现的效果是这样的：

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L10/L10-show.gif)


### Player动画实现

当游戏状态为.Tutorial的时候，Player是静态呈现在教程界面上的，为此我们想要实现一个动画，让其挥动翅膀。而实现方法也很简单，动画由多张图片组成，指定一定时间播放完毕，具体用**SKTexture**实例化每一个图片，然后放到数组中；紧接着调用**animateWithTextures(_:timePerFrame:)**播放动画。

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L10/L10-texture.png)

找到setupTutorial()方法，再其下方新增一个方法:

```swift
func setupPlayerAnimation() {
    
    var textures: Array<SKTexture> = []
    // 我们有4张图片
    for i in 0..<4 {
        textures.append(SKTexture(imageNamed: "Bird\(i)"))
    }
    // 4=3-1
    for i in 3.stride(through: 0, by: -1) {
        textures.append(SKTexture(imageNamed: "Bird\(i)"))
    }
    
    let playerAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.07)
    player.runAction(SKAction.repeatActionForever(playerAnimation))
    
}
```

正如前面所说，我们采用`for-in`循环实例化了4个`SKTexture`实例存储于数组中，接着调用方法播放动画。现在请将该方法添加到`switchToMainMenu() `以及`switchToTutorial()`方法中的最后，点击运行,看看Player是否挥动翅膀了。

在玩游戏的时候我们会注意到Player掉落时是直上直下，有些呆板，这里需要替换掉，动画效果如图：

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L10/L10-rotate.png)

在开始实现Player旋转机制前，先定义几个常量以及变量,请在`GameScene()`类中添加如下属性

```swift
// 新增常量
let kMinDegrees: CGFloat = -90			// 定义Player最小角度为-90
let kMaxDegrees: CGFloat = 25			// 定义Player最大角度为25
let kAngularVelocity: CGFloat = 1000.0	// 定义角速度

// 新增变量
var playerAngularVelocity: CGFloat = 0.0	// 实时更新player的角度
var lastTouchTime: NSTimeInterval = 0		// 用户最后一次点击时间
var lastTouchY: CGFloat = 0.0				// 用户最后一次点击坐标
```

请找到`flapPlayer`方法，这个方法是在游戏状态下，用户点击一次屏幕需要调用的方法(具体请跳到`touchesBegan`方法)，为此我们将在这里进行`lastTouchTime`与`lastTouchY`变量的更新,替换后的内容如下:


```swift
func flapPlayer(){
   // 发出一次煽动翅膀的声音
   runAction(flapAction)
   // 重新设定player的速度！！
   playerVelocity  = CGPointMake(0, kImpulse)
   
   //===========新增内容============
   playerAngularVelocity = kAngularVelocity.degreesToRadians()
   lastTouchTime = lastUpdateTime
   lastTouchY = player.position.y
   //==============================
   
   // 使得帽子下上跳动
   let moveUp = SKAction.moveByX(0, y: 12, duration: 0.15)
   moveUp.timingMode = .EaseInEaseOut
   let moveDown = moveUp.reversedAction()
   sombrero.runAction(SKAction.sequence([moveUp,moveDown]))
}
```

如此每次用户点击一次屏幕，就会重新计算Player应该旋转多少。那么什么时候去真正更新Player的状态呢？答案是`update()`方法。这里我们要更新的是Player的信息，请找到`updatePlayer()`方法，新增如下内容到最后：

```swift
if player.position.y < lastTouchY {
  playerAngularVelocity = -kAngularVelocity.degreesToRadians()
}

// Rotate player
let angularStep = playerAngularVelocity * CGFloat(dt)
player.zRotation += angularStep
player.zRotation = min(max(player.zRotation, kMinDegrees.degreesToRadians()), kMaxDegrees.degreesToRadians())
```
点击运行！不出意味应该和预期效果一样。


### Shake动画

先前说到Player撞击障碍物后要有一个摇晃的动画以及闪烁的小锅，那样显得更有真实感不是吗，这里需要调用screenShakeWithNode来实现，摇晃对象是谁？自然是**worldNode**喽。

由于内容简单，请直接定位到`switchToFalling()`方法，替换早前内容:

```swift
enum Layer: CGFloat {
  case Background
  case Obstacle
  case Foreground
  case Player
  case UI
  case Flash		//新增一个层
}

func switchToFalling() {
   gameState = .Falling
   
   // Screen shake
   let shake = SKAction.screenShakeWithNode(worldNode, amount: CGPoint(x: 0, y: 7.0), oscillations: 10, duration: 1.0)
   worldNode.runAction(shake)
   
   // Flash
   let whiteNode = SKSpriteNode(color: SKColor.whiteColor(), size: size)
   whiteNode.position = CGPoint(x: size.width/2, y: size.height/2)
   whiteNode.zPosition = Layer.Flash.rawValue
   worldNode.addChild(whiteNode)
   
   whiteNode.runAction(SKAction.removeFromParentAfterDelay(0.01))
   
   runAction(SKAction.sequence([
       whackAction,
       SKAction.waitForDuration(0.1),
       fallingAction
       ]))
   
   player.removeAllActions()
   stopSpawning()
}
```

哦对了，请注释掉GameViewController.swift中的几行代码，去掉所有调试信息，这样才是一个完整的游戏；

```swift
// 4.设置一些调试参数
//skView.showsFPS = true          // 显示帧数
//skView.showsNodeCount = true    // 显示当前场景下节点个数
//skView.showsPhysics = true      // 显示物理体
//skView.ignoresSiblingOrder = true   // 忽略节点添加顺序
```

点击运行，享受你的劳动果实吧！



###结尾

这个游戏系列文章终于连载完成，当时可能是一时兴起，最后还是坚持下来了。文章更多是在叙述整个游戏是如何开发出来，并未在一些基础知识以及实现原理上细说，这是之后我要补充的，最后谢谢大家的支持。如果觉得不错，请点击喜欢并关注我，同时将我的文章推荐给你的朋友。8~