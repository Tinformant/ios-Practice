//
//  GameViewController.swift
//  CrappyBirds
//
//  Created by Runze Si on 3/19/16.
//  Copyright (c) 2016 SiR. All rights reserved.
//


import SpriteKit

func randomX(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
    return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var background : SKSpriteNode!
    
    var bird : SKSpriteNode!
    var birdTextureAtlas = SKTextureAtlas(named: "player.atlas")
    var birdTextures = [SKTexture]()
    
    var explosionTextureAtlas = SKTextureAtlas(named: "explosion.atlas")
    var explosionTextures = [SKTexture]()
    
    var floors = [SKSpriteNode]()
    
    var pipes = [SKSpriteNode]()
    let pipeSpacing = CGFloat(800)
    
    let BIRD_CAT  : UInt32 = 0x1 << 0;
    let FLOOR_CAT : UInt32 = 0x1 << 1;
    let PIPE_CAT  : UInt32 = 0x1 << 2;
    
    var isRunning = true
    
    var bottomPipeY = CGFloat(0)
    var topPipeY = CGFloat(0)
    
    func didBeginContact(contact: SKPhysicsContact) {
        print("something colided")
        isRunning = false
        
        let explosion = SKAction.animateWithTextures(explosionTextures, timePerFrame: 0.1)
        //let removeBird = SKAction.removeFromParent()
        let actionSeq = SKAction.sequence([explosion])
        bird.runAction(actionSeq)
        bird.position.x = CGRectGetMidX(frame)
        isRunning = true
    }
    
    override func didMoveToView(view: SKView) {
        
        self.physicsWorld.contactDelegate = self
        
        // Keep bird from flying off screen
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)
        
        // Background
        background = SKSpriteNode(imageNamed: "background")
        background.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        background.zPosition = -1000
        addChild(background)
        
        // Bird
        for texName in explosionTextureAtlas.textureNames.sort() {
            let tex = explosionTextureAtlas.textureNamed(texName)
            explosionTextures.append(tex)
        }
        for texName in birdTextureAtlas.textureNames.sort() {
            let tex = birdTextureAtlas.textureNamed(texName)
            birdTextures.append(tex)
        }
        bird = SKSpriteNode(texture: birdTextures[0])
        bird.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
        bird.size.width /= 10
        bird.size.height /= 10
        let birdAnimation =  SKAction.repeatActionForever(SKAction.animateWithTextures(birdTextures, timePerFrame: 0.1))
        bird.runAction(birdAnimation)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.width/2)
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.restitution = 0.0
        bird.physicsBody?.categoryBitMask = BIRD_CAT
        bird.physicsBody?.collisionBitMask = FLOOR_CAT | PIPE_CAT
        bird.physicsBody?.contactTestBitMask = PIPE_CAT
        
        let particlesPath = NSBundle.mainBundle().pathForResource("MyParticle", ofType: "sks")!
        let particles = NSKeyedUnarchiver.unarchiveObjectWithFile(particlesPath) as! SKEmitterNode!
        bird.addChild(particles)
        addChild(bird)
        
        // Floors
        for i in 0 ..< 2 {
            let floor = SKSpriteNode(imageNamed: "floor")
            
            floor.anchorPoint = CGPointZero
            floor.position = CGPointMake(CGFloat(i) * floor.size.width, 0)
            
            var rect = floor.frame
            rect.origin.x = 0
            rect.origin.y = 0
            floor.physicsBody = SKPhysicsBody(edgeLoopFromRect: rect)
            floor.physicsBody?.dynamic = false
            floor.physicsBody?.categoryBitMask = FLOOR_CAT
            
            floors.append(floor)
            addChild(floor)
        }
        
        // Pipes
        for i in 0 ..< 2 {
            // Bottom
            let bottomPipe = SKSpriteNode(imageNamed: "bottomPipe")
            bottomPipe.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
            bottomPipe.size.width *= 0.5
            bottomPipe.size.height *= 0.5
            
            bottomPipe.position.y = CGRectGetMaxY(floors[i].frame) +
                0.5 * bottomPipe.size.height
            bottomPipeY = bottomPipe.position.y
            bottomPipe.position.x = CGFloat(i + 1) * pipeSpacing
            bottomPipe.physicsBody = SKPhysicsBody(texture: bottomPipe.texture!, size: bottomPipe.size)
            bottomPipe.physicsBody?.dynamic = false
            bottomPipe.physicsBody?.categoryBitMask = PIPE_CAT
            addChild(bottomPipe)
            pipes.append(bottomPipe)
            
            // Top
            let topPipe = SKSpriteNode(imageNamed: "topPipe")
            topPipe.position = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame))
            topPipe.size.width *= 0.5
            topPipe.size.height *= 0.5
            
            topPipe.position.y = CGRectGetMaxY(frame) -
                0.5 * topPipe.size.height
            topPipeY = topPipe.position.y
            
            topPipe.position.x = CGFloat(i + 1) * pipeSpacing
            topPipe.physicsBody = SKPhysicsBody(texture: topPipe.texture!, size: topPipe.size)
            topPipe.physicsBody?.dynamic = false
            topPipe.physicsBody?.categoryBitMask = PIPE_CAT
            
            addChild(topPipe)
            pipes.append(topPipe)
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 150))
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        if(isRunning) {
            bird.position.x = CGRectGetMidX(frame)
            
            // Move floor
            let floorSpeed = CGFloat(4)
            for floor in floors {
                floor.position.x -= floorSpeed
                
                if floor.position.x < -floor.size.width/2  {
                    floor.position.x += 2 * floor.size.width
                }
            }
            
            // Move pipes
            let pipeSpeed = CGFloat(3)
            
            for i in 0 ..< 4 {
                let pipe = pipes[i]
                pipe.position.x -= pipeSpeed
                
                if pipe.position.x < -pipe.size.width/2 {
                    pipe.position.x += 2 * pipeSpacing
                    
                    if(i % 2 == 0) { // bottom pipe
                        pipe.position.y = randomX(bottomPipeY - 300, secondNum: bottomPipeY)
                    } else { // top pipes
                        pipe.position.y = randomX(topPipeY, secondNum: topPipeY + 300)
                    }
                    
                }
            }
        }
    }
}