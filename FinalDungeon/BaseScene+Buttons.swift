/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension of `BaseScene` to enable it to respond to button presses.
*/

import Foundation

extension BaseScene: ButtonNodeResponderType {
    func findAllButtonsInScene() -> [ButtonNode] {
        return ButtonIdentifier.allButtonIdentifiers.flatMap { buttonIdentifier in
            childNode(withName: "//\(buttonIdentifier.rawValue)") as? ButtonNode
        }
    }
    
    
    // MARK: - ButtonNodeResponderType
    func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
        case .home:
            sceneManager.transitionToScene(identifier: .home)
            
        case .proceedToNextScene:
            sceneManager.transitionToScene(identifier: .nextLevel)
            
        case .replay:
            sceneManager.transitionToScene(identifier: .currentLevel)
            
        default:
            fatalError("Unsupported ButtonNode type in Scene.")
        }
    }
    
}
