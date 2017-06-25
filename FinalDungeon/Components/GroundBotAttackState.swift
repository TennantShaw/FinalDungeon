/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The state of a `GroundBot` when actively charging toward the `PlayerBot` or another `TaskBot`.
*/

import SpriteKit
import GameplayKit

class GroundBotAttackState: GKState {
    
    // MARK: - Properties
    unowned var entity: GroundBot
    var lastDistanceToTarget: Float = 0
    var movementComponent: MovementComponent {
        guard let movementComponent = entity.component(ofType: MovementComponent.self) else { fatalError("A GroundBotAttackState's entity must have a MovementComponent.") }
        return movementComponent
    }
    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else { fatalError("A GroundBotAttackState's entity must have a PhysicsComponent.") }
        return physicsComponent
    }
    var targetPosition: float2 {
        guard let targetPosition = entity.targetPosition else { fatalError("A GroundBotRotateToAttackState's entity must have a targetPosition set.") }
        return targetPosition
    }
    
    
    // MARK: - Initializers
    required init(entity: GroundBot) {
        self.entity = entity
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        let contactedBodies = physicsComponent.physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let entity = contactedBody.node?.entity else { continue }
            print("I just smacked the pants off yo ass")
            applyDamageToEntity(entity: entity)
        }
        
        let targetPosition = self.targetPosition
        
        let dx = targetPosition.x - entity.agent.position.x
        let dy = targetPosition.y - entity.agent.position.y
        
        lastDistanceToTarget = hypot(dx, dy)
        let targetVector = float2(x: Float(dx), y: Float(dy))
        
        let movementComponent = self.movementComponent
        
        movementComponent.movementSpeed *= GameplayConfiguration.GroundBot.movementSpeedMultiplierWhenAttacking
        movementComponent.angularSpeed *= GameplayConfiguration.GroundBot.angularSpeedMultiplierWhenAttacking
        
        movementComponent.nextTranslation = MovementKind(displacement: targetVector)
        movementComponent.nextRotation = nil
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        let targetPosition = self.targetPosition
        
        let dx = targetPosition.x - entity.agent.position.x
        let dy = targetPosition.y - entity.agent.position.y
        
        let currentDistanceToTarget = hypot(dx, dy)
        if currentDistanceToTarget < GameplayConfiguration.GroundBot.attackEndProximity {
            stateMachine?.enter(TaskBotAgentControlledState.self)
            return
        }
        
        if currentDistanceToTarget > lastDistanceToTarget {
            stateMachine?.enter(TaskBotAgentControlledState.self)
            return
        }
        
        lastDistanceToTarget = currentDistanceToTarget
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is TaskBotAgentControlledState.Type, is TaskBotZappedState.Type:
            return true
            
        default:
            return false
        }
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        
        let movementComponent = self.movementComponent
        
        movementComponent.nextRotation = nil
        movementComponent.nextTranslation = nil
        movementComponent.movementSpeed /= GameplayConfiguration.GroundBot.movementSpeedMultiplierWhenAttacking
        movementComponent.angularSpeed /= GameplayConfiguration.GroundBot.angularSpeedMultiplierWhenAttacking
    }
    
    
    // MARK: - Convenience
    func applyDamageToEntity(entity: GKEntity) {
        if let playerBot = entity as? PlayerBot, let chargeComponent = playerBot.component(ofType: ChargeComponent.self), !playerBot.isPoweredDown  {
            chargeComponent.loseCharge(chargeToLose: GameplayConfiguration.GroundBot.chargeLossPerContact)
        }
        else if let taskBot = entity as? TaskBot, taskBot.isGood {
            taskBot.isGood = false
        }
    }
    
}
