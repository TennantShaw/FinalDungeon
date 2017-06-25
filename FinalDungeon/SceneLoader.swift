/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class encapsulating the work necessary to load a scene and its resources based on a given `SceneMetadata` instance.
*/

import GameplayKit

extension NSNotification.Name {
    public static let SceneLoaderDidCompleteNotification    = NSNotification.Name(rawValue: "SceneLoaderDidCompleteNotification")
    public static let SceneLoaderDidFailNotification        = NSNotification.Name(rawValue: "SceneLoaderDidFailNotification")
}

class SceneLoader {
    
    // MARK: - Properties
    lazy var stateMachine: GKStateMachine = {
        var states = [
            SceneLoaderInitialState(sceneLoader: self),
            SceneLoaderResourcesAvailableState(sceneLoader: self),
            SceneLoaderPreparingResourcesState(sceneLoader: self),
            SceneLoaderResourcesReadyState(sceneLoader: self)
        ]
        states += [
            SceneLoaderDownloadingResourcesState(sceneLoader: self),
            SceneLoaderDownloadFailedState(sceneLoader: self)
        ]
        
        return GKStateMachine(states: states)
    }()
    
    let sceneMetadata: SceneMetadata
    var scene: BaseScene?
    var error: Error?
    var progress: Progress? {
        didSet {
            guard let progress = progress else { return }
            
            progress.cancellationHandler = { [unowned self] in
                self.requestedForPresentation = false
                self.error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
                NotificationCenter.default.post(name: NSNotification.Name.SceneLoaderDidFailNotification, object: self)
            }
        }
    }
    
    var bundleResourceRequest: NSBundleResourceRequest?
    var requiresProgressSceneForPreparing: Bool {
        return sceneMetadata.loadableTypes.contains { $0.resourcesNeedLoading }
    }
    
    var requestedForPresentation = false {
        didSet {
            guard requestedForPresentation else { return }
            
            if stateMachine.currentState is SceneLoaderDownloadingResourcesState {
                bundleResourceRequest?.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
            }
            
            if let preparingState = stateMachine.currentState as? SceneLoaderPreparingResourcesState {
                preparingState.operationQueue.qualityOfService = .userInteractive
            }
        }
    }
    
    
    // MARK: - Initialization
    init(sceneMetadata: SceneMetadata) {
        self.sceneMetadata = sceneMetadata
        stateMachine.enter(SceneLoaderInitialState.self)
    }
    
    func downloadResourcesIfNecessary() {
        if sceneMetadata.requiresOnDemandResources {
            stateMachine.enter(SceneLoaderDownloadingResourcesState.self)
        }
        else {
            stateMachine.enter(SceneLoaderResourcesAvailableState.self)
        }
    }
    
    func asynchronouslyLoadSceneForPresentation() -> Progress {
        if let progress = progress , !progress.isCancelled {
            return progress
        }
        
        switch stateMachine.currentState {
        case is SceneLoaderResourcesReadyState:
            progress = Progress(totalUnitCount: 0)
            
        case is SceneLoaderResourcesAvailableState:
            progress = Progress(totalUnitCount: 1)
            
            stateMachine.enter(SceneLoaderPreparingResourcesState.self)
            
        default:
            progress = Progress(totalUnitCount: 2)
            
            let downloadingState = stateMachine.state(forClass: SceneLoaderDownloadingResourcesState.self)!
            downloadingState.enterPreparingStateWhenFinished = true
            
            stateMachine.enter(SceneLoaderDownloadingResourcesState.self)
            
            guard let bundleResourceRequest = bundleResourceRequest else {
                fatalError("In the `SceneLoaderDownloadingResourcesState`, but a valid resource request has not been created.")
            }
            
            progress!.addChild(bundleResourceRequest.progress, withPendingUnitCount: 1)
            bundleResourceRequest.loadingPriority = 0.8
        }
        
        return progress!
    }
    
    func purgeResources() {
        progress?.cancel()
        stateMachine.enter(SceneLoaderInitialState.self)
        bundleResourceRequest = nil
        scene = nil
        error = nil
    }
}
