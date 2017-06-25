/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A subclass of `Operation` that manages the loading of a `BaseScene`.
            
*/

import Foundation

class LoadSceneOperation: SceneOperation, ProgressReporting {
    
    // MARK: - Properties
    let sceneMetadata: SceneMetadata
    var scene: BaseScene?
    let progress: Progress
    
    
    // MARK: - Initialization
    init(sceneMetadata: SceneMetadata) {
        self.sceneMetadata = sceneMetadata
        
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
        
        state = .executing
        let scene = sceneMetadata.sceneType.init(fileNamed: sceneMetadata.fileName)!
        self.scene = scene
        scene.createCamera()
        progress.completedUnitCount = 1
        state = .finished
    }
}
