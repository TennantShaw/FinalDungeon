/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class to manage the display of an overlay set of nodes on top of an existing scene.
*/

import SpriteKit

class SceneOverlay {
    
    // MARK: - Properties
    let backgroundNode: SKSpriteNode
    let contentNode: SKSpriteNode
    let nativeContentSize: CGSize
    
    
    // MARK: - Intialization
    init(overlaySceneFileName fileName: String, zPosition: CGFloat) {
        let overlayScene = SKScene(fileNamed: fileName)!
        let contentTemplateNode = overlayScene.childNode(withName: "Overlay") as! SKSpriteNode
        
        backgroundNode = SKSpriteNode(color: contentTemplateNode.color, size: contentTemplateNode.size)
        backgroundNode.zPosition = zPosition
        
        contentNode = contentTemplateNode.copy() as! SKSpriteNode
        contentNode.position = .zero
        backgroundNode.addChild(contentNode)
        
        contentNode.color = .clear
        
        nativeContentSize = contentNode.size
    }
    
    func updateScale() {
        guard let viewSize = backgroundNode.scene?.view?.frame.size else {
            return
        }
        
        backgroundNode.size = viewSize
        
        let scale = viewSize.height / nativeContentSize.height
        contentNode.setScale(scale)
    }
}
