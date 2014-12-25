//
//  GameViewController.swift
//  CandyClone
//
//  Created by Edward Oakenfold on 2014-12-13.
//  Copyright (c) 2014 Edward Oakenfold. All rights reserved.
//

// credit:
// http://www.raywenderlich.com/75270/make-game-like-candy-crush-with-swift-tutorial-part-1
// Matthijs Hollemans did all the hard work
// this impl is slightly different, smaller, with a stricter MVC and bug fixes

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {

    var level:Level! // model
    var scene:GameScene! // view
    
    var swipeFromCandy:Candy?
    var canHandleInput:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        level = Level()

        let skView = self.view as SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        skView.multipleTouchEnabled = false
        
        scene = GameScene(size: skView.bounds.size, row: level.numRow, col: level.numCol)
        scene.scaleMode = .AspectFill
        
        let candies = level.shuffle()
        scene.createCandySprites(candies)
        canHandleInput = true
        
        skView.presentScene(scene)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if canHandleInput {
            let touch = touches.anyObject() as UITouch
            if let touchedCandy = scene.touchedCandy(touch) {
                swipeFromCandy = touchedCandy
                scene.selectCandy(touchedCandy)
            }
        }
    }
    
    func handleMatchingCandies() {
        var chains = self.level.findChains()
        if chains.count == 0 {
            self.level.updatePossibleSwaps()
            self.canHandleInput = true
            return
        }
        self.level.removeCandies(chains)
        self.scene.animateChainRemoval(chains) {
            let filler = self.level.fillHoles()
            self.scene.animateFallingCandies(filler) {
                let newCandies = self.level.addNewCandies()
                self.scene.animateNewCandies(newCandies) {
                    self.handleMatchingCandies()
                }
            }
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if swipeFromCandy != nil {
            let touch = touches.anyObject() as UITouch
            if let swipeToCandy = scene.touchedCandy(touch) {
                let swap = Swap(fromCandy: swipeFromCandy!, toCandy: swipeToCandy)
                if level.isNeighbourSwap(swap) {
                    swipeFromCandy = nil // disable further candy input until touch begins again
                    canHandleInput = false
                    scene.deselectCandy(swap.a)
                    if level.isPossibleSwap(swap) {
                        level.performSwap(swap)
                        scene.animateSwap(swap, invalid: false) {
                            self.handleMatchingCandies()
                        }
                    }
                    else {
                        scene.animateSwap(swap, invalid: true) {
                            self.canHandleInput = true
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        // in case user never selected another candy
        if let candy = swipeFromCandy {
            scene.deselectCandy(candy)
            swipeFromCandy = nil
        }
    }
    
    override func touchesCancelled(touches: NSSet, withEvent event: UIEvent) {
        touchesEnded(touches, withEvent: event)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
