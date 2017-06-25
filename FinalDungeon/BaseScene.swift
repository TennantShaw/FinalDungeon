/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The base class for all scenes in the app.
*/

import SpriteKit

/**
 A base class for all of the scenes in the app.
 */
class BaseScene: SKScene, GameInputDelegate, ControlInputSourceGameStateDelegate {
    
    // MARK: - Properties
    var nativeSize = CGSize.zero
    var backgroundNode: SKSpriteNode? {
        return nil
    }
    var buttons = [ButtonNode]()
    var focusChangesEnabled = false
    var overlay: SceneOverlay? {
        didSet {
            buttons = []
            
            if let overlay = overlay, let camera = camera {
                overlay.backgroundNode.removeFromParent()
                camera.addChild(overlay.backgroundNode)
                
                overlay.backgroundNode.alpha = 0.0
                overlay.backgroundNode.run(SKAction.fadeIn(withDuration: 0.25))
                overlay.updateScale()
                
                buttons = findAllButtonsInScene()
            }
            
            oldValue?.backgroundNode.run(SKAction.fadeOut(withDuration: 0.25)) {
                oldValue?.backgroundNode.removeFromParent()
            }
        }
    }
    weak var sceneManager: SceneManager!
    
    
    // MARK: - SKScene Life Cycle
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        updateCameraScale()
        overlay?.updateScale()
        
        sceneManager.gameInput.delegate = self
        
        buttons = findAllButtonsInScene()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        
        updateCameraScale()
        overlay?.updateScale()
    }
    
    
    // MARK: - GameInputDelegate
    func gameInputDidUpdateControlInputSources(gameInput: GameInput) {
        for controlInputSource in gameInput.controlInputSources {
            controlInputSource.gameStateDelegate = self
        }
    }
    
    
    // MARK: - ControlInputSourceGameStateDelegate
    func controlInputSourceDidSelect(_ controlInputSource: ControlInputSourceType) {
    }
    
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didSpecifyDirection direction: ControlInputDirection) {
    }
    
    func controlInputSourceDidTogglePauseState(_ controlInputSource: ControlInputSourceType) {
    }
    
    
    // MARK: - Camera Actions
    func createCamera() {
        if let backgroundNode = backgroundNode {
            nativeSize = backgroundNode.size
        } else {
            nativeSize = size
        }
        
        let camera = SKCameraNode()
        self.camera = camera
        addChild(camera)
        
        updateCameraScale()
    }
    
    func centerCameraOnPoint(point: CGPoint) {
        if let camera = camera {
            camera.position = point
        }
    }
    
    func updateCameraScale() {
        if let camera = camera {
            camera.setScale(nativeSize.height / size.height)
        }
    }
}
