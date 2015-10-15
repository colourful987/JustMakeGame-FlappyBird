###Lecture09 —— 服务员，说好的菜单呢？

Lecture08课程结束，我们已经走过了90%，剩下的10%是对游戏体验的改进罢了。就比如，刚启动游戏，“Player”就出现在屏幕中Flap一下翅膀，然后还没等用户清楚这个游戏是什么情况的时候，“Player”已经坠地阵亡了。这种游戏体验可谓是差到极致，试想一个用户下载游戏并启动，此时还对游戏没有一丝认知，渴求先看看帮助说明或者玩法介绍之类吧！

因为本课程中，将剔除早前的直接进入游戏的弊端，通过添加主菜单供用户选择开始一次游戏亦或是查看游戏帮助说明等选项。如下:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L09/L09-MainMenu.png)

前文已经给出了游戏状态有如下几种:


```swift
enum GameState{
    case MainMenu
    case Tutorial
    case Play
    case Falling
    case ShowingScore
    case GameOver
}
```

当我们开始一个游戏的时候，必须制定当前新游戏的状态，比如是*MainMenu*显示主菜单呢还是直接进入正题*Play*开始进行游戏。为此我们自定义一个构造函数`init(size: CGSize, gameState: GameState) `传入gameState设置新游戏初识状态。请添加如下两个方法到*GameScene.swift*中的*GameScene*类中。

```swift
init(size: CGSize, gameState: GameState) {
    self.gameState = gameState
    super.init(size: size)
}
```

添加完毕之后，你会发现编译器报错，这也是情理之中，毕竟修改了构造方法导致早前的初始化方法都不能使用了。不急，慢慢修改。请定位到`switchToNewGame()`方法，要知道早前我们开始一个新游戏就是调用该函数，但是未指定新游戏的状态，为此我们要大刀阔斧地小改一番...如下：

```swift
func switchToNewGame(gameState: GameState) {	//改动1 添加了一个传入参数
    
    runAction(popAction)
    
    let newScene = GameScene(size: size,gameState:gameState)//修改传入参数
    let transition = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.5)
    view?.presentScene(newScene, transition: transition)
}
```

wo ca!!这下早前所有调用`switchToNewGame()`方法的地方都报错了。请不要着急，凡是循序渐进，首先找到`touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)`方法，这次真要大改一番了:


```swift
override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
	
	//1
   let touch = touches.first
   let touchLocation = touch?.locationInNode(self)
   
   switch gameState {
   case .MainMenu:
   		//2
       if touchLocation?.y < size.height * 0.15 {
           //TODO: 之后添加
       } else if touchLocation?.x < size.width * 0.6 {
       		//3
           switchToNewGame(.Tutorial)
       }
       break
   case .Tutorial:
       //TODO: 之后添加
       break
   case .Play:
       flapPlayer()
       break
   case .Falling:
       break
   case .ShowingScore:
       break
   case .GameOver:
   		//4
       if touchLocation?.x < size.width * 0.6 {
           switchToNewGame(.MainMenu)
       }
       break
   }
}
```

改动还是蛮大的，起码现在需要根据你点击的位置来执行相应的点击事件：

1. 获得第一个点击，然后得到在场景中的位置Position,自然就是点Point：包括x坐标值和y坐标值了。
2. 这里我们只是简单判断点击位置的范围，比如点击位置下偏下方时，就装作点击了"Learn to make this game的按钮"。
3. 倘若通过位置判断，你点击了*Play*按钮，则新建一个初始游戏状态为`.Tutorial`的新游戏，此时并不会立刻开始游戏，而是显示一个教程画面，只有当再次点击时才会开始游戏。
4. 此时处于游戏结束状态，通过点击OK按钮开启一个新游戏，但是游戏状态为.Menu。

此时还有个报错来自于"GameViewController.switf文件"，请找到` let scene = GameScene(size:CGSizeMake(320, 320 * aspectRatio))`这一行，改为我们定义的构造方法` let scene = GameScene(size:CGSizeMake(320, 320 * aspectRatio),gameState:.MainMenu)`即可。   

点击运行，我去!! 咋不灵了.....

貌似`didMoveToView()`方法中 我们并没有根据游戏初始状态来初始化游戏场景...请转到`GameScene`类中，定位到`didMoveToView()`,将其中内容替换成如下内容:


