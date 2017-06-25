/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `SceneManager` is responsible for presenting scenes, requesting future scenes be downloaded, and loading assets in the background.
*/

import SpriteKit

protocol SceneManagerDelegate: class {
    func sceneManager(_ sceneManager: SceneManager, didTransitionTo scene: SKScene)
}

final class SceneManager {
    
    // MARK: - Types
    enum SceneIdentifier {
        case home, end
        case currentLevel, nextLevel
        case level(Int)
    }
    
    
    // MARK: - Properties
    let sceneLoaderForMetadata: [SceneMetadata: SceneLoader]
    let gameInput: GameInput
    let presentingView: SKView
    var nextSceneMetadata: SceneMetadata {
        let homeScene = sceneConfigurationInfo.first!
        guard let currentSceneMetadata = currentSceneMetadata else { return homeScene }
        let index = sceneConfigurationInfo.index(of: currentSceneMetadata)!
        
        if index + 1 < sceneConfigurationInfo.count {
            return sceneConfigurationInfo[index + 1]
        }
        return homeScene
    }
    
    weak var delegate: SceneManagerDelegate?
    private (set) var currentSceneMetadata: SceneMetadata?
    private var progressScene: ProgressScene?
    private let sceneConfigurationInfo: [SceneMetadata]
    private var loadingCompletedObserver: AnyObject?
    
    
    // MARK: - Initialization
    init(presentingView: SKView, gameInput: GameInput) {
        self.presentingView = presentingView
        self.gameInput = gameInput
        
        let url = Bundle.main.url(forResource: "SceneConfiguration", withExtension: "plist")!
        let scenes = NSArray(contentsOf: url) as! [[String: AnyObject]]
        
        sceneConfigurationInfo = scenes.map {
            SceneMetadata(sceneConfiguration: $0)
        }
        
        var sceneLoaderForMetadata = [SceneMetadata: SceneLoader]()
        for metadata in sceneConfigurationInfo {
            let sceneLoader = SceneLoader(sceneMetadata: metadata)
            sceneLoaderForMetadata[metadata] = sceneLoader
        }
        
        self.sceneLoaderForMetadata = sceneLoaderForMetadata
        registerForNotifications()
    }
    
    deinit {
        if let loadingCompletedObserver = loadingCompletedObserver {
            NotificationCenter.default.removeObserver(loadingCompletedObserver, name: NSNotification.Name.SceneLoaderDidCompleteNotification, object: nil)
        }
    }
    
    
    // MARK: - Scene Transitioning
    func prepareScene(identifier sceneIdentifier: SceneIdentifier) {
        let loader = sceneLoader(forSceneIdentifier: sceneIdentifier)
        _ = loader.asynchronouslyLoadSceneForPresentation()
    }
    
    func transitionToScene(identifier sceneIdentifier: SceneIdentifier) {
        let loader = self.sceneLoader(forSceneIdentifier: sceneIdentifier)
        
        if loader.stateMachine.currentState is SceneLoaderResourcesReadyState {
            presentScene(for: loader)
        }
        else {
            _ = loader.asynchronouslyLoadSceneForPresentation()
            
            loader.requestedForPresentation = true
            
            if loader.requiresProgressSceneForPreparing {
                presentProgressScene(for: loader)
            }
        }
    }
    
    
    // MARK: - Scene Presentation
    func presentScene(for loader: SceneLoader) {
        guard let scene = loader.scene else {
            assertionFailure("Requested presentation for a `sceneLoader` without a valid `scene`.")
            return
        }
        
        currentSceneMetadata = loader.sceneMetadata
        
        DispatchQueue.main.async {
            scene.sceneManager = self
            let transition = SKTransition.fade(withDuration: GameplayConfiguration.SceneManager.transitionDuration)
            self.presentingView.presentScene(scene, transition: transition)
            self.beginDownloadingNextPossibleScenes()
            self.progressScene = nil
            self.delegate?.sceneManager(self, didTransitionTo: scene)
            loader.stateMachine.enter(SceneLoaderInitialState.self)
        }
    }
    
    func presentProgressScene(for loader: SceneLoader) {
        guard progressScene == nil else { return }
        
        progressScene = ProgressScene.progressScene(withSceneLoader: loader)
        progressScene!.sceneManager = self
        
        let transition = SKTransition.doorsCloseHorizontal(withDuration: GameplayConfiguration.SceneManager.progressSceneTransitionDuration)
        presentingView.presentScene(progressScene!, transition: transition)
    }
    
    private func beginDownloadingNextPossibleScenes() {
        let possibleScenes = allPossibleNextScenes()
        
        for sceneMetadata in possibleScenes {
            let resourceRequest = sceneLoaderForMetadata[sceneMetadata]!
            resourceRequest.downloadResourcesIfNecessary()
        }
        
        var unreachableScenes = Set(sceneLoaderForMetadata.keys)
        unreachableScenes.subtract(possibleScenes)
        
        for sceneMetadata in unreachableScenes {
            let resourceRequest = sceneLoaderForMetadata[sceneMetadata]!
            resourceRequest.purgeResources()
        }
    }
    
    private func allPossibleNextScenes() -> Set<SceneMetadata> {
        let homeScene = sceneConfigurationInfo.first!
        
        guard let currentSceneMetadata = currentSceneMetadata else {
            return [homeScene]
        }
        return [homeScene, nextSceneMetadata, currentSceneMetadata]
    }
    
    
    // MARK: - SceneLoader Notifications
    func registerForNotifications() {
        guard loadingCompletedObserver == nil else { return }
        
        loadingCompletedObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.SceneLoaderDidCompleteNotification, object: nil, queue: OperationQueue.main) { [unowned self] notification in
            let sceneLoader = notification.object as! SceneLoader
            
            guard let managedSceneLoader = self.sceneLoaderForMetadata[sceneLoader.sceneMetadata], managedSceneLoader === sceneLoader else { return }
            
            guard sceneLoader.stateMachine.currentState is SceneLoaderResourcesReadyState else {
                fatalError("Received complete notification, but the `stateMachine`'s current state is not ready.")
            }
            
            if sceneLoader.requestedForPresentation {
                self.presentScene(for: sceneLoader)
            }
            sceneLoader.requestedForPresentation = false
        }
    }
    
    
    // MARK: - Convenience
    func sceneLoader(forSceneIdentifier sceneIdentifier: SceneIdentifier) -> SceneLoader {
        let sceneMetadata: SceneMetadata
        switch sceneIdentifier {
        case .home:
            sceneMetadata = sceneConfigurationInfo.first!
            
        case .currentLevel:
            guard let currentSceneMetadata = currentSceneMetadata else {
                fatalError("Current scene doesn't exist.")
            }
            sceneMetadata = currentSceneMetadata
            
        case .level(let number):
            sceneMetadata = sceneConfigurationInfo[number]
            
        case .nextLevel:
            sceneMetadata = nextSceneMetadata
            
        case .end:
            sceneMetadata = sceneConfigurationInfo.last!
        }
        
        return sceneLoaderForMetadata[sceneMetadata]!
    }
}
