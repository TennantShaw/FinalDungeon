/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state that `GroundBot`s enter prior to rotate toward the `PlayerBot` or another `TaskBot` prior to attack.
*/

import SpriteKit
import GameplayKit

class GroundBotRotateToAttackState: GKState {
    
    // MARK: - Properties
    unowned var entity: GroundBot
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A GroundBotRotateToAttackState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity.component(ofType: OrientationComponent.self) else { fatalError("A GroundBotRotateToAttackState's entity must have an OrientationComponent.") }
        return orientationComponent
    }
    var targetPosition: float2 {
        guard let targetPosition = entity.targetPosition else { fatalError("A GroundBotRotateToAttackState's entity must have a targetLocation set.") }
        return targetPosition
    }
    
    
    // MARK: - Initializers
    required init(entity: GroundBot) {
        self.entity = entity
    }
    
    
    // MARK: - GPState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        animationComponent.requestedAnimationState = .walkForward
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        let orientationComponent = self.orientationComponent
        
        let angleDeltaToTarget = shortestAngleDeltaToTargetFromRotation(entityRotation: Float(orientationComponent.zRotation))
        
        var delta = CGFloat(seconds * GameplayConfiguration.GroundBot.preAttackRotationSpeed)
        if angleDeltaToTarget < 0 {
            delta *= -1
        }
        
        if abs(delta) >= abs(angleDeltaToTarget) {
            orientationComponent.zRotation += angleDeltaToTarget
            stateMachine?.enter(GroundBotPreAttackState.self)
            return
        }
        
        orientationComponent.zRotation += delta
        
        animationComponent.requestedAnimationState = .walkForward
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is TaskBotAgentControlledState.Type, is GroundBotPreAttackState.Type, is TaskBotZappedState.Type:
            return true
            
        default:
            return false
        }
    }
    
    
    // MARK: - Convenience
    func shortestAngleDeltaToTargetFromRotation(entityRotation: Float) -> CGFloat {
        let groundBotPosition = entity.agent.position
        let targetPosition = self.targetPosition
        
        let translationVector = float2(x: targetPosition.x - groundBotPosition.x, y: targetPosition.y - groundBotPosition.y)
        
        let angleVector = float2(x: cos(entityRotation), y: sin(entityRotation))
        
        let dotProduct = dot(translationVector, angleVector)
        let crossProduct = cross(translationVector, angleVector)
        
        let translationVectorMagnitude = hypot(translationVector.x, translationVector.y)
        let angle = acos(dotProduct / translationVectorMagnitude)
        
        if crossProduct.z < 0 {
            return CGFloat(angle)
        }
        else {
            return CGFloat(-angle)
        }
    }
    
}
