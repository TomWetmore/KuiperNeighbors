//
//  AstroBody.swift
//
//  Created by Thomas Wetmore on 21 August 2014.
//  Last changed on 22 November 2026.
//

import Darwin // For math functions.

///  Heliocentric gravitational constant in years and AU.
let hgc_year_au = heliocentricGravitationalConstant*pow(secondsPerYear, 2.0)/pow(astronomicalUnit, 3.0);

/// AstroBodies represent objects in the Solar System that orbit the sun. They can be used in
/// different contexts, so not all properties need be set in all applications.
///
public struct AstroBody: CustomStringConvertible, Positioned, Equatable, Hashable {

    // Intrisic properties.
    public private(set) var name: String             // Name of body. Must be unique.
    public private(set) var mass = 0.0               // Mass of body in kilograms, if used.
    public private(set) var radius = 0.0             // Radius of body in meters, if used.

    // Position and velocity Vectors.
    public private(set) var position = Vector.zero   // Heliocentric position in AU.
    public private(set) var velocity = Vector.zero   // Heliocentric velocity in AU/year.

    // Orbital elements.
    public private(set) var semimajorAxis = 0.0      // Semi-major axis in AU.
    public private(set) var eccentricity = 0.0       // Orbital eccentricity; dimensionless.
    public private(set) var inclination = 0.0        // Inclination from ecliptic in radians.
    public private(set) var longAscendingNode = 0.0  // Longitude of ascending node in radians.
    public private(set) var argPeriapsis = 0.0       // Argument of periapsis in radians.
    public private(set) var longPeriapsis = 0.0      // Longitude of periapsis in radians.
    public private(set) var epoch = AstroTime.now()  // Date and time of trueAnomalyAtEpoch.
    public private(set) var trueAnomalyAtEpoch = 0.0 // True anomaly in radians.

	public static func == (lhs: AstroBody, rhs: AstroBody) -> Bool {
		return lhs.name == rhs.name
	}

    /// Mean anomaly at epoch in radians; requires trueAnomalyAtEpoch and eccentricity.
    public var meanAnomalyAtEpoch: Double {
		trueToMeanAnomaly(trueAnomaly: trueAnomalyAtEpoch, eccentricity: eccentricity)
    }

    /// Argument of latitude in radians; requires trueAnamalyAtEpoch and argPeriapsis.
    public var argLatitude: Double {
        trueAnomalyAtEpoch + argPeriapsis
    }

    /// True longitude in radians; requires trueAnomaly, argPeriapsis, and longAscendingNode.
	public func trueLongitude(trueAnomaly: Double) -> Double {
        trueAnomaly + argPeriapsis + longAscendingNode
    }

    /// Apoapsis distance in AU; requires eccentricity and semimajorAxis.
    public var apoapsis: Double {
        (1 + eccentricity)*semimajorAxis
    }

    /// Periapsis distance in AU; requires eccentricity and semimajorAxis.
    public var periapsis: Double {
        (1 - eccentricity)*semimajorAxis
    }

    /// Semilatus rectum in AU; requires eccentricity and semimajorAxis.
	public var semilatusRectum: Double {
        (1 - eccentricity*eccentricity)*semimajorAxis
    }

    /// Orbital period in years; requires semimajorAxis, and hgc_year_au.
    public var period: Double {
        twoPi*sqrt(semimajorAxis*semimajorAxis*semimajorAxis/hgc_year_au)
    }

    /// Description of body.
    public var description: String {

        var buffer: String = ""
        buffer += "\(name)"
        buffer += " smax:\(semimajorAxis.format(3))"
        buffer += " eccn:\(eccentricity.format(3))"
        buffer += " incl:\(inclination.format(3))"
        buffer += " anod:\(longAscendingNode.format(3))"
        buffer += " aper:\(argPeriapsis.format(3))"
        return buffer
    }

    /// Init AstroBody with intrinsic properties.
    ///
    init (name: String, mass: Double, radius: Double) {
        self.name = name
        self.mass = mass
        self.radius = radius
    }

    /// Assumes AstroBodies have unique names.
    public func hash (into hasher: inout Hasher) {
        hasher.combine(name)
    }

