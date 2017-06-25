/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An enumeration that converts between rotations (in radians) and 16-point compass point orientations (with east as zero). Used when determining which animation to use for an entity's current orientation.
 */

import CoreGraphics

enum CompassDirection: Int {
    case east = 0, eastByNorthEast, northEast, northByNorthEast
    case north, northByNorthWest, northWest, westByNorthWest
    case west, westBySouthWest, southWest, southBySouthWest
    case south, southBySouthEast, southEast, eastBySouthEast
    
    static let allDirections: [CompassDirection] =
        [
            .east, .eastByNorthEast, .northEast, .northByNorthEast,
            .north, .northByNorthWest, .northWest, .westByNorthWest,
            .west, .westBySouthWest, .southWest, .southBySouthWest,
            .south, .southBySouthEast, .southEast, .eastBySouthEast
        ]
    
    var zRotation: CGFloat {
        let stepSize = CGFloat(Double.pi * 2.0) / CGFloat(CompassDirection.allDirections.count)
        return CGFloat(self.rawValue) * stepSize
    }
    
    init(zRotation: CGFloat) {
        let twoPi = Double.pi * 2
        let rotation = (Double(zRotation) + twoPi).truncatingRemainder(dividingBy: twoPi)
        let orientation = rotation / twoPi
        let rawFacingValue = round(orientation * 16.0).truncatingRemainder(dividingBy: 16.0)
        self = CompassDirection(rawValue: Int(rawFacingValue))!
    }
    
    init(string: String) {
        switch string {
        case "North":
            self = .north
            
        case "NorthEast":
            self = .northEast
            
        case "East":
            self = .east
            
        case "SouthEast":
            self = .southEast
            
        case "South":
            self = .south
            
        case "SouthWest":
            self = .southWest
            
        case "West":
            self = .west
            
        case "NorthWest":
            self = .northWest
            
        default:
            fatalError("Unknown or unsupported string - \(string)")
        }
    }
}

