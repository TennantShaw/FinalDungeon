/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Protocols that manage and respond to control input for the `PlayerBot` and for the game as a whole.
*/

import simd

enum ControlInputDirection: Int {
    case up = 0, down, left, right
    
    init?(vector: float2) {
        guard length(vector) >= 0.5 else { return nil }
        
        if abs(vector.x) > abs(vector.y) {
            self = vector.x > 0 ? .right : .left
        }
        else {
            self = vector.y > 0 ? .up : .down
        }
    }
}

protocol ControlInputSourceGameStateDelegate: class {
    func controlInputSourceDidSelect(_ controlInputSource: ControlInputSourceType)
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didSpecifyDirection: ControlInputDirection)
    func controlInputSourceDidTogglePauseState(_ controlInputSource: ControlInputSourceType)
}

protocol ControlInputSourceDelegate: class {
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateDisplacement displacement: float2)
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateAngularDisplacement angularDisplacement: float2)
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateWithRelativeDisplacement relativeDisplacement: float2)
    func controlInputSource(_ controlInputSource: ControlInputSourceType, didUpdateWithRelativeAngularDisplacement relativeAngularDisplacement: float2)
}

protocol ControlInputSourceType: class {
    weak var delegate: ControlInputSourceDelegate? { get set }
    weak var gameStateDelegate: ControlInputSourceGameStateDelegate? { get set }
    func resetControlState()
}
