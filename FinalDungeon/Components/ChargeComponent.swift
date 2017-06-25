/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `GKComponent` that tracks the "charge" (or "health") of a `PlayerBot` or `TaskBot`. For a `PlayerBot`, "charge" indicates how much power the `PlayerBot` has left before it must recharge (during which time the `PlayerBot` is inactive). For a `TaskBot`, "charge" indicates whether the `TaskBot` is "good" or "bad".
*/

import SpriteKit
import GameplayKit

protocol ChargeComponentDelegate: class {
    func chargeComponentDidLoseCharge(chargeComponent: ChargeComponent)
}

class ChargeComponent: GKComponent {
    
    // MARK: - Properties
    var charge: Double
    let maximumCharge: Double
    var percentageCharge: Double {
        if maximumCharge == 0 {
            return 0.0
        }
        
        return charge / maximumCharge
    }
    
    var hasCharge: Bool {
        return (charge > 0.0)
    }
    
    var isFullyCharged: Bool {
        return charge == maximumCharge
    }
    
    var noCharge: Bool {
        return charge == 0
    }
    
    let chargeBar: ChargeBar?
    weak var delegate: ChargeComponentDelegate?
    
    
    // MARK: - Initializers
    init(charge: Double, maximumCharge: Double, displaysChargeBar: Bool = false) {
        self.charge = charge
        self.maximumCharge = maximumCharge
        
        if displaysChargeBar {
            chargeBar = ChargeBar()
        }
        else {
            chargeBar = nil
        }
        
        super.init()
        
        chargeBar?.level = percentageCharge
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Component actions
    func loseCharge(chargeToLose: Double) {
        var newCharge = charge - chargeToLose
        
        newCharge = min(maximumCharge, newCharge)
        newCharge = max(0.0, newCharge)
        
        if newCharge < charge {
            charge = newCharge
            chargeBar?.level = percentageCharge
            delegate?.chargeComponentDidLoseCharge(chargeComponent: self)
        }
    }
    
    func addCharge(chargeToAdd: Double) {
        var newCharge = charge + chargeToAdd
        
        newCharge = min(maximumCharge, newCharge)
        newCharge = max(0.0, newCharge)
        
        if newCharge > charge {
            charge = newCharge
            chargeBar?.level = percentageCharge
        }
    }
}

