/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An extension of `BaseScene` to provide iOS platform specific functionality. This file is only included in the iOS target.
*/

import UIKit

extension BaseScene {
    
    // MARK: Properties
    var touchControlInputNode: TouchControlInputNode {
        return sceneManager.gameInput.nativeControlInputSource as! TouchControlInputNode
    }
    
    
    // MARK: Setup Touch Handling
    func addTouchInputToScene() {
        guard let camera = camera else { fatalError("Touch input controls can only be added to a scene that has an associated camera.") }
        
        touchControlInputNode.removeFromParent()
        
        if self is LevelScene {
            touchControlInputNode.size = size
            touchControlInputNode.position = CGPoint.zero
            touchControlInputNode.zPosition = WorldLayer.top.rawValue - CGFloat(1.0)
            camera.addChild(touchControlInputNode)
            touchControlInputNode.hideThumbStickNodes = false
        }
    }
}
