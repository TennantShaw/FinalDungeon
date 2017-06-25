/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A scene used to indicate the progress of loading additional content between scenes.
*/

import SpriteKit

private var progressSceneKVOContext = 0

class ProgressScene: BaseScene {
    
    // MARK: - Properties
    override var backgroundNode: SKSpriteNode? {
        return childNode(withName: "backgroundNode") as? SKSpriteNode
    }
    
    var labelNode: SKLabelNode {
        return backgroundNode!.childNode(withName: "label") as! SKLabelNode
    }
    
    var progressBarNode: SKSpriteNode {
        return backgroundNode!.childNode(withName: "progressBar") as! SKSpriteNode
    }
    
    var sceneLoader: SceneLoader!
    var progressBarInitialWidth: CGFloat!
    var progress: Progress? {
        didSet {
            oldValue?.removeObserver(self, forKeyPath: "fractionCompleted", context: &progressSceneKVOContext)
            progress?.addObserver(self, forKeyPath: "fractionCompleted", options: [.new, .initial], context: &progressSceneKVOContext)
        }
    }
    
    private var downloadFailedObserver: AnyObject?
    
    
    // MARK: - Initializers
    static func progressScene(withSceneLoader loader: SceneLoader) -> ProgressScene {
        let progressScene = ProgressScene(fileNamed: "ProgressScene")!
        
        progressScene.createCamera()
        progressScene.setup(withSceneLoader: loader)
        
        return progressScene
    }
    
    func setup(withSceneLoader loader: SceneLoader) {
        self.sceneLoader = loader
        
        if let progress = sceneLoader.progress {
            self.progress = progress
        }
        else {
            progress = sceneLoader.asynchronouslyLoadSceneForPresentation()
        }
        
        let defaultCenter = NotificationCenter.default
        downloadFailedObserver = defaultCenter.addObserver(forName: NSNotification.Name.SceneLoaderDidFailNotification, object: sceneLoader, queue: OperationQueue.main) { [unowned self] notification in
            guard let loader = notification.object as? SceneLoader, let error = loader.error else { fatalError("The scene loader has no error to show.") }
            
            self.showError(error as NSError)
        }
    }
    
    deinit {
        if let downloadFailedObserver = downloadFailedObserver {
            NotificationCenter.default.removeObserver(downloadFailedObserver, name: NSNotification.Name.SceneLoaderDidFailNotification, object: sceneLoader)
        }
        progress = nil
    }
    
    
    // MARK: - Scene Life Cycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        centerCameraOnPoint(point: backgroundNode!.position)
        progressBarInitialWidth = progressBarNode.frame.width
        
        if let error = sceneLoader.error {
            showError(error as NSError)
        }
        else {
            showDefaultState()
        }
    }
    
    
    // MARK: - Key Value Observing (KVO) for NSProgress
    @nonobjc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &progressSceneKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if let changedProgress = object as? Progress, changedProgress == progress, keyPath == "fractionCompleted" {
            DispatchQueue.main.async {
                guard let progress = self.progress else { return }
                self.progressBarNode.size.width = self.progressBarInitialWidth * CGFloat(progress.fractionCompleted)
                self.labelNode.text = progress.localizedDescription
            }
        }
    }
    
    
    // MARK: - ButtonNodeResponderType
    override func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
        case .retry:
            progress = sceneLoader.asynchronouslyLoadSceneForPresentation()
            sceneLoader.requestedForPresentation = true
            showDefaultState()
        case .cancel:
            progress!.cancel()
        default:
            super.buttonTriggered(button: button)
        }
    }
    
    
    // MARK: - Convenience
    func button(withIdentifier identifier: ButtonIdentifier) -> ButtonNode? {
        return backgroundNode?.childNode(withName: identifier.rawValue) as? ButtonNode
    }
    
    func showDefaultState() {
        progressBarNode.isHidden = false
        
        button(withIdentifier: .home)?.isHidden = true
        button(withIdentifier: .retry)?.isHidden = true
        button(withIdentifier: .cancel)?.isHidden = false
    }
    
    func showError(_ error: NSError) {
        progress = nil
        
        button(withIdentifier: .home)?.isHidden = false
        button(withIdentifier: .retry)?.isHidden = false
        button(withIdentifier: .cancel)?.isHidden = true
        
        progressBarNode.isHidden = true
        progressBarNode.size.width = 0.0
        
        if error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError {
            labelNode.text = NSLocalizedString("Cancelled", comment: "Displayed when the user cancels loading.")
        }
        else {
            showAlert(for: error)
        }
    }
    
    func showAlert(for error: NSError) {
        labelNode.text = NSLocalizedString("Failed", comment: "Displayed when the scene loader fails to load a scene.")
    }
}

