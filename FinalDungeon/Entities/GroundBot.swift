/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A ground-based `TaskBot` with a distance attack. This `GKEntity` subclass allows for convenient construction of an entity with appropriate `GKComponent` instances.
*/

import SpriteKit
import GameplayKit

class GroundBot: TaskBot, ChargeComponentDelegate, ResourceLoadableType {
    
    // MARK: - Static Properties
    static var textureSize = CGSize(width: 75.0, height: 75.0)
    static var shadowSize = CGSize(width: 80.0, height: 30.0)
    static var shadowTexture: SKTexture = {
        let shadowAtlas = SKTextureAtlas(named: "Shadows")
        return shadowAtlas.textureNamed("GroundBotShadow")
    }()
    
    static var shadowOffset = CGPoint(x: 0.0, y: -40.0)
    static var goodAnimations: [AnimationState: [CompassDirection: Animation]]?
    static var badAnimations: [AnimationState: [CompassDirection: Animation]]?
    
    
    // MARK: - TaskBot Properties
    override var goodAnimations: [AnimationState: [CompassDirection: Animation]] {
        return GroundBot.goodAnimations!
    }
    
    override var badAnimations: [AnimationState: [CompassDirection: Animation]] {
        return GroundBot.badAnimations!
    }
    
    
    // MARK: - GroundBot Properties
    var targetPosition: float2?
    
    
    // MARK: - Initialization
    required init(isGood: Bool, goodPathPoints: [CGPoint], badPathPoints: [CGPoint]) {
        super.init(isGood: isGood, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)
        
        let initialAnimations: [AnimationState: [CompassDirection: Animation]]
        let initialCharge: Double
        
        if isGood {
            guard let goodAnimations = GroundBot.goodAnimations else {
                fatalError("Attempt to access GroundBot.goodAnimations before they have been loaded.")
            }
            initialAnimations = goodAnimations
            initialCharge = 0.0
        }
        else {
            guard let badAnimations = GroundBot.badAnimations else {
                fatalError("Attempt to access GroundBot.badAnimations before they have been loaded.")
            }
            initialAnimations = badAnimations
            initialCharge = GameplayConfiguration.GroundBot.maximumCharge
        }
        
        let renderComponent = RenderComponent()
        addComponent(renderComponent)
        
        let orientationComponent = OrientationComponent()
        addComponent(orientationComponent)
        
        let shadowComponent = ShadowComponent(texture: GroundBot.shadowTexture, size: GroundBot.shadowSize, offset: GroundBot.shadowOffset)
        addComponent(shadowComponent)
        
        let animationComponent = AnimationComponent(textureSize: GroundBot.textureSize, animations: initialAnimations)
        addComponent(animationComponent)
        
        let intelligenceComponent = IntelligenceComponent(states: [
            TaskBotAgentControlledState(entity: self),
            GroundBotRotateToAttackState(entity: self),
            GroundBotPreAttackState(entity: self),
            GroundBotAttackState(entity: self),
            TaskBotZappedState(entity: self)
            ])
        addComponent(intelligenceComponent)
        
        let physicsBody = SKPhysicsBody(circleOfRadius: GameplayConfiguration.TaskBot.physicsBodyRadius, center: GameplayConfiguration.TaskBot.physicsBodyOffset)
        let physicsComponent = PhysicsComponent(physicsBody: physicsBody, colliderType: .TaskBot)
        addComponent(physicsComponent)
        
        let chargeComponent = ChargeComponent(charge: initialCharge, maximumCharge: GameplayConfiguration.GroundBot.maximumCharge)
        chargeComponent.delegate = self
        addComponent(chargeComponent)
        
        let movementComponent = MovementComponent()
        addComponent(movementComponent)
        
        renderComponent.node.physicsBody = physicsComponent.physicsBody
        
        renderComponent.node.addChild(animationComponent.node)
        animationComponent.shadowNode = shadowComponent.node
        
        beamTargetOffset = GameplayConfiguration.GroundBot.beamTargetOffset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - ContactableType
    override func contactWithEntityDidBegin(_ entity: GKEntity) {
        super.contactWithEntityDidBegin(entity)
        
        guard let attackState = component(ofType: IntelligenceComponent.self)?.stateMachine.currentState as? GroundBotAttackState else { return }
        
        attackState.applyDamageToEntity(entity: entity)
    }
    
    
    // MARK: - RulesComponentDelegate
    override func rulesComponent(rulesComponent: RulesComponent, didFinishEvaluatingRuleSystem ruleSystem: GKRuleSystem) {
        super.rulesComponent(rulesComponent: rulesComponent, didFinishEvaluatingRuleSystem: ruleSystem)
        guard let scene = component(ofType: RenderComponent.self)?.node.scene else { return }
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { return }
        guard let agentControlledState = intelligenceComponent.stateMachine.currentState as? TaskBotAgentControlledState else { return }
        
        guard agentControlledState.elapsedTime >= GameplayConfiguration.GroundBot.delayBetweenAttacks else { return }
        
        guard case let .huntAgent(targetAgent) = mandate else { return }
        
        guard distanceToAgent(otherAgent: targetAgent) <= GameplayConfiguration.GroundBot.maximumAttackDistance else { return }
        
        var hasLineOfSight = true
        
        scene.physicsWorld.enumerateBodies(alongRayStart: CGPoint(agent.position), end: CGPoint(targetAgent.position)) { body, _, _, stop in
            if ColliderType(rawValue: body.categoryBitMask).contains(.Obstacle) {
                hasLineOfSight = false
                stop.pointee = true
            }
        }
        
        if !hasLineOfSight { return }
        
        targetPosition = targetAgent.position
        intelligenceComponent.stateMachine.enter(GroundBotRotateToAttackState.self)
    }
    
    
    // MARK: - ChargeComponentDelegate
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent) {
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { return }
        
        isGood = !chargeComponent.hasCharge
        
        if !isGood {
            intelligenceComponent.stateMachine.enter(TaskBotZappedState.self)
        }
    }
    
    
    // MARK: - ResourceLoadableType
    static var resourcesNeedLoading: Bool {
        return goodAnimations == nil || badAnimations == nil
    }
    
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ()) {
        super.loadSharedAssets()
        
        let groundBotAtlasNames = [
            "GroundBotGoodWalk",
            "GroundBotBadWalk",
            "GroundBotAttack",
            "GroundBotZapped"
        ]
        
        SKTextureAtlas.preloadTextureAtlasesNamed(groundBotAtlasNames) { error, groundBotAtlases in
            if let error = error {
                fatalError("One or more texture atlases could not be found: \(error)")
            }
            
            goodAnimations = [:]
            goodAnimations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[0], withImageIdentifier: "GroundBotGoodWalk", forAnimationState: .walkForward)
            
            badAnimations = [:]
            badAnimations![.walkForward] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[1], withImageIdentifier: "GroundBotBadWalk", forAnimationState: .walkForward)
            badAnimations![.attack] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[2], withImageIdentifier: "GroundBotAttack", forAnimationState: .attack, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake", repeatTexturesForever: false)
            badAnimations![.zapped] = AnimationComponent.animationsFromAtlas(atlas: groundBotAtlases[3], withImageIdentifier: "GroundBotZapped", forAnimationState: .zapped, bodyActionName: "ZappedShake", shadowActionName: "ZappedShadowShake")
            
            completionHandler()
        }
    }
    
    static func purgeResources() {
        goodAnimations = nil
        badAnimations = nil
    }
}
