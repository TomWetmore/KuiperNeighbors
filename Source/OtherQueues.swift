//
//  OtherQueues.swift
//  KuiperNearestNeighbors
//
//  Created by Thomas Wetmore on 1/25/25.
//  Last changed on 1/29/25.
//

import Foundation

/// Ordered queue of objects and distances.
///
final class KD3QueueX<Object: Positioned>: CustomStringConvertible {

    /// An object and its distance from the target.
    struct Neighbor {

        let object: Object
        let distance: Double
    }

    /// Neighbors sorted from nearest to farthest.
    private(set) var elements: [Neighbor] = []

    /// Maximum number of neighbors to keep.
    private let maxSize: Int

    init(size: Int) {

        precondition(size >= 0, "Queue size must be nonnegative.")
        maxSize = size
    }

    /// True when the queue contains its maximum number of neighbors.
    var full: Bool {
        elements.count == maxSize
    }

    /// The farthest distance currently retained, or infinity until the queue is full.
    var maxDistance: Double {
        guard full else { return .infinity }
        return elements.last?.distance ?? .infinity
    }

    /// Return a string describing this queue.
    var description: String {
        let distances = elements.map { $0.distance.format(3) }
        return "[" + distances.joined(separator: ", ") + "]"
    }

    /// Insert a new Object in this queue if its distance is small enough or
    /// there is room.
    ///
    func insert(object: Object, distance: Double) {
        
        guard maxSize > 0 else { return }

        // Find the first element whose distance is not less than the new distance.
        var low = 0
        var high = elements.count
        while low < high {
            let mid = (low + high) / 2
            if elements[mid].distance < distance {
                low = mid + 1
            } else {
                high = mid
            }
        }

        // If full, discard a new element that belongs after every retained neighbor.
        if full && low == elements.count { return }

        elements.insert(Neighbor(object: object, distance: distance), at: low)
        if elements.count > maxSize {
            elements.removeLast()
        }
    }
}

