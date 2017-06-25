/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used to represent the player at level start when being 'beamed' into the level.
*/

import SpriteKit
import GameplayKit

class PlayerBotAppearState: GKState {
    
    // MARK: - Properties
    unowned var entity: PlayerBot
    var elapsedTime: TimeInterval = 0.0
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an RenderComponent.") }
        return renderComponent
    }
    
    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity.component(ofType: OrientationComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an OrientationComponent.") }
        return orientationComponent
    }
    
    var inputComponent: InputComponent {
        guard let inputComponent = entity.component(ofType: InputComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an InputComponent.") }
        return inputComponent
    }
    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else { fatalError("A PlayerBotPlayerControlledState's entity must have a PhysicsComponent.") }
        return physicsComponent
    }
    
    var node = SKSpriteNode()
    
    
    // MARK: - Initializers
    required init(entity: PlayerBot) {
        self.entity = entity
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        elapsedTime = 0.0
        
        guard let appearTextures = PlayerBot.appearTextures else {
            fatalError("Attempt to access PlayerBot.appearTextures before they have been loaded.")
        }
        let texture = appearTextures[orientationComponent.compassDirection]!
        node.texture = texture
        node.size = PlayerBot.textureSize
        
        node.shader = PlayerBot.teleportShader
        
        renderComponent.node.addChild(node)
        
        animationComponent.node.isHidden = true
        
        inputComponent.isEnabled = false
        
        let contactedBodies = physicsComponent.physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let entity = contactedBody.node?.entity else { continue }
            print("I'm touching you so softly, PlayerBotAppearState")
            setMoogleFree(entity: entity)
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        elapsedTime += seconds
        
        if elapsedTime > GameplayConfiguration.PlayerBot.appearDuration {
            node.removeFromParent()
            stateMachine?.enter(PlayerBotPlayerControlledState.self)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PlayerBotPlayerControlledState.Type
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        animationComponent.node.isHidden = false
        inputComponent.isEnabled = true
    }
    
    func setMoogleFree(entity: GKEntity) {
        if let moogle = entity as? Moogle, !moogle.isCaptive {
            moogle.isCaptive = false
        }
    }

    
}
