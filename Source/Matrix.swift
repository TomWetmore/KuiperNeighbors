//
//  Matrix.swift
//  AstronomyKit
//
//  Created by Thomas Wetmore on 8/21/2014.
//  Last changed on 3/4/2022.
//  Copyright (c) 2014-2022 Deadends Software. All rights reserved.
//

import Darwin // sin, cos.

// Instances of this struct are three by three matrices of doubles.
public struct Matrix : CustomStringConvertible {

    // MARK: Stored Instance Properties
    public private(set) var top = Vector(0, 0, 0) // Top row vector in matrix.
    public private(set) var mid = Vector(0, 0, 0) // Middle row vector in matrix.
    public private(set) var bot = Vector(0, 0, 0) // Bottom row vector in matrix.

    //public private(set) var left = (x: 0, y: 0, z: 0) // Left column vector of matrix

    // MARK: Computed Instance Properties
    public var description: String { "\(top)\n\(mid)\n\(bot)" } // Description of this matrix.

    // MARK: Stored Type Properties
    // Zero Matrix.
    public static let zero = Matrix(top: Vector.zero, mid: Vector.zero, bot: Vector.zero)
    // Identity Matrix.
    public static let identity = Matrix(top: Vector.i, mid: Vector.j, bot: Vector.k)

    // MARK: Subscripts
    // Subscript [i, j] returns the element in ith row and jth column.
    // An out of bounds index causes a fatal error.
    public subscript (row: Int, col: Int) -> Double {
        if row < 0 || row >= 3 || col < 0 || col >= 3 {
            fatalError("Subscript out of bounds: [\(row),\(col)]")
        }
        if row == 0 {
            return top[col]
        } else if row == 1 {
            return mid[col]
        } else {
            return bot[col]
        }
    }

    // MARK: Type Methods
    // Return x-axis rotation Matrix.
    public static func rotateX (angle: Double) -> Matrix {
        let s = sin(angle)
        let c = cos(angle)
        let top = Vector(1, 0,  0)
        let mid = Vector(0, c, -s)
        let bot = Vector(0, s,  c)
        return Matrix(top: top, mid: mid, bot: bot)
    }

    // Return y-axis rotation Matrix.
    public static func rotateY (angle: Double) -> Matrix {
        let s = sin(angle)
        let c = cos(angle)
        let top = Vector(c,  0, s)
        let mid = Vector(0,  1, 0)
        let bot = Vector(-s, 0, c)
        return Matrix(top: top, mid: mid, bot: bot)
    }

    // Return z-axis rotation Matrix.
    public static func rotateZ (angle: Double) -> Matrix {
        let s = sin(angle)
        let c = cos(angle)
        let top = Vector(c, -s, 0)
        let mid = Vector(s,  c, 0)
        let bot = Vector(0,  0, 0)
        return Matrix(top: top, mid: mid, bot: bot)
    }

    // MARK: Instance Methods
    // Return transpose Matrix.
    public func transpose () -> Matrix {
        let newTop = Vector(top.x, mid.x, bot.x)
        let newMid = Vector(top.y, mid.y, bot.y)
        let newBot = Vector(top.z, mid.z, bot.z)
        return Matrix(top: newTop, mid: newMid, bot: newBot)
    }
}

// MARK: Global Operators
// Post-multiply a Matrix by a Vector, yielding a Vector.
public func * (lhs: Matrix, rhs: Vector) -> Vector {
    return Vector(x: dot(lhs.top, rhs), y: dot(lhs.mid, rhs), z: dot(lhs.bot, rhs))
}

// Pre-multiply a Matrix by a Vector, yielding a Vector.
public func * (lhs: Vector, rhs: Matrix) -> Vector {
    let x = lhs.x*rhs[0, 0] + lhs.y*rhs[1, 0] + lhs.z*rhs[2, 0]
    let y = lhs.x*rhs[0, 1] + lhs.y*rhs[1, 1] + lhs.z*rhs[2, 1]
    let z = lhs.x*rhs[0, 2] + lhs.y*rhs[1, 2] + lhs.z*rhs[2, 2]
    return Vector(x, y, z)
}

// Multipy two Matrices, yielding a Matrix.
public func * (lhs: Matrix, rhs: Matrix) -> Matrix {
    let lft = Vector(rhs[0,0], rhs[1,0], rhs[2,0])
    let dim = Vector(rhs[0,1], rhs[1,1], rhs[2,1])
    let rgt = Vector(rhs[0,2], rhs[1,2], rhs[2,2])
    let top = Vector(dot(lhs.top, lft), dot(lhs.top, dim), dot(lhs.top, rgt))
    let mid = Vector(dot(lhs.mid, lft), dot(lhs.mid, dim), dot(lhs.mid, rgt))
    let bot = Vector(dot(lhs.bot, lft), dot(lhs.bot, dim), dot(lhs.bot, rgt))
    return Matrix(top: top, mid: mid, bot: bot)
}
