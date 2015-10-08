###Lecture07 —— 老板，来块记分牌！

- “Hey!我昨天*Flappy Bird*得了100分!!!”
- “我叶良辰表示不服!”

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L07/L07-yeliangcheng2.jpg)


*Lecture06*课时完毕，我们已经初步完成游戏的主体，可惜却没有一个衡量得分的标准。类似*FlappyBird*游戏，当然是谁通过的障碍物越多，就越牛逼。不如我们设定如下规则:

* 通过一对障碍物得1分。
* 触碰地面或者障碍物判定失败，结算分数。


当前任务主要分为:

1. 显示分数牌
2. 如何判断通过障碍物。

###01.显示分数牌

像*Flappy Bird*的小游戏，我们不妨仅用*SKLabelNode*来显示分数，就类似平常我们所用的*UILabel*。请在`var gameState: GameState = .Play`语句下方添加对记分牌的声明`var scoreLabel: SKLabelNode!`,同时我们还需要用一个变量存储分数，继续在下方添加`var score = 0`;此外对于这些显示额外帮主内容的，我们还需要添加一个`UI`层，请修改早前的`Layer`枚举：

```swift
enum Layer: CGFloat {
    case Background
    case Obstacle
    case Foreground
    case Player
    case UI	//新内容
}
```

类似早前*setupBackground()*,*setupForeground()*那样，我们依葫芦画瓢设置记分牌，请添加一个方法，如下：

```swift
 func setupLabel() {
   scoreLabel = SKLabelNode(fontNamed: "AmericanTypewriter-Bold")
   scoreLabel.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
   scoreLabel.position = CGPoint(x: size.width/2, y: size.height - 20)
   scoreLabel.text = "0"
   scoreLabel.verticalAlignmentMode = .Top
   scoreLabel.zPosition = Layer.UI.rawValue
   worldNode.addChild(scoreLabel)
 }
```

注意到在设置字体名字为`AmericanTypewriter-Bold`过长且之后可能还需要用到，不妨新增一个常量`let kFontName = "AmericanTypewriter-Bold"`(在`kEverySpawnDelay`下方即可)，另外`size.height - 20`中的20是一个页边距，也是一个常量，不妨也一并替换掉，声明一个常量`let kMargin: CGFloat = 20.0`。**注意:新增的两个常量都是在GameScene类中作为全局变量。**

现在`setupLabel()`函数改为:

```swift
func setupLabel() {
  scoreLabel = SKLabelNode(fontNamed: kFontName)//改动1
  scoreLabel.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
  scoreLabel.position = CGPoint(x: size.width/2, y: size.height - kMargin)//改动2  
  scoreLabel.text = "0"
  scoreLabel.verticalAlignmentMode = .Top
  scoreLabel.zPosition = Layer.UI.rawValue
  worldNode.addChild(scoreLabel)
}
```

点击运行，不出意外屏幕正中间靠上已经显示一个大大的"0",可惜无论你经过多少个障碍物，还是鸭蛋，那是因为还未实现计分功能。

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L07/L07-ScoreScene.png)

###02.实现计分

**思路:**
在`update()`方法中，每隔大约33毫秒时间检测一次*Player*是否过了障碍物，倘若过了就得一分，不过这里又有一个问题，倘若已经得知过了第一个障碍物，但紧随33毫秒后之后，仍然只过了第一个障碍物，难道还得分？？显然不是!为此我们需要为已经过了一次的障碍物添加一个[Passed]标志，而没有过的障碍物是没有标志位为[]。如下图:


![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L07/L07-Passed.png)   

图中的设置了障碍物的标志位:["Passed"]或者[]两种。那么问题来了，哪里存储这些标志位呢？答案是*Sprite*中的`userData`属性，其类型是`NSMutableDictionary`可变字典，请在`func createObstacle()->SKSpriteNode{}`方法中找到`sprite.zPosition = Layer.Obstacle.rawValue`语句下添加一条新语句:

```swift
//...
sprite.userData = NSMutableDictionary()
//...
```
注意到一开始`userData`是一个空字典[],倘若执行`userData["Passed"] = NSNumber(bool: true)`，就新增了一个键为`Passed`，值为`true`的元素。

理解完这些，开始构思咱们的`updateScore()`方法:

```swift
func updateScore() {
worldNode.enumerateChildNodesWithName("BottomObstacle", usingBlock: { node, stop in
    if let obstacle = node as? SKSpriteNode {
        if let passed = obstacle.userData?["Passed"] as? NSNumber {
            if passed.boolValue {
                return
            }
        }
        if self.player.position.x > obstacle.position.x + obstacle.size.width/2 {
            self.score++
            self.scoreLabel.text = "\(self.score)"
            self.runAction(self.coinAction)
            obstacle.userData?["Passed"] = NSNumber(bool: true)
        }
    }
})
}
```

**讲解:**

1. 起初场景中产生的障碍物都是携带的[]空字典内容。
2. *Player*从一对障碍物的左侧穿越到右侧，才算"Passed",计分一次。
3. 检测方法很简单，只需要循环遍历*worldNode*节点中的所有障碍物，检查它的*userData*是否包含了*Passed*键值。两种情况:1.包含意味着当前障碍物已经经过且计算过分数了，所以无须再次累加，直接返回即可;2.当前障碍物为[]，说明还未被穿越过，因此需要通过位置检测(*Player*当前位置位于障碍物右侧?)，来判断是否穿越得分，是就分数累加且设置当前障碍物为已经"Passed"，否则什么都不处理，返回。

请将*updateScore()*添加到*update()*方法中**.Play**情况最下方。

点击运行，通过障碍物得分！！！


