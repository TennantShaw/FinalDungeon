/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An implementation of the `ControlInputSourceType` protocol that enables support for touch-based thumbsticks on iOS.
*/

import SpriteKit

class TouchControlInputNode: SKSpriteNode, ThumbStickNodeDelegate, ControlInputSourceType {
    
    // MARK: - Properties
    weak var delegate: ControlInputSourceDelegate?
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate?
    let allowsStrafing = true
    let leftThumbStickNode: ThumbStickNode
    let rightThumbStickNode: ThumbStickNode
    let pauseButton: SKSpriteNode
    var leftControlTouches = Set<UITouch>()
    var rightControlTouches = Set<UITouch>()
    let centerDividerWidth: CGFloat
    var hideThumbStickNodes: Bool = false {
        didSet {
            leftThumbStickNode.isHidden = hideThumbStickNodes
            rightThumbStickNode.isHidden = true
        }
    }
    
    
    // MARK: - Initialization
    init(frame: CGRect, thumbStickNodeSize: CGSize) {
        centerDividerWidth = frame.width / 4.5
        
        let initialVerticalOffset = -thumbStickNodeSize.height
        let initialHorizontalOffset = frame.width / 2 - thumbStickNodeSize.width
        
        leftThumbStickNode = ThumbStickNode(size: thumbStickNodeSize)
        leftThumbStickNode.position = CGPoint(x: -initialHorizontalOffset, y: initialVerticalOffset)
        
        rightThumbStickNode = ThumbStickNode(size: thumbStickNodeSize)
        rightThumbStickNode.position = CGPoint(x: initialHorizontalOffset, y: initialVerticalOffset)
        
        let buttonSize = CGSize(width: frame.height / 4, height: frame.height / 4)
        pauseButton = SKSpriteNode(texture: nil, color: UIColor.clear, size: buttonSize)
        pauseButton.position = CGPoint(x: 0, y: frame.height / 2)
        
        super.init(texture: nil, color: UIColor.clear, size: frame.size)
        rightThumbStickNode.delegate = self
        leftThumbStickNode.delegate = self
        
        addChild(leftThumbStickNode)
        addChild(rightThumbStickNode)
        addChild(pauseButton)
        
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - ThumbStickNodeDelegate
    func thumbStickNode(thumbStickNode: ThumbStickNode, didUpdateXValue xValue: Float, yValue: Float) {
        if thumbStickNode === leftThumbStickNode {
            let displacement = float2(x: xValue, y: yValue)
            delegate?.controlInputSource(self, didUpdateDisplacement: displacement)
        }
        else if thumbStickNode === rightThumbStickNode {
            let displacement = float2(x: xValue, y: yValue)
            
            if length(displacement) >= GameplayConfiguration.TouchControl.minimumRequiredThumbstickDisplacement {
                delegate?.controlInputSource(self, didUpdateAngularDisplacement: displacement)
            }
            else {
                delegate?.controlInputSource(self, didUpdateAngularDisplacement: float2())
            }
        }
    }
    
    func thumbStickNode(thumbStickNode: ThumbStickNode, isPressed: Bool) {
    }
    
    
    // MARK: - ControlInputSourceType
    func resetControlState() {
    }
    
    
    // MARK: - UIResponder
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for touch in touches {
            let touchPoint = touch.location(in: self)
            let touchIsInCenter = touchPoint.x < centerDividerWidth / 2 && touchPoint.x > -centerDividerWidth / 2
            if hideThumbStickNodes || touchIsInCenter {
                continue
            }
            
            if touchPoint.x < 0 {
                leftControlTouches.formUnion([touch])
                leftThumbStickNode.position = pointByCheckingControlOffset(suggestedPoint: touchPoint)
                leftThumbStickNode.touchesBegan([touch], with: event)
            }
            else {
                rightControlTouches.formUnion([touch])
                rightThumbStickNode.position = pointByCheckingControlOffset(suggestedPoint: touchPoint)
                rightThumbStickNode.touchesBegan([touch], with: event)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let movedLeftTouches = touches.intersection(leftControlTouches)
        leftThumbStickNode.touchesMoved(movedLeftTouches, with: event)
        
        let movedRightTouches = touches.intersection(rightControlTouches)
        rightThumbStickNode.touchesMoved(movedRightTouches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        for touch in touches {
            let touchPoint = touch.location(in: self)
            
            if pauseButton === atPoint(touchPoint) {
                gameStateDelegate?.controlInputSourceDidTogglePauseState(self)
                break
            }
        }
        
        let endedLeftTouches = touches.intersection(leftControlTouches)
        leftThumbStickNode.touchesEnded(endedLeftTouches, with: event)
        leftControlTouches.subtract(endedLeftTouches)
        
        let endedRightTouches = touches.intersection(rightControlTouches)
        rightThumbStickNode.touchesEnded(endedRightTouches, with: event)
        rightControlTouches.subtract(endedRightTouches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        
        leftThumbStickNode.resetTouchPad()
        rightThumbStickNode.resetTouchPad()
        
        leftControlTouches.removeAll(keepingCapacity: true)
        rightControlTouches.removeAll(keepingCapacity: true)
    }
    
    
    // MARK: - Convenience Methods
    func pointByCheckingControlOffset(suggestedPoint: CGPoint) -> CGPoint {
        let controlSize = leftThumbStickNode.size
        let sceneSize = scene!.size
        let minX = -sceneSize.width / 2 + controlSize.width / 1.5
        let maxX = sceneSize.width / 2 - controlSize.width / 1.5
        
        let minY = -sceneSize.height / 2 + controlSize.height / 1.5
        let maxY = sceneSize.height / 2 - controlSize.height / 1.5
        
        let boundX = max(min(suggestedPoint.x, maxX), minX)
        let boundY = max(min(suggestedPoint.y, maxY), minY)
        
        return CGPoint(x: boundX, y: boundY)
    }
    
}
