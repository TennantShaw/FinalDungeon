/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that resources for the scene are being loaded into memory.
*/

import GameplayKit

class SceneLoaderPreparingResourcesState: GKState {
    
    // MARK: - Properties
    unowned let sceneLoader: SceneLoader
    let operationQueue = OperationQueue()
    var progress: Progress? {
        didSet {
            guard let progress = progress else { return }
            progress.cancellationHandler = { [unowned self] in
                self.cancel()
            }
        }
    }
    
    
    // MARK: - Initialization
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
        operationQueue.name = "com.example.apple-samplecode.sceneloaderpreparingresourcesstate"
        operationQueue.qualityOfService = .utility
    }
    
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        loadResourcesAsynchronously()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is SceneLoaderResourcesReadyState.Type where sceneLoader.scene != nil:
            return true
        case is SceneLoaderResourcesAvailableState.Type:
            return true
        default:
            return false
        }
    }
    
    
    // MARK: - Load Resources
    private func loadResourcesAsynchronously() {
        let sceneMetadata = sceneLoader.sceneMetadata
        let loadingProgress = Progress(totalUnitCount: sceneMetadata.loadableTypes.count + 1)
        sceneLoader.progress?.addChild(loadingProgress, withPendingUnitCount: 1)
        progress = loadingProgress
        let loadSceneOperation = LoadSceneOperation(sceneMetadata: sceneMetadata)
        loadingProgress.addChild(loadSceneOperation.progress, withPendingUnitCount: 1)
        loadSceneOperation.completionBlock = { [unowned self] in
            DispatchQueue.main.async {
                self.sceneLoader.scene = loadSceneOperation.scene
                let didEnterReadyState = self.stateMachine!.enter(SceneLoaderResourcesReadyState.self)
                assert(didEnterReadyState, "Failed to transition to `ReadyState` after resources were prepared.")
            }
        }
        
        for loaderType in sceneMetadata.loadableTypes {
            let loadResourcesOperation = LoadResourcesOperation(loadableType: loaderType)
            loadingProgress.addChild(loadResourcesOperation.progress, withPendingUnitCount: 1)
            loadSceneOperation.addDependency(loadResourcesOperation)
            operationQueue.addOperation(loadResourcesOperation)
        }
        operationQueue.addOperation(loadSceneOperation)
    }
    
    func cancel() {
        operationQueue.cancelAllOperations()
        sceneLoader.scene = nil
        sceneLoader.error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        DispatchQueue.main.async {
            self.stateMachine!.enter(SceneLoaderResourcesAvailableState.self)
            NotificationCenter.default.post(name: NSNotification.Name.SceneLoaderDidFailNotification, object: self.sceneLoader)
        }
    }
}