    /// Set the orbital elements for this AstroBody.
    ///
	mutating func setElements(semimajorAxis: Double,
							  eccentricity: Double,
							  inclination: Double,
							  longAscendingNode: Double,
							  argPeriapsis: Double,
							  epoch: AstroTime,
							  trueAnomalyAtEpoch: Double) {

		self.semimajorAxis = semimajorAxis
		self.eccentricity = eccentricity
		self.inclination = inclination
		self.longAscendingNode = longAscendingNode
		self.argPeriapsis = argPeriapsis
		self.epoch = epoch
		self.trueAnomalyAtEpoch = trueAnomalyAtEpoch
	}

    /// Set the orbital elements of this AstroBody from its position and velocity in AU and AU/year.
    /// TODO: THIS METHOD HASN'T BEEN NEEDED SO HASN'T BEEN TESTED. USE WITH CAUTION.
    ///
    mutating func setElements(primaryMass: Double,
                               g: Double,
                               primaryPosition: Vector,
                               primaryVelocity: Vector) {

        // Get the position and velocity of this AstroObject relative to its primary.
        let position = self.position - primaryPosition
        let velocity = self.velocity - primaryVelocity
        let radius = position.length  // Distance from sun.
        let velocitySquared = velocity.square

        // Get the angular momentum, perpendicular to orbital plane.
        let angularMomentum = cross(position, velocity)

        // Get the ascending node, the intersection of the orbital planes; if the the planes
        // coplanar this vector is zero.
        let ascendingNode: Vector = cross(Vector.k, angularMomentum)
        let nMagnitude: Double = ascendingNode.length
        let coplanar: Bool = nMagnitude == 0

        // Get the gravitational parameter.
        let mu: Double = g*(mass + primaryMass)

        // Get the eccentricity Vector; its magnitude is the eccentricity; it points to periapsis.
        let eccentricity = (position*(velocitySquared - mu/radius) -
                                        velocity*dot(position, velocity))/mu
        self.eccentricity = eccentricity.length

        // Get semi-latus rectum and semimajor axis of this AstroBody.
        let semiLatusRectum: Double = angularMomentum.square/mu
        semimajorAxis = semiLatusRectum/(1 - self.eccentricity*self.eccentricity)

        // Get orbital inclination; for coplanar orbits this is zero.
        inclination = acos(angularMomentum.z/angularMomentum.length)

        // Get longitude of the ascending node; undefined for coplanar orbits.
        longAscendingNode = acos(ascendingNode.x/nMagnitude)
        if ascendingNode.y < 0 {
            longAscendingNode -= Double.pi
        }

        // Get argument of periapsis; undefined if orbit is circular.
        argPeriapsis = acos(dot(ascendingNode, eccentricity)/nMagnitude/self.eccentricity)
        if eccentricity.z > 0 {
            argPeriapsis -= Double.pi
        }

        // Get longitude of periapsis; undefined if orbit is circular; special formula used if
        //orbit is coplanar.
        if !coplanar {
            longPeriapsis = longAscendingNode + argPeriapsis
        } else {
            longPeriapsis = acos(dot(eccentricity, Vector.i)/self.eccentricity)
        }

        // Get true anomaly at epoch; undefined if orbit is circular.
        trueAnomalyAtEpoch = acos(dot(eccentricity, self.position)/self.eccentricity/radius)
        if dot(position, self.velocity) > 0 {
            trueAnomalyAtEpoch -= Double.pi
        }
    }

    /// Set the heliocentric coordinates of this body for a specific time. The orbital elements
	/// must be valid.
    ///
    public mutating func setHeliocentric (time: AstroTime) {

        let a = semimajorAxis
        let e = eccentricity

        // Get time since epoch in years.
        let differenceInYears: Double = (time - epoch)/daysPerYear

        // Get mean anomaly since last periapsis passage.
        var meanAnomaly = meanAnomalyAtEpoch + twoPi*differenceInYears/period
        meanAnomaly = fmod(meanAnomaly, twoPi)
        if meanAnomaly < 0.0 {
            meanAnomaly += twoPi
        }

        // Get eccentric anomaly from mean anomaly.
        let eccentricAnomaly = meanToEccentricAnomaly(meanAnomaly: meanAnomaly, eccentricity: e)

        // Get perifocal coordinates.
        let p = a*(cos(eccentricAnomaly) - e)
        let q = a*sqrt(1.0 - e*e)*sin(eccentricAnomaly)

        // Get heliocentric coordinates.
        position = periToEclipticMatrix() * Vector(x: p, y: q, z: 0.0)
    }

