/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKEntity` subclass that provides a base class for `GroundBot` and `FlyingBot`. This subclass allows for convenient construction of the common AI-related components shared by the game's antagonists.
*/

import SpriteKit
import GameplayKit

class TaskBot: GKEntity, ContactNotifiableType, GKAgentDelegate, RulesComponentDelegate {
    
    // MARK: - Nested types
    enum TaskBotMandate {
        case huntAgent(GKAgent2D)
        case followGoodPatrolPath
        case followBadPatrolPath
        case returnToPositionOnPath(float2)
    }
    
    
    // MARK: - Properties
    var isGood: Bool {
        didSet {
            guard isGood != oldValue else { return }
            
            guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { fatalError("TaskBots must have an intelligence component.") }
            guard let animationComponent = component(ofType: AnimationComponent.self) else { fatalError("TaskBots must have an animation component.") }
            guard let chargeComponent = component(ofType: ChargeComponent.self) else { fatalError("TaskBots must have a charge component.") }
            
            agent.maxSpeed = GameplayConfiguration.TaskBot.maximumSpeedForIsGood(isGood: isGood)
            agent.maxAcceleration = GameplayConfiguration.TaskBot.maximumAcceleration
            
            if isGood {
                let closestPointOnGoodPath = closestPointOnPath(path: goodPathPoints)
                mandate = .returnToPositionOnPath(float2(closestPointOnGoodPath))
                
                intelligenceComponent.stateMachine.enter(TaskBotAgentControlledState.self)
                
                animationComponent.animations = goodAnimations
                
                chargeComponent.charge = 0.0
            }
            else {
                
                let closestPointOnBadPath = closestPointOnPath(path: badPathPoints)
                mandate = .returnToPositionOnPath(float2(closestPointOnBadPath))
                
                animationComponent.animations = badAnimations
                
                chargeComponent.charge = chargeComponent.maximumCharge
                
                intelligenceComponent.stateMachine.enter(TaskBotZappedState.self)
            }
        }
    }
    
    var mandate: TaskBotMandate
    
    var goodPathPoints: [CGPoint]
    
    var badPathPoints: [CGPoint]
    
    var behaviorForCurrentMandate: GKBehavior {
        guard let levelScene = component(ofType: RenderComponent.self)?.node.scene as? LevelScene else {
            return GKBehavior()
        }
        
        let agentBehavior: GKBehavior
        let radius: Float
        
        let debugPathPoints: [CGPoint]
        var debugPathShouldCycle = false
        let debugColor: SKColor
        
        switch mandate {
        case .followGoodPatrolPath, .followBadPatrolPath:
            let pathPoints = isGood ? goodPathPoints : badPathPoints
            radius = GameplayConfiguration.TaskBot.patrolPathRadius
            agentBehavior = TaskBotBehavior.behavior(forAgent: agent, patrollingPathWithPoints: pathPoints, pathRadius: radius, inScene: levelScene)
            debugPathPoints = pathPoints
            debugPathShouldCycle = true
            debugColor = isGood ? SKColor.green : SKColor.purple
            
        case let .huntAgent(targetAgent):
            radius = GameplayConfiguration.TaskBot.huntPathRadius
            (agentBehavior, debugPathPoints) = TaskBotBehavior.behaviorAndPathPoints(forAgent: agent, huntingAgent: targetAgent, pathRadius: radius, inScene: levelScene)
            debugColor = SKColor.red
            
        case let .returnToPositionOnPath(position):
            radius = GameplayConfiguration.TaskBot.returnToPatrolPathRadius
            (agentBehavior, debugPathPoints) = TaskBotBehavior.behaviorAndPathPoints(forAgent: agent, returningToPoint: position, pathRadius: radius, inScene: levelScene)
            debugColor = SKColor.yellow
        }
        return agentBehavior
    }
    
    var goodAnimations: [AnimationState: [CompassDirection: Animation]] {
        fatalError("goodAnimations must be overridden in subclasses")
    }
    
    var badAnimations: [AnimationState: [CompassDirection: Animation]] {
        fatalError("badAnimations must be overridden in subclasses")
    }
    
    var agent: TaskBotAgent {
        guard let agent = component(ofType: TaskBotAgent.self) else { fatalError("A TaskBot entity must have a GKAgent2D component.") }
        return agent
    }
    
    var renderComponent: RenderComponent {
        guard let renderComponent = component(ofType: RenderComponent.self) else { fatalError("A TaskBot must have an RenderComponent.") }
        return renderComponent
    }
    
    var beamTargetOffset = CGPoint.zero
    
    var debugNode = SKNode()
    
    
    // MARK: - Initializers
    required init(isGood: Bool, goodPathPoints: [CGPoint], badPathPoints: [CGPoint]) {
        self.isGood = isGood
        
        self.goodPathPoints = goodPathPoints
        self.badPathPoints = badPathPoints
        
        mandate = isGood ? .followGoodPatrolPath : .followBadPatrolPath
        
        super.init()
        
        let agent = TaskBotAgent()
        agent.delegate = self
        
        agent.maxSpeed = GameplayConfiguration.TaskBot.maximumSpeedForIsGood(isGood: isGood)
        agent.maxAcceleration = GameplayConfiguration.TaskBot.maximumAcceleration
        agent.mass = GameplayConfiguration.TaskBot.agentMass
        agent.radius = GameplayConfiguration.TaskBot.agentRadius
        agent.behavior = GKBehavior()
        
        
        addComponent(agent)
        
        let rulesComponent = RulesComponent(rules: [
            PlayerBotNearRule(),
            PlayerBotMediumRule(),
            PlayerBotFarRule(),
            BadTaskBotPercentageLowRule(),
            BadTaskBotPercentageMediumRule(),
            BadTaskBotPercentageHighRule()
            ])
        addComponent(rulesComponent)
        rulesComponent.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - GKAgentDelegate
    func agentWillUpdate(_: GKAgent) {
        updateAgentPositionToMatchNodePosition()
        updateAgentRotationToMatchTaskBotOrientation()
    }
    
    func agentDidUpdate(_: GKAgent) {
        guard let intelligenceComponent = component(ofType: IntelligenceComponent.self) else { return }
        guard let orientationComponent = component(ofType: OrientationComponent.self) else { return }
        
        if intelligenceComponent.stateMachine.currentState is TaskBotAgentControlledState {
            component(ofType: AnimationComponent.self)?.requestedAnimationState = .walkForward
            updateNodePositionToMatchAgentPosition()
            let newRotation: Float
            if agent.velocity.x > 0.0 || agent.velocity.y > 0.0 {
                newRotation = atan2(agent.velocity.y, agent.velocity.x)
            }
            else {
                newRotation = agent.rotation
            }
            
            if newRotation.isNaN { return }
            
            orientationComponent.zRotation = CGFloat(newRotation)
        }
        else {
            updateAgentPositionToMatchNodePosition()
            updateAgentRotationToMatchTaskBotOrientation()
        }
    }
    
    
    // MARK: - RulesComponentDelegate
    func rulesComponent(rulesComponent: RulesComponent, didFinishEvaluatingRuleSystem ruleSystem: GKRuleSystem) {
        let state = ruleSystem.state["snapshot"] as! EntitySnapshot
        
        let huntPlayerBotRaw = [
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageHigh.rawValue as AnyObject,
                Fact.playerBotNear.rawValue as AnyObject
                ]),
            
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.rawValue as AnyObject,
                Fact.playerBotNear.rawValue as AnyObject
                ]),
            
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageHigh.rawValue as AnyObject,
                Fact.playerBotMedium.rawValue as AnyObject,
                ]),
            
            ]
        
        let huntPlayerBot = huntPlayerBotRaw.reduce(0.0, max)
        
        let huntTaskBotRaw = [
            
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageLow.rawValue as AnyObject,
                ]),
            
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.rawValue as AnyObject,
                ]),
            
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageLow.rawValue as AnyObject,
                Fact.playerBotMedium.rawValue as AnyObject,
                ]),
            
            ruleSystem.minimumGrade(forFacts: [
                Fact.badTaskBotPercentageMedium.rawValue as AnyObject,
                Fact.playerBotFar.rawValue as AnyObject,
                ]),
            
            ]
        
        let huntTaskBot = huntTaskBotRaw.reduce(0.0, max)
        
        if huntPlayerBot >= huntTaskBot && huntPlayerBot > 0.0 {
            guard let playerBotAgent = state.playerBotTarget?.target.agent else { return }
            mandate = .huntAgent(playerBotAgent)
        }
        else if huntTaskBot > huntPlayerBot {
            mandate = .huntAgent(state.nearestGoodTaskBotTarget!.target.agent)
        }
        else {
            switch mandate {
            case .followBadPatrolPath:
                break
            default:
                let closestPointOnBadPath = closestPointOnPath(path: badPathPoints)
                mandate = .returnToPositionOnPath(float2(closestPointOnBadPath))
            }
        }
    }
    
    
    // MARK: - ContactableType
    func contactWithEntityDidBegin(_ entity: GKEntity) {}
    
    func contactWithEntityDidEnd(_ entity: GKEntity) {}
    
    
    // MARK: - Convenience
    func distanceToAgent(otherAgent: GKAgent2D) -> Float {
        let deltaX = agent.position.x - otherAgent.position.x
        let deltaY = agent.position.y - otherAgent.position.y
        
        return hypot(deltaX, deltaY)
    }
    
    func distanceToPoint(otherPoint: float2) -> Float {
        let deltaX = agent.position.x - otherPoint.x
        let deltaY = agent.position.y - otherPoint.y
        
        return hypot(deltaX, deltaY)
    }
    
    func closestPointOnPath(path: [CGPoint]) -> CGPoint {
        let taskBotPosition = agent.position
        let closestPoint = path.min {
            return distance_squared(taskBotPosition, float2($0)) < distance_squared(taskBotPosition, float2($1))
        }
        
        return closestPoint!
    }
    
    func updateAgentPositionToMatchNodePosition() {
        let renderComponent = self.renderComponent
        
        let agentOffset = GameplayConfiguration.TaskBot.agentOffset
        agent.position = float2(x: Float(renderComponent.node.position.x + agentOffset.x), y: Float(renderComponent.node.position.y + agentOffset.y))
    }
    
    func updateAgentRotationToMatchTaskBotOrientation() {
        guard let orientationComponent = component(ofType: OrientationComponent.self) else { return }
        agent.rotation = Float(orientationComponent.zRotation)
    }
    
    func updateNodePositionToMatchAgentPosition() {
        let agentPosition = CGPoint(agent.position)
        
        let agentOffset = GameplayConfiguration.TaskBot.agentOffset
        renderComponent.node.position = CGPoint(x: agentPosition.x - agentOffset.x, y: agentPosition.y - agentOffset.y)
    }
    
    
    // MARK: - Debug Path Drawing
    func drawDebugPath(path: [CGPoint], cycle: Bool, color: SKColor, radius: Float) {
        guard path.count > 1 else { return }
        
        debugNode.removeAllChildren()
        
        var drawPath = path
        
        if cycle {
            drawPath += [drawPath.first!]
        }
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let strokeColor = SKColor(red: red, green: green, blue: blue, alpha: 0.4)
        let fillColor = SKColor(red: red, green: green, blue: blue, alpha: 0.2)
        
        for index in 0..<drawPath.count - 1 {
            let current = CGPoint(x: drawPath[index].x, y: drawPath[index].y)
            let next = CGPoint(x: drawPath[index + 1].x, y: drawPath[index + 1].y)
            
            let circleNode = SKShapeNode(circleOfRadius: CGFloat(radius))
            circleNode.strokeColor = strokeColor
            circleNode.fillColor = fillColor
            circleNode.position = current
            debugNode.addChild(circleNode)
            
            let deltaX = next.x - current.x
            let deltaY = next.y - current.y
            let rectNode = SKShapeNode(rectOf: CGSize(width: hypot(deltaX, deltaY), height: CGFloat(radius) * 2))
            rectNode.strokeColor = strokeColor
            rectNode.fillColor = fillColor
            rectNode.zRotation = atan(deltaY / deltaX)
            rectNode.position = CGPoint(x: current.x + (deltaX / 2.0), y: current.y + (deltaY / 2.0))
            debugNode.addChild(rectNode)
        }
    }
    
    
    // MARK: - Shared Assets
    class func loadSharedAssets() {
        ColliderType.definedCollisions[.TaskBot] = [
            .Obstacle,
            .PlayerBot,
            .TaskBot,
            .Moogle
        ]
        
        ColliderType.requestedContactNotifications[.TaskBot] = [
            .Obstacle,
            .PlayerBot,
            .TaskBot,
            .Moogle
        ]
    }
}
