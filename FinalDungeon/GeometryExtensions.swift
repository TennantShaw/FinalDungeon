/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A series of extensions to provide convenience interoperation between `CGPoint` representations of geometric points (common in SpriteKit) and `float2` representations of points (common in GameplayKit).
*/

import CoreGraphics
import simd

extension CGPoint {
    
    // MARK: - Initializers
    init(_ point: float2) {
        x = CGFloat(point.x)
        y = CGFloat(point.y)
    }
}

extension float2 {
    
    // MARK: - Initialization
    init(_ point: CGPoint) {
        self.init(x: Float(point.x), y: Float(point.y))
    }
}

extension float2: Equatable {}

public func ==(lhs: float2, rhs: float2) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

extension float2 {
    func nearestPointOnLineSegment(lineSegment: (startPoint: float2, endPoint: float2)) -> float2 {
        let vectorFromStartToLine = self - lineSegment.startPoint
        let lineSegmentVector = lineSegment.endPoint - lineSegment.startPoint
        let lineLengthSquared = distance_squared(lineSegment.startPoint, lineSegment.endPoint)
        let projectionAlongSegment = dot(vectorFromStartToLine, lineSegmentVector)
        let componentInSegment = projectionAlongSegment / lineLengthSquared
        let fractionOfComponent = max(0, min(1, componentInSegment))
        return lineSegment.startPoint + lineSegmentVector * fractionOfComponent
    }
}
