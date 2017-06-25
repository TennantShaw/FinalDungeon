//
//  CaptiveComponent.swift
//  DemoBots
//
//  Created by Tennant Shaw on 6/13/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import SpriteKit
import GameplayKit

protocol CaptiveComponentDelegate: class {
    func captiveSetFree(CaptiveComponent: CaptiveComponent)
}

class CaptiveComponent: GKComponent {
    
    // MARK: - Properties
    var isCaptive: Bool = true
    
    
    // MARK: - Initializers
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Component Actions
    func setFree(freeCaptive: Bool) {
        if freeCaptive == true {
            isCaptive = false
        }
    }
}
