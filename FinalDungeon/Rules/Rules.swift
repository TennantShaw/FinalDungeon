/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file introduces the rules used by the `TaskBot` rule system to determine an appropriate action for the `TaskBot`. The rules fall into three distinct sets:
                Percentage of bad `TaskBot`s in the level (low, medium, high):
                    `BadTaskBotPercentageLowRule`
                    `BadTaskBotPercentageMediumRule`
                    `BadTaskBotPercentageHighRule`
                How close the `TaskBot` is to the `PlayerBot` (near, medium, far):
                    `PlayerBotNearRule`
                    `PlayerBotMediumRule`
                    `PlayerBotFarRule`
*/

import GameplayKit

enum Fact: String {
    case badTaskBotPercentageLow = "BadTaskBotPercentageLow"
    case badTaskBotPercentageMedium = "BadTaskBotPercentageMedium"
    case badTaskBotPercentageHigh = "BadTaskBotPercentageHigh"
    case playerBotNear = "PlayerBotNear"
    case playerBotMedium = "PlayerBotMedium"
    case playerBotFar = "PlayerBotFar"
}

class BadTaskBotPercentageLowRule: FuzzyTaskBotRule {
    
    // MARK: - Properties
    override func grade() -> Float {
        return max(0.0, 1.0 - 3.0 * snapshot.badBotPercentage)
    }
    
    
    // MARK: - Initializers
    init() { super.init(fact: .badTaskBotPercentageLow) }
}


class BadTaskBotPercentageMediumRule: FuzzyTaskBotRule {
    
    // MARK: - Properties
    override func grade() -> Float {
        if snapshot.badBotPercentage <= 1.0 / 3.0 {
            return min(1.0, 3.0 * snapshot.badBotPercentage)
        }
        else {
            return max(0.0, 1.0 - (3.0 * snapshot.badBotPercentage - 1.0))
        }
    }
    
    
    // MARK: - Initializers
    init() { super.init(fact: .badTaskBotPercentageMedium) }
}


class BadTaskBotPercentageHighRule: FuzzyTaskBotRule {
    
    // MARK: - Properties
    override func grade() -> Float {
        return min(1.0, max(0.0, (3.0 * snapshot.badBotPercentage - 1)))
    }
    
    
    // MARK: - Initializers
    init() { super.init(fact: .badTaskBotPercentageHigh) }
}


class PlayerBotNearRule: FuzzyTaskBotRule {
    
    // MARK: - Properties
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (oneThird - distance) / oneThird
    }
    
    
    // MARK: - Initializers
    init() { super.init(fact: .playerBotNear) }
}


class PlayerBotMediumRule: FuzzyTaskBotRule {
    
    // MARK: - Properties
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return 1 - (fabs(distance - oneThird) / oneThird)
    }
    
    
    // MARK: - Initializers
    init() { super.init(fact: .playerBotMedium) }
}


class PlayerBotFarRule: FuzzyTaskBotRule {
    
    // MARK: - Properties
    override func grade() -> Float {
        guard let distance = snapshot.playerBotTarget?.distance else { return 0.0 }
        let oneThird = snapshot.proximityFactor / 3
        return (distance - oneThird) / oneThird
    }
    
    
    // MARK: - Initializers
    init() { super.init(fact: .playerBotFar) }
}
