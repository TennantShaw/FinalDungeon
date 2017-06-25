/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The base class for a `LevelScene`'s Pause, Fail, and Success states. Handles the task of loading and displaying a full-screen overlay from a scene file when the state is entered.
*/

import SpriteKit
import GameplayKit

class LevelSceneOverlayState: GKState {
    
    // MARK: - Properties
    unowned let levelScene: LevelScene
    var overlay: SceneOverlay!
    var overlaySceneFileName: String { fatalError("Unimplemented overlaySceneName") }
    
    
    // MARK: - Initializers
    init(levelScene: LevelScene) {
        self.levelScene = levelScene
        
        super.init()
        
        overlay = SceneOverlay(overlaySceneFileName: overlaySceneFileName, zPosition: WorldLayer.top.rawValue)
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        levelScene.overlay = overlay
    }
    
    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        
        levelScene.overlay = nil
    }
    
    
    // MARK: - Convenience
    func button(withIdentifier identifier: ButtonIdentifier) -> ButtonNode? {
        return overlay.contentNode.childNode(withName: "//\(identifier.rawValue)") as? ButtonNode
    }
}
