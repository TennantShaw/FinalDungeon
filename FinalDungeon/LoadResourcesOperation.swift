/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A subclass of `Operation` that manages the loading of a `ResourceLoadableType`'s resources.
            
*/

import Foundation

class LoadResourcesOperation: SceneOperation, ProgressReporting {
    
    // MARK: - Properties
    let loadableType: ResourceLoadableType.Type
    let progress: Progress
    
    
    // MARK: - Initialization
    init(loadableType: ResourceLoadableType.Type) {
        self.loadableType = loadableType
        progress = Progress(totalUnitCount: 1)
        super.init()
    }
    
    
    // MARK: - NSOperation
    override func start() {
        guard !isCancelled else { return }
        if progress.isCancelled {
            cancel()
            return
        }
        guard loadableType.resourcesNeedLoading else {
            finish()
            return
        }
        state = .executing
        loadableType.loadResources() { [unowned self] in
            self.finish()
        }
    }
    
    func finish() {
        progress.completedUnitCount = 1
        state = .finished
    }
}
