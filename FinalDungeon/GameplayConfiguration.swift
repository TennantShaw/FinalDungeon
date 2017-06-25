/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Configuration information and parameters for the game's gameplay. Adjust these numbers to modify how the game behaves.
*/

import Foundation
import CoreGraphics

struct GameplayConfiguration {
    struct Moogle {
        static var physicsBodyRadius: CGFloat = 30.0
        static var physicsBodyOffset = CGPoint(x: 0.0, y: -25.0)
    }
    
    struct Trap {
        static var physicsBodyRadius: CGFloat = 10.0
        static var physicsBodyOffset = CGPoint(x: 0.0, y: 0.0)
        static let chargeLossPerContact = 50.0

    }
    
    struct PlayerBot {
        /// The movement speed (in points per second) for the `PlayerBot`.
        static let movementSpeed: CGFloat = 300.0
        
        /// The angular rotation speed (in radians per second) for the `PlayerBot`.
        static let angularSpeed = CGFloat(Double.pi) * 1.4
        
        /// The radius of the `PlayerBot`'s physics body.
        static var physicsBodyRadius: CGFloat = 15.0
        
        /// The offset of the `PlayerBot`'s physics body's center from the `PlayerBot`'s center.
        static let physicsBodyOffset = CGPoint(x: 0.0, y: -25.0)
        
        /// The radius of the agent associated with this `PlayerBot` for pathfinding.
        static let agentRadius = Float(physicsBodyRadius)
        
        /// The offset of the agent's center from the `PlayerBot`'s center.
        static let agentOffset = physicsBodyOffset
        
        /// The offset of the `PlayerBot`'s antenna
        static let antennaOffset = CGPoint(x: 0.0, y: 50.0)
        
        /// The offset of the `PlayerBot`'s charge bar from its position.
        static let chargeBarOffset = CGPoint(x: 0.0, y: 65.0)
        
        /// The initial charge value for the `PlayerBot`'s health bar.
        static let initialCharge = 100.0
        
        /// The maximum charge value for the `PlayerBot`'s health bar.
        static let maximumCharge = 100.0
        
        /// The length of time for which the `PlayerBot` remains in its "hit" state.
        static let hitStateDuration: TimeInterval = 0.75
        
        /// The length of time that it takes the `PlayerBot` to recharge when deactivated.
        static let rechargeDelayWhenInactive: TimeInterval = 1.0
        
        /// The amount of charge that the `PlayerBot` gains per second when recharging.
        static let rechargeAmountPerSecond = 50.0
        
        /// The amount of time it takes the `PlayerBot` to appear in a level before becoming controllable by the player.
        static let appearDuration: TimeInterval = 0.50
    }
    
    struct TaskBot {
        /// The length of time a `TaskBot` waits before re-evaluating its rules.
        static let rulesUpdateWaitDuration: TimeInterval = 0.5
        
        /// The length of time a `TaskBot` waits before re-checking for an appropriate behavior.
        static let behaviorUpdateWaitDuration: TimeInterval = 0.25
        
        /// How close a `TaskBot` has to be to a patrol path start point in order to start patrolling.
        static let thresholdProximityToPatrolPathStartPoint: Float = 50.0
        
        /// The maximum speed (in points per second) for the `TaskBot` when in its "good" state.
        static let maximumSpeedWhenGood: Float = 250.0
        
        /// The maximum speed (in points per second) for the `TaskBot` when in its "bad" state.
        static let maximumSpeedWhenBad: Float = 120.0
        
        /// A convenience function to return the max speed for a state.
        static func maximumSpeedForIsGood(isGood: Bool) -> Float {
            return isGood ? maximumSpeedWhenGood : maximumSpeedWhenBad
        }
        
        /*
         `maximumAcceleration` is set to a high number to enable the TaskBot to turn very quickly.
         This ensures that the `TaskBot` can follow its patrol path more effectively.
         */
        /// The maximum acceleration (in points per second per second) for the `TaskBot`.
        static let maximumAcceleration: Float = 300.0
        
        /// The agent's mass.
        static let agentMass: Float = 0.25
        
