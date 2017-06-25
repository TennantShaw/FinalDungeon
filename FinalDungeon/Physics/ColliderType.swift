/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An option set used for categorizing physics bodies in SpriteKit's physics world.
*/

import SpriteKit
import GameplayKit

struct ColliderType: OptionSet, Hashable, CustomDebugStringConvertible {
    
    // MARK: - Static properties
    static var requestedContactNotifications = [ColliderType: [ColliderType]]()
    static var definedCollisions = [ColliderType: [ColliderType]]()
    
    
    // MARK: - Properties
    let rawValue: UInt32
    
    
    // MARK: - Options
    static var Obstacle: ColliderType  { return self.init(rawValue: 1 << 0) }
    static var PlayerBot: ColliderType { return self.init(rawValue: 1 << 1) }
    static var TaskBot: ColliderType   { return self.init(rawValue: 1 << 2) }
    static var Moogle: ColliderType    { return self.init(rawValue: 1 << 4) }
    static var Trap: ColliderType      { return self.init(rawValue: 1 << 9) }
    
    
    // MARK: - Hashable
    var hashValue: Int {
        return Int(rawValue)
    }
    
    
    // MARK: - CustomDebugStringConvertible
    var debugDescription: String {
        switch self.rawValue {
        case ColliderType.Obstacle.rawValue:
            return "ColliderType.Obstacle"
            
        case ColliderType.PlayerBot.rawValue:
            return "ColliderType.PlayerBot"
            
        case ColliderType.TaskBot.rawValue:
            return "ColliderType.TaskBot"
            
        case ColliderType.Moogle.rawValue:
            return "ColliderType.Moogle"
            
        case ColliderType.Trap.rawValue:
            return "ColliderType.Trap"

        default:
            return "UnknownColliderType(\(self.rawValue))"
        }
    }
    
    
    // MARK: - SpriteKit Physics Convenience
    var categoryMask: UInt32 {
        return rawValue
    }
    
    var collisionMask: UInt32 {
        let mask = ColliderType.definedCollisions[self]?.reduce(ColliderType()) { initial, colliderType in
            return initial.union(colliderType)
        }
        
        return mask?.rawValue ?? 0
    }
    
    var contactMask: UInt32 {
        let mask = ColliderType.requestedContactNotifications[self]?.reduce(ColliderType()) { initial, colliderType in
            return initial.union(colliderType)
        }
        
        return mask?.rawValue ?? 0
    }
    
    
    // MARK: - ContactNotifiableType Convenience
    func notifyOnContactWith(_ colliderType: ColliderType) -> Bool {
        if let requestedContacts = ColliderType.requestedContactNotifications[self] {
            return requestedContacts.contains(colliderType)
        }
        
        return false
    }
}
