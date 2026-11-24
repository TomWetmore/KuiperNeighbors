//
//  Support.swift
//  This file has support functions used by the main program to read AstroBodies, build
//  balanced and unbalanced KD3Trees, find nearest neighbors in various ways, and test that
//  the nearest neighbor functions work properly.
//
//  Created by Thomas Wetmore on 19 January 2025.
//  Last changed on 22 November 2026.
//

import Foundation

/// Read an MPC orbital file and return the Array of AstroBodies extracted.
///
func getAstroBodiesFromMPCFile(_ path: String, time: AstroTime) -> [AstroBody] {

	print("===================================================")
	print("\(logTime()): GETTING ASTROBODIES FROM MPC FILE: \(path)")
	var bodies: [AstroBody] = getMPCBodiesFrom(path: path)
	if logging {print("\(logTime()): Read \(bodies.count) bodies from the file.")}
	// Filter bodies by orbital elements range.
	var (minLength, maxLength, maxInclination) = (25.0, 65.0, degreesToRadians(90)) // For Kuiper belt
	if mainAsteroidBelt { // For main asteroid belt
		(minLength, maxLength, maxInclination) = (2.1, 3.3, degreesToRadians(20))
	}
	if logging { print("\(logTime()): Filtering bodies to orbital parameters.") }
	bodies = bodies.filter {
		$0.semimajorAxis >= minLength && $0.semimajorAxis <= maxLength &&
		$0.inclination <= maxInclination
	}
	if logging { print("\(logTime()): There are \(bodies.count) filtered bodies") }
	// Compute and set the heliocentric coordinates for the bodies.
	if logging { print("\(logTime()): Computing heliocentric coordinates for \(time).") }
	bodies = bodies.map {
		var body = $0
		body.setHeliocentric(time: time)
		return body
	}
	return bodies
}

/// Create a balanced KD3Tree<AstroBody> from an Array of AstroBodies.
///
func createBalancedTree(_ bodies: [AstroBody]) -> KD3Tree<AstroBody>? {

	if !buildBalancedTree && !useBalancedTree { return nil }
	print("===================================================")
	print("\(logTime()): CREATING BALANCED TREE")
	guard let balancedTree = balancedTree(objects: bodies) else {
		print("\(logTime()): Error: balanced tree is nil.")
		return nil
	}
	print("\(logTime()): Balanced tree has \(balancedTree.count()) elements.")
	if showBalancedTree {
		if balancedTree.count() > 0 {
			print("\(logTime()): Contents of the balanced tree:")
			print("\(logTime()): \(balancedTree.description)")
		} else {
			print("\(logTime()): Error: balanced tree is empty.")
			return nil
		}
	}
	return balancedTree
}

/// Creates a unbalanced KD3Tree<AstroBody> from an Array of AstroBodies.
///
func createUnbalancedTree(_ bodies: [AstroBody]) -> KD3Tree<AstroBody>? {
    
	if !buildUnbalancedTree && !useUnbalancedTree && !buildBalancedTree {
        return nil
    }
	print("===================================================")
	print("\(logTime()): CREATING UNBALANCED TREE")
	let unbalancedTree = KD3Tree<AstroBody>(objects: bodies)
	if unbalancedTree.count() == 0 {
		print("\(logTime()): Error: unbalanced tree is empty.")
		return nil
	}
	print("\(logTime()): Unbalanced tree has \(unbalancedTree.count()) elements.")
	if showUnbalancedTree {
		if unbalancedTree.count() > 0 {
			print("\(logTime()): Contents of the unbalanced tree:")
			print("\(logTime()): \(unbalancedTree.description)")
		} else {
			print("\(logTime()): Error: unbalanced tree is empty.")
			return nil
		}
	}
	return unbalancedTree
}

//// nearestNeighborCheckPoints(bodies:tree:) calls nearestNeighbor(point:) on ever AstroBody to make sure it is its own
//// closest neighbor.
//func nearestTwoNeighborsCheckPoints(bodies: [AstroBody], tree: KD3Tree<AstroBody>) -> [AstroBody] {
//
//	print("===================================================")
//	print("CHECKING TWONEARESTNEIGHBORPOINTS(OBJECTS:TREE:)")
//	print("\(logTime()): Check nearestKNeighbors by Points to find two nearest neighbors of each AstroBody.")
//	var pairs = [AstroBody : AstroBody]()  // Map for finding nearest neighbor pairs.
//	var distanceSum = 0.0
//	var comparisons = 0
//	var allSame = true
//	var k2nearBodies = [AstroBody]()
//	var distances = [Double]()
//	bodies.forEach {
//		// Get two nearest neighbors and their distances.
//		let (neighbors, neighborDistances) = tree.kNearestNeighbors(k: 2, point: $0.position)
//		comparisons += tree.visits
//		// Check that first is the body itself.
//		if $0 != neighbors[0] {
//			print("\(logTime()): Yikes: \($0) and \(neighbors[0]) are not the same!")
//			allSame = false
//		}
//		distances.append(neighborDistances[1])
//		distanceSum += neighborDistances[1]
//		k2nearBodies.append(neighbors[1])
//		pairs[$0] = neighbors[1]
//	}
//	if allSame {
//		print("\(logTime()): Success: nearest neighbors are all themselves.")
//	} else {
//		print("\(logTime()): Failure: nearest neighbors are not all themselves.")
//	}
//
//	print("\(logTime()): Number of comparisons: \(comparisons)")
//	print("\(logTime()): Average nearest neighbor distance: \((distanceSum/Double(bodies.count)).format(9)) au")
//	return k2nearBodies
//}

func meanAndMedian(numbers: [Double]) -> (average: Double, median: Double) {
	guard numbers.count > 0 else { return (0.0, 0.0) }
	let average = numbers.reduce(0, +) / Double(numbers.count)
	let sorted = numbers.sorted()
	let medianIndex = numbers.count / 2
	let median = numbers.count.isMultiple(of: 2) ? (sorted[medianIndex - 1] + sorted[medianIndex]) / 2 : sorted[medianIndex]
	return (average, median)
}
