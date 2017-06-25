//
//  TrapSetState.swift
//  DemoBots
//
//  Created by Tennant Shaw on 6/14/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import SpriteKit
import GameplayKit

class TrapSetState: GKState {
    
    // MARK: - Properties
    unowned var entity: Trap
    var elapsedTime: TimeInterval = 0.0
    static var appearTextures: [CompassDirection: SKTexture]?
    
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A Trap's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else { fatalError("A Trap's entity must have an RenderComponent.") }
        return renderComponent
    }
    
    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else { fatalError("A Trap's entity must have a PhysicsComponent.") }
        return physicsComponent
    }
    
    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity.component(ofType: OrientationComponent.self) else { fatalError("A Trap's entity must have an OrientationComponent.") }
        return orientationComponent
    }
    var node = SKSpriteNode()
    
    // MARK: - Initializers
    required init(entity: Trap) {
        self.entity = entity
    }

    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        elapsedTime = 0.0
        
        guard let appearTextures = Trap.appearTextures else {
            fatalError("Attempt to access Trap.appearTextures before they have been loaded.")
        }
        let texture = appearTextures[orientationComponent.compassDirection]!
        node.texture = texture
        node.size = Trap.textureSize
        node.isHidden = true
        
        renderComponent.node.addChild(node)
        
        animationComponent.node.isHidden = true
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        let contactedBodies = physicsComponent.physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let entity = contactedBody.node?.entity else { continue }
            print("Stepped on a trap. you dead dude")
            applyDamageToEntity(entity: entity)
            stateMachine?.enter(TrapSprungState.self)
            self.node.isHidden = false
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is TrapSprungState.Type
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        animationComponent.node.isHidden = false
    }
    
    // MARK: - Convenience
    func applyDamageToEntity(entity: GKEntity) {
        if let playerBot = entity as? PlayerBot, let chargeComponent = playerBot.component(ofType: ChargeComponent.self), !playerBot.isPoweredDown  {
            chargeComponent.loseCharge(chargeToLose: GameplayConfiguration.Trap.chargeLossPerContact)
        }
        else if let taskBot = entity as? TaskBot, taskBot.isGood {
            taskBot.isGood = false
        }
    }
    
    func adjustNodePhysics(entity: GKEntity) {
        if let playerBot = entity as? PlayerBot, let physicsComponent = playerBot.component(ofType: PhysicsComponent.self) {
            physicsComponent.physicsBody.collisionBitMask = (entity.component(ofType: PhysicsComponent.self)?.physicsBody.collisionBitMask)!
        }
    }
}
