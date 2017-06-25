/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that provides and manages the actions used to animate characters on screen as they move through different states and face different directions. `AnimationComponent` is supported by a structure called `Animation` that encapsulates information about an individual animation.
*/

import SpriteKit
import GameplayKit

enum AnimationState: String {
    case idle = "Idle"
    case walkForward = "WalkForward"
    case walkBackward = "WalkBackward"
    case preAttack = "PreAttack"
    case attack = "Attack"
    case zapped = "Zapped"
    case hit = "Hit"
    case inactive = "Inactive"
}


struct Animation {
    
    // MARK: - Properties
    let animationState: AnimationState
    let compassDirection: CompassDirection
    let textures: [SKTexture]
    var frameOffset = 0
    var offsetTextures: [SKTexture] {
        if frameOffset == 0 {
            return textures
        }
        let offsetToEnd = Array(textures[frameOffset..<textures.count])
        let startToBeforeOffset = textures[0..<frameOffset]
        return offsetToEnd + startToBeforeOffset
    }
    
    let repeatTexturesForever: Bool
    
    let bodyActionName: String?
    
    let bodyAction: SKAction?
    
    let shadowActionName: String?
    
    let shadowAction: SKAction?
}

class AnimationComponent: GKComponent {
    
    // MARK: - Static Properties
    static let bodyActionKey = "bodyAction"
    static let shadowActionKey = "shadowAction"
    static let textureActionKey = "textureAction"
    static let timePerFrame = TimeInterval(1.0 / 10.0)
    
    
    // MARK: - Properties
    var requestedAnimationState: AnimationState?
    let node: SKSpriteNode
    var shadowNode: SKSpriteNode?
    var animations: [AnimationState: [CompassDirection: Animation]]
    private(set) var currentAnimation: Animation?
    private var elapsedAnimationDuration: TimeInterval = 0.0
    
    
    // MARK: - Initializers
    init(textureSize: CGSize, animations: [AnimationState: [CompassDirection: Animation]]) {
        node = SKSpriteNode(texture: nil, size: textureSize)
        self.animations = animations
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Character Animation
    private func runAnimationForAnimationState(animationState: AnimationState, compassDirection: CompassDirection, deltaTime: TimeInterval) {
        elapsedAnimationDuration += deltaTime
        if currentAnimation != nil && currentAnimation!.animationState == animationState && currentAnimation!.compassDirection == compassDirection { return }
        
        guard let unwrappedAnimation = animations[animationState]?[compassDirection] else {
            print("Unknown animation for state \(animationState.rawValue), compass direction \(compassDirection.rawValue).")
            return
        }
        var animation = unwrappedAnimation
        
        if currentAnimation?.bodyActionName != animation.bodyActionName {
            node.removeAction(forKey: AnimationComponent.bodyActionKey)
            node.position = CGPoint.zero
            if let bodyAction = animation.bodyAction {
                node.run(SKAction.repeatForever(bodyAction), withKey: AnimationComponent.bodyActionKey)
            }
        }
        
        if currentAnimation?.shadowActionName != animation.shadowActionName {
            shadowNode?.removeAction(forKey: AnimationComponent.shadowActionKey)
            
            shadowNode?.position = CGPoint.zero
            
            shadowNode?.xScale = 1.0
            shadowNode?.yScale = 1.0
            
            if let shadowAction = animation.shadowAction {
                shadowNode?.run(SKAction.repeatForever(shadowAction), withKey: AnimationComponent.shadowActionKey)
            }
        }
        
        node.removeAction(forKey: AnimationComponent.textureActionKey)
        
        let texturesAction: SKAction
        
        if animation.textures.count == 1 {
            texturesAction = SKAction.setTexture(animation.textures.first!)
        }
        else {
            
            if currentAnimation != nil && animationState == currentAnimation!.animationState {
                let numberOfFramesInCurrentAnimation = currentAnimation!.textures.count
                let numberOfFramesPlayedSinceCurrentAnimationBegan = Int(elapsedAnimationDuration / AnimationComponent.timePerFrame)
                animation.frameOffset = (currentAnimation!.frameOffset + numberOfFramesPlayedSinceCurrentAnimationBegan + 1) % numberOfFramesInCurrentAnimation
            }
            
            if animation.repeatTexturesForever {
                texturesAction = SKAction.repeatForever(SKAction.animate(with: animation.offsetTextures, timePerFrame: AnimationComponent.timePerFrame))
            }
            else {
                texturesAction = SKAction.animate(with: animation.offsetTextures, timePerFrame: AnimationComponent.timePerFrame)
            }
        }
        
        node.run(texturesAction, withKey: AnimationComponent.textureActionKey)
        currentAnimation = animation
        elapsedAnimationDuration = 0.0
    }
    
    
    // MARK: - GKComponent Life Cycle
    override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)
        
        if let animationState = requestedAnimationState {
            guard let orientationComponent = entity?.component(ofType: OrientationComponent.self) else { fatalError("An AnimationComponent's entity must have an OrientationComponent.") }
            
            runAnimationForAnimationState(animationState: animationState, compassDirection: orientationComponent.compassDirection, deltaTime: deltaTime)
            requestedAnimationState = nil
        }
    }
    
    
    // MARK: - Texture loading utilities
    class func firstTextureForOrientation(compassDirection: CompassDirection, inAtlas atlas: SKTextureAtlas, withImageIdentifier identifier: String) -> SKTexture {
        let textureNames = atlas.textureNames.filter {
            $0.hasPrefix("\(identifier)_\(compassDirection.rawValue)_")
            }.sorted()
        return atlas.textureNamed(textureNames.first!)
    }
    
    class func actionForAllTexturesInAtlas(atlas: SKTextureAtlas) -> SKAction {
        let textures = atlas.textureNames.sorted().map {
            atlas.textureNamed($0)
        }
        
        if textures.count == 1 {
            return SKAction.setTexture(textures.first!)
        }
        else {
            let texturesAction = SKAction.animate(with: textures, timePerFrame: AnimationComponent.timePerFrame)
            return SKAction.repeatForever(texturesAction)
        }
    }
    
    class func animationsFromAtlas(atlas: SKTextureAtlas, withImageIdentifier identifier: String, forAnimationState animationState: AnimationState, bodyActionName: String? = nil, shadowActionName: String? = nil, repeatTexturesForever: Bool = true, playBackwards: Bool = false) -> [CompassDirection: Animation] {
        let bodyAction: SKAction?
        if let name = bodyActionName {
            bodyAction = SKAction(named: name)
        }
        else {
            bodyAction = nil
        }
        
        let shadowAction: SKAction?
        if let name = shadowActionName {
            shadowAction = SKAction(named: name)
        }
        else {
            shadowAction = nil
        }
        
        var animations = [CompassDirection: Animation]()
        
        for compassDirection in CompassDirection.allDirections {
            
            let textures = atlas.textureNames.filter {
                $0.hasPrefix("\(identifier)_\(compassDirection.rawValue)_")
                }.sorted {
                    playBackwards ? $0 > $1 : $0 < $1
                }.map {
                    atlas.textureNamed($0)
            }
            
            animations[compassDirection] = Animation(
                animationState: animationState,
                compassDirection: compassDirection,
                textures: textures,
                frameOffset: 0,
                repeatTexturesForever: repeatTexturesForever,
                bodyActionName: bodyActionName,
                bodyAction: bodyAction,
                shadowActionName: shadowActionName,
                shadowAction: shadowAction
            )
            
        }
        return animations
    }
}
