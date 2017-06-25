/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `TaskBotBehavior` is a `GKBehavior` subclass that provides convenience class methods to construct the appropriate goals and behaviors for different `TaskBot` mandates.
*/

import SpriteKit
import GameplayKit

class TaskBotBehavior: GKBehavior {
    
    // MARK: - Behavior factory methods
    static func behaviorAndPathPoints(forAgent agent: GKAgent2D, huntingAgent target: GKAgent2D, pathRadius: Float, inScene scene: LevelScene) -> (behavior: GKBehavior, pathPoints: [CGPoint]) {
        let behavior = TaskBotBehavior()
        behavior.addTargetSpeedGoal(speed: agent.maxSpeed)
        behavior.addAvoidObstaclesGoal(forScene: scene)
        let agentsToFlockWith: [GKAgent2D] = scene.entities.flatMap { entity in
            if let taskBot = entity as? TaskBot, !taskBot.isGood && taskBot.agent !== agent && taskBot.distanceToAgent(otherAgent: agent) <= GameplayConfiguration.Flocking.agentSearchDistanceForFlocking {
                return taskBot.agent
            }
            return nil
        }
        
        if !agentsToFlockWith.isEmpty {
            let separationGoal = GKGoal(toSeparateFrom: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.separationRadius, maxAngle: GameplayConfiguration.Flocking.separationAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.separationWeight, for: separationGoal)
            
            let alignmentGoal = GKGoal(toAlignWith: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.alignmentRadius, maxAngle: GameplayConfiguration.Flocking.alignmentAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.alignmentWeight, for: alignmentGoal)
            
            let cohesionGoal = GKGoal(toCohereWith: agentsToFlockWith, maxDistance: GameplayConfiguration.Flocking.cohesionRadius, maxAngle: GameplayConfiguration.Flocking.cohesionAngle)
            behavior.setWeight(GameplayConfiguration.Flocking.cohesionWeight, for: cohesionGoal)
        }
        
        let pathPoints = behavior.addGoalsToFollowPath(from: agent.position, to: target.position, pathRadius: pathRadius, inScene: scene)
        return (behavior, pathPoints)
    }
    
    static func behaviorAndPathPoints(forAgent agent: GKAgent2D, returningToPoint endPoint: float2, pathRadius: Float, inScene scene: LevelScene) -> (behavior: GKBehavior, pathPoints: [CGPoint]) {
        let behavior = TaskBotBehavior()
        behavior.addTargetSpeedGoal(speed: agent.maxSpeed)
        behavior.addAvoidObstaclesGoal(forScene: scene)
        let pathPoints = behavior.addGoalsToFollowPath(from: agent.position, to: endPoint, pathRadius: pathRadius, inScene: scene)
        return (behavior, pathPoints)
    }
    
    static func behavior(forAgent agent: GKAgent2D, patrollingPathWithPoints patrolPathPoints: [CGPoint], pathRadius: Float, inScene scene: LevelScene) -> GKBehavior {
        let behavior = TaskBotBehavior()
        behavior.addTargetSpeedGoal(speed: agent.maxSpeed)
        behavior.addAvoidObstaclesGoal(forScene: scene)
        let pathVectorPoints = patrolPathPoints.map { float2($0) }
        let path = GKPath(points: pathVectorPoints, radius: pathRadius, cyclical: true)
        behavior.addFollowAndStayOnPathGoals(for: path)
        return behavior
    }
    
    
    // MARK: - Goals
    private func extrudedObstaclesContaining(point: float2, inScene scene: LevelScene) -> [GKPolygonObstacle] {
        let extrusionRadius = Float(GameplayConfiguration.TaskBot.pathfindingGraphBufferRadius) + 5
        return scene.polygonObstacles.filter { obstacle in
            let range = 0..<obstacle.vertexCount
            let polygonVertices = range.map { obstacle.vertex(at: $0) }
            guard !polygonVertices.isEmpty else { return false }
            let maxX = polygonVertices.max { $0.x < $1.x }!.x + extrusionRadius
            let maxY = polygonVertices.max { $0.y < $1.y }!.y + extrusionRadius
            let minX = polygonVertices.min { $0.x < $1.x }!.x - extrusionRadius
            let minY = polygonVertices.min { $0.y < $1.y }!.y - extrusionRadius
            return (point.x > minX && point.x < maxX) && (point.y > minY && point.y < maxY)
        }
    }
    
    private func connectedNode(forPoint point: float2, onObstacleGraphInScene scene: LevelScene) -> GKGraphNode2D? {
        let pointNode = GKGraphNode2D(point: point)
        scene.graph.connectUsingObstacles(node: pointNode)
        if pointNode.connectedNodes.isEmpty {
            scene.graph.remove([pointNode])
            let intersectingObstacles = extrudedObstaclesContaining(point: point, inScene: scene)
            scene.graph.connectUsingObstacles(node: pointNode, ignoringBufferRadiusOf: intersectingObstacles)
            if pointNode.connectedNodes.isEmpty {
                scene.graph.remove([pointNode])
                return nil
            }
        }
        return pointNode
    }
    
    private func addGoalsToFollowPath(from startPoint: float2, to endPoint: float2, pathRadius: Float, inScene scene: LevelScene) -> [CGPoint] {
        guard let startNode = connectedNode(forPoint: startPoint, onObstacleGraphInScene: scene),
            let endNode = connectedNode(forPoint: endPoint, onObstacleGraphInScene: scene) else { return [] }
        defer { scene.graph.remove([startNode, endNode]) }
        let pathNodes = scene.graph.findPath(from: startNode, to: endNode) as! [GKGraphNode2D]
        guard pathNodes.count > 1 else { return [] }
        let path = GKPath(graphNodes: pathNodes, radius: pathRadius)
        addFollowAndStayOnPathGoals(for: path)
        let pathPoints = pathNodes.map { CGPoint($0.position) }
        return pathPoints
    }
    
    private func addAvoidObstaclesGoal(forScene scene: LevelScene) {
        setWeight(1.0, for: GKGoal(toAvoid: scene.polygonObstacles, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeForObstacleAvoidance))
    }
    
    private func addTargetSpeedGoal(speed: Float) {
        setWeight(0.5, for: GKGoal(toReachTargetSpeed: speed))
    }
    
    private func addFollowAndStayOnPathGoals(for path: GKPath) {
        setWeight(1.0, for: GKGoal(toFollow: path, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeWhenFollowingPath, forward: true))
        setWeight(1.0, for: GKGoal(toStayOn: path, maxPredictionTime: GameplayConfiguration.TaskBot.maxPredictionTimeWhenFollowingPath))
    }
}
