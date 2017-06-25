//
//  MoogleFreeState.swift
//  DemoBots
//
//  Created by Tennant Shaw on 6/13/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import SpriteKit
import GameplayKit

class MoogleFreeState: GKState {
    
    // MARK: - Properties
    unowned var entity: Moogle
    var elapsedTime: TimeInterval = 0.0
    var animationComponent: AnimationComponent {
        guard let animationComponent = entity.component(ofType: AnimationComponent.self) else {
            fatalError("A MoogleFreeState's entity must have an AnimationComponent")
        }
        return animationComponent
    }
    
    var renderComponent: RenderComponent {
        guard let renderComponent = entity.component(ofType: RenderComponent.self) else { fatalError("A PlayerBotAppearState's entity must have an RenderComponent.") }
        return renderComponent
    }
    // MARK: - Initializers
    required init(entity: Moogle) {
        self.entity = entity
    }
    
    // MARK: - GKState Life Cycle
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        elapsedTime = 0.0
        self.animationComponent.node.removeFromParent()
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        elapsedTime += seconds
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    
}
