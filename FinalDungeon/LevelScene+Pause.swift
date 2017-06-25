/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension on `LevelScene` which ensures that game play is paused when the app enters the background for a number of user initiated events.
*/

import UIKit

extension LevelScene {
    
    // MARK: - Properties
    override var isPaused: Bool {
        didSet {
            if overlay != nil {
                worldNode.isPaused = true
            }
        }
    }
    
    private var pauseNotificationNames: [NSNotification.Name] {
        return [NSNotification.Name.UIApplicationWillResignActive]
    }
    
    
    // MARK: - Convenience
    func registerForPauseNotifications() {
        for notificationName in pauseNotificationNames {
            NotificationCenter.default.addObserver(self, selector: #selector(LevelScene.pauseGame), name: notificationName, object: nil)
        }
    }
    
    func pauseGame() {
        stateMachine.enter(LevelScenePauseState.self)
    }
    
    func unregisterForPauseNotifications() {
        for notificationName in pauseNotificationNames {
            NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
        }
    }
}
