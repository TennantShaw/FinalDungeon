/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    These types are used by the game's AI to capture and evaluate a snapshot of the game's state. `EntityDistance` encapsulates the distance between two entities. `LevelStateSnapshot` stores an `EntitySnapshot` for every entity in the level. `EntitySnapshot` stores the distances from an entity to every other entity in the level.
*/

import GameplayKit

struct EntityDistance {
    let source: GKEntity
    let target: GKEntity
    let distance: Float
}

class LevelStateSnapshot {
    
    // MARK: - Properties
    var entitySnapshots: [GKEntity: EntitySnapshot] = [:]
    
    
    // MARK: - Initialization
    init(scene: LevelScene) {
        func agentForEntity(entity: GKEntity) -> GKAgent2D {
            if let agent = entity.component(ofType: TaskBotAgent.self) {
                return agent
            }
            else if let playerBot = entity as? PlayerBot {
                return playerBot.agent
            }
            else if let moogle = entity as? Moogle {
                return moogle.agent
            }
            else if let trap = entity as? Trap {
                return trap.agent
            }
            fatalError("All entities in a level must have an accessible associated GKEntity")
        }
        
        var entityDistances: [GKEntity: [EntityDistance]] = [:]
        
        for entity in scene.entities {
            entityDistances[entity] = []
        }
        
        for sourceEntity in scene.entities {
            let sourceIndex = scene.entities.index(of: sourceEntity)!
            let sourceAgent = agentForEntity(entity: sourceEntity)
            for targetEntity in scene.entities[scene.entities.index(after: sourceIndex) ..< scene.entities.endIndex] {
                let targetAgent = agentForEntity(entity: targetEntity)
                let dx = targetAgent.position.x - sourceAgent.position.x
                let dy = targetAgent.position.y - sourceAgent.position.y
                let distance = hypotf(dx, dy)
                entityDistances[sourceEntity]!.append(EntityDistance(source: sourceEntity, target: targetEntity, distance: distance))
                entityDistances[targetEntity]!.append(EntityDistance(source: targetEntity, target: sourceEntity, distance: distance))
            }
        }
        
        let (goodTaskBots, badTaskBots) = scene.entities.reduce(([], [])) {
            
            (workingArrays: (goodBots: [TaskBot], badBots: [TaskBot]), thisEntity: GKEntity) -> ([TaskBot], [TaskBot]) in
            guard let thisTaskBot = thisEntity as? TaskBot else { return workingArrays }
            if thisTaskBot.isGood {
                return (workingArrays.goodBots + [thisTaskBot], workingArrays.badBots)
            }
            else {
                return (workingArrays.goodBots, workingArrays.badBots + [thisTaskBot])
            }
            
        }
        
        let badBotPercentage = Float(badTaskBots.count) / Float(goodTaskBots.count + badTaskBots.count)
        
        for entity in scene.entities {
            let entitySnapshot = EntitySnapshot(badBotPercentage: badBotPercentage, proximityFactor: scene.levelConfiguration.proximityFactor, entityDistances: entityDistances[entity]!)
            entitySnapshots[entity] = entitySnapshot
        }
        
    }
    
}

class EntitySnapshot {
    
    // MARK: - Properties
    let badBotPercentage: Float
    let proximityFactor: Float
    let playerBotTarget: (target: PlayerBot, distance: Float)?
    let nearestGoodTaskBotTarget: (target: TaskBot, distance: Float)?
    let entityDistances: [EntityDistance]
    
    
    // MARK: - Initialization
    init(badBotPercentage: Float, proximityFactor: Float, entityDistances: [EntityDistance]) {
        self.badBotPercentage = badBotPercentage
        self.proximityFactor = proximityFactor
        self.entityDistances = entityDistances.sorted {
            return $0.distance < $1.distance
        }
        
        var playerBotTarget: (target: PlayerBot, distance: Float)?
        var nearestGoodTaskBotTarget: (target: TaskBot, distance: Float)?
        
        for entityDistance in self.entityDistances {
            if let target = entityDistance.target as? PlayerBot, playerBotTarget == nil && target.isTargetable {
                playerBotTarget = (target: target, distance: entityDistance.distance)
            }
            else if let target = entityDistance.target as? TaskBot, nearestGoodTaskBotTarget == nil && target.isGood {
                nearestGoodTaskBotTarget = (target: target, distance: entityDistance.distance)
            }
            
            if playerBotTarget != nil && nearestGoodTaskBotTarget != nil {
                break
            }
        }
        
        self.playerBotTarget = playerBotTarget
        self.nearestGoodTaskBotTarget = nearestGoodTaskBotTarget
    }
}
