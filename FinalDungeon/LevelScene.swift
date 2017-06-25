/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `LevelScene` is an `SKScene` representing a playable level in the game. `WorldLayer` is an enumeration that represents the different z-indexed layers of a `LevelScene`.
*/

import SpriteKit
import GameplayKit

enum WorldLayer: CGFloat {
    static let zSpacePerCharacter: CGFloat = 100
    
    case board = -100, shadows = -50, obstacles = -25, characters = 0, aboveCharacters = 1000, top = 1100
    
    var nodeName: String {
        switch self {
        case .board: return "board"
        case .shadows: return "shadows"
        case .obstacles: return "obstacles"
        case .characters: return "characters"
        case .aboveCharacters: return "above_characters"
        case .top: return "top"
        }
    }
    
    var nodePath: String {
        return "/world/\(nodeName)"
    }
    
    static var allLayers = [board, shadows, obstacles, characters, aboveCharacters, top]
}

class LevelScene: BaseScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    var worldLayerNodes = [WorldLayer: SKNode]()
    
    var worldNode: SKNode {
        return childNode(withName: "world")!
    }
    
    let playerBot = PlayerBot()
    let moogle = Moogle()
    let trap = Trap()
    var entities = Set<GKEntity>()
    
    var lastUpdateTimeInterval: TimeInterval = 0
    let maximumUpdateDeltaTime: TimeInterval = 1.0 / 60.0
    
    var levelConfiguration: LevelConfiguration!
    
    lazy var stateMachine: GKStateMachine = GKStateMachine(states: [
        LevelSceneActiveState(levelScene: self),
        LevelScenePauseState(levelScene: self),
        LevelSceneSuccessState(levelScene: self),
        LevelSceneFailState(levelScene: self)
        ])
    
    let timerNode = SKLabelNode(text: "--:--")
    
    override var overlay: SceneOverlay? {
        didSet {
            focusChangesEnabled = (overlay != nil)
        }
    }
    
    
    // MARK: - Pathfinding
    let graph = GKObstacleGraph(obstacles: [], bufferRadius: GameplayConfiguration.TaskBot.pathfindingGraphBufferRadius)
    lazy var obstacleSpriteNodes: [SKSpriteNode] = self["world/obstacles/*"] as! [SKSpriteNode]
    lazy var polygonObstacles: [GKPolygonObstacle] = SKNode.obstacles(fromNodePhysicsBodies: self.obstacleSpriteNodes)
    
    
    // MARK: - Rule State
    var levelStateSnapshot: LevelStateSnapshot?
    
    func entitySnapshotForEntity(entity: GKEntity) -> EntitySnapshot? {
        if levelStateSnapshot == nil {
            levelStateSnapshot = LevelStateSnapshot(scene: self)
        }
        return levelStateSnapshot!.entitySnapshots[entity]
    }
    
    
    // MARK: - Component Systems
    lazy var componentSystems: [GKComponentSystem] = {
        let agentSystem = GKComponentSystem(componentClass: TaskBotAgent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        let chargeSystem = GKComponentSystem(componentClass: ChargeComponent.self)
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let rulesSystem = GKComponentSystem(componentClass: RulesComponent.self)
        
        return [rulesSystem, intelligenceSystem, movementSystem, agentSystem, chargeSystem, animationSystem]
    }()
    
    
    // MARK: - Initializers
    deinit {
        unregisterForPauseNotifications()
    }
    
    
    // MARK: - Scene Life Cycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        levelConfiguration = LevelConfiguration(fileName: sceneManager.currentSceneMetadata!.fileName)
        
        graph.addObstacles(polygonObstacles)
        
        registerForPauseNotifications()
        
        loadWorldLayers()
        
        beamInPlayerBot()
        addMoogle()
        
        physicsWorld.gravity = CGVector.zero
        
        physicsWorld.contactDelegate = self
        
        stateMachine.enter(LevelSceneActiveState.self)
        
        timerNode.zPosition = WorldLayer.aboveCharacters.rawValue
        timerNode.fontColor = SKColor.white
        timerNode.fontName = GameplayConfiguration.Timer.fontName
        timerNode.horizontalAlignmentMode = .center
        timerNode.verticalAlignmentMode = .top
        scaleTimerNode()
        camera!.addChild(timerNode)
        
        func nodePointsFromNodeNames(nodeNames: [String]) -> [CGPoint] {
            let charactersNode = childNode(withName: WorldLayer.characters.nodePath)!
            return nodeNames.map {
                charactersNode[$0].first!.position
            }
        }
        
        for taskBotConfiguration in levelConfiguration.taskBotConfigurations {
            let taskBot: TaskBot
            
            let goodPathPoints = nodePointsFromNodeNames(nodeNames: taskBotConfiguration.goodPathNodeNames)
            let badPathPoints = nodePointsFromNodeNames(nodeNames: taskBotConfiguration.badPathNodeNames)
            
            switch taskBotConfiguration.locomotion {
            case .ground:
                taskBot = GroundBot(isGood: !taskBotConfiguration.startsBad, goodPathPoints: goodPathPoints, badPathPoints: badPathPoints)
            }
            
            guard let orientationComponent = taskBot.component(ofType: OrientationComponent.self) else {
                fatalError("A task bot must have an orientation component to be able to be added to a level")
            }
            orientationComponent.compassDirection = taskBotConfiguration.initialOrientation
            
            let taskBotNode = taskBot.renderComponent.node
            taskBotNode.position = taskBot.isGood ? goodPathPoints.first! : badPathPoints.first!
            taskBot.updateAgentPositionToMatchNodePosition()
            
            addEntity(entity: taskBot)
        }
        
        
        
        for trapConfiguration in levelConfiguration.trapConfiguration {
            let trap: Trap
            trap = Trap()
            
            let trapPosition = nodePointsFromNodeNames(nodeNames: trapConfiguration.trapNodeNames)
            guard let orientationComponent = trap.component(ofType: OrientationComponent.self) else {
                fatalError("A trap must have an orientation component to be able to be added to a level")
            }
            orientationComponent.compassDirection = trapConfiguration.initialOrientation
            
            let trapNode = trap.renderComponent.node
            trapNode.position = trapPosition.first!
            
            addEntity(entity: trap)
        }
        addTouchInputToScene()
    }
    

    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        setCameraConstraints()
        scaleTimerNode()
    }
    
    
    // MARK: - SKScene Processing
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard view != nil else { return }
        var deltaTime = currentTime - lastUpdateTimeInterval
        deltaTime = deltaTime > maximumUpdateDeltaTime ? maximumUpdateDeltaTime : deltaTime
        lastUpdateTimeInterval = currentTime
        levelStateSnapshot = nil
        if worldNode.isPaused { return }
        stateMachine.update(deltaTime: deltaTime)
        
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }
    
    override func didFinishUpdate() {
        if let playerBotNode = playerBot.component(ofType: RenderComponent.self)?.node, playerBotNode.scene == self {
            playerBot.updateAgentPositionToMatchNodePosition()
        }
        
        let ySortedEntities = entities.sorted {
            let nodeA = $0.0.component(ofType: RenderComponent.self)!.node
            let nodeB = $0.1.component(ofType: RenderComponent.self)!.node
            
            return nodeA.position.y > nodeB.position.y
        }
        
        var characterZPosition = WorldLayer.zSpacePerCharacter
        for entity in ySortedEntities {
            let node = entity.component(ofType: RenderComponent.self)!.node
            node.zPosition = characterZPosition
            
            characterZPosition += WorldLayer.zSpacePerCharacter
        }
    }
    
    
    // MARK: - SKPhysicsContactDelegate
    @objc(didBeginContact:) func didBegin(_ contact: SKPhysicsContact) {
        handleContact(contact: contact) { (ContactNotifiableType: ContactNotifiableType, otherEntity: GKEntity) in
            ContactNotifiableType.contactWithEntityDidBegin(otherEntity)
        }
    }
    
    @objc(didEndContact:) func didEnd(_ contact: SKPhysicsContact) {
        handleContact(contact: contact) { (ContactNotifiableType: ContactNotifiableType, otherEntity: GKEntity) in
            ContactNotifiableType.contactWithEntityDidEnd(otherEntity)
        }
    }
    
    
    // MARK: - SKPhysicsContactDelegate convenience
    private func handleContact(contact: SKPhysicsContact, contactCallback: (ContactNotifiableType, GKEntity) -> Void) {
        let colliderTypeA = ColliderType(rawValue: contact.bodyA.categoryBitMask)
        let colliderTypeB = ColliderType(rawValue: contact.bodyB.categoryBitMask)
        
        let aWantsCallback = colliderTypeA.notifyOnContactWith(colliderTypeB)
        let bWantsCallback = colliderTypeB.notifyOnContactWith(colliderTypeA)
        
        assert(aWantsCallback || bWantsCallback, "Unhandled physics contact - A = \(colliderTypeA), B = \(colliderTypeB)")
        
        let entityA = contact.bodyA.node?.entity
        let entityB = contact.bodyB.node?.entity
        
        if let notifiableEntity = entityA as? ContactNotifiableType, let otherEntity = entityB, aWantsCallback {
            contactCallback(notifiableEntity, otherEntity)
        }
        
        
        if let notifiableEntity = entityB as? ContactNotifiableType, let otherEntity = entityA, bWantsCallback {
            contactCallback(notifiableEntity, otherEntity)
        }
    }
    
    
    // MARK: - Level Construction
    func loadWorldLayers() {
        for worldLayer in WorldLayer.allLayers {
            let foundNodes = self["world/\(worldLayer.nodeName)"]
            precondition(!foundNodes.isEmpty, "Could not find a world layer node for \(worldLayer.nodeName)")
            let layerNode = foundNodes.first!
            layerNode.zPosition = worldLayer.rawValue
            worldLayerNodes[worldLayer] = layerNode
        }
    }
    
    func addEntity(entity: GKEntity) {
        entities.insert(entity)
        
        for componentSystem in self.componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
        
        if let renderNode = entity.component(ofType: RenderComponent.self)?.node {
            addNode(node: renderNode, toWorldLayer: .characters)
            
            
            if let shadowNode = entity.component(ofType: ShadowComponent.self)?.node {
                addNode(node: shadowNode, toWorldLayer: .shadows)
                
                let xRange = SKRange(constantValue: shadowNode.position.x)
                let yRange = SKRange(constantValue: shadowNode.position.y)
                
                let constraint = SKConstraint.positionX(xRange, y: yRange)
                constraint.referenceNode = renderNode
                
                shadowNode.constraints = [constraint]
            }
            
            
            if let chargeBar = entity.component(ofType: ChargeComponent.self)?.chargeBar {
                addNode(node: chargeBar, toWorldLayer: .aboveCharacters)
                
                let xRange = SKRange(constantValue: GameplayConfiguration.PlayerBot.chargeBarOffset.x)
                let yRange = SKRange(constantValue: GameplayConfiguration.PlayerBot.chargeBarOffset.y)
                
                let constraint = SKConstraint.positionX(xRange, y: yRange)
                constraint.referenceNode = renderNode
                
                chargeBar.constraints = [constraint]
            }
        }
        
        if let intelligenceComponent = entity.component(ofType: IntelligenceComponent.self) {
            intelligenceComponent.enterInitialState()
        }
    }
    
    func addNode(node: SKNode, toWorldLayer worldLayer: WorldLayer) {
        let worldLayerNode = worldLayerNodes[worldLayer]!
        
        worldLayerNode.addChild(node)
    }
    
    
    // MARK: - GameInputDelegate
    override func gameInputDidUpdateControlInputSources(gameInput: GameInput) {
        super.gameInputDidUpdateControlInputSources(gameInput: gameInput)
        
        for controlInputSource in gameInput.controlInputSources {
            controlInputSource.delegate = playerBot.component(ofType: InputComponent.self)
        }
    }
    
    
    // MARK: - ControlInputSourceGameStateDelegate
    override func controlInputSourceDidTogglePauseState(_ controlInputSource: ControlInputSourceType) {
        if stateMachine.currentState is LevelSceneActiveState {
            stateMachine.enter(LevelScenePauseState.self)
        }
        else {
            stateMachine.enter(LevelSceneActiveState.self)
        }
    }
    
    
    // MARK: - ButtonNodeResponderType
    override func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
        case .resume:
            stateMachine.enter(LevelSceneActiveState.self)
        default:
            super.buttonTriggered(button: button)
        }
    }
    
    
    // MARK: - Convenience
    private func setCameraConstraints() {
        guard let camera = camera else { return }
        
        let zeroRange = SKRange(constantValue: 0.0)
        let playerNode = playerBot.renderComponent.node
        let playerBotLocationConstraint = SKConstraint.distance(zeroRange, to: playerNode)
        let scaledSize = CGSize(width: size.width * camera.xScale, height: size.height * camera.yScale)
        let boardNode = childNode(withName: WorldLayer.board.nodePath)!
        let boardContentRect = boardNode.calculateAccumulatedFrame()
        let xInset = min((scaledSize.width / 2) - 100.0, boardContentRect.width / 2)
        let yInset = min((scaledSize.height / 2) - 100.0, boardContentRect.height / 2)
        let insetContentRect = boardContentRect.insetBy(dx: xInset, dy: yInset)
        let xRange = SKRange(lowerLimit: insetContentRect.minX, upperLimit: insetContentRect.maxX)
        let yRange = SKRange(lowerLimit: insetContentRect.minY, upperLimit: insetContentRect.maxY)
        let levelEdgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        levelEdgeConstraint.referenceNode = boardNode
        camera.constraints = [playerBotLocationConstraint, levelEdgeConstraint]
    }
    
    private func scaleTimerNode() {
        timerNode.fontSize = size.height * GameplayConfiguration.Timer.fontSize
        timerNode.position.y = size.height / 2.0
    }
    
    private func beamInPlayerBot() {
        let charactersNode = childNode(withName: WorldLayer.characters.nodePath)!
        let transporterCoordinate = charactersNode.childNode(withName: "transporter_coordinate")!
        
        guard let orientationComponent = playerBot.component(ofType: OrientationComponent.self) else {
            fatalError("A player bot must have an orientation component to be able to be added to a level")
        }
        orientationComponent.compassDirection = levelConfiguration.initialPlayerBotOrientation
        
        let playerNode = playerBot.renderComponent.node
        playerNode.position = transporterCoordinate.position
        playerBot.updateAgentPositionToMatchNodePosition()
        
        setCameraConstraints()
        
        addEntity(entity: playerBot)
    }
    
    private func addMoogle() {
        let charactersNode = childNode(withName: WorldLayer.characters.nodePath)!
        let moogleCoordinate = charactersNode.childNode(withName: "moogle_coordinate")!
        
        guard let orientationComponent = moogle.component(ofType: OrientationComponent.self) else {
            fatalError("A moogle must have an orientation component to be able to be added to a level")
        }
        orientationComponent.compassDirection = levelConfiguration.initialMoogleOrientation
        
        let moogleNode = moogle.renderComponent.node
        moogleNode.position = moogleCoordinate.position
        
        addEntity(entity: moogle)
    }
    
}
