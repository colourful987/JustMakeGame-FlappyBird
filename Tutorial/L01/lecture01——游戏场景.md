### Lecture01 —— 游戏场景



>本教程参考自RayWenderlich的视频教程[How To Make a Game Like Flappy Bird Series (Swift)](http://www.raywenderlich.com/video-tutorials#swiftflappy)。本教程中，你将从无到有亲自开发一个基于*SpriteKit*框架的*Flappy bird*小游戏。总体难度不大，但要求你掌握*Swift*基础语法与*SpriteKit*框架知识。此外，教程中所有素材均来自*Raywenderlich*，鼓励学习交流，但请勿用于商业用途。



**友情帮助**: 为了方便大家快速上手项目，我在*github*中上传了起始项目文件供大家下载，请点击[这里]()下载。



### 01.项目文件介绍

首先请打开项目，先介绍项目已有文件,你将看到如下目录:

![L01-Dir](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L01/L01-Dir.png)    



主要讲解以下一些重要的文件：

-Resource文件夹:资源文件放置处
 
 	- Art:以atlas图册方式管理素材文件。
 
 	- SKTUtiles:采用Extension对一些类进行拓展，添加一些有用的方法或属性。
 
 	- Sounds:游戏声音素材
 
-GameScene.swift:Flappy游戏比较简单，因此一个游戏场景足以，有关于场景内容设置、交互等均在该场景中设置。
 
-GameViewController.swift:视图控制器，包含一个视图*view*,当然这个视图比较特殊:为*SKView*，用于呈现场景*Scene*。

### 02.呈现视图

选中*GameViewController.swift*文件，先前提及视图控制器中的*SKView*，其职责在于呈现游戏场景*Scene*。不过现在空文件中神马都木有，我们将重写`viewWillLayoutSubviews()`方法呈现场景。定位到*GameViewController*类，添加以下代码:      

``` swift
override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    // 1.对view进行父类向子类的变形，结果是一个可选类型 因此需要解包
    if let  skView = self.view as? SKView{
        // 倘若skView中没有场景Scene，需要重新创建创建一个
        if skView.scene == nil{

            /*==  创建场景代码  ==*/

            // 2.获得高宽比例
            let aspectRatio = skView.bounds.size.height / skView.bounds.size.width
            // 3.new一个场景实例 这里注意场景的width始终为320 至于高是通过width * aspectRatio获得
            let scene = GameScene(size:CGSizeMake(320, 320 * aspectRatio))

            // 4.设置一些调试参数
            skView.showsFPS = true          // 显示帧数
            skView.showsNodeCount = true    // 显示当前场景下节点个数
            skView.showsPhysics = true      // 显示物理体
            skView.ignoresSiblingOrder = true   // 忽略节点添加顺序

            // 5.设置场景呈现模式
            scene.scaleMode = .AspectFill

            // 6.呈现场景
            skView.presentScene(scene)
        }
    }
}
```

这里需要注意2、3处，固定了游戏场景的宽度*Width = 320*,高度则通过*Width*乘以高宽比相乘得到，对于*iPhone4s iPhone5/5s*这些宽为320的设备来说自然没什么影响，但是对于*iPhone6/6Pluse*设备，相当于将设备宽高同时缩小相同倍数，直至宽为320时停止；再通过设置*scaleMode*为`AspectFill`(更多*ScaleMode*，请点击[这里](http://blog.csdn.net/colouful987/article/details/44855213)了解)呈现视图。

对于4来说，我们需要了解游戏运行时每秒的帧数、当前场景中节点个数、显示节点的物理体等，因此通过设置这些参数能帮助我们更好的调试。

OK,点击运行项目，模拟器运行结果一片漆黑，不过右下角显示*node=1 60.0fps*,表明当前场景中显示了一个节点，帧数为60左右。

>Question:什么都还没添加，视图中怎么会有一个节点Node了呢?     
>
>Answer:场景Scene类为SKScene,继承自SKNode,因此当skView呈现场景时，自然就将一个节点置于其中了。



### 03场景内容的填充



定位到*GameScene.swift*文件，可以看到文件中已经声明了一个*GameScene*类，当然类中我们还未实现任何东西，因此这是运行项目呈现出来的场景是漆黑一片。是时候一步步配置游戏场景了！

首先，定位到*GameScene*类中，在类中顶部添加如下三个变量，如下：



``` swift
class GameScene:SKScene:{
let worldNode = SKNode()
var playableStart:CGFloat = 0
var playableHeight:CGFloat = 0
//...文件其他内容
}
```

如上实例化了一个节点命名为`worldNode`,原因在于之后游戏中所有的节点都将添加至这个节点中，方便管理。此外游戏中场景分为*Background*和*Ground*两部分，前者是背景，鸟可以在该区域中上下飞行；后者地面，小鸟仅限于跌落至上面。具体划分请看下图:

![L01-Scene](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L01//L01-Scene.png)   

其中，背景和地面均作为节点添加至`worldNode`节点中。请在`didMoveToView(view:)`方法中添加如下代码:

``` swift
override func didMoveToView(view: SKView) {
    addChild(worldNode)
    setupBackground()
    setupForeground()
}
```

首先添加`worldNode`节点到场景中，接着`setupBackground()`和`setupForeground()`两个方法分别设置背景和地面两个节点，当然此时方法还未实现。

通常游戏包含多个节点，为了细化节点的图层关系，节点`Node`中设定了一个`zPosition`属性用于标识节点相距你的程度，越小越里面，越大越外面。显然游戏中，背景至于最底部，其次是地面，最后才是`Player`那只鸟。为此我们将使用枚举来说明层级关系，在`GameScene`类上方添加`Layer`的声明：

``` swift
enum Layer: CGFloat {
  case Background
  case Foreground
  case Player
}
class GameScene:SKScene{}
```

干完这些，是时候补充剩下的两个方法的实现了。首先添加`setupBackground()`方法至*GameScene*类中：    

``` swift
func setupBackground(){
    // 1
    let background = SKSpriteNode(imageNamed: "Background")
    background.anchorPoint = CGPointMake(0.5, 1)
    background.position = CGPointMake(size.width/2.0, size.height)
    background.zPosition = Layer.Background.rawValue
    worldNode.addChild(background)

    // 2
    playableStart = size.height - background.size.height
    playableHeight = background.size.height
}
```

依葫芦画瓢实现`setupForeground()`方法:

``` swift
func setupForeground() {

  let foreground = SKSpriteNode(imageNamed: "Ground")
  foreground.anchorPoint = CGPoint(x: 0, y: 1)
  foreground.position = CGPoint(x: 0, y: playableStart)
  foreground.zPosition = Layer.Foreground.rawValue
  worldNode.addChild(foreground)
}
```



点击运行，你将看到如下画面，*Good Job!* 你已经完成了第一步，之后我们将添加*Player*以及障碍物到场景中。



![L01-end](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L01/L01-end.png)



>倘若你觉得SpritKit的基础知识不够扎实，不妨看看[这个](http://blog.csdn.net/colouful987/article/category/2898663)。