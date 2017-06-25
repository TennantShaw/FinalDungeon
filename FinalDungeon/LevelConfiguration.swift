/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A structure that encapsulates the initial configuration of a level in the game, including the initial states and positions of `TaskBot`s. This information is loaded from a property list.
*/

import Foundation

struct LevelConfiguration {
    
    // MARK: Types
    struct TaskBotConfiguration {
        
        // MARK: Properties
        enum Locomotion {
            case ground
        }
        
        let locomotion: Locomotion
        let initialOrientation: CompassDirection
        let goodPathNodeNames: [String]
        let badPathNodeNames: [String]
        let startsBad: Bool
        
        
        // MARK: Initialization
        init(botConfigurationInfo: [String: AnyObject]) {
            switch botConfigurationInfo["locomotion"] as! String {
            case "ground":
                locomotion = .ground
            default:
                fatalError("Unknown locomotion found while parsing `taskBot` data")
            }
            
            initialOrientation = CompassDirection(string: botConfigurationInfo["initialOrientation"] as! String)
            goodPathNodeNames = botConfigurationInfo["goodPathNodeNames"] as! [String]
            badPathNodeNames = botConfigurationInfo["badPathNodeNames"] as! [String]
            startsBad = botConfigurationInfo["startsBad"] as! Bool
        }
        
    }
    
    struct TrapConfiguration {
        
        // MARK: - Properties
        let initialOrientation: CompassDirection
        let trapNodeNames: [String]
        
        // MARK: - Initialization
        init(trapConfigurationInfo: [String:AnyObject]) {
            initialOrientation = CompassDirection(string: trapConfigurationInfo["initialOrientation"] as! String)
            
            trapNodeNames = trapConfigurationInfo["trapPosition"] as! [String]
        }
    }
    
    
    // MARK: Properties
    private let configurationInfo: [String: AnyObject]
    let initialPlayerBotOrientation: CompassDirection
    let initialMoogleOrientation: CompassDirection
    let taskBotConfigurations: [TaskBotConfiguration]
    let trapConfiguration: [TrapConfiguration]
    let fileName: String
    
    var nextLevelName: String? {
        return configurationInfo["nextLevel"] as! String?
    }
    
    var timeLimit: TimeInterval {
        return configurationInfo["timeLimit"] as! TimeInterval
    }
    
    var proximityFactor: Float {
        return configurationInfo["proximityFactor"] as! Float
    }
    
    
    // MARK: Initialization
    init(fileName: String) {
        self.fileName = fileName
        
        let url = Bundle.main.url(forResource: fileName, withExtension: "plist")
        
        configurationInfo = NSDictionary(contentsOf: url!) as! [String: AnyObject]
        
        let botConfigurations = configurationInfo["taskBotConfigurations"] as! [[String: AnyObject]]
        let trapConfigurations = configurationInfo["trapConfigurations"] as! [[String:AnyObject]]
        
        taskBotConfigurations = botConfigurations.map { TaskBotConfiguration(botConfigurationInfo: $0) }
        trapConfiguration = trapConfigurations.map { TrapConfiguration(trapConfigurationInfo: $0) }
        
        
        initialPlayerBotOrientation = CompassDirection(string: configurationInfo["initialPlayerBotOrientation"] as! String)
        initialMoogleOrientation = CompassDirection(string: configurationInfo["moogleOrientation"] as! String)
    }
}

