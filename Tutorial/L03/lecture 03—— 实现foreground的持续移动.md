###Lecture 03 —— 实现foreground的持续移动


####本文任务

* 游戏运行中，*Foreground*地面持续滚动。


###持续移动地面

**任务一需要解决的问题**:

1. 如何移动地面。
2. 如何无缝连接。

**问题一**的解决思路是每次渲染完毕进入`update()`方法中更新*Foreground*的坐标位置，即改变*position*的*x*值。
    
**问题二**的解决思路是实例化两个*Foreground*，相邻紧挨，以约定好的速度向左移动，当第一个节点位置超出屏幕范围(对玩家来说是不可见)时，改变其坐标位置，添加到第二个节点尾部，如此循环实现无缝连接，参考图为:

![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L03/L03-Window.png)
![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L03/L03-ForegroundOne.png)
![](https://raw.githubusercontent.com/colourful987/JustMakeGame-FlappyBird/master/Resource/L03/L03-ForegroundTwo.png)


**代码实现:**

找到*GameScene*类中的`setupForeground()`方法，由于现在需要实例化两个*Foreground*，显然早前的已不再使用，替换方法中的所有内容:

```swift
func setupForeground() {
    for i in 0..<2{
        let foreground = SKSpriteNode(imageNamed: "Ground")
        foreground.anchorPoint = CGPoint(x: 0, y: 1)
        // 改动1
        foreground.position = CGPoint(x: CGFloat(i) * size.width, y: playableStart)
        foreground.zPosition = Layer.Foreground.rawValue
        // 改动2
        foreground.name = "foreground"
        worldNode.addChild(foreground)
    }
}
```    

注意我们采用`for-in`进行2次实例化，代码有两处改动:1.放置位置与*i*值相关；2.给节点取名为“foreground”,方便之后查找操作。

*Foreground*匀速移动，自然速度值需要固定，姑且这里设为150.0，请在`let kImpulse: CGFloat = 400.0`下方添加一行速度常量定义`let kGroundSpeed: CGFloat = 150.0`。

对于*Foreground*的位置更新自然也是在方法`update()`中进行了，每隔大约33毫秒就跳入该函数更新*position*。就像早前`updatePlayer()`一样，在其下方声明一个名为*updateForeground*方法。

```swift
func updateForeground(){
   //1
   worldNode.enumerateChildNodesWithName("foreground") { (node, stop) -> Void in
   		//2
       if let foreground = node as? SKSpriteNode{
       		//3
           let moveAmt = CGPointMake(-self.kGroundSpeed * CGFloat(self.dt), 0)
           foreground.position += moveAmt
           //4
           if foreground.position.x < -foreground.size.width{
             foreground.position += CGPoint(x: foreground.size.width * CGFloat(2), y: 0)
           }
       }
   }
}
```    

讲解:

1. 还记得先前设置了*Foreground*节点的名字为*foreground*吗？通过`enumerateChildNodesWithName`方法即可遍历所有名为*foreground*的节点。
2. 注意*node*是`SKNode`类型，而*foreground*精灵是`SKSpriteNode`类型，需要向下变形。
3. 计算dt时间中*foreground*移动的距离，更新*position*坐标位置。
4. 倘若该*foreground*超出了屏幕，则正如前面所说的将其添加到第二个精灵尾部。

> 4中的位置条件判断，希望读者理解透彻。首先*SpriteKit*中坐标系与之前不同，原点位于左下角，x轴正方向自左向右，y轴正方向自下向上；其次*wordNode*节点位于原点处，因此它内部的坐标系也是以左下角为原点。请集合上文图片进行理解。


ok，将`updateForeground`方法添加到`update()`中的最下面即可，点击运行。
