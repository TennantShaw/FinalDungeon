/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKEntity` subclass that represents the player-controlled protagonist of DemoBots. This subclass allows for convenient construction of a new entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class PlayerBot: GKEntity, ChargeComponentDelegate, ResourceLoadableType, ContactNotifiableType {
    
    // MARK: - Static properties
    static var textureSize = CGSize(width: 75.0, height: 75.0)
    static var shadowSize = CGSize(width: 60.0, height: 30.0)
    static var shadowTexture: SKTexture = {
        let shadowAtlas = SKTextureAtlas(named: "Shadows")
        return shadowAtlas.textureNamed("PlayerBotShadow")
    }()
    static var shadowOffset = CGPoint(x: 0.0, y: -40.0)
    static var animations: [AnimationState: [CompassDirection: Animation]]?
    static var appearTextures: [CompassDirection: SKTexture]?
    static var teleportShader: SKShader!

    
    // MARK: - Properties
    var isPoweredDown = false
    var freeMoogle = true
    let agent: GKAgent2D
    var isTargetable: Bool {
        guard let currentState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState else { return false }

        switch currentState {
            case is PlayerBotPlayerControlledState, is PlayerBotHitState:
                return true
            
            default:
                return false
        }
    }
    var antennaOffset = GameplayConfiguration.PlayerBot.antennaOffset
    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else { fatalError("A PlayerBot must have an RenderComponent.") }
        return renderComponent
    }

    
    // MARK: - Initializers
    override init() {
        agent = GKAgent2D()
        agent.radius = GameplayConfiguration.PlayerBot.agentRadius
        
        super.init()
        let renderComponent = RenderComponent()
        addComponent(renderComponent)
        
        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)

        let shadowComponent = ShadowComponent(texture: PlayerBot.shadowTexture, size: PlayerBot.shadowSize, offset: PlayerBot.shadowOffset)
        addComponent(shadowComponent)
        
        let inputComponent = InputComponent()
        addComponent(inputComponent)

        let physicsComponent = PhysicsComponent(physicsBody: SKPhysicsBody(circleOfRadius: GameplayConfiguration.PlayerBot.physicsBodyRadius, center: GameplayConfiguration.PlayerBot.physicsBodyOffset), colliderType: .PlayerBot)
        addComponent(physicsComponent)

        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        let movementComponent = MovementComponent()
        addComponent(movementComponent)
        
        let chargeComponent = ChargeComponent(charge: GameplayConfiguration.PlayerBot.initialCharge, maximumCharge: GameplayConfiguration.PlayerBot.maximumCharge, displaysChargeBar: true)
        chargeComponent.delegate = self
        addComponent(chargeComponent)
        
        guard let animations = PlayerBot.animations else {
            fatalError("Attempt to access PlayerBot.animations before they have been loaded.")
        }
        let animationComponent = AnimationComponent(textureSize: PlayerBot.textureSize, animations: animations)
        addComponent(animationComponent)
        
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        let intelligenceComponent = IntelligenceComponent(states: [
            PlayerBotAppearState(entity: self),
            PlayerBotPlayerControlledState(entity: self),
            PlayerBotHitState(entity: self),
            PlayerBotRechargingState(entity: self)
        ])
        addComponent(intelligenceComponent)
        
        let contactedBodies = physicsComponent.physicsBody.allContactedBodies()
        for contactedBody in contactedBodies {
            guard let entity = contactedBody.node?.entity else { continue }
            print("I'm touching you so softly")
            setMoogleFree(entity: entity)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Charge component delegate
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        if let intelligenceComponent = component(ofType: IntelligenceComponent.self) {
            if !chargeComponent.hasCharge {
                isPoweredDown = true
                intelligenceComponent.stateMachine.enter(PlayerBotRechargingState.self)
            }
            else {
                intelligenceComponent.stateMachine.enter(PlayerBotHitState.self)
            }
        }
    }
    
    
    // MARK: - ResourceLoadableType
    static var resourcesNeedLoading: Bool {
        return appearTextures == nil || animations == nil
    }
    
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ()) {
        loadMiscellaneousAssets()
        
        let playerBotAtlasNames = [
            "PlayerBotIdle",
            "PlayerBotWalk",
            "PlayerBotInactive",
            "PlayerBotHit"
        ]
        

        SKTextureAtlas.preloadTextureAtlasesNamed(playerBotAtlasNames) { error, playerBotAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }

            appearTextures = [:]
            for orientation in CompassDirection.allDirections {
                appearTextures![orientation] = AnimationComponent.firstTextureForOrientation(compassDirection: orientation, inAtlas: playerBotAtlases[0], withImageIdentifier: "PlayerBotIdle")
            }
            
            animations = [:]
            animations![.idle] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[0], withImageIdentifier: "PlayerBotIdle", forAnimationState: .idle)
            animations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1], withImageIdentifier: "PlayerBotWalk", forAnimationState: .walkForward)
            animations![.walkBackward] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[1], withImageIdentifier: "PlayerBotWalk", forAnimationState: .walkBackward, playBackwards: true)
            animations![.inactive] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[2], withImageIdentifier: "PlayerBotInactive", forAnimationState: .inactive)
            animations![.hit] = AnimationComponent.animationsFromAtlas(atlas: playerBotAtlases[3], withImageIdentifier: "PlayerBotHit", forAnimationState: .hit, repeatTexturesForever: false)
            
            completionHandler()
        }
    }
    
    static func purgeResources() {
        appearTextures = nil
        animations = nil
    }
    
    class func loadMiscellaneousAssets() {
        teleportShader = SKShader(fileNamed: "Teleport.fsh")
        teleportShader.addUniform(SKUniform(name: "u_duration", float: Float(GameplayConfiguration.PlayerBot.appearDuration)))
        
        ColliderType.definedCollisions[.PlayerBot] = [
            .PlayerBot,
            .TaskBot,
            .Obstacle,
            .Moogle,
            .Trap
        ]
    }

    // MARK: - Contact Notifiable Type
    func contactWithEntityDidBegin(_ entity: GKEntity) {        
        guard let freeCaptiveState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState as? MoogleCaptiveState else { return }
        
        freeCaptiveState.setMoogleFree(entity: entity)
    }
    
    func contactWithEntityDidEnd(_ entity: GKEntity) {
        
    }

    
    // MARK: - Convenience
    func updateAgentPositionToMatchNodePosition() {
        let renderComponent = self.renderComponent
        let agentOffset = GameplayConfiguration.PlayerBot.agentOffset
        agent.position = float2(x: Float(renderComponent.node.position.x + agentOffset.x), y: Float(renderComponent.node.position.y + agentOffset.y))
    }
    
    func setMoogleFree(entity: GKEntity) {
        if let moogle = entity as? Moogle, !moogle.isCaptive {
            moogle.isCaptive = false
        }
    }
    
}
