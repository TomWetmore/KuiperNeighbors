//
//  BruteForce.swift
//  KuiperNearestNeighbors
//
//  Created by Thomas Wetmore on 24 January 2025.
//  Last changed on 24 November 2026.
//

import Foundation

/// Find nearest neighbors and distances using the brute force n-squared algorithm. Used to
/// validate the KD3Tree algorithm. Requires bodies to have Positions.
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

/// Find the k nearest neighbors and distances using the brute force n-squared
/// algorithm.
///
func bruteForceKNearestNeighbors<Object: Positioned>(objects: [Object], k: Int)
        -> [([Object], [Double])] {

    var results: [([Object], [Double])] = [] // (Objects, Distances) for each Object.
    for target in objects {

        let queue = KD3QueueX<Object>(size: k)
        for candidate in objects {
            if target.name != candidate.name {
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

