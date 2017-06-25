/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the player when hit by a `TaskBot` attack.
*/

import SpriteKit
import GameplayKit

class PlayerBotHitState: GKState {
    
    // MARK: - Properties
    unowned var entity: PlayerBot
    var elapsedTime: TimeInterval = 0.0
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerBotHitState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    
    // MARK: - Initializers
    required init(entity: PlayerBot) {
        self.entity = entity
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        elapsedTime = 0.0
        animationComponent.requestedAnimationState = .hit
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        elapsedTime += seconds
        if elapsedTime >= GameplayConfiguration.PlayerBot.hitStateDuration {
            if entity.isPoweredDown {
                stateMachine?.enter(PlayerBotRechargingState.self)
            }
            else {
                stateMachine?.enter(PlayerBotPlayerControlledState.self)
            }
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is PlayerBotPlayerControlledState.Type, is PlayerBotRechargingState.Type:
            return true
            
        default:
            return false
        }
    }
}
