/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the `PlayerBot` when ready for control input from the player.
*/

import SpriteKit
import GameplayKit

class PlayerBotPlayerControlledState: GKState {
    
    // MARK: - Properties
    unowned var entity: PlayerBot
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerBotPlayerControlledState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    var movementComponent: MovementComponent {
        guard let movementComponent = entity.component(ofType: MovementComponent.self) else { fatalError("A PlayerBotPlayerControlledState's entity must have a MovementComponent.") }
        return movementComponent
    }
    var inputComponent: InputComponent {
        guard let inputComponent = entity.component(ofType: InputComponent.self) else { fatalError("A PlayerBotPlayerControlledState's entity must have an InputComponent.") }
        return inputComponent
    }
    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else { fatalError("A PlayerBotPlayerControlledState's entity must have a PhysicsComponent.") }
        return physicsComponent
    }
    
    
    // MARK: - Initializers
    required init(entity: PlayerBot) {
        self.entity = entity
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        inputComponent.isEnabled = true
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        animationComponent.requestedAnimationState = .idle
        
        let contactedBodies = physicsComponent.physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let entity = contactedBody.node?.entity else { continue }
            print("I'm touching you so softly, PlayerBotPlayerControlledState")
            setMoogleFree(entity: entity)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is PlayerBotHitState.Type, is PlayerBotRechargingState.Type:
            return true
            
        default:
            return false
        }
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        entity.component(ofType: InputComponent.self)?.isEnabled = false
        let movementComponent = self.movementComponent
        movementComponent.nextTranslation = nil
        movementComponent.nextRotation = nil
    }
    
    func setMoogleFree(entity: GKEntity) {
        if let moogle = entity as? Moogle {
            moogle.isCaptive = false
        }
    }
}
