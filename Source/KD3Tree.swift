//
//  KD3Tree.swift
//
//  Created by Thomas Wetmore on 7 September 2014.
//  Last changed on 28 November 2026.
//
/// This file implements KD3Tree, a three-dimensional KD tree that organizes Objects in 3-space.
/// A KD3Tree partitions space by cycling through three dimensions. This allows efficient nearest-
/// neighbor searches, range queries, and other operations, reducing computational complexity.
///
/// Included are a public interface, a public class, four private classes and a public function:
///
/// Positioned -- public protocol that Objects in KD3Trees must meet. Positioned has properties:
///   name: String { get } -- unique name of the Object.
///   position: Vector { get } -- position of the Object in 3-space.
///
/// KD3Tree<Object: Positioned> : CustomStringConvertible -- The only class with a public interface.
///   The public API consists of two properties, two initializers and four methods:
//
//   visits: Int { get } -- used by the most recent neighbor calculation.
//   description: String { get } -- Indented string showing contents of the KD3Tree.
//   init() -- Create an empty KD3Tree.
//   init(objects: [Object]) -- Create a KD3Tree and insert an array of Objects into it.
//   insert(_ object: Object) -- Insert an Object into this KD3Tree.
//   nearestNeighbor(point: Vector) -> Object? -- Return nearest Object to a point.
//   kNearestNeighbors(k: Int, point: Vector) -> ([Object], [Double]) -- Return k nearest Objects
//       and their and distances to a point.
//   nearestDifferentNeighbor(point: Vector) -> Object? -- Return nearest Object to a point that
//       does not occupy the point.
//
// balancedTree<Object: Positioned> (objects: [Object]) -> KD3Tree<Object>? -- Public function that
//   takes an array of Objects and returns a balanced KD3Tree containing those Objects.
//
// KD3Node<Object: Positioned> : CustomStringConvertible -- Private class for KD3Trees nodes; they holds Objects.
// KD3Queue<Object: Positioned> : CustomStringConvertible -- Private class that holds queues of KD3Nodes.
// SortQueueElement<Object> -- Private class used by the balancedTree function.
// SortQueue<Object> -- Private class used by the balancedTree function.

/// Protocol implemented by KD3Node Object.
///
public protocol Positioned {

    var name: String { get }  // Name of object.
    var position: Vector { get }  // Position of object.
}

/// Node in a KD3Tree.
///
private class KD3Node<Object: Positioned> : CustomStringConvertible {

	let object: Object // Object this node holds.
    let axis: Int // Axis that splits this node's children.
    var left: KD3Node?  // Left child.
    var right: KD3Node? // Right child.
    var name: String { object.name } // Name of this node.
    var position: Vector { object.position } // Position of this node.
    var description: String { "\(axis): \(name): \(position)" } // Description of this node.

    /// Create a KD3Node with an Object and axis.
    init(axis: Int, object: Object) {

        self.axis = axis
        self.object = object
    }

    /// Create and recursively insert a new KD3Node below this KD3Node.
    /// 
    func insert(_ object: Object) {

        if object.position[axis] < self.position[axis] {
            if let left {
                left.insert(object)
            } else {
                left = KD3Node(axis: (axis + 1)%3, object: object)
            }
        } else {
            if let right {
                right.insert(object)
            } else {
                right = KD3Node(axis: (axis + 1)%3, object: object)
            }
        }
    }

    /// Density of this KD3Node; density measures the completeness of the binary
    /// tree below this node.
    ///
    func density(level: Int, densities: inout [Int]) {

        while densities.count <= level { // Grow density array when necessary.
            densities.append(0)
        }
        densities[level] += 1
        if let left {
            left.density(level: level+1, densities: &densities)
        }
        if let right {
            right.density(level: level+1, densities: &densities)
        }
    }
}

/// Cartesian KD3Tree binary search trees.
///
public class KD3Tree<Object: Positioned> : CustomStringConvertible {