    /// Return the rotation Matrix that converts an AstroBody's perifocal (pq) coordinates
	/// to heliocentric (ijk) coordinates. The body must have longAscendingNode, argPeriapsis,
    /// and inclination.
    ///
    func periToEclipticMatrix () -> Matrix {

        let cosAnod = cos(longAscendingNode)
        let sinAnod = sin(longAscendingNode)
        let cosAper = cos(argPeriapsis)
        let sinAper = sin(argPeriapsis)
        let cosIncl = cos(inclination)
        let sinIncl = sin(inclination)
        
        // Elements of the rotation matrix.
        let r11 = cosAnod*cosAper - sinAnod*sinAper*cosIncl
        let r12 = -cosAnod*sinAper - sinAnod*cosAper*cosIncl
        let r13 = sinAnod*sinIncl
        let r21 = sinAnod*cosAper + cosAnod*sinAper*cosIncl
        let r22 = -sinAnod*sinAper + cosAnod*cosAper*cosIncl
        let r23 = -cosAnod*sinIncl
        let r31 = sinAper*sinIncl
        let r32 = cosAper*sinIncl
        let r33 = cosIncl

        // Rows of the rotation matrix.
        let row0 = Vector(r11, r12, r13)
        let row1 = Vector(r21, r22, r23)
        let row2 = Vector(r31, r32, r33)
        return Matrix(top: row0, mid: row1, bot: row2)
    }
}


/// Convert mean anomaly to true anomaly.
///
func meanToTrueAnomaly (meanAnomaly: Double, eccentricity: Double) -> Double {
	eccentricToTrueAnomaly(
		eccentricAnomaly: meanToEccentricAnomaly(meanAnomaly: meanAnomaly, eccentricity: eccentricity),
		eccentricity: eccentricity)
}

/// Convert mean anomaly to eccentric anomaly by solving Kepler's equation. This function stops
/// after 50 iterations if the anomaly hasn't converged.
///
func meanToEccentricAnomaly (meanAnomaly: Double, eccentricity: Double) -> Double {
    
    let error = 0.00000000000001
    let maxCount = 50
    var estimate0 = 0.0
    var estimate1 = meanAnomaly
    var count = 0

    repeat {
        estimate0 = estimate1
        estimate1 = estimate0 + (meanAnomaly - estimate0
                              + eccentricity*sin(estimate0))/(1.0 - eccentricity*cos(estimate0))
        count += 1
    } while fabs(estimate1 - estimate0) > error && count < maxCount
    if keplerComplain && count >= maxCount {
        print("Exceeded maxCount in meanToEccetricAnomaly")
    }
    if showEccentricAnomalyCount {
        print("eccentric anomaly count = \(count)")
    }
    return estimate1
}

/// Convert eccentric anomaly to true anomaly.
///
func eccentricToTrueAnomaly(eccentricAnomaly: Double, eccentricity: Double) -> Double {
    2.0*atan2(sin(eccentricAnomaly/2.0)*sqrt(1.0 + eccentricity),
                     cos(eccentricAnomaly/2.0)*sqrt(1.0 - eccentricity));
}

/// Convert true anomaly to mean anomaly.
///
func trueToMeanAnomaly(trueAnomaly: Double, eccentricity: Double) -> Double {
	eccentricToMeanAnomaly(eccentricAnomaly: trueToEccentricAnomaly(trueAnomaly: trueAnomaly,
																	eccentricity: eccentricity),
						   eccentricity: eccentricity)
}

/// Convert true anomaly to eccentric anomaly.
///
func trueToEccentricAnomaly(trueAnomaly: Double, eccentricity: Double) -> Double {
    atan2(sqrt(1.0 - eccentricity*eccentricity)*sin(trueAnomaly),
                 eccentricity + cos(trueAnomaly));
}

/// Convert eccentric anomaly to mean anomaly.
///
func eccentricToMeanAnomaly(eccentricAnomaly: Double, eccentricity: Double) -> Double {
    eccentricAnomaly - eccentricity*sin(eccentricAnomaly);
}
