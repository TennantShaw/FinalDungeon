/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `LevelScene` to indicate that the player completed a level successfully.
*/

import SpriteKit
import GameplayKit

class LevelSceneSuccessState: LevelSceneOverlayState {
    
    // MARK: - Properties
    override var overlaySceneFileName: String {
        return "SuccessScene"
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        levelScene.worldNode.isHidden = true

        if let inputComponent = levelScene.playerBot.component(ofType: InputComponent.self) {
            inputComponent.isEnabled = false
        }
        levelScene.sceneManager.prepareScene(identifier: .nextLevel)
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return false
    }
}
