//
//  GameViewController.swift
//  FlappyBird
//
//  Created by pmst on 15/10/4.
//  Copyright (c) 2015年 pmst. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    
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
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
