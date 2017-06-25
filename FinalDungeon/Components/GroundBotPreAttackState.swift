/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The state `GroundBot`s are in immediately prior to starting their ramming attack.
*/

import SpriteKit
import GameplayKit

class GroundBotPreAttackState: GKState {
    
    // MARK: - Properties
    unowned var entity: GroundBot
    var elapsedTime: TimeInterval = 0.0
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A GroundBotPreAttackState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    
    // MARK: - Initializers
    required init(entity: GroundBot) {
        self.entity = entity
    }
    
    
    // MARK: - GPState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        elapsedTime = 0.0
        
        animationComponent.requestedAnimationState = .attack
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        elapsedTime += seconds
        
        if elapsedTime >= GameplayConfiguration.TaskBot.preAttackStateDuration {
            stateMachine?.enter(GroundBotAttackState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is TaskBotAgentControlledState.Type, is GroundBotAttackState.Type, is TaskBotZappedState.Type:
            return true
            
        default:
            return false
        }
    }
}
