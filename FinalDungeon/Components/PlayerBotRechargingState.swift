/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the player when immobilized by `TaskBot` attacks.
*/

import SpriteKit
import GameplayKit

class PlayerBotRechargingState: GKState {
    
    // MARK: - Properties
    unowned var entity: PlayerBot
    var elapsedTime: TimeInterval = 0.0
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerBotRechargingState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    var chargeComponent: ChargeComponent {
        guard let chargeComponent = entity.component(ofType: ChargeComponent.self) else { fatalError("A PlayerBotRechargingState's entity must have a ChargeComponent.") }
        return chargeComponent
    }
    
    
    // MARK: - Initializers
    required init(entity: PlayerBot) {
        self.entity = entity
    }
    
    
    // MARK: - GKState life cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        elapsedTime = 0.0
        animationComponent.requestedAnimationState = .inactive
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        elapsedTime += seconds
        
        if elapsedTime < GameplayConfiguration.PlayerBot.rechargeDelayWhenInactive { return }
        
        let chargeComponent = self.chargeComponent
        
        let amountToRecharge = GameplayConfiguration.PlayerBot.rechargeAmountPerSecond * seconds
        chargeComponent.addCharge(chargeToAdd: amountToRecharge)
        
        if chargeComponent.isFullyCharged {
            entity.isPoweredDown = false
            stateMachine?.enter(PlayerBotPlayerControlledState.self)
        }
    }

    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayerBotPlayerControlledState.Type
    }
}
