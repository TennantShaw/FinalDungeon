//
//  Moogle.swift
//  DemoBots
//
//  Created by Tennant Shaw on 6/13/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import SpriteKit
import GameplayKit

class Moogle: GKEntity, ContactNotifiableType, GKAgentDelegate, ResourceLoadableType, CaptiveComponentDelegate {
    
    
    // MARK: - Static properties
    static var textureSize = CGSize(width: 100.0, height: 100.0)
    static var shadowSize = CGSize(width: 90.0, height: 40.0)
    static var shadowTexture: SKTexture = {
        let shadowAtlas = SKTextureAtlas(named: "Shadows")
        return shadowAtlas.textureNamed("PlayerBotShadow")
    }()
    static var shadowOffset = CGPoint(x: 0.0, y: -40.0)
    static var animations: [AnimationState: [CompassDirection: Animation]]?
    static var appearTextures: [CompassDirection: SKTexture]?
    
    // MARK: - Moogle Properties
    var isCaptive: Bool {
        didSet {
            guard isCaptive != oldValue else { return }
            
            guard let intelligenceComponent = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState else {
                fatalError("Moogles must have an intelligence component.")
            }
            
            if isCaptive {
                intelligenceComponent.stateMachine?.enter(MoogleCaptiveState.self)
            } else {
                intelligenceComponent.stateMachine?.enter(MoogleFreeState.self)
            }
        }
    }
    
    var targetPosition: float2?
    let agent: GKAgent2D
    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else { fatalError("A Moogle must have an RenderComponent.") }
        return renderComponent
    }
    
    
    // MARK: - Initializers
    override init() {
        isCaptive = true
        agent = GKAgent2D()
        super.init()
        let renderComponent = RenderComponent()
        addComponent(renderComponent)
        
        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)
        
        let shadowComponent = ShadowComponent(texture: Moogle.shadowTexture, size: Moogle.shadowSize, offset: Moogle.shadowOffset)
        addComponent(shadowComponent)
        
        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: GameplayConfiguration.Moogle.physicsBodyRadius, center: GameplayConfiguration.Moogle.physicsBodyOffset), colliderType: .Moogle)
        addComponent(physicsComponent)
        
        renderComponent.node.physicsBody = physicsComponent.physicsBody

        guard let animations = Moogle.animations else {
            fatalError("Attemp to access Moogle.animations before they have been loaded.")
        }
        let animationComponent = AnimationComponent(textureSize: Moogle.textureSize, animations: animations)
        addComponent(animationComponent)
        
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        let intelligenceComponent = IntelligenceComponent(states: [
            MoogleCaptiveState(entity: self),
            MoogleFreeState(entity: self)
            ])
        addComponent(intelligenceComponent)
        
    }
    
    
    // MARK: ResourceLoadableType
    
    static var resourcesNeedLoading: Bool {
        return appearTextures == nil || animations == nil
    }
    
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ()) {
        let moogleAtlasNames = ["Moogle"]
        
        SKTextureAtlas.preloadTextureAtlasesNamed(moogleAtlasNames) { error, moogleAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }
            
            appearTextures = [:]
            for orientation in CompassDirection.allDirections {
                appearTextures![orientation] = AnimationComponent.firstTextureForOrientation(compassDirection: orientation, inAtlas: moogleAtlases[0], withImageIdentifier: "Moogle")
            }
            
            // Set up all of the `PlayerBot`s animations.
            animations = [:]
            animations![.idle] = AnimationComponent.animationsFromAtlas(atlas: moogleAtlases[0], withImageIdentifier: "Moogle", forAnimationState: .idle)
            completionHandler()
        }
    }
    
    static func purgeResources() {
        appearTextures = nil
        animations = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func contactWithEntityDidBegin(_ entity: GKEntity) {
        guard let freeState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState as? MoogleCaptiveState else { return }
        
        freeState.setMoogleFree(entity: entity)
    }
    
    func contactWithEntityDidEnd(_ entity: GKEntity) {
        
    }
    
    func captiveSetFree(CaptiveComponent: CaptiveComponent) {
        
    }
    
    // MARK: - Shared Assets
    class func loadSharedAssets() {
        ColliderType.definedCollisions[.Moogle] = [
            .Obstacle,
            .PlayerBot,
            .TaskBot,
            .Moogle
        ]
        
        ColliderType.requestedContactNotifications[.Moogle] = [
            .Obstacle,
            .PlayerBot,
            .TaskBot,
            .Moogle
        ]
    }
}
