/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that enables an entity to move appropriately for the input directing it. Used by a `PlayerBot` to move around a level in response to input from its `InputComponent`, and used by a `GroundBot` to perform its charging-forward attack.
*/

import SpriteKit
import GameplayKit

struct MovementKind {
    
    // MARK: - Properties
    let isRelativeToOrientation: Bool
    let displacement: float2
    
    
    // MARK: - Initializers
    init(displacement: float2, relativeToOrientation: Bool = false) {
        isRelativeToOrientation = relativeToOrientation
        self.displacement = displacement
    }
}

class MovementComponent: GKComponent {
    
    // MARK: - Properties
    var nextTranslation: MovementKind?
    var nextRotation: MovementKind?
    var allowsStrafing = false
    var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else { fatalError("A MovementComponent's entity must have a RenderComponent") }
        return renderComponent
    }
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity?.component(ofType: AnimationComponent.self) else { fatalError("A MovementComponent's entity must have an AnimationComponent") }
        return animationComponent
    }
    var orientationComponent: OrientationComponent {
        guard let orientationComponent = entity?.component(ofType: OrientationComponent.self) else { fatalError("A MovementComponent's entity must have an OrientationComponent") }
        return orientationComponent
    }
    var movementSpeed: CGFloat
    var angularSpeed: CGFloat
    
    
    // MARK: - Initializers
    override init() {
        movementSpeed = GameplayConfiguration.PlayerBot.movementSpeed
        angularSpeed = GameplayConfiguration.PlayerBot.angularSpeed
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - GKComponent Life Cycle
    override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)
        
        let node = renderComponent.node
        let orientationComponent = self.orientationComponent
        
        var animationState: AnimationState?
        
        if let movement = nextRotation, let newRotation = angleForRotatingNode(node: node, withRotationalMovement: movement, duration: deltaTime)  {
            orientationComponent.zRotation = newRotation
            animationState = .idle
        }
        else {
            nextRotation = nil
        }
        
        if let movement = nextTranslation, let newPosition = pointForTranslatingNode(node: node, withTranslationalMovement: movement, duration: deltaTime) {
            node.position = newPosition
            
            if nextRotation == nil {
                orientationComponent.zRotation = CGFloat(atan2(movement.displacement.y, movement.displacement.x))
            }
            
            animationState = animationStateForDestination(node: node, destination: newPosition)
        }
        else {
            nextTranslation = nil
        }
        
        if let animationState = animationState {
            let animationComponent = self.animationComponent
            
            if animationStateCanBeOverwritten(animationState: animationComponent.currentAnimation?.animationState) && animationStateCanBeOverwritten(animationState: animationComponent.requestedAnimationState) {
                animationComponent.requestedAnimationState = animationState
            }
        }
    }
    
    
    // MARK: - Convenience Methods
    func pointForTranslatingNode(node: SKNode, withTranslationalMovement translation: MovementKind, duration: TimeInterval) -> CGPoint? {
        guard translation.displacement != float2() else { return nil }
        
        var displacement = translation.displacement
        if translation.isRelativeToOrientation {
            guard displacement.x != 0 else { return nil }
            displacement = calculateAbsoluteDisplacementFromRelativeDisplacement(relativeDisplacement: displacement)
        }
        
        let angle = CGFloat(atan2(displacement.y, displacement.x))
        
        let maxPossibleDistanceToMove = movementSpeed * CGFloat(duration)
        
        let normalizedDisplacement: float2
        if length(displacement) > 1.0 {
            normalizedDisplacement = normalize(displacement)
        }
        else {
            normalizedDisplacement = displacement
        }
        
        let actualDistanceToMove = CGFloat(length(normalizedDisplacement)) * maxPossibleDistanceToMove
        
        let dx = actualDistanceToMove * cos(angle)
        let dy = actualDistanceToMove * sin(angle)
        
        return CGPoint(x: node.position.x + dx, y: node.position.y + dy)
    }
    
    func angleForRotatingNode(node: SKNode, withRotationalMovement rotation: MovementKind, duration: TimeInterval) -> CGFloat? {
        guard rotation.displacement != float2() else { return nil }
        
        let angle: CGFloat
        if rotation.isRelativeToOrientation {
            let rotationComponent = rotation.displacement.y
            guard rotationComponent != 0 else { return nil }
            
            let rotationDirection = CGFloat(rotationComponent > 0 ? 1 : -1)
            
            let maxPossibleRotation = angularSpeed * CGFloat(duration)
            
            let dz = rotationDirection * maxPossibleRotation
            
            angle = orientationComponent.zRotation + dz
        }
        else {
            angle = CGFloat(atan2(rotation.displacement.y, rotation.displacement.x))
        }
        
        return angle
    }
    
    private func animationStateForDestination(node: SKNode, destination: CGPoint) -> AnimationState {
        let isMovingWithOrientation = (orientationComponent.zRotation * atan2(destination.y, destination.x)) > 0
        return isMovingWithOrientation ? .walkForward : .walkBackward
    }
    
    private func calculateAbsoluteDisplacementFromRelativeDisplacement(relativeDisplacement: float2) -> float2 {
        var angleRelativeToOrientation = Float(orientationComponent.zRotation)
        
        if relativeDisplacement.x < 0 {
            angleRelativeToOrientation += Float(Double.pi)
        }
        
        let dx = length(relativeDisplacement) * cos(angleRelativeToOrientation)
        let dy = length(relativeDisplacement) * sin(angleRelativeToOrientation)
        
        if nextRotation == nil {
            let directionFactor = Float(relativeDisplacement.x)
            nextRotation = MovementKind(displacement: float2(x: directionFactor * dx, y: directionFactor * dy))
        }
        
        return float2(x: dx, y: dy)
    }
    
    private func animationStateCanBeOverwritten(animationState: AnimationState?) -> Bool {
        switch animationState {
        case .idle?, .walkForward?, .walkBackward?:
            return true
            
        default:
            return false
        }
    }
}
