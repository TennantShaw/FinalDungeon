//
//  MoogleCaptiveState.swift
//  DemoBots
//
//  Created by Tennant Shaw on 6/13/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import SpriteKit
import GameplayKit

class MoogleCaptiveState: GKState {
    
    // MARK: - Properties
    unowned var entity: Moogle
    var elapsedTime: TimeInterval = 0.0
    static var appearTextures: [CompassDirection: SKTexture]?
    
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else { fatalError("A Moogle's entity must have an AnimationComponent.") }
        return animationComponent
    }
    
    var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else { fatalError("A Moogle's entity must have an RenderComponent.") }
        return renderComponent
    }
    
    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else { fatalError("A Moogle's entity must have a PhysicsComponent.") }
        return physicsComponent
    }

    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity.component(ofType: OrientationComponent.self) else { fatalError("A Moogle's entity must have an OrientationComponent.") }
        return orientationComponent
    }
    var node = SKSpriteNode()
    
    // MARK: - Initializers
    required init(entity: Moogle) {
        self.entity = entity
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        elapsedTime = 0.0
        
        let contactedBodies = physicsComponent.physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let entity = contactedBody.node?.entity else { continue }
            print("I know you touched me. MoogleCaptiveState")
            setMoogleFree(entity: entity)
        }
        
        guard let appearTextures = Moogle.appearTextures else {
            fatalError("Attempt to access Moogle.appearTextures before they have been loaded.")
        }
        let texture = appearTextures[orientationComponent.compassDirection]!
        node.texture = texture
        node.size = Moogle.textureSize
        
        renderComponent.node.addChild(node)
        
        animationComponent.node.isHidden = true
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is MoogleFreeState.Type
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        animationComponent.node.isHidden = false
    }
    
    func setMoogleFree(entity: GKEntity) {
        if let moogle = entity as? Moogle, !moogle.isCaptive {
            moogle.isCaptive = false
        }
    }

}
