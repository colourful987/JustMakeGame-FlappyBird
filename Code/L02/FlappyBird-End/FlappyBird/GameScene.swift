//
//  GameScene.swift
//  FlappyBird
//
//  Created by pmst on 15/10/4.
//  Copyright (c) 2015年 pmst. All rights reserved.
//

import SpriteKit

enum Layer: CGFloat {
    case Background
    case Foreground
    case Player
}

class GameScene: SKScene {
    
    // MARK: - 常量
    let kGravity:CGFloat = -1500.0
    let kImpulse:CGFloat = 400
    
    let worldNode = SKNode()
    var playableStart:CGFloat = 0
    var playableHeight:CGFloat = 0
    let player = SKSpriteNode(imageNamed: "Bird0")
    var lastUpdateTime :NSTimeInterval = 0
    var dt:NSTimeInterval = 0
    var playerVelocity = CGPoint.zero
    
    // MARK: - 变量
    
    
    // MARK: - 音乐
    let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
    let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
    let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
    let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
    
    override func didMoveToView(view: SKView) {
        addChild(worldNode)
        setupBackground()
        setupForeground()
        setupPlayer()
    }
    
    // MARK: Setup Method
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
    
    func setupForeground() {
        
        let foreground = SKSpriteNode(imageNamed: "Ground")
        foreground.anchorPoint = CGPoint(x: 0, y: 1)
        foreground.position = CGPoint(x: 0, y: playableStart)
        foreground.zPosition = Layer.Foreground.rawValue
        worldNode.addChild(foreground)
    }
    func setupPlayer(){
        player.position = CGPointMake(size.width * 0.2, playableHeight * 0.4 + playableStart)
        player.zPosition = Layer.Player.rawValue
        worldNode.addChild(player)
    }
    
    // MARK: - GamePlay
    func flapPlayer(){
        // 发出一次煽动翅膀的声音
        runAction(flapAction)
        // 重新设定player的速度！！
        playerVelocity  = CGPointMake(0, kImpulse)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        flapPlayer()
    }
    // MARK: - Updates
    override func update(currentTime: CFTimeInterval) {
        if lastUpdateTime > 0{
            dt = currentTime - lastUpdateTime
        }else{
            dt = 0
        }
        lastUpdateTime = currentTime
        
        updatePlayer()
    }
    
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
}
