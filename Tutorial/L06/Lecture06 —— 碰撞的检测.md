###Lecture06 —— 碰撞的检测


前文已经为各个精灵新增了*Physics Body*,设置了三个掩码:

* *categoryBitMask*表明了分属类别。
* *collisionBitMask*告知能与哪些物体碰撞。
* *contactTestBitMask*则告知能与哪些物体接触。

现在遗留的问题是如何检测碰撞?难道是在*update()*方法进行检测:遍历所有的节点，通过判断节点的位置是否有交集吗？天呐！这也太麻烦了。确实，如果通过自己实时检测实在过于劳累，何不让*Sprite Kit*来帮你代劳，每当物体之间发生碰撞了，立马通知你来处理事件。*Bingo！！* 显然这里要用**协议+代理**了，设置场景为代理，每当*Sprite Kit*检测到碰撞事件发生，就通知*GameScene*来处理，当前哪里事情都是在协议(*Protocol*)中声明了。

###01.游戏状态

在正式开始今天的碰撞检测课程之前，谈谈如何划分游戏各时的状态，仅以*Flappy bird*游戏为例，简单划分如下:

* *MaiMenu*。开始一次游戏、查看排名以及游戏帮助。
* *Tutorial*。考虑到新手对于新游戏的上手，在选择进行一次新游戏时，展示玩法教程显然是一个明确且友好的措施。
* *Play*。正处于游戏的状态。
* *Falling*。*Player*因为不小心碰到障碍物失败下落时刻。**注意:接触障碍物，失败掉落才算!**
* *ShowingScore*。显示得分。
* *GameeOver*。告知游戏结束。


为此请打开*Lecture05*的完成工程，打开*GameScene.swift*文件，新增游戏状态的枚举声明到`enum Layer{}`下方:

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

当然，我们还需要声明一个变量用于存储游戏场景的状态，请找到*GameScene*类中`let sombrero = SKSpriteNode(imageNamed: "Sombrero")`这条代码，在下方新增三个新变量:

```swift
//1
var hitGround = false
//2
var hitObstacle = false
//3
var gameState: GameState = .Play
```

1. 标识符，记录*Player*是否掉落至地面。
2. 标识符，记录*Player*是否碰撞了仙人掌。
3. 游戏状态，默认是正在玩。


###02.碰撞检测

正如前面提及的**协议+代理**方式检测物体之间的碰撞情况。首先请使得类*GameScene*遵循`SKPhysicsContactDelegate`协议:

```swift
class GameScene: SKScene,SKPhysicsContactDelegate{...}
```    

接着在*didMoveToView()*方法中设置代理为`self`，找到`physicsWorld.gravity = CGVector(dx: 0, dy: 0)`这行代码，添加该行代码`physicsWorld.contactDelegate = self`。

`SKPhysicsContactDelegate`协议中定义了两个可选方法,分别是:

* `optional public func didBeginContact(contact: SKPhysicsContact)`
* `optional public func didEndContact(contact: SKPhysicsContact)`

分别用于反馈两个物体开始接触、结束接触两个时刻。本文采用第一个方法用户处理物体接触事件。

```swift
func didBeginContact(contact: SKPhysicsContact) {
    let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
    
    if other.categoryBitMask == PhysicsCategory.Ground {
        hitGround = true
    }
    if other.categoryBitMask == PhysicsCategory.Obstacle {
        hitObstacle = true
    }
}
```    

`contact`包含了接触的所有信息，其中*bodyA*和*bodyB*代表两个碰撞的物体，显然发生碰撞的结果只有两种可能：1.*Player*和地面；2.*Player*和障碍物。可惜我们无法确实*bodyA*就是*Player*,亦或是*bodyB*就是它。这是有不确定性的，我们需要通过`categoryBitMask`来区分“阵营”。一旦确定哪个是*Player*之后，我们就能取到与之发生接触的*other*，通过判断其类别来分别置为标志位。


一旦标志位设置之后，我们需要在*update()*方法中进行处理了！


###03.根据游戏状态来处理事件

请定位到`update()`方法，修改其中的内容:

