/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that the loader is currently downloading on demand resources.
*/

import GameplayKit

class SceneLoaderDownloadingResourcesState: GKState {
    
    // MARK: - Properties
    unowned let sceneLoader: SceneLoader
    var enterPreparingStateWhenFinished = false
    
    
    // MARK: - Initialization
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        sceneLoader.error = nil
        beginDownloadingScene()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is SceneLoaderDownloadFailedState.Type, is SceneLoaderResourcesAvailableState.Type, is SceneLoaderPreparingResourcesState.Type:
            return true
            
        default:
            return false
        }
    }
    
    // MARK: - Downloading Actions
    private func beginDownloadingScene() {
        let bundleResourceRequest = NSBundleResourceRequest(tags: sceneLoader.sceneMetadata.onDemandResourcesTags)
        sceneLoader.bundleResourceRequest = bundleResourceRequest
        bundleResourceRequest.beginAccessingResources { error in
            DispatchQueue.main.async {
                if let error = error {
                    bundleResourceRequest.endAccessingResources()
                    self.sceneLoader.error = error
                    self.stateMachine!.enter(SceneLoaderDownloadFailedState.self)
                }
                else if self.enterPreparingStateWhenFinished {
                    self.stateMachine!.enter(SceneLoaderPreparingResourcesState.self)
                }
                else {
                    self.stateMachine!.enter(SceneLoaderResourcesAvailableState.self)
                }
            }
        }
    }
}
