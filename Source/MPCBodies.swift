//
//  MPCBodies.swift
//
//  Created by Thomas Wetmore on 25 August 2014.
//  Last changed on 22 November 2026.
//

import Foundation

/// Read a Minor Planet Center orbit file and build an AstroBody from each line.
///
public func getMPCBodiesFrom(path: String) -> [AstroBody] {

    var objects = [AstroBody]()
    var lines = [String]()

	// Read the file and the the array of Strings for each line.
    if let fileString = try? String(contentsOfFile: path, encoding: .utf8) {
        print("\(logTime()): Breaking file into lines.")
        fileString.components(separatedBy: "\n").forEach { lines.append($0) }
        print("\(logTime()): File has \(lines.count) lines.")
    }
    print("\(logTime()): Creating bodies for each line.")
    lines.forEach {
        if let object = getMPCBody(line: $0) {
            objects.append(object)
        }
    }
    return objects
}

/// Create an AstroBody from a line in an MPC orbit file. The lines are composed of
/// fixed length fields.
///
func getMPCBody(line: String) -> AstroBody? {

    // Extract properties from the line. First convert it to UTF16.
    let chars = Array(line.utf16)
    if chars.count == 0 {
        return nil
    }

    // The orbital elements on the line are five of the six Keplerian elements: semimajor
    // axis, inclination, eccentricity, argument of perihelion, and longitude of ascending
    // node. Instead of true anomaly at epoch the file uses mean anomaly at epoch.

    let epoch: AstroTime = extractEpoch(chars, start: 21)  // Epoch of anomaly.
    let meanAnomalyAtEpoch = degreesToRadians(extractDouble(chars, start: 27, end: 35))
    let argPerihelion = degreesToRadians(extractDouble(chars, start: 38, end: 46))
    let ascendingNode = degreesToRadians(extractDouble(chars, start: 49, end: 57))
    let inclination = degreesToRadians(extractDouble(chars, start: 60, end: 68))
    let eccentricity = extractDouble(chars, start: 71, end: 79)
    let semimajorAxis = extractDouble(chars, start: 93, end: 103)
	let designation = extractString(chars, start: 1, end: 7) // Packed designation.

	let trueAnomalyAtEpoch = meanToTrueAnomaly(meanAnomaly: meanAnomalyAtEpoch,
												   eccentricity: eccentricity)

    // Create an AstroBody with the six Keplerian elements.
    var astroBody = AstroBody(name: designation, mass: 0.0, radius: 0.0)
    astroBody.setElements(semimajorAxis: semimajorAxis,
                          eccentricity: eccentricity,
                          inclination: inclination,
                          longAscendingNode: ascendingNode,
                          argPeriapsis: argPerihelion,
                          epoch: epoch,
                          trueAnomalyAtEpoch: trueAnomalyAtEpoch)
    return astroBody
}

/// Extract a Double from a range in an array of utf16 values. Start and end are 1-based.
///
private func extractDouble (_ chars: [UInt16], start: Int, end: Int) -> Double {

    // 46 is '.' and 48 to 57 are '0' to '9'.
    var intPart = 0.0
    var decPart = 0.0
    var pow10 = 10.0
    var left = true
    for index in start - 1 ..< end {
        let char = chars[index]
        if char == 46 {
            left = false
        } else if char >= 48 && char <= 57 {
            let digit = char - 48
            if left {
                intPart = intPart*10.0 + Double(digit)
            } else {
                decPart = decPart + Double(digit)/pow10
                pow10 *= 10.0
            }
        }
    }
    return intPart + decPart
}

/// Extract a String from a range in an array of utf16 values. Start and end are 1-based.
///
private func extractString (_ chars: [UInt16], start: Int, end: Int) -> String {

    var result: String = ""
    for index in start - 1 ..< min(end, chars.count) {
        result.append(Character(UnicodeScalar(chars[index])!))
    }
    return result.trimmingCharacters(in: CharacterSet.whitespaces)
}

/// Convert the MPC representation of date to an AstroTime object. Start is 1-based.
///
private func extractEpoch(_ chars: [UInt16], start: Int) -> AstroTime {

    // 48 is '0', 57 is '9', 65 is 'A', 75 is 'K'.
    let a = chars[start-1]
    let b = chars[start]
    let c = chars[start+1]
    let d = chars[start+2]
    let e = chars[start+3]

    var year: Int = ((a == 75) ? 2000 : 1900)
    year = year + 10*(Int(b) - 48) + Int(c) - 48
    let month: Int = (Int(d) < 57) ? Int(d) - 48 : Int(d) - 65 + 10
    let day: Int = (Int(e) < 57) ? Int(e) - 48 : Int(e) - 65 + 10
    return AstroTime(year: Int(year), month: month, day: day)
}
