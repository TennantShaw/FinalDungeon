/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the `TaskBot` when being zapped by a `PlayerBot` attack.
*/

import SpriteKit
import GameplayKit

class TaskBotZappedState: GKState {
    
    // MARK: - Properties
    unowned var entity: TaskBot
    var elapsedTime: TimeInterval = 0.0
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A TaskBotZappedState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    
    // MARK: - Initializers
    required init(entity: TaskBot) {
        self.entity = entity
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        elapsedTime = 0.0
        
        if let movementComponent = entity.component(ofType: MovementComponent.self) {
            movementComponent.nextTranslation = nil
            movementComponent.nextRotation = nil
            
        }
        
        animationComponent.requestedAnimationState = .zapped
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        elapsedTime += seconds
        
        if entity.isGood || elapsedTime >= GameplayConfiguration.TaskBot.zappedStateDuration {
            stateMachine?.enter(TaskBotAgentControlledState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is TaskBotZappedState.Type:
            elapsedTime = 0.0
            return false
            
        case is TaskBotAgentControlledState.Type:
            return true
            
        default:
            return false
        }
    }
}
