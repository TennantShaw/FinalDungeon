//
//  Trap.swift
//  DemoBots
//
//  Created by Tennant Shaw on 6/14/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import SpriteKit
import GameplayKit

class Trap: GKEntity, ContactNotifiableType, GKAgentDelegate, ResourceLoadableType {
    
    // MARK: - Static Properties
    static var textureSize = CGSize(width: 100.0, height: 100.0)
    static var animations: [AnimationState: [CompassDirection: Animation]]?
    static var appearTextures: [CompassDirection: SKTexture]?

    
    // MARK: - Properties
    var targetPosition: float2?
    let agent: GKAgent2D
    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else { fatalError("A Trap must have an RenderComponent.") }
        return renderComponent
    }
    
    
    // MARK: - Initializers
    override init() {
        agent = GKAgent2D()
        super.init()
        let renderComponent = RenderComponent()
        addComponent(renderComponent)
        
        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)
        
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: GameplayConfiguration.Trap.physicsBodyRadius, center: GameplayConfiguration.Trap.physicsBodyOffset), colliderType: .Trap)
        addComponent(physicsComponent)
        
        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        guard let animations = Trap.animations else {
            fatalError("Attemp to access Trap.animations before they have been loaded.")
        }
        let animationComponent = AnimationComponent(textureSize: Trap.textureSize, animations: animations)
        addComponent(animationComponent)
        
        renderComponent.node.addChild(animationComponent.node)
        
        let intelligenceComponent = IntelligenceComponent(states: [
            TrapSetState(entity: self),
            TrapSprungState(entity: self)
            ])
        addComponent(intelligenceComponent)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    
    // MARK: - ContactNotifiableType
    func contactWithEntityDidBegin(_ entity: GKEntity) {
        
    }
    
    func contactWithEntityDidEnd(_ entity: GKEntity) {
        
    }
    
    // MARK: ResourceLoadableType
    
    static var resourcesNeedLoading: Bool {
        return appearTextures == nil || animations == nil
    }
    
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ()) {
        let trapAtlasNames = ["Trap"]
        
        SKTextureAtlas.preloadTextureAtlasesNamed(trapAtlasNames) { error, trapAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }
            
            appearTextures = [:]
            for orientation in CompassDirection.allDirections {
                appearTextures![orientation] = AnimationComponent.firstTextureForOrientation(compassDirection: orientation, inAtlas: trapAtlases[0], withImageIdentifier: "Trap")
            }
            
            // Set up all of the `PlayerBot`s animations.
            animations = [:]
            animations![.idle] = AnimationComponent.animationsFromAtlas(atlas: trapAtlases[0], withImageIdentifier: "Trap", forAnimationState: .idle)
            completionHandler()
        }
    }
    
    static func purgeResources() {
        appearTextures = nil
        animations = nil
    }

    // MARK: - Shared Assets
    class func loadSharedAssets() {
        ColliderType.definedCollisions[.Trap] = [
            .Obstacle,
            .PlayerBot,
            .Moogle,
            .Trap
        ]
        
        ColliderType.requestedContactNotifications[.Trap] = [
            .Obstacle,
            .PlayerBot,
            .Moogle,
            .Trap
        ]
    }


}
