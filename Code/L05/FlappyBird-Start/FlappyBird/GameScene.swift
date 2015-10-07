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
    case Obstacle
    case Foreground
    case Player
}

class GameScene: SKScene {
    
    // MARK: - 常量
    let kGravity:CGFloat = -1500.0
    let kImpulse:CGFloat = 400
    let kGroundSpeed:CGFloat = 150.0
    let kBottomObstacleMinFraction: CGFloat = 0.1
    let kBottomObstacleMaxFraction: CGFloat = 0.6
    let kGapMultiplier: CGFloat = 3.5
    
    let worldNode = SKNode()
    var playableStart:CGFloat = 0
    var playableHeight:CGFloat = 0
    let player = SKSpriteNode(imageNamed: "Bird0")
    var lastUpdateTime :NSTimeInterval = 0
    var dt:NSTimeInterval = 0
    var playerVelocity = CGPoint.zero
    let sombrero = SKSpriteNode(imageNamed: "Sombrero")
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
        setupSomebrero()
        
        startSpawning()
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
    
    func setupSomebrero(){
        sombrero.position = CGPointMake(31 - sombrero.size.width/2, 29 - sombrero.size.height/2)
        player.addChild(sombrero)
    }

    
    // MARK: - GamePlay
    func createObstacle()->SKSpriteNode{
        let sprite = SKSpriteNode(imageNamed: "Cactus")
        sprite.zPosition = Layer.Obstacle.rawValue
        return sprite
    }
    
    func spawnObstacle(){
        //1
        let bottomObstacle = createObstacle()
        let startX = size.width + bottomObstacle.size.width/2
        
        let bottomObstacleMin = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMinFraction
        let bottomObstacleMax = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMaxFraction
        bottomObstacle.position = CGPointMake(startX, CGFloat.random(min: bottomObstacleMin, max: bottomObstacleMax))
        worldNode.addChild(bottomObstacle)
        
        let topObstacle = createObstacle()
        topObstacle.zRotation = CGFloat(180).degreesToRadians()
        topObstacle.position = CGPoint(x: startX, y: bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + player.size.height * kGapMultiplier)
        worldNode.addChild(topObstacle)
        
        let moveX = size.width + topObstacle.size.width
        let moveDuration = moveX / kGroundSpeed
        let sequence = SKAction.sequence([
            SKAction.moveByX(-moveX, y: 0, duration: NSTimeInterval(moveDuration)),
            SKAction.removeFromParent()
            ])
        topObstacle.runAction(sequence)
        bottomObstacle.runAction(sequence)
    }

    func startSpawning(){
        let firstDelay = SKAction.waitForDuration(1.75)
        let spawn = SKAction.runBlock(spawnObstacle)
        let everyDelay = SKAction.waitForDuration(1.5)
        let spawnSequence = SKAction.sequence([
            spawn,everyDelay
            ])
        let foreverSpawn = SKAction.repeatActionForever(spawnSequence)
        let overallSequence = SKAction.sequence([firstDelay,foreverSpawn])
        runAction(overallSequence)
    }
    func setupPlayer(){
        player.position = CGPointMake(size.width * 0.2, playableHeight * 0.4 + playableStart)
        player.zPosition = Layer.Player.rawValue
        worldNode.addChild(player)
    }
    func flapPlayer(){
        // 发出一次煽动翅膀的声音
        runAction(flapAction)
        // 重新设定player的速度！！
        playerVelocity  = CGPointMake(0, kImpulse)
        
        // 使得帽子下上跳动
        let moveUp = SKAction.moveByX(0, y: 12, duration: 0.15)
        moveUp.timingMode = .EaseInEaseOut
        let moveDown = moveUp.reversedAction()
        sombrero.runAction(SKAction.sequence([moveUp,moveDown]))
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
        updateForeground()
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
    func updateForeground(){
        worldNode.enumerateChildNodesWithName("foreground") { (node, stop) -> Void in
            if let foreground = node as? SKSpriteNode{
                let moveAmt = CGPointMake(-self.kGroundSpeed * CGFloat(self.dt), 0)
                foreground.position += moveAmt
                
                if foreground.position.x < -foreground.size.width{
                  foreground.position += CGPoint(x: foreground.size.width * CGFloat(2), y: 0)
                }
            }
        }
    }
}


















