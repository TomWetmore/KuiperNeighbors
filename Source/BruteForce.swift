//
//  BruteForce.swift
//  KuiperNearestNeighbors
//
//  Created by Thomas Wetmore on 1/24/25.
//  Last changed on 1/25/25.
//

import Foundation

///// Find nearest neighbors and distances using brute force. Used for validating the KD3Tree
///// algorithms. Requires bodies to have Positions initialized, so AstroBodies must have their
///// heliocentric coordinates.
/////
//func bruteForce<Object: Positioned>(objects: [Object], visits: inout Int) ->
//        (neighbors: [Object], distances: [Double]) {
//
//	var nearBodies = [Object]() // Nearest neighbors.
//	var distances = [Double]()  // Distances to neighbors.
//	visits = 0  // Number of visits to find neighbors.
//	for target in objects {
//		var nearestDistance = Double.infinity
//		var nearestBody: Object? = nil
//		for candidate in objects {
//			if target.name != candidate.name {
//				visits += 1
//				let distance = (target.position - candidate.position).length
//				if distance < nearestDistance {
//					nearestBody = candidate
//					nearestDistance = distance
//				}
//			}
//		}
//		nearBodies.append(nearestBody!)
//		distances.append(nearestDistance)
//	}
//	return (nearBodies, distances)
//}
//
///// Use brute force to find the k nearest neighbors and their distaances from an Array
//// of Objects.
//func bruteForceKNearestNeighbors<Object: Positioned>(objects: [Object], k: Int) -> ([([Object], [Double])]) {
//	var results: [([Object], [Double])] = [] // (Objects, Distances) neighbor information for each Object.
//	for target in objects {
//		let queue = KD3QueueX<Object>(size: k, dummyObject: objects[0]) // Init queue for neighbor info.
//		for candidate in objects {
//			if target.name != candidate.name { // Don't compare object to self.
//				queue.insert(object: candidate, distance: (target.position - candidate.position).length)
//			}
//		}
//		let kObjects = queue.elements.map { $0.object }
//		let kDistances = queue.elements.map { $0.distance }
//		results.append((kObjects, kDistances))
//	}
//	return results
//}


//
//  BruteForce.swift
//  KuiperNearestNeighbors
//
//  Created by Thomas Wetmore on 1/24/25.
//  Last changed on 1/25/25.
//

import Foundation

/// Find nearest neighbors and distances using brute force. Used for validating the KD3Tree
/// algorithms. Requires bodies to have Positions initialized, so AstroBodies must have their
/// heliocentric coordinates.
///
func bruteForce<Object: Positioned>(objects: [Object], visits: inout Int) ->
        (neighbors: [Object], distances: [Double]) {

    var nearBodies = [Object]() // Nearest neighbors.
    var distances = [Double]()  // Distances to neighbors.
    visits = 0  // Number of visits to find neighbors.
    for target in objects {
        var nearestDistance = Double.infinity
        var nearestBody: Object? = nil
        for candidate in objects {
            if target.name != candidate.name {
                visits += 1
                let distance = (target.position - candidate.position).length
                if distance < nearestDistance {
                    nearestBody = candidate
                    nearestDistance = distance
                }
            }
        }
        nearBodies.append(nearestBody!)
        distances.append(nearestDistance)
    }
    return (nearBodies, distances)
}

/// Use brute force to find the k nearest neighbors and their distances from an Array
/// of Objects.
func bruteForceKNearestNeighbors<Object: Positioned>(
    objects: [Object],
    k: Int
) -> [([Object], [Double])] {
    var results: [([Object], [Double])] = [] // (Objects, Distances) for each Object.
    for target in objects {
        let queue = KD3QueueX<Object>(size: k)
        for candidate in objects {
            if target.name != candidate.name { // Don't compare object to self.
                queue.insert(
                    object: candidate,
                    distance: (target.position - candidate.position).length
                )
            }
        }
        let kObjects = queue.elements.map { $0.object }
        let kDistances = queue.elements.map { $0.distance }
        results.append((kObjects, kDistances))
    }
    return results
}

