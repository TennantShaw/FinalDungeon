/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `ButtonNode` is a custom `SKSpriteNode` that provides button-like behavior in a SpriteKit scene. It is supported by `ButtonNodeResponderType` (a protocol for classes that can respond to button presses) and `ButtonIdentifier` (an enumeration that defines all of the kinds of buttons that are supported in the game).
*/

import SpriteKit

protocol ButtonNodeResponderType: class {
    func buttonTriggered(button: ButtonNode)
}

enum ButtonIdentifier: String {
    case resume = "Resume"
    case home = "Home"
    case proceedToNextScene = "ProceedToNextScene"
    case replay = "Replay"
    case retry = "Retry"
    case cancel = "Cancel"
    
    static let allButtonIdentifiers: [ButtonIdentifier] = [
        .resume, .home, .proceedToNextScene, .retry, .cancel]
    
}

class ButtonNode: SKSpriteNode {
    
    // MARK: - Properties
    var buttonIdentifier: ButtonIdentifier!
    var responder: ButtonNodeResponderType {
        guard let responder = scene as? ButtonNodeResponderType else {
            fatalError("ButtonNode may only be used within a `ButtonNodeResponderType` scene.")
        }
        return responder
    }
    var isHighlighted = false {
        didSet {
            guard oldValue != isHighlighted else { return }
            
            removeAllActions()
            
            let newScale: CGFloat = isHighlighted ? 0.99 : 1.01
            let scaleAction = SKAction.scale(by: newScale, duration: 0.15)
            
            let newColorBlendFactor: CGFloat = isHighlighted ? 1.0 : 0.0
            let colorBlendAction = SKAction.colorize(withColorBlendFactor: newColorBlendFactor, duration: 0.15)
            
            run(SKAction.group([scaleAction, colorBlendAction]))
        }
    }
    var isSelected = false {
        didSet {
            texture = isSelected ? selectedTexture : defaultTexture
        }
    }
    var defaultTexture: SKTexture?
    var selectedTexture: SKTexture?
    var focusableNeighbors = [ControlInputDirection: ButtonNode]()
    var isFocused = false {
        didSet {
            if isFocused {
                run(SKAction.scale(to: 1.08, duration: 0.20))
                
                focusRing.alpha = 0.0
                focusRing.isHidden = false
                focusRing.run(SKAction.fadeIn(withDuration: 0.2))
            }
            else {
                run(SKAction.scale(to: 1.0, duration: 0.20))
                
                focusRing.isHidden = true
            }
        }
    }
    lazy var focusRing: SKNode = self.childNode(withName: "focusRing")!
    
    
    // MARK: - Initializers
    override init(texture: SKTexture?, color: SKColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let nodeName = name, let buttonIdentifier = ButtonIdentifier(rawValue: nodeName) else {
            fatalError("Unsupported button name found.")
        }
        self.buttonIdentifier = buttonIdentifier
        defaultTexture = texture
        selectedTexture = texture
        focusRing.isHidden = true
        isUserInteractionEnabled = true
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let newButton = super.copy(with: zone) as! ButtonNode
        
        newButton.buttonIdentifier = buttonIdentifier
        newButton.defaultTexture = defaultTexture?.copy() as? SKTexture
        newButton.selectedTexture = selectedTexture?.copy() as? SKTexture
        
        return newButton
    }
    
    func buttonTriggered() {
        if isUserInteractionEnabled {
            responder.buttonTriggered(button: self)
        }
    }
    
    func performInvalidFocusChangeAnimationForDirection(direction: ControlInputDirection) {
        let animationKey = "ButtonNode.InvalidFocusChangeAnimationKey"
        guard action(forKey: animationKey) == nil else { return }
        
        let theAction: SKAction
        switch direction {
        case .up:    theAction = SKAction(named: "InvalidFocusChange_Up")!
        case .down:  theAction = SKAction(named: "InvalidFocusChange_Down")!
        case .left:  theAction = SKAction(named: "InvalidFocusChange_Left")!
        case .right: theAction = SKAction(named: "InvalidFocusChange_Right")!
        }
        
        run(theAction, withKey: animationKey)
    }
    
    
    // MARK: - Responder
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        isHighlighted = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        isHighlighted = false
        
        if containsTouches(touches: touches) {
            buttonTriggered()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)
        
        isHighlighted = false
    }
    
    private func containsTouches(touches: Set<UITouch>) -> Bool {
        guard let scene = scene else { fatalError("Button must be used within a scene.") }
        
        return touches.contains { touch in
            let touchPoint = touch.location(in: scene)
            let touchedNode = scene.atPoint(touchPoint)
            return touchedNode === self || touchedNode.inParentHierarchy(self)
        }
    }
}