	private var root: KD3Node<Object>? // Root of tree.
	private(set) var visits = 0 // Number of nodes visited by the last tree search.
	private(set) var nearVisits = 0 // Number of near side visits. For testing and debugging.
	private(set) var farVisits = 0  // Number of far side visits. For testing and debugging.
	private(set) var trace = ""  // Latest search trace. For testing and debugging.

    /// Description of this KD3Tree.
	public var description: String {

		if let root {
			var buf = ""
			addNodeDescription(node: root, indent: "", buf: &buf)
			return buf
		} else {
			return "empty tree"
		}
	}

	/// Create a KD3Tree from an array of Objects. For balanced trees the array must be
    /// presorted.
    ///
	init(objects: [Object]) {

		objects.forEach { self.insert($0) }
	}

	/// Insert a KD3Node into the tree. U-ses the insert method on the root.
	///
	private func insert(_ object: Object) {

		if let root {
			root.insert(object)
		} else {
			root = KD3Node(axis: 0, object: object)
		}
	}

	/// Density of this KD3Tree shown as the number of KD3Nodes at each level distance from
    /// the root. For balanced trees the values are powers of two until the deepest level.
    ///
	func density() -> [Int] {

		var densities = [Int]()  // Number of KD3Nodes at each level.
		if let root {
			root.density(level: 1, densities: &densities)
		}
		return densities
	}

	/// The number of KD3Nodes in this KD3Tree.
    ///
	func count() -> Int {

        func count(node: KD3Node<Object>?) -> Int {
            guard let node = node else { return 0 }
            return 1 + count(node: node.left) + count(node: node.right)
        }

		return count(node: root)
	}
}

/// Nearest neighbors to points.
///
extension KD3Tree {

	// Legend: I calls II. III call IV. IV calls V. III not called (part of API.)

	/// I. Return the nearest Objects and distances for every point in an Array of points.
    ///
	func nearestNeighbors(points: [Vector]) -> ([Object], [Double]) {

		var visits = 0
		return nearestNeighbors(points: points, visits: &visits)
	}

	/// II. Return the nearest Objects and distances for every point in an Array of points.
	/// Also returns the number of visits needed to find the neighbors.
    ///
	func nearestNeighbors(points: [Vector], visits: inout Int) -> ([Object], [Double]) {

		var objects: [Object] = []
		var distances: [Double] = []
		points.forEach {

			if let (object, distance) = nearestNeighbor(point: $0) {
				objects.append(object)
				distances.append(distance)
				visits += self.visits
			}
		}
		return (objects, distances)
	}

	/// III. Return the nearest Object and distance to a point. If the point has the same
	/// position as an Object that Object is returned.
    ///
	func nearestNeighbor(point: Vector) -> (Object, Double)? {

		var visits = 0
		return nearestNeighbor(point: point, visits: &visits)
	}

	/// IV. Return the nearest Object and distance to a point. If the point has the same
	/// position as an Object that Object is returned. Returns the number of visits used
    /// to find the neighbor.
    ///
	func nearestNeighbor(point: Vector, visits: inout Int) -> (Object, Double)? {

		var near: KD3Node<Object>?
		var distance = Double.infinity
		self.visits = 0
		nearestNeighbor(point: point, node: root, near: &near, nearDistance: &distance)
		visits = self.visits
		return near == nil ? nil : (near!.object, distance)
	}

	/// V. Recursive helper that does nearest neighbor point search.
    ///
	private func nearestNeighbor(point: Vector, node: KD3Node<Object>?, near: inout KD3Node<Object>?,
								 nearDistance: inout Double) {

		guard let node else {
            return
        }
		visits += 1
		let axis = node.axis
		let distance = (point - node.position).length

		if distance < nearDistance { // Closest so far?
			nearDistance = distance
			near = node
			if nearDistance == 0.0 {
                return
            }
		}
		// Find the side of the axis more likely to hold the neighbor.
		var one: KD3Node<Object>?
		var two: KD3Node<Object>?

		if point[axis] < node.position[axis] {
			one = node.left
			two = node.right
		} else {
			one = node.right
			two = node.left
		}
        // Look on the more likely side.
		nearestNeighbor(point: point, node: one, near: &near, nearDistance: &nearDistance)
		if let two {
            // Look on the less likely side.
			if abs(point[axis] - node.position[axis]) < nearDistance {
				nearestNeighbor(point: point, node: two, near: &near, nearDistance: &nearDistance)
			}
		}
	}
}

