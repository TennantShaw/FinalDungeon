/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An abstraction representing game input for the user currently playing the game. Manages the player's control input sources, and handles game controller connections / disconnections.
*/

import GameController

protocol GameInputDelegate: class {
    func gameInputDidUpdateControlInputSources(gameInput: GameInput)
}

final class GameInput {
    
    // MARK: - Properties
    let nativeControlInputSource: ControlInputSourceType
    var controlInputSources: [ControlInputSourceType] {
        let sources: [ControlInputSourceType?] = [nativeControlInputSource]
        return sources.flatMap { return $0 as ControlInputSourceType? }
    }
    weak var delegate: GameInputDelegate? {
        didSet {
            delegate?.gameInputDidUpdateControlInputSources(gameInput: self)
        }
    }
    private let controlsQueue = DispatchQueue(label: "com.example.apple-samplecode.player.controlsqueue")
    
    
    // MARK: - Initialization
    init(nativeControlInputSource: ControlInputSourceType) {
        self.nativeControlInputSource = nativeControlInputSource
    }
}
