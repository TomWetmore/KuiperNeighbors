//
//  AstroLibrary.swift
//  AstronomyKit
//
//  Created by Thomas Wetmore on 8/25/2014.
//  Last changed on 3/28/2022.
//  Copyright (c) 2014-2022 Deadends Software. All rights reserved.
//

import Foundation

// Extend Double with a method to format a number to a given number of decimal digits.
extension Double {
    func format(_ digits: Int) -> String {
        String(format: "%.\(digits)f", self)
    }
}

// Two pi.
let twoPi = 2.0*Double.pi

// Speed of light.
let speedOfLight = 2.99792458e8  // meters/second.

// Constant of gravitation.
let constantOfGravitation = 6.67428e-11  // meters^3/kilogram/second^2

// Heliocentric gravitational constant (solar mass parameter).
let heliocentricGravitationalConstant = 1.32712440041e20  // meters^3/second^2.

// Radians to degrees conversion constant.
let piDividedBy180 = Double.pi/180.0

// Seconds per Gregorian year.
let secondsPerYear = 31556952.0

// Days per Gregorian year.
let daysPerYear = 365.2425;

// Meters per astronomical unit.
let astronomicalUnit = 149597870700.0  // meters

// Some solar system constants.
let jupiterSemimajorAxis = 5.2044  // astronomical units
let saturnSemimajorAxis = 9.5826   // astronomical units
let uranusSemimajorAxis = 19.2184  // astronomical units
let neptuneSemimajorAxis = 30.0690 // astronomical units
let plutoSemimajorAxis = 39.482    // astronomical units

let massOfSun =     1.98855e30 // kilograms
let massOfEarth =   5.97219e24 // kilograms
let massOfNeptune = 1.0242e26  // kilograms

// Convert degrees to radians.
func degreesToRadians (_ degrees: Double) -> Double {
    
    degrees*piDividedBy180
}

// Convert radians to degrees.
func radiansToDegrees (radians: Double) -> Double {
    radians/piDividedBy180
}

// Formatted time for labelling logs.
func logTime() -> String {
    let d = Date()
    let df = DateFormatter()
    df.dateFormat = "mm:ss.SSS"
    return df.string(from: d)
}
