/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the `TaskBot` when its movement is being managed by an `GKAgent`.
*/

import SpriteKit
import GameplayKit

class TaskBotAgentControlledState: GKState {
    
    // MARK: - Properties
    unowned var entity: TaskBot
    var elapsedTime: TimeInterval = 0.0
    var timeSinceBehaviorUpdate: TimeInterval = 0.0
    
    
    // MARK: - Initializers
    required init(entity: TaskBot) {
        self.entity = entity
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        timeSinceBehaviorUpdate = 0.0
        elapsedTime = 0.0
        
        entity.agent.behavior = entity.behaviorForCurrentMandate
        
        if let chargeComponent = entity.component(ofType: ChargeComponent.self), chargeComponent.hasCharge {
            let chargeToAdd = chargeComponent.maximumCharge - chargeComponent.charge
            chargeComponent.addCharge(chargeToAdd: chargeToAdd)
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        timeSinceBehaviorUpdate += seconds
        elapsedTime += seconds
        
        if timeSinceBehaviorUpdate >= GameplayConfiguration.TaskBot.behaviorUpdateWaitDuration {
            
            if case let .returnToPositionOnPath(position) = entity.mandate, entity.distanceToPoint(otherPoint: position) <= GameplayConfiguration.TaskBot.thresholdProximityToPatrolPathStartPoint {
                entity.mandate = entity.isGood ? .followGoodPatrolPath : .followBadPatrolPath
            }
            
            entity.agent.behavior = entity.behaviorForCurrentMandate
            
            timeSinceBehaviorUpdate = 0.0
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is GroundBotRotateToAttackState.Type, is TaskBotZappedState.Type:
            return true
            
        default:
            return false
        }
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        
        entity.agent.behavior = GKBehavior()
    }
}
