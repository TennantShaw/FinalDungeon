/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An iOS-specific `SKSpriteNode` subclass used to provide the on-screen thumbsticks that enable player control.
*/

import SpriteKit

protocol ThumbStickNodeDelegate: class {
    func thumbStickNode(thumbStickNode: ThumbStickNode, didUpdateXValue xValue: Float, yValue: Float)
    
    func thumbStickNode(thumbStickNode: ThumbStickNode, isPressed: Bool)
}

class ThumbStickNode: SKSpriteNode {
    
    // MARK: - Properties
    var touchPad: SKSpriteNode
    weak var delegate: ThumbStickNodeDelegate?
    let center: CGPoint
    let trackingDistance: CGFloat
    let normalAlpha: CGFloat = 0.3
    let selectedAlpha: CGFloat = 0.5
    
    override var alpha: CGFloat {
        didSet {
            touchPad.alpha = alpha
        }
    }
    
    
    // MARK: - Initialization
    init(size: CGSize) {
        trackingDistance = size.width / 2
        
        let touchPadLength = size.width / 2.2
        center = CGPoint(x: size.width / 2 - touchPadLength, y: size.height / 2 - touchPadLength)
        
        let touchPadSize = CGSize(width: touchPadLength, height: touchPadLength)
        let touchPadTexture = SKTexture(imageNamed: "ControlPad")
        
        touchPad = SKSpriteNode(texture: touchPadTexture, color: UIColor.clear, size: touchPadSize)
        
        super.init(texture: touchPadTexture, color: UIColor.clear, size: size)
        
        alpha = normalAlpha
        
        addChild(touchPad)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - UIResponder
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        alpha = selectedAlpha
        
        delegate?.thumbStickNode(thumbStickNode: self, isPressed: true)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            var dx = touchLocation.x - center.x
            var dy = touchLocation.y - center.y
            
            let distance = hypot(dx, dy)
            
            if distance > trackingDistance {
                dx = (dx / distance) * trackingDistance
                dy = (dy / distance) * trackingDistance
            }
            
            touchPad.position = CGPoint(x: center.x + dx, y: center.y + dy)
            
            let normalizedDx = Float(dx / trackingDistance)
            let normalizedDy = Float(dy / trackingDistance)
            delegate?.thumbStickNode(thumbStickNode: self, didUpdateXValue: normalizedDx, yValue: normalizedDy)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard !touches.isEmpty else { return }
        
        resetTouchPad()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        resetTouchPad()
    }
    
    func resetTouchPad() {
        alpha = normalAlpha
        
        let restoreToCenter = SKAction.move(to: CGPoint.zero, duration: 0.2)
        touchPad.run(restoreToCenter)
        
        delegate?.thumbStickNode(thumbStickNode: self, isPressed: false)
        delegate?.thumbStickNode(thumbStickNode: self, didUpdateXValue: 0, yValue: 0)
    }
}
