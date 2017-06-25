/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The initial state of a `SceneLoader`. Determines which state should be entered at the beginning of the scene loading process.
*/

import GameplayKit

class SceneLoaderInitialState: GKState {
    
    // MARK: - Properties
    unowned let sceneLoader: SceneLoader
    
    
    // MARK: - Initialization
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
    }
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        if !sceneLoader.sceneMetadata.requiresOnDemandResources {
            stateMachine!.enter(SceneLoaderResourcesAvailableState.self)
        }
    }
    
    override func isValidNextState(_  stateClass: AnyClass) -> Bool {
        if stateClass is SceneLoaderDownloadingResourcesState.Type {
            return true
        }
        return stateClass is SceneLoaderResourcesAvailableState.Type
    }
}