```swift
override func update(currentTime: CFTimeInterval) {
    if lastUpdateTime > 0 {
        dt = currentTime - lastUpdateTime
    } else {
        dt = 0
    }
    lastUpdateTime = currentTime
    
    switch gameState {
    case .MainMenu:
        break
    case .Tutorial:
        break
    case .Play:
        updateForeground()
        updatePlayer()
        //1
        checkHitObstacle()	//Play状态下检测是否碰撞了障碍物
        //2
        checkHitGround()	//Play状态下检测是否碰撞了地面
        break
    case .Falling:
        updatePlayer()
        //3
        checkHitGround()	//Falling状态下检测是否掉落至地面 此时已经失败了
        break
    case .ShowingScore:
        break
    case .GameOver:
        break
    }
}
```

其中1，2，3中三个方法均是通过状态标志位来处理碰撞事件，请添加`checkHitObstacle()`以及`checkHitGround()`方法到`updateForeground()`方法下方:

```swift
// 与障碍物发生碰撞
func checkHitObstacle() {
    if hitObstacle {
        hitObstacle = false
        switchToFalling()
    }
}
// 掉落至地面
func checkHitGround() {
    
    if hitGround {
        hitGround = false
        playerVelocity = CGPoint.zero
        player.zRotation = CGFloat(-90).degreesToRadians()
        player.position = CGPoint(x: player.position.x, y: playableStart + player.size.width/2)
        runAction(hitGroundAction)
        switchToShowScore()
    }
}

// MARK: - Game States
// 由Play状态变为Falling状态
func switchToFalling() {
    
    gameState = .Falling
    
    runAction(SKAction.sequence([
        whackAction,
        SKAction.waitForDuration(0.1),
        fallingAction
        ]))
    
    player.removeAllActions()
    stopSpawning()
    
}
// 显示分数状态
func switchToShowScore() {
    gameState = .ShowingScore
    player.removeAllActions()
    stopSpawning()
}
// 重新开始一次游戏
func switchToNewGame() {
    
    runAction(popAction)
    
    let newScene = GameScene(size: size)
    let transition = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.5)
    view?.presentScene(newScene, transition: transition)
    
}
```

完成后自然你发现`stopSpawning()`方法并未实现，因为我打算好好讲讲这个。早前在`didMoveToView()`方法中调用`startSpawning()`源源不断地产生障碍物，但是一旦游戏结束，我们所要做的事情有两个:1.停止继续产生障碍物；2.已经在场景中的障碍物停止移动。那么如何制定某个动作*Action*停止呢？答案是先为这个动作命名(简单来说设置一个**Key**而已)，然后用`removeActionForKey()`来移除。


OK,找到`startSpawning()`方法，将`runAction(overallSequence)`替换成`runAction(overallSequence, withKey: "spawn")`；定位到`spawnObstacle()`方法，分别设置*bottomObstacle*和*topObstacle*精灵的名字,方便之后找到它们并进行操作:

```swift
...
bottomObstacle.name = "BottomObstacle"
worldNode.addChild(bottomObstacle)
...
topObstacle.name = "TopObstacle"
worldNode.addChild(topObstacle)
...
```

现在来实现`stopSpawning()`方法,在`startSpawning()`下方添加就好:

```swift
func stopSpawning() {

 removeActionForKey("spawn")
 
 worldNode.enumerateChildNodesWithName("TopObstacle", usingBlock: { node, stop in
   node.removeAllActions()
 })
 worldNode.enumerateChildNodesWithName("BottomObstacle", usingBlock: { node, stop in
   node.removeAllActions()
 })
}
```

点击运行，我擦！还没来得及点就掉地上了......好吧，只能在游戏进入一瞬间先让*Player*向上蹦跶下。添加`flapPlayer()`到`didMoveToView()`方法的最下方。


点击运行，Nice!!*Player*顺利穿过了障碍，不小心碰到了障碍物，再点击，等等!怎么还能动...好吧，看来`touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?)`点击事件中我们并未根据游戏状态来处理，是时候修改了。

```swift
override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    switch gameState {
    case .MainMenu:
        break
    case .Tutorial:
        break
    case .Play:
        flapPlayer()
        break
    case .Falling:
        break
    case .ShowingScore:
        switchToNewGame()
        break
    case .GameOver:
        break
    }
}
```


点击运行，失败重新开始游戏...等等貌似还有问题，怎么点击想重新开始游戏会突然掉落到地面上...好吧，请看[lecture02](http://www.jianshu.com/p/82697ebf5cad)中的时间间隔图，匆忙的你找找原因，试试解决吧。

