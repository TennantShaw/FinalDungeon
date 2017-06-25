/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that enables an entity to accept control input from device-specific sources.
*/

import SpriteKit
import GameplayKit

class InputComponent: GKComponent, ControlInputSourceDelegate {
    
    // MARK: - Types
    struct InputState {
        var translation: MovementKind?
        var rotation: MovementKind?
        var beamIsTriggered = false
        var allowsStrafing = false
        
        static let noInput = InputState()
    }
    
    
    // MARK: - Properties
    var isEnabled = true {
        didSet {
            if isEnabled {
                applyInputState(state: state)
            }
            else {
                applyInputState(state: InputState.noInput)
            }
        }
    }
    
    var state = InputState() {
        didSet {
            if isEnabled {
                applyInputState(state: state)
            }
        }
    }
    
    
    // MARK: - ControlInputSourceDelegate
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateDisplacement displacement: float2) {
        state.translation = MovementKind(displacement: displacement)
    }
    
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateAngularDisplacement angularDisplacement: float2) {
        state.rotation = MovementKind(displacement: angularDisplacement)
    }
    
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateWithRelativeDisplacement relativeDisplacement: float2) {
        state.translation = MovementKind(displacement: relativeDisplacement, relativeToOrientation: true)
    }
    
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateWithRelativeAngularDisplacement relativeAngularDisplacement: float2) {
        state.rotation = MovementKind(displacement: relativeAngularDisplacement, relativeToOrientation: true)
    }
    
    
    // MARK: - Convenience
    func applyInputState(state: InputState) {
        if let movementComponent = entity?.component(ofType: MovementComponent.self) {
            movementComponent.nextRotation = state.rotation
            movementComponent.nextTranslation = state.translation
        }
    }
}