/// Nearest neighbors to Objects. If the Object (or an Object with its position) is already in the
/// KD3Tree, then that Object is the nearest and is returned. This can be surprising.
///
extension KD3Tree {

	/// I. Return the nearest neighbors of an Array of Objects and their distances.
    ///
	func nearestNeighbors(objects: [Object]) -> ([Object], [Double]) {

		var visits = 0
		return nearestNeighbors(objects: objects, visits: &visits)
	}

	/// II. Return the nearest neighbors of an Array of Objects and their distances, and
	/// the number of visits needed to find them.
    ///
	func nearestNeighbors(objects: [Object], visits: inout Int) -> ([Object], [Double]) {

		var neighbors: [Object] = []
		var distances: [Double] = []
		
		objects.forEach {
			if let (neighbor, distance) = nearestNeighbor(object: $0) {
				neighbors.append(neighbor)
				distances.append(distance)
				visits += self.visits
			}
		}
		return (neighbors, distances)
	}

	/// III. Return the nearest Object to an Object and its distance. If the Object is already
    /// in the tree or there is another Object in the tree with the exact position it is returned.
    ///
	func nearestNeighbor(object: Object) -> (Object, Double)? {

		var visits = 0
		return nearestNeighbor(object: object, visits: &visits)
	}

	/// IV. Return the nearest Object to an Object and its distance, and return the number
	/// of visits needed to find the Object.
    ///
	func nearestNeighbor(object: Object, visits: inout Int) -> (Object, Double)? {

		var near: KD3Node<Object>? = nil
		var nearDistance = Double.infinity

		self.visits = 0
		nearestNeighbor(object: object, node: root, near: &near, nearDistance: &nearDistance)
		visits = self.visits
		if near == nil {
			return nil
		}
		return (near!.object, nearDistance)
	}

	/// V. Recursive helper used to find nearest neighbor Objects.
	///
	private func nearestNeighbor(object: Object, node: KD3Node<Object>?, near: inout KD3Node<Object>?,
								 nearDistance: inout Double) {
								 
		guard let node else {
			return
		}
		visits += 1
		let axis = node.axis

		let distance = (object.position - node.position).length
		if node.object.name != object.name && distance < nearDistance {
			nearDistance = distance
			near = node
		}
		let objCoord = object.position[axis] // Determine more likely side.
		let nodeCoord = node.position[axis]
		var one: KD3Node<Object>? = nil
		var two: KD3Node<Object>? = nil
		if objCoord < nodeCoord {
			one = node.left
			two = node.right
		} else {
			one = node.right
			two = node.left
		}
		nearestNeighbor(object: object, node: one, near: &near, nearDistance: &nearDistance) // More likely.
		if let two = two, abs(objCoord - nodeCoord) < nearDistance {
			nearestNeighbor(object: object, node: two, near: &near, nearDistance: &nearDistance) // Less likely.
		}
	}
}

// extension for the kNearestNeighbor Object methods.
extension KD3Tree {

	// I. kNearestNeighbors(objects:k) -- Array of Objects without visits.
	func kNearestNeighbors(objects: [Object], k: Int) -> [([Object], [Double])]? {
		var visits = 0
		return kNearestNeighbors(objects: objects, k: k, visits: &visits)
	}

