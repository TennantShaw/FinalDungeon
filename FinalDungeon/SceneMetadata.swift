/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A structure to encapsulate metadata about a scene in the game.
*/

import Foundation

struct SceneMetadata {
    
    // MARK: - Properties
    let fileName: String
    let sceneType: BaseScene.Type
    let loadableTypes: [ResourceLoadableType.Type]
    let onDemandResourcesTags: Set<String>
    var requiresOnDemandResources: Bool {
        return !onDemandResourcesTags.isEmpty
    }
    
    
    // MARK: - Initialization
    init(sceneConfiguration: [String: AnyObject]) {
        fileName = sceneConfiguration["fileName"] as! String
        
        let typeIdentifier = sceneConfiguration["sceneType"] as! String
        switch typeIdentifier {
        case "LevelScene":
            sceneType = LevelScene.self
            
        case "HomeEndScene":
            sceneType = HomeEndScene.self
            
        default:
            fatalError("Unidentified sceneType requested.")
        }
        
        var loadableTypesForScene = [ResourceLoadableType.Type]()
        
        if let tags = sceneConfiguration["onDemandResourcesTags"] as? [String] {
            onDemandResourcesTags = Set(tags)
            
            loadableTypesForScene += tags.flatMap { tag in
                switch tag {
                case "GroundBot":
                    return GroundBot.self
                case "Moogle":
                    return Moogle.self
                case "Trap":
                    return Trap.self
                default:
                    return nil
                }
            }
        }
        else {
            onDemandResourcesTags = []
        }
        
        
        if sceneType == LevelScene.self {
            loadableTypesForScene = loadableTypesForScene + [PlayerBot.self, Moogle.self, Trap.self]
        }
        
        loadableTypes = loadableTypesForScene
    }
}


// MARK: - Hashable
extension SceneMetadata: Hashable {
    var hashValue: Int {
        return fileName.hashValue
    }
}

func ==(lhs: SceneMetadata, rhs: SceneMetadata)-> Bool {
    return lhs.hashValue == rhs.hashValue
}
