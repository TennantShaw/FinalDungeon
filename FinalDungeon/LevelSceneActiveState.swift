/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `LevelScene` to indicate that the game is actively being played. This state updates the current time of the level's countdown timer.
*/

import SpriteKit
import GameplayKit

class LevelSceneActiveState: GKState {
    
    // MARK: - Properties
    unowned let levelScene: LevelScene
    var timeRemaining: TimeInterval = 0.0
    let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()
    
    var timeRemainingString: String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, timeRemaining))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    
    // MARK: - Initializers
    init(levelScene: LevelScene) {
        self.levelScene = levelScene
        
        timeRemaining = levelScene.levelConfiguration.timeLimit
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        levelScene.timerNode.text = timeRemainingString
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        timeRemaining -= seconds
        
        levelScene.timerNode.text = timeRemainingString
        
        let moogleHeldCaptive = !levelScene.entities.contains { entity in
            if let moogle = entity as? Moogle {
                if moogle.isCaptive == true {
                    return moogle.isCaptive
                }
                return false
            }
            return false
        }
        
        // This is how you win or lose a level
        //
        //
        //
        //
        
        if moogleHeldCaptive {
            stateMachine?.enter(LevelSceneSuccessState.self)
        } else if timeRemaining <= 0.0 {
            stateMachine?.enter(LevelSceneFailState.self)
        }
        
        let allTaskBotsAreGood = !levelScene.entities.contains { entity in
            if let taskBot = entity as? TaskBot {
                return !taskBot.isGood
            }
            return false
        }
        
        if allTaskBotsAreGood {
            stateMachine?.enter(LevelSceneSuccessState.self)
        }
        else if timeRemaining <= 0.0 {
            stateMachine?.enter(LevelSceneFailState.self)
        }
        
        let playerHasCharge = !levelScene.entities.contains { entity in
            if let player = entity as? PlayerBot {
                return player.isPoweredDown
            }
            return false
        }
        
        if !playerHasCharge {
            stateMachine?.enter(LevelSceneFailState.self)
        } else if timeRemaining <= 0.0 {
            stateMachine?.enter(LevelSceneFailState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is LevelScenePauseState.Type, is LevelSceneFailState.Type, is LevelSceneSuccessState.Type:
            return true
            
        default:
            return false
        }
    }
}