	// II. kNearestNeighbors(objects:k:visits) -- Array of Objects with visits.
	func kNearestNeighbors(objects: [Object], k: Int, visits: inout Int) -> [([Object], [Double])]? {
		self.visits = 0
		let results = objects.map { object in // Map each to its k nearest neighbors.
			kNearestNeighbors(object: object, k: k, visits: &visits)
		}
		visits = self.visits
		return results.isEmpty ? nil : results
	}

	// III. kNearestNeighbors(object:k:) -- Single Object without visits.
	func kNearestNeighbors(object: Object, k: Int) -> ([Object], [Double]) {
		var visits = 0
		return kNearestNeighbors(object: object, k: k, visits: &visits)
	}

	// IV. kNearestNeighbors(object:k:visits:) -- Single Object with visits.
	func kNearestNeighbors(object: Object, k: Int, visits: inout Int) -> ([Object], [Double]) {
		visits = 0
		var queue = KD3Queue<Object>(size: k)
		kNearestNeighbors(object: object, node: root, queue: &queue)
		return (queue.elements.map { $0.object }, queue.elements.map { $0.distance })
	}

	// V. kNearestNeighbors(body:node:queue:) -- Recursive helper used by kNearestNeighbors(object:k:visits:).
	// Parameters: self: KD3Tree; object: object; node: current node in tree; queue: queue of neighbors.
	private func kNearestNeighbors(object: Object, node: KD3Node<Object>?, queue: inout KD3Queue<Object>) {
		guard let node = node else { return }
		visits += 1
		let axis = node.axis

		let distance = (object.position - node.position).length
		if node.object.name != object.name {
			queue.insert(object: node.object, distance: distance)
		}
		let objCoord = object.position[axis]
		let nodeCoord = node.position[axis]

		var one = node.left
		var two = node.right
		if object.position[axis] > node.position[axis] {
			one = node.right
			two = node.left
		}
		kNearestNeighbors(object: object, node: one, queue: &queue) // More likely side.
		if let two = two, abs(objCoord - nodeCoord) < queue.maxDistance {
			kNearestNeighbors(object: object, node: two, queue: &queue) // Less likely side.
		}
	}
}

// Extension for the kNearestNeighbor point methods.
extension KD3Tree {


	// I. kNearestNeighbors(points:k:) -- Array of points without visits.
	func kNearestNeighbors(points: [Vector], k: Int) -> [([Object], [Double])]? {
		var visits = 0
		return kNearestNeighbors(points: points, k: k, visits: &visits)
	}

	// II. kNearestNeighbors(points:k:visits) -- Array of points with visits.
	func kNearestNeighbors(points: [Vector], k: Int, visits: inout Int) -> [([Object], [Double])]? {
			self.visits = 0
			let results = points.compactMap { point in
				kNearestNeighbors(point: point, k: k, visits: &visits)
			}
			visits = self.visits
			return results.isEmpty ? nil : results
	}

	// III. kNearestNeighbors(point:k:) -- Single point without visits.
	func kNearestNeighbors(point: Vector, k: Int) -> ([Object], [Double])? {
		var visits = 0
		return kNearestNeighbors(point: point, k: k, visits: &visits)
	}

	// IV. kNearestNeighbors(point:visits:) -- Single point with visits -- only caller to recursive helper.
	func kNearestNeighbors(point: Vector, k: Int, visits: inout Int) -> ([Object], [Double])? {
		visits = 0
		var queue = KD3Queue<Object>(size: k)
		kNearestNeighbors(point: point, node: self.root, queue: &queue)
		return (queue.elements.map { $0.object }, queue.elements.map { $0.distance })
	}

