/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that the downloading of on demand resources failed.
*/

import GameplayKit

class SceneLoaderDownloadFailedState: GKState {
    
    // MARK: - Properties
    unowned let sceneLoader: SceneLoader
    
    
    // MARK: - Initialization
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        sceneLoader.progress = nil
        NotificationCenter.default.post(name: NSNotification.Name.SceneLoaderDidFailNotification, object: sceneLoader)
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is SceneLoaderDownloadingResourcesState.Type
    }
}
