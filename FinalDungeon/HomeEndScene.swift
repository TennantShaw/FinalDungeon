/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An `SKScene` used to represent and manage the home and end scenes of the game.
*/

import SpriteKit

class HomeEndScene: BaseScene {
    
    // MARK: - Properties
    override var backgroundNode: SKSpriteNode? {
        return childNode(withName: "backgroundNode") as? SKSpriteNode
    }
    
    var proceedButton: ButtonNode? {
        return backgroundNode?.childNode(withName: ButtonIdentifier.proceedToNextScene.rawValue) as? ButtonNode
    }
    
    private var sceneLoaderNotificationObservers = [Any]()
    
    
    // MARK: - Deinitialization
    deinit {
        // Deregister for scene loader notifications.
        for observer in sceneLoaderNotificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    
    // MARK: - Scene Life Cycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        registerForNotifications()
        centerCameraOnPoint(point: backgroundNode!.position)
        
        sceneManager.prepareScene(identifier: .level(1))
        
        let levelLoader = sceneManager.sceneLoader(forSceneIdentifier: .level(1))
        
        if !(levelLoader.stateMachine.currentState is SceneLoaderResourcesReadyState) {
            proceedButton?.alpha = 0.0
            proceedButton?.isUserInteractionEnabled = false
        }
    }
    
    func registerForNotifications() {
        guard sceneLoaderNotificationObservers.isEmpty else { return }
        
        let handleSceneLoaderNotification: (Notification) -> () = { [unowned self] notification in
            let sceneLoader = notification.object as! SceneLoader
            
            if sceneLoader.sceneMetadata.sceneType is LevelScene.Type {
                self.proceedButton?.isUserInteractionEnabled = true
                self.proceedButton?.run(SKAction.fadeIn(withDuration: 1.0))
            }
        }
        
        let completeNotification = NotificationCenter.default.addObserver(forName: NSNotification.Name.SceneLoaderDidCompleteNotification, object: nil, queue: OperationQueue.main, using: handleSceneLoaderNotification)
        let failNotification = NotificationCenter.default.addObserver(forName: NSNotification.Name.SceneLoaderDidFailNotification, object: nil, queue: OperationQueue.main, using: handleSceneLoaderNotification)
        
        sceneLoaderNotificationObservers += [completeNotification, failNotification]
    }
}
