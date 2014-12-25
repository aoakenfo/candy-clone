//
//  GameScene.swift
//  CandyClone
//
//  Created by Edward Oakenfold on 2014-12-13.
//  Copyright (c) 2014 Edward Oakenfold. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let tileWidth = 32
    let tileHeight = 36
    let gameLayer = SKNode()
    let candyLayer = SKNode()
    let tileLayer = SKNode()
    
    var selectedCandySprites:[SKSpriteNode] = []
    
    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    let fallingCandySound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let newCandySound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    init(size: CGSize, row:Int, col:Int) {
        super.init(size: size)
        
        // center background image
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        let backgroundNode = SKSpriteNode(imageNamed: "background")
        addChild(backgroundNode)
        
        addChild(gameLayer)
        
        tileLayer.position = CGPoint(x: -tileWidth  * col / 2,
                                     y: -tileHeight * row / 2)
        gameLayer.addChild(tileLayer)
        
        candyLayer.position = tileLayer.position
        gameLayer.addChild(candyLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createCandySprites(candies:[Candy?]) {
        
        for i in 0..<CandyType.NumCandies.rawValue {
            let candyType = CandyType(rawValue: i)!
            let selectedSprite = SKSpriteNode(imageNamed: candyType.selectedSpriteName)
            selectedCandySprites.append(selectedSprite)
        }
 
        for i in 0..<candies.count {
            if let candy = candies[i] {
                let candySprite = SKSpriteNode(imageNamed: candy.type.spriteName)
                candySprite.position = CGPoint(
                    x: candy.col * tileWidth + tileWidth/2,
                    y: candy.row * tileHeight + tileHeight/2)
                candySprite.name = "candy"
                candy.sprite = candySprite
                candySprite.userData = ["candy":candy]
                candyLayer.addChild(candySprite)
                
                let tileSprite = SKSpriteNode(imageNamed: "Tile")
                tileSprite.position = candySprite.position
                tileSprite.alpha = 0.65
                tileLayer.addChild(tileSprite)
            }
        }
    }
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
    }
    
    func touchedCandy(touch:UITouch) -> Candy? {
        let location = touch.locationInNode(candyLayer)
        let touchedNode = candyLayer.nodeAtPoint(location)
        if touchedNode.name == "candy" {
            return touchedNode.userData!.objectForKey("candy") as? Candy
        }
        
        return nil
    }
    
    func selectCandy(candy:Candy) {
        let selectedSprite = selectedCandySprites[candy.type.rawValue]
        candy.sprite!.addChild(selectedSprite)
    }
    
    func deselectCandy(candy:Candy) {
        let selectedSprite = selectedCandySprites[candy.type.rawValue]
        selectedSprite.removeFromParent()
    }
    
    func animateSwap(swap:Swap, invalid:Bool, completion: () -> ()) {
        let spriteA = swap.a.sprite!
        let spriteB = swap.b.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration:NSTimeInterval = 0.25
        
        let moveA = SKAction.moveTo(spriteB.position, duration: duration)
        moveA.timingMode = .EaseOut
        
        let moveB = SKAction.moveTo(spriteA.position, duration: duration)
        moveB.timingMode = .EaseOut
        
        if invalid {
            spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
            spriteB.runAction(SKAction.sequence([moveB, moveA])) {
                self.runAction(self.invalidSwapSound)
            }
        }
        else {
            spriteA.runAction(moveA, completion: completion)
            spriteB.runAction(moveB) {
                self.runAction(self.swapSound)
            }
        }
    }
    
    func animateChainRemoval(chains:[[Candy]], completion: () -> ()) {
        let duration = 0.25
        for chain in chains {
            for candy in chain {
                let sprite = candy.sprite!
                if sprite.actionForKey("remove") == nil {
                    let scale = SKAction.scaleTo(0.1, duration: duration)
                    scale.timingMode = .EaseOut
                    sprite.runAction(SKAction.sequence([scale, SKAction.removeFromParent()]), withKey:"remove")
                }
            }
        }
        runAction(matchSound)
        runAction(SKAction.waitForDuration(duration), completion: completion)
    }
    
    func animateFallingCandies(filler:[[Candy]], completion: () -> ()) {
        var longestDuration:NSTimeInterval = 0
        
        for fill in filler {
            for (index, candy) in enumerate(fill) {
                let newPosition = CGPoint(
                    x: candy.col * tileWidth  + tileWidth/2,
                    y: candy.row * tileHeight + tileHeight/2)
                let sprite = candy.sprite!
                let duration = NSTimeInterval((sprite.position.y - newPosition.y) / CGFloat(tileHeight) * 0.1)
                let delay = NSTimeInterval(index) * 0.15 + 0.05
                longestDuration = max(longestDuration, duration + delay)
                
                let move = SKAction.moveTo(newPosition, duration: duration)
                move.timingMode = .EaseOut
                sprite.runAction(SKAction.sequence([SKAction.waitForDuration(delay),
                    SKAction.group([move, fallingCandySound])]))
            }
        }
        
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateNewCandies(newCandies:[[Candy]], completion: () -> ()) {
        var longestDuration:NSTimeInterval = 0
        
        for freshCandies in newCandies {
            
            // incoming array ordered from top to bottom
            let startingRow = freshCandies[0].row + 1
            
            for (index, candy) in enumerate(freshCandies) {
                
                let candySprite = SKSpriteNode(imageNamed: candy.type.spriteName)
                candySprite.position = CGPoint(
                    x: candy.col * tileWidth  + tileWidth/2,
                    y: startingRow * tileHeight + tileHeight/2)
                candySprite.name = "candy"
                candy.sprite = candySprite
                candySprite.userData = ["candy":candy]
                candyLayer.addChild(candySprite)
                
                let duration = NSTimeInterval(startingRow - candy.row) * 0.1
                let delay = NSTimeInterval(freshCandies.count - index - 1) * 0.2 + 0.1
                longestDuration = max(longestDuration, duration + delay)
                
                let newPosition = CGPoint(
                    x: candy.col * tileWidth  + tileWidth/2,
                    y: candy.row * tileHeight + tileHeight/2)
                
                let move = SKAction.moveTo(newPosition, duration: duration)
                move.timingMode = .EaseOut
                candySprite.alpha = 0
                let groupAction = SKAction.group([SKAction.fadeInWithDuration(0.05), move, newCandySound])
                candySprite.runAction(SKAction.sequence([SKAction.waitForDuration(delay), groupAction]))
            }
        }
     
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
