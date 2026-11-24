//
//  Vector.swift
//  AstronomyKit
//
//  Created by Thomas Wetmore on 8/21/2014.
//  Last changed on 3/6/2022.
//  Copyright (c) 2014-2022 DeadEnds Software. All rights reserved.
//

import Darwin // sqrt.

// Instances are Cartesian vectors.
//--------------------------------------------------------------------------------------------------
public struct Vector : CustomStringConvertible {

    // Stored Instance Properties:
    public let x: Double // x coordinate
    public let y: Double // y coordinate
    public let z: Double // z coordinate

    // Computed Instance Properties:
    // Scalar square of Vector.
    public var square: Double {
        x*x + y*y + z*z
    }

    // Length of the Vector.
    public var length: Double {
        sqrt(square)
    }

    // Description of Vector.
    public var description: String {
        "(\(x.format(2)), \(y.format(2)), \(z.format(2)))"
    }

    // Initializers.
    // Initializer that requires all labels.
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    // Initializer that uses no labels.
    public init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    // Subscripts.
    // Define the [0], [1] and [2] subscripts to return x, y and z coordinates.
    subscript (index: Int) -> Double {
        if index < 0 || index >= 3 {
            fatalError("vector index out of bounds: [\(index)]")
        }
        if index == 0 {
            return x
        } else if index == 1 {
            return y
        } else {
            return z
        }
    }

    /// i unit vector.
    public static let i = Vector(x: 1, y: 0, z: 0)

    /// j unit vector.
    public static let j = Vector(x: 0, y: 1, z: 0)

    /// k unit vector.
    public static let k = Vector(x: 0, y: 0, z: 1)

    /// Zero vector.
    public static let zero = Vector(x: 0, y: 0, z: 0)  // zero vector
}

/// Vector addition.
///
public func + (lhs: Vector, rhs: Vector) -> Vector {
    Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
}

/// Vector subtraction.
///
public func - (lhs: Vector, rhs: Vector) -> Vector {
    Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
}

/// Vector dot product.
///
public func dot (_ lhs: Vector, _ rhs: Vector) -> Double {
    lhs.x*rhs.x + lhs.y*rhs.y + lhs.z*rhs.z
}

/// Vector cross product.
public func cross (_ lhs: Vector, _ rhs: Vector) -> Vector {
    Vector(x: lhs.y*rhs.z - lhs.z*rhs.y, y: lhs.z*rhs.x - lhs.x*rhs.z, z: lhs.x*rhs.y - lhs.y*rhs.x)
}

/// Vector scalar multiplication, vector*double and double*vector.
///
public func * (vector: Vector, scalar: Double) -> Vector {
    Vector(x: vector.x*scalar, y: vector.y*scalar, z: vector.z*scalar)
}
public func * (scalar: Double, vector: Vector) -> Vector {
    Vector(x: vector.x*scalar, y: vector.y*scalar, z: vector.z*scalar)
}

/// Vector scalar division, vector/double and double/vector.
public func / (vector: Vector, scalar: Double) -> Vector {
    Vector(x: vector.x/scalar, y: vector.y/scalar, z: vector.z/scalar)
}
public func / (scalar: Double, vector: Vector) -> Vector {
    Vector(x: vector.x/scalar, y: vector.y/scalar, z: vector.z/scalar)
}