        /// The radius of the `TaskBot`'s physics body.
        static var physicsBodyRadius: CGFloat = 35.0
        
        /// The offset of the `TaskBot` physics body's center from the `TaskBot`'s center.
        static let physicsBodyOffset = CGPoint(x: 0.0, y: -25.0)
        
        /// The radius (in points) of the agent associated with this `TaskBot` for steering.
        static let agentRadius = Float(physicsBodyRadius)
        
        /// The offset of the agent's center from the `TaskBot`'s center.
        static let agentOffset = physicsBodyOffset
        
        /// The maximum time to look ahead when following a path.
        static let maxPredictionTimeWhenFollowingPath: TimeInterval = 1.5
        
        /// The maximum time to look ahead for obstacles to be avoided.
        static let maxPredictionTimeForObstacleAvoidance: TimeInterval = 1.5
        
        /// The radius of the path along which an agent patrols.
        static let patrolPathRadius: Float = 10.0
        
        /// The radius of the path along which an agent travels when hunting.
        static let huntPathRadius: Float = 20.0
        
        /// The radius of the path along which an agent travels when returning to its patrol path.
        static let returnToPatrolPathRadius: Float = 20.0
        
        /// The buffer radius (in points) to add to polygon obstacles when calculating agent pathfinding.
        static let pathfindingGraphBufferRadius: Float = 30.0
        
        /// The duration of a `TaskBot`'s pre-attack state.
        static let preAttackStateDuration: TimeInterval = 0.5
        
        /// The duration of a `TaskBot`'s zapped state.
        static let zappedStateDuration: TimeInterval = 0.75
    }
    
    struct GroundBot {
        /// The maximum amount of charge a `GroundBot` stores.
        static let maximumCharge = 100.0
        
        /// The amount of charge a `PlayerBot` loses by a single `GroundBot` attack.
        static let chargeLossPerContact = 25.0
        
        /// The maximum distance a `GroundBot` can be from a target before it attacks.
        static let maximumAttackDistance: Float = 300.0
        
        /// Proximity to the target after which the `GroundBot` attack should end.
        static let attackEndProximity: Float = 7.0
        
        /// How fast the `GroundBot` rotates to face its target in radians per second.
        static let preAttackRotationSpeed = Double.pi / 4
        
        /// How much faster the `GroundBot` can move when attacking.
        static let movementSpeedMultiplierWhenAttacking: CGFloat = 3.0
        
        /// How much faster the `GroundBot` can rotate when attacking.
        static let angularSpeedMultiplierWhenAttacking: CGFloat = 3.0
        
        /// The amount of time to wait between `GroundBot` attacks.
        static let delayBetweenAttacks: TimeInterval = 0.5
        
        /// The offset from the `GroundBot`'s position that should be used for beam targeting.
        static let beamTargetOffset = CGPoint(x: 0.0, y: 40.0)
    }
    
    struct Flocking {
        static let separationRadius: Float = 25.3
        static let separationAngle = Float (3 * (Double.pi / 4))
        static let separationWeight: Float = 2.0
        
        static let alignmentRadius: Float = 43.333
        static let alignmentAngle = Float(Double.pi / 4)
        static let alignmentWeight: Float = 1.667
        
        static let cohesionRadius: Float = 50.0
        static let cohesionAngle = Float(Double.pi / 2)
        static let cohesionWeight: Float = 1.667
        
        static let agentSearchDistanceForFlocking: Float = 50.0
    }
    
    struct TouchControl {
        static let minimumRequiredThumbstickDisplacement: Float = 0.35
        static let minimumControlSize: CGFloat = 140
        static let idealRelativeControlSize: CGFloat = 0.15
    }
    
    struct SceneManager {
        static let transitionDuration: TimeInterval = 2.0
        static let progressSceneTransitionDuration: TimeInterval = 0.5
    }
    
    struct Timer {
        static let fontName = "DINCondensed-Bold"
        static let fontSize: CGFloat = 0.05
        static let paddingSize: CGFloat = 0.2
    }
}