	// V. kNearestNeighbors(point:node:queue:) is the recursive method that does out the k-nearest neighbor search.
	private func kNearestNeighbors(point: Vector, node: KD3Node<Object>?, queue: inout KD3Queue<Object>) {
		if let node = node {
			visits += 1
			let axis = node.axis
			let distance = (point - node.position).length
			queue.insert(object: node.object, distance: distance)

			// Find the side of the axis more likely to hold the neighbor.
			var one: KD3Node<Object>?
			var two: KD3Node<Object>?
			if point[axis] <= node.position[axis] {
				one = node.left
				two = node.right
			} else {
				one = node.right
				two = node.left
			}
			// Search the more likely side of the axis.
			kNearestNeighbors(point: point, node: one, queue: &queue)
			// Search the other side if it could hold nearest neighbors.
			if let two = two {
				if !queue.full || abs(point[axis] - node.position[axis]) < queue.maxDistance {
					kNearestNeighbors(point: point, node: two, queue: &queue)
				}
			}
		}
	}
}

// extension with the instrumented nearestDifferentNeigbor family of methods.
extension KD3Tree {

	// I. nearestNeighborTrace(points:nearVisits:farVisits:) returns the nearest Objects and their distances to an
	// Array of Vectors. It also prints the traces of all searches. It also returns via reference the number of near
	// visits and far visits made while finding the nearest objects.
	func nearestNeighborTrace(points: [Vector], nearVisits: inout Int, farVisits: inout Int) -> ([Object], [Double]) {
		var nearObjects = [Object]()
		var nearDistances = [Double]()
		visits = 0
		nearVisits = 0
		farVisits = 0
		var trace = ""
		for point in points {
			let (object, distance) = nearestNeighborTrace(point: point, trace: &trace)!
			//print("\(trace)")
			nearVisits += self.nearVisits
			farVisits += self.farVisits
			nearObjects.append(object)
			nearDistances.append(distance)
		}
		return (nearObjects, nearDistances)
	}

	// III.
	func nearestNeighborTrace(point: Vector, trace: inout String) -> (Object, Double)? {
		var near: KD3Node<Object>? = nil
		var nearDistance = Double.infinity
		trace = ""
		nearVisits = 0
		farVisits = 0
		nearestNeighborTrace(point: point, node: root, near: &near, nearDist: &nearDistance, trace: &trace)
		return (near!.object, nearDistance)
	}

    // V. nearensNeighborTrace(point:node:near:nearDist:side:trace) is the recursive helper that does the search.
	private func nearestNeighborTrace(point: Vector, node: KD3Node<Object>?, near: inout KD3Node<Object>?,
									  nearDist: inout Double, trace: inout String) {
		guard let node = node else { return }
		let axis = node.axis
		// See if the current node is the closest so far.
		let distance = (point - node.position).length
		if distance > 0 && distance < nearDist {
			trace.append("*")
			nearDist = distance
			near = node
		}
		// Find the side of the axis more likely to hold the neighbor.
		var one: KD3Node<Object>?
		var two: KD3Node<Object>?
		if point[axis] < node.position[axis] {
			one = node.left
			two = node.right
		} else {
			one = node.right
			two = node.left
		}
		trace.append("n(")
		nearVisits += 1
		nearestNeighborTrace(point: point, node: one, near: &near, nearDist: &nearDist, trace: &trace)
		trace.append(")")
		if let two = two {
			let axisDist = abs(point[axis] - node.position[axis])
			if axisDist < nearDist {
				trace.append("f[")
				farVisits += 1
				nearestNeighborTrace(point: point, node: two, near: &near, nearDist: &nearDist, trace: &trace)
				trace.append("]")
			}
		}
	}

    // Recursive method used by the KD3Tree description property.
    private func addNodeDescription (node: KD3Node<Object>,  // Current node to describe.
                                     indent: String,  // Indent level of current node.
                                     buf: inout String) {  // Description accumluation buffer.
        if let child = node.left {
            addNodeDescription(node: child, indent: indent + "  ", buf: &buf)
        }
        buf += indent + node.description + "\n"
        if let child = node.right {
            addNodeDescription(node: child, indent: indent + "  ", buf: &buf)
        }
    }
}

// KD3Queue is a struct for ordered queues of Objects and distances.
struct KD3Queue<Object: Positioned>: CustomStringConvertible {