```swift
override func didMoveToView(view: SKView) {
    physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    physicsWorld.contactDelegate = self
    
    addChild(worldNode)
    
    // 以下为替换内容 
    if gameState == .MainMenu {
        switchToMainMenu()
    } else {
        switchToTutorial()
    }
}
//MARK: Game States 
//添加剩余两个场景切换方法
func switchToMainMenu() {
   
   gameState = .MainMenu
   setupBackground()
   setupForeground()
   setupPlayer()
   setupSomebrero()
   //TODO: 实现setupMainMenu()主界面布局 之后把注释去掉
   
}

func switchToTutorial() {
   gameState = .Tutorial
   setupBackground()
   setupForeground()
   setupPlayer()
   setupSomebrero()
   setupLabel()
   //TODO: 实现setupTutorial()教程界面布局 之后把注释去掉
}
```

其中我们还未实现对主界面的布局，以及教程界面的布局，这也是接下来所要干的事了。

**实现主界面的布局:**

代码貌似很长，但内容很熟悉不是吗，当年你在配置ScoreCard界面的时候不也这么做过？先布局几个button，然后执行几个动画罢了，请边码边回忆是怎么对精灵位置放置，添加动作的。

```swift
func setupMainMenu() {
     
     let logo = SKSpriteNode(imageNamed: "Logo")
     logo.position = CGPoint(x: size.width/2, y: size.height * 0.8)
     logo.zPosition = Layer.UI.rawValue
     worldNode.addChild(logo)
     
     // Play button
     let playButton = SKSpriteNode(imageNamed: "Button")
     playButton.position = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
     playButton.zPosition = Layer.UI.rawValue
     worldNode.addChild(playButton)
     
     let play = SKSpriteNode(imageNamed: "Play")
     play.position = CGPoint.zero
     playButton.addChild(play)
     
     // Rate button
     let rateButton = SKSpriteNode(imageNamed: "Button")
     rateButton.position = CGPoint(x: size.width * 0.75, y: size.height * 0.25)
     rateButton.zPosition = Layer.UI.rawValue
     worldNode.addChild(rateButton)
     
     let rate = SKSpriteNode(imageNamed: "Rate")
     rate.position = CGPoint.zero
     rateButton.addChild(rate)
     
     // Learn button
     let learn = SKSpriteNode(imageNamed: "button_learn")
     learn.position = CGPoint(x: size.width * 0.5, y: learn.size.height/2 + kMargin)
     learn.zPosition = Layer.UI.rawValue
     worldNode.addChild(learn)
     
     // Bounce button
     let scaleUp = SKAction.scaleTo(1.02, duration: 0.75)
     scaleUp.timingMode = .EaseInEaseOut
     let scaleDown = SKAction.scaleTo(0.98, duration: 0.75)
     scaleDown.timingMode = .EaseInEaseOut
     
     learn.runAction(SKAction.repeatActionForever(SKAction.sequence([
         scaleUp, scaleDown
         ])))
     
 }
```

**实现教程界面设置:**

反观这个教程界面就显得简单多了，只需要添加一章玩法帮助的图就ok了，如下:

```swift
func setupTutorial() {
    
    let tutorial = SKSpriteNode(imageNamed: "Tutorial")
    tutorial.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.4 + playableStart)
    tutorial.name = "Tutorial"
    tutorial.zPosition = Layer.UI.rawValue
    worldNode.addChild(tutorial)
    
    let ready = SKSpriteNode(imageNamed: "Ready")
    ready.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.7 + playableStart)
    ready.name = "Tutorial"
    ready.zPosition = Layer.UI.rawValue
    worldNode.addChild(ready)
    
}
```

好了，定位到`switchToMainMenu()`和`switchToTutorial()`方法，把*TODO字样的之后方法进行调用*。

点击运行项目，恩...出来了，而且再次点击Play会转到教程界面。不过再点击的话，貌似没反应了，聪明的你肯定会转到`touchesBegan()`方法，定位到.Tutorial状态，你会发现此时名下啥都没有，怎么可能开始愉快的玩耍呢？？？

为此在下方添加一个`switchToPlay()`方法并在.Tutorial下调用。

```swift
func switchToPlay() {
    // 从.Tutorial 状态转到.Play状态
    gameState = .Play
    
    // 移除Tutorial精灵 
    worldNode.enumerateChildNodesWithName("Tutorial", usingBlock: { node, stop in
        node.runAction(SKAction.sequence([
            SKAction.fadeOutWithDuration(0.5),
            SKAction.removeFromParent()
            ]))
    })
    
    // 开始产生障碍物 从右向左移动
    startSpawning()
    
    // 让Player 向上蹦跶一次...
    flapPlayer()
}
```

点击运行项目，请尽情享受成功的果实吧！

倘若你对游戏某一部分不太熟悉，请到[github]()下载所有课程的代码和课件。

> 此教程已接近尾声，博主忙于工作，文章更新速度不快，请见谅！ 请期待下文对游戏的进一步优化。
