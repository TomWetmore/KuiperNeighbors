//
//  OtherQueues.swift
//  KuiperNearestNeighbors
//
//  Created by Thomas Wetmore on 1/25/25.
//  Last changed on 1/29/25.
//

import Foundation

///// Ordered queue of Objects and distances.
/////
//class KD3QueueX<Object: Positioned>: CustomStringConvertible {
//
//	/// Element of a KD3Queue
//    ///
//	struct Neighbor {
//		let object: Object
//		let distance: Double
//	}
//
//	/*private*/ var elements: UnsafeMutableBufferPointer<Neighbor>
//
//    /// Number of element in this queue.
//	private var count: Int = 0
//
//    /// Max size of this queue.
//	private let maxSize: Int
//
//    /// True if the queue is full.
//	var full: Bool {
//        elements.count >= maxSize
//    }
//
//
//	init(size: Int, dummyObject: Object) {
//
//		maxSize = size
//		elements = UnsafeMutableBufferPointer<Neighbor>.allocate(capacity: size)
//		elements.initialize(repeating: Neighbor(object: dummyObject, distance: Double.infinity))
//	}
//
//	deinit {
//		elements.deinitialize() // Deinitialize the elements.
//		elements.deallocate() // Deallocate the buffer.
//	}
//
//	/// Return the max distance in the neighbors Array.
//	var maxDistance: Double {
//		return elements.last?.distance ?? .infinity
//	}
//
//	/// Return a String describing this KD3Queue.
//	var description: String {
//		var buf: String = "["
//		var started = false
//		for element in elements {
//			if started { buf += ", " }
//			else { started = true }
//			buf += "\(element.distance.format(3))"
//		}
//		buf += "]"
//		return buf
//	}
//
//	func insert(object: Object, distance: Double) {
//		let newElement = Neighbor(object: object, distance: distance)
//
//		// Find the position for insertion using binary search
//		var low = 0
//		var high = count
//		while low < high {
//			let mid = (low + high) / 2
//			if elements[mid].distance < distance {
//				low = mid + 1
//			} else {
//				high = mid
//			}
//		}
//
//		// Insert only if the queue is not full or the new distance is smaller than the largest
//		if count < maxSize || low < count {
//			// Shift elements to make room for the new element
//			for i in stride(from: min(count, maxSize - 1), to: low, by: -1) {
//				elements[i] = elements[i - 1]
//			}
//
//			// Insert the new element
//			elements[low] = newElement
//			if count < maxSize {
//				count += 1
//			}
//		}
//	}
//}

//
//  OtherQueues.swift
//  KuiperNearestNeighbors
//
//  Created by Thomas Wetmore on 1/25/25.
//  Last changed on 11/23/26.
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

    /// Maximum number of neighbors retained.
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

