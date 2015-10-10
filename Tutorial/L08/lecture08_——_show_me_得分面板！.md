### Lecture08 —— Show Me 得分面板！


课时7中实现了得分机制，当你越战越勇，得分也蹭蹭地往上加，不过马有失蹄，人有失足，总会不小心失败，这时候就要结算你的劳动成果了:通常都是告知游戏结束，得分几何，最好成绩等等信息。咱们游戏是这么设计的:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L08/L08-panel.png)

**本文任务:**

* 当游戏结束时呈现上图的内容。

**思路：**

* 简单来说就是实例化几个特定纹理(你可以理解为照片*image*)的精灵，然后按照特定布局放置到屏幕中，是不是灰常简单呢?


###01.使用NSUserDefaults来保存数据

使用*NSUserDefaults*用于持久性的保存得分记录是一个明智的决定，我们不可能为了存一个数据而使用诸如`Core Data`或者`Sqlite`等数据库。

####1-1 从NSUserDefault中读取分数

请在*GameScene*类中添加一个新方法，用于读取游戏记录得分:

```swift
func bestScore()->Int{
    return NSUserDefaults.standardUserDefaults().integerForKey("BestScore")
}
```   

可以看到方法中为最高得分设置了名为"BestScore"的键。

####1-2 在NSUserDefault中设置分数

有读取自然有写，请在*bestScore()*方法下方添加一个新方法:

```swift
func setBestScore(bestScore:Int){
    NSUserDefaults.standardUserDefaults().setInteger(bestScore, forKey: "BestScore")
    NSUserDefaults.standardUserDefaults().synchronize()
}
```


###02.构建得分面板

得分面板如文中给出图片布局，工程量还是蛮大的，不过我会一步一步讲解，无需担心一口吃撑的情况。

首先请找到*setupLabel*方法，在它下方声明咱们的设置得分面板的函数，取名为`setupScorecard()`:

```swift
func setupScorecard() {
   //1
   if score > bestScore() {
     setBestScore(score)
   } 
   //...等下添加其他内容
}
```
* 首先调用`bestScore()`取到历史最高得分，与本回合得分比较，倘若这次“走狗屎运”得了高分，咱们就要更新历史最高纪录，也就是调用`setBestScore(score)`方法。

接着，着手添加得分面板的精灵，内容有点多，请注意别码错:

```swift
func setupScorecard() {
 
   if score > bestScore() {
     setBestScore(score)
   }
   
   // 1 得分面板背景
   let scorecard = SKSpriteNode(imageNamed: "ScoreCard")
   scorecard.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
   scorecard.name = "Tutorial"
   scorecard.zPosition = Layer.UI.rawValue
   worldNode.addChild(scorecard)
   
   // 2 本次得分
   let lastScore = SKLabelNode(fontNamed: kFontName)
   lastScore.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
   lastScore.position = CGPoint(x: -scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
   lastScore.text = "\(score)"
   scorecard.addChild(lastScore)
   
   // 3 最好成绩
   let bestScoreLabel = SKLabelNode(fontNamed: kFontName)
   bestScoreLabel.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
   bestScoreLabel.position = CGPoint(x: scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
   bestScoreLabel.text = "\(self.bestScore())"
   scorecard.addChild(bestScoreLabel)
   
   // 4 游戏结束
   let gameOver = SKSpriteNode(imageNamed: "GameOver")
   gameOver.position = CGPoint(x: size.width/2, y: size.height/2 + scorecard.size.height/2 + kMargin + gameOver.size.height/2)
   gameOver.zPosition = Layer.UI.rawValue
   worldNode.addChild(gameOver)
   
   // 5 ok按钮背景以及ok标签
   let okButton = SKSpriteNode(imageNamed: "Button")
   okButton.position = CGPoint(x: size.width * 0.25, y: size.height/2 - scorecard.size.height/2 - kMargin - okButton.size.height/2)
   okButton.zPosition = Layer.UI.rawValue
   worldNode.addChild(okButton)
   
  
   let ok = SKSpriteNode(imageNamed: "OK")
   ok.position = CGPoint.zeroPoint
   ok.zPosition = Layer.UI.rawValue
   okButton.addChild(ok)
   
   // 6 share按钮背景以及share标签
   let shareButton = SKSpriteNode(imageNamed: "Button")
   shareButton.position = CGPoint(x: size.width * 0.75, y: size.height/2 - scorecard.size.height/2 - kMargin - shareButton.size.height/2)
   shareButton.zPosition = Layer.UI.rawValue
   worldNode.addChild(shareButton)
   

   let share = SKSpriteNode(imageNamed: "Share")
   share.position = CGPoint.zeroPoint
   share.zPosition = Layer.UI.rawValue
   shareButton.addChild(share)
}
```

当你码完了这一段超长代码之后，你会松一口气，现在还有一步就能享受胜利的果实了!!
想想我们时候什么需要显示这个得分面板。*Player*掉落失败的时候，对吗?请找到`switchToShowScore()`方法，在最下方调用`setupScorecard()`，点击运行，过几个障碍物，然后自由落体，看看是否良好地显示了得分面板。

Good Job!显示本次得分，历史最高纪录以及选项按钮——不过此时并没有什么卵用。

你有木有发现得分面板“毫无征兆”地就出现在了场景中央，来加个动画吧!!!


###03.为得分面板添加动画

请回到原先的`setupScorecard()`方法，继续再下方添加动画代码:

```swift

//=== 添加一个常量 用于定义动画时间 ====
let kAnimDelay = 0.3

func setupScorecard() {
	//。。。。。。
	//==== 以下是新添加的内容 =====
	gameOver.setScale(0)
	gameOver.alpha = 0
	let group = SKAction.group([
	   SKAction.fadeInWithDuration(kAnimDelay),
	   SKAction.scaleTo(1.0, duration: kAnimDelay)
	   ])
	group.timingMode = .EaseInEaseOut
	gameOver.runAction(SKAction.sequence([
	   SKAction.waitForDuration(kAnimDelay),
	   group
	   ]))
	
	scorecard.position = CGPoint(x: size.width * 0.5, y: -scorecard.size.height/2)
	let moveTo = SKAction.moveTo(CGPoint(x: size.width/2, y: size.height/2), duration: kAnimDelay)
	moveTo.timingMode = .EaseInEaseOut
	scorecard.runAction(SKAction.sequence([
	   SKAction.waitForDuration(kAnimDelay * 2),
	   moveTo
	   ]))
	
	okButton.alpha = 0
	shareButton.alpha = 0
	let fadeIn = SKAction.sequence([
	   SKAction.waitForDuration(kAnimDelay * 3),
	   SKAction.fadeInWithDuration(kAnimDelay)
	   ])
	okButton.runAction(fadeIn)
	shareButton.runAction(fadeIn)
	
	let pops = SKAction.sequence([
	   SKAction.waitForDuration(kAnimDelay),
	   popAction,
	   SKAction.waitForDuration(kAnimDelay),
	   popAction,
	   SKAction.waitForDuration(kAnimDelay),
	   popAction,
	   SKAction.runBlock(switchToGameOver)
	   ])
	runAction(pops)
}
```


点击运行，玩耍吧!


> 注意: 我发现了一个BUG，倘若游戏一开始就使得它下落触碰地面，弹出的得分面板*share*标签放置位置是错误的，因为它的背景以`let shareButton = SKSpriteNode(imageNamed: "Button")` 返回的是一个精灵`size=0`，让我百思不得其解。希望找到问题的朋友可以告知我。