	// Neighbor is an element of a KD3Queue
	struct Neighbor {
		let object: Object
		let distance: Double
	}

	var elements: [Neighbor] = []
    private let maxSize: Int // Max size of queue.
    var full: Bool { elements.count >= maxSize } // True if queue is full.

	// init initialize a KD3Queue with a max size.
	init(size: Int) {
		maxSize = size
	}

    // maxdistance returns the max distance in the neighbors Array.
	var maxDistance: Double {
		return elements.last?.distance ?? .infinity
	}

    // description returns a String describing this KD3Queue.
    var description: String {
        var buf: String = "["
        var started = false
        for element in elements {
            if started { buf += ", " }
			else { started = true }
			buf += "\(element.distance.format(3))"
        }
        buf += "]"
        return buf
    }

	// Insert an Object into this KD3Queue if there is room or if the distance is less than the current max.
	mutating func insert(object: Object, distance: Double) {
		let newElement = Neighbor(object: object, distance: distance)

		// Find the correct position using binary search
		let index = elements.firstIndex { $0.distance >= distance } ?? elements.count

		// Insert the new element at the correct position
		elements.insert(newElement, at: index)

		// If the queue exceeds the maximum size, remove the last (largest distance) element
		if elements.count > maxSize {
			elements.removeLast()
		}
	}
}

/// Create a balanced KD3Tree from an Array of Objects. This is done by ordering the Array so
/// that a balanced KD3Tree is created by adding Objects in that order.
///
public func balancedTree<Object: Positioned>(objects: [Object]) -> KD3Tree<Object>? {

	var ordered = [Object]() // Objects in the order needed to build a balanced KD3Tree.
    let queue = SortQueue<Object>() // Create first element based on full Array.
    queue.enqueue(element: SortQueueElement<Object>(axis: 0, objects: objects))

    while !queue.empty {
		var element = queue.dequeue() // Get next SortQueueElement from the queue.
        let axis = element.axis // Sort the Objects in the element around the axis.
        element.objects.sort { $0.position[axis] < $1.position[axis] }
        let mid = element.mid // Add the median to the ordered Array.
        let count = element.count
        ordered.append(element.objects[mid])
        if count > 1 { // Put remaining Objects into SortQueueElements and enqueue them onto the SortQueue.
            let left = Array(element.objects[0 ... mid - 1])
            queue.enqueue(element: SortQueueElement<Object>(axis: (axis + 1)%3, objects: left))
        }
        if count > 2 {
            let right = Array(element.objects[mid + 1 ... count - 1])
            queue.enqueue(element: SortQueueElement<Object>(axis: (axis + 1)%3, objects: right))
        }
    }
    // Return a balanced KD3Tree by by inserting the ordered objects into a new KD3Tree.
    return KD3Tree<Object>(objects: ordered)
}

/// Structure for the elements used to create balanced KD3Trees.
///
private struct SortQueueElement<Object> {

    var axis: Int // Axis of this element.
    var objects: [Object] // Objects in this element.
    var count: Int { objects.count }  // Number of Objects in this element.
    var mid: Int { objects.count/2 }  // Median index of this element.

    /// Initialize a SortQueueElement with an axis and Array of Objects.
    ///
    init (axis: Int, objects: [Object]) {
        self.axis = axis
        self.objects = objects
    }
}

/// Queue used to create balanced KD3Trees.
///
private class SortQueue<Object> {
    
    var elements = [SortQueueElement<Object>]()  // Elements making up this SortQueue.
    var empty: Bool { elements.count == 0 }  // Return true if this SortQueue is empty.

    /// Add a SortQueueElement to this SortQueue.
    ///
    func enqueue(element: SortQueueElement<Object>) {

        elements.append(element)
    }

    /// Remove and return a SortQueueElement from this SortQueue. Not called if the
    /// queue is empty.
    func dequeue() -> SortQueueElement<Object> {

        let element = elements[0]
        elements.remove(at: 0)
        return element
    }
}
