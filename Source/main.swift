//
//  main.swift
//
//  Created by Thomas Wetmore on 21 August 2014.
//  Last changed on 23 November 2026.
//

import Foundation

// Program switches.
let logging = true
let getBruteForceBodies = false // Brute force distances used as ground truth for the the others.
let getObservationBias = false
let buildBalancedTree = true
let buildUnbalancedTree = true
let useBalancedTree = true
let useUnbalancedTree = false
let showBalancedTree = false
let showUnbalancedTree = false
let showObjectsAndPositions = false
let showBruteForceDistances = false
let runUnitTests = false
let showNearestDistances = false
let showPeriods = false
let plotSemimajorAxes = false
let showPlutoXYZ = true
let showEccentricAnomalyCount = false
let mainAsteroidBelt = false
let nearestNeighborCheck = true
let secondNearestNeighborCheck = true
let differentNearestNeighborCheck = true
let findNumberOfPairs = true
let compareNearestNeighborMethods = true
let useRandomFilter = false
let randomFilterFraction = 0.01
let showTreeDensities = false
let treeSearchTracing = false
let keplerComplain = true
let checkNearestObject = true
let checkNearestByPoints = true
let checkNearestByObjects = true
let checkTwoNearestByPoints = true
let checkTwoNearestByObjects = true
let runDevelopmentTestsFlag = false
let path = "/Users/ttw4/Desktop/Development/Swift/KuiperNeighbors/Resources/distant25112026.txt"

testMain() // According to ChatGPT, I really shouldn't have to explicitly call the main function like this.
func main() {

	let time = AstroTime.now()
	let bodies = getAstroBodiesFromMPCFile(path, time: time)
	//let bodies =  getMPCBodiesFrom(path: path)
	let tree = createBalancedTree(bodies)
	var visits = 0
	let (neighbors, distances) = tree!.nearestNeighbors(objects: bodies, visits: &visits)
	if bodies.count != neighbors.count { print("\(logTime()): Failure: number of bodies != number of neighbors.") }
	let (mean, median) = meanAndMedian(numbers: distances)
	print("\(logTime()): Object: mean = \(mean.format(9)); median = \(median.format(9)); visits = \(visits)")
}

// This is the "old" main program.
func testMain() {

    print("================================================")
    printWithLog("STARTING ORIGINAL MAIN PROGRAM")

	// Use the current time as the epoch for orbital calculatiions.
	let time: AstroTime = AstroTime.now()

	// Run various tests if requested (left over from development).
	if runDevelopmentTestsFlag { runDevelopmentTests() }

	// getAstroBodies gets the Array of AstroBodies from the MPC text file.
	var bodies = getAstroBodiesFromMPCFile(path, time: time)

	// Filter AstroBodies by randomly removing a fraction.
	if useRandomFilter { ramdonFilter(&bodies) }

	// Show coordinates of Pluto as sanity check on the setHeliocentric function.
	if showPlutoXYZ { showPluto(bodies) }

	// Print table of bodies and their positions.
	if showObjectsAndPositions { showObjects(time, bodies) }

	// Find difference between radius vectors and semimajor axes. This shows observation bias.
	if getObservationBias { observationBias(bodies) }

	// Create balanced KD3Tree.
	let balanced = createBalancedTree(bodies)

	// Create unbalanced KD3Tree based on the order in the MPC file.
	let unbalanced = createUnbalancedTree(bodies)

	// Choose tree to test.
	let tree: KD3Tree = useBalancedTree ? balanced! : unbalanced!
	let treeType = useBalancedTree ? "balanced" : "unbalanced"
	print("\(logTime()): Using the \(treeType) tree.")

	// Use brute force to get nearest neighbors and their distances.
	print("===================================================")
	print("\(logTime()): FIND BRUTE FORCE NEAREST NEIGHBORS AND DISTANCES.")
	var visits = 0
	let (nearBodies, nearDistances) = bruteForce(objects: bodies, visits: &visits)
	var (mean, median) = meanAndMedian(numbers: nearDistances)
	print("\(logTime()): Brute force: mean = \(mean.format(9)); median = \(median.format(9)); visits = \(visits)")

	// Run the new brute force function.
//	print("===================================================")
//	print("\(logTime()): NEW NEW FIND BRUTE FORCE NEAREST NEIGHBORS AND DISTANCES.")
//	let bfnResults = bruteForceKNearestNeighbors(objects: bodies, k: 6)
//	print("\(logTime()): Finished the new brute force works.")

	// Find nearest neighbors using nearestNeighbor(point:) and check that it is itself.
	print("===================================================")
	print("\(logTime()): CHECKING NEAREST NEIGHBORS BY POINT.")
	visits = 0
	let points = bodies.map { $0.position }
	let (pntNeighbors, pntDistances) = tree.nearestNeighbors(points: points, visits: &visits)
	if pntNeighbors == bodies { print("\(logTime()): Sucess: all bodies are their own nearest neighbor.") }
	else { print("\(logTime()): Error: some bodies are not their own nearest neighbor.") }
	if pntDistances.allSatisfy({$0 == 0.0}) { print("\(logTime()): Success: all point distances are 0.0") }
	else { print("\(logTime()): Error: some point distances are not 0.0") }

	// Find nearest neighbors using nearestNeighbors(objects:visits:) and check results against the brute force.
	print("===================================================")
	print("\(logTime()): CHECKING NEAREST NEIGHBORS BY OBJECT.")
	visits = 0
	let (objNeighbors, objDistances) = tree.nearestNeighbors(objects: bodies, visits: &visits)
	if bodies.count != objNeighbors.count { print("\(logTime()): Failure: number of bodies != number of neighbors.") }
	if nearBodies == objNeighbors { print("\(logTime()): Success: all neighbors match brute force neighbors.") }
	else { print("\(logTime()): Failure: some neighbbors do not match brute force neighbors.") }
	if objDistances == nearDistances { print("\(logTime()): Success: all object distances match brute force distances.") }
	else { print("\(logTime()): Failure: some object distances do not match brute force distances.") }
	(mean, median) = meanAndMedian(numbers: objDistances)
	print("\(logTime()): Object: mean = \(mean.format(9)); median = \(median.format(9)); visits = \(visits)")

	// Find the two nearest neighbors to each AstroBody by object and check that the first matches brute force.
	print("===================================================")
	print("\(logTime()): CHECKING NEAREST TWO NEIGHBORS BY OBJECT.")
	visits = 0
	var results = tree.kNearestNeighbors(objects: bodies, k: 2, visits: &visits)!
	var firstBodies = results.map { $0.0.first! }
	if firstBodies == nearBodies { print("\(logTime()): Success: all first neighbors match brute force neighbors.") }
	else { print("\(logTime()): Failure: some first neighbors do not match brute force neighbors.") }
	var firstDistances: [Double] = results.map { $0.1.first! }
	if firstDistances == nearDistances { print("\(logTime()): Success: all first distances match brute force distances.") }
	else { print("\(logTime()): Failure: some first distances do not match brute force distances.") }
	(mean, median) = meanAndMedian(numbers: firstDistances)
	print("\(logTime()): Object: mean = \(mean.format(9)); median = \(median.format(9)); visits = \(visits)")

	// Find the two nearest neighbors to each AstroBody by point and check that the first is themselves and the second
	// matches brute force.
	print("===================================================")
	print("\(logTime()): CHECKING NEAREST TWO NEIGHBORS BY POINT.")
	visits = 0
	results = tree.kNearestNeighbors(points: points, k: 2, visits: &visits)!
	firstBodies = results.map { $0.0.first!}
	firstDistances = results.map {$0.1.first!}
	// firstBodies should be the same as bodies.
	if firstBodies == bodies { print("\(logTime()): Success: first neighbors are themselves.") }
	else { print("\(logTime()): Failure: first neighbors are not themselves.") }

	if firstDistances.allSatisfy({ $0 == 0 }) {
		print("\(logTime()): Success: all firstDistances are zero.")
	} else {
		print("\(logTime()): Failure: not all firstDistances are zero.")
	}
	let secondBodies = results.compactMap { $0.0.count > 1 ? $0.0[1] : nil }
	let secondDistances = results.compactMap { $0.1.count > 1 ? $0.1[1] : nil }
	if (secondBodies == nearBodies) { print("\(logTime()): Success all secondBodies match brute force bodies") }
	else { print("\(logTime()): Failure: some secondBodies do not match brute force bodies") }
	if (secondDistances == nearDistances) { print("\(logTime()): Success: all secondDistances match brute force distances") }
	else { print("\(logTime()): Failure: some secondDistances do not match brute force distances") }
	(mean, median) = meanAndMedian(numbers: secondDistances)
	print("\(logTime()): Object: mean = \(mean.format(9)); median = \(median.format(9)); visits = \(visits)")

	// Generate the traces.
	print("===================================================")
	print("\(logTime()): RUN NEAREST NEIGHBOR TRACE.")
	var nearVisits = 0
	var farVisits = 0
	let (_, traceDistances) = tree.nearestNeighborTrace(points: points, nearVisits: &nearVisits, farVisits: &farVisits)
	(mean, median) = meanAndMedian(numbers: traceDistances)
	print("\(logTime()): Number of comparisons: \(nearVisits + farVisits) (near: \(nearVisits), far: \(farVisits)).")
	print("\(logTime()): Trace: mean = \(mean.format(9)); median = \(median.format(9))")

	//--------------------------- CLEAN UP BELOW ----------------------------
	// Sort the distances and remove duplicates.
	let distances = nearDistances.sorted() {$0 < $1}
	var newDistances = [Double]()
	var check = 0.0
	var num = 0
	var den = 0
	for d in distances {
		den += 1
		if d != check {
			newDistances.append(d)
			check = d
			num += 1
		}
	}
	print("\(logTime()): num/den = \(num)/\(den) = \((Double(num)/Double(den)).format(4))")

	// Show the nearest distances.
	if showNearestDistances {
		print("\(logTime()): Nearest distances (au), sorted closest to furthest:")
		print("\(logTime()): There are \(newDistances.count) unique distances")
		newDistances.forEach {
			print("\(logTime()): \($0.format(3)), ", terminator: "")
		}
		print("")
		print("\(logTime()): Before sort: \(distances.count); after sort: \(newDistances.count)")
	}

	// Show the median distance.
	print("\(logTime()): Median distance: \(newDistances[newDistances.count/2].format(9)) au.")

	// Show the periods. The orbital periods of plutinos cluster around 247.3 years (1.5 × Neptune's
	// orbital period), varying by at most a few years from this value.
	if showPeriods {
		var periods = [Double]()
		for body in bodies {
			periods.append(body.period)
		}
		periods.sort() { $0 < $1 }
		for period in periods {
			print("\(logTime()): \(period.format(3)), ", terminator: "")
		}
		// Put each period into a map from year to number.
		var yearMap = [Int : Int]()
		for period in periods {
			let year = Int(period)
			if let count = yearMap[year] {
				yearMap[year] = count + 1
			} else {
				yearMap[year] = 1
			}
		}
		var years = [Int]()
		for year in yearMap.keys {
			years.append(year)
		}
		years.sort() { $0 < $1 }
		for year in 1...100000 {
			if yearMap[year] != nil {
				print("\(logTime()): \(year)\t\(yearMap[year]!)")
			}
		}
	}
	// Plot semimajor axes.
	if plotSemimajorAxes {
		var map = [Int : Int]()
		// Put semimajor axis counts into buckets one tenth of an AU in size.
		for body in bodies {
			let key = Int(body.semimajorAxis*10)
			if let count = map[key] {
				map[key] = count + 1
			} else {
				map[key] = 1
			}
		}
		for size in 200...800 {  // Show bucket sizes from 20 to 80 AU.
			if let count = map[size] {
				print("\(logTime()): \(size)\t\(count)")
			}
		}
	}

	if showTreeDensities {
		print("\(logTime()): Starting to compute density of tree.")
		let densities = tree.density()
		for density in densities {
			print("\(density)")
		}
		print("\(logTime()): Done computing density.")
	}
}

/// Test the anomaly functions, going back and forth.
///
func testAnomaly () {

	var M = 0.618830048239492  // mean anomaly.
	let e = 0.2474562  // eccentricity.
	var E = meanToEccentricAnomaly(meanAnomaly: M, eccentricity: e)  // eccentric anomaly.
	let T = eccentricToTrueAnomaly(eccentricAnomaly: E, eccentricity: e)  // true anomaly.
	print("M = \(M)  E = \(E)  T = \(T)");
	E = trueToEccentricAnomaly(trueAnomaly: T, eccentricity: e)  // eccentric anomaly.
	M = eccentricToMeanAnomaly(eccentricAnomaly: E, eccentricity: e)  // mean anomaly.
	print("T = \(T)  E = \(E)  M = \(M)");
}

/// Test the AstroTime functions.
///
func testTime () {

	let today = AstroTime.now()
	print("\(today)")
	let julian = today.toJulian()
	print("julian: \(julian)")
	let newToday = AstroTime(julian: julian)
	print("\(newToday)")
	var testTime = AstroTime.validTime(year: 2010, month: 10, day: 10, hour: 10, minute: 10, second: 10)
	print("\(String(describing: testTime))")
	testTime = AstroTime.validTime(year: 2010, month: 10, day: 10, hour: 25, minute: 10, second: 10)
	print("\(String(describing: testTime))")
	testTime = AstroTime.validTime(year: 2010, month: "August", day: 10)
	print("\(String(describing: testTime))")
	testTime = AstroTime.validTime(year: 2010, month: "AAUGUUS", day: 10)
	print("\(String(describing: testTime))")
}

/// Test the Matrix class.
///
func testMatrix() {

	var test = Matrix.identity * Matrix.identity
	print(test)
	test = Matrix.identity * Matrix.identity.transpose()
	print(Matrix.identity.transpose())
	print(test)
}

// Random Number filtering function.
func randomFilter(fraction: Double) -> Bool {
	let randomNumber = Double.random(in: 0.0 ... 1.0)
	return randomNumber < fraction
}


fileprivate func showObjects(_ time: AstroTime, _ bodies: [AstroBody]) {
	print("\n\(logTime()): Bodies processed with positions and distances at time \(time):")
	for body in bodies {
		print("\(logTime()): \(body.name) at \(body.position), distance \(body.position.length.format(2))",
			  terminator:"")
		print(", semimajor axis \(body.semimajorAxis.format(2))")
	}
}

fileprivate func showPluto(_ bodies: [AstroBody]) {
	bodies.forEach {
		if $0.name == "(134340) Pluto" {  // Search for Pluto's 'designation string'.
			let p = $0.position
			print("\(logTime()): Pluto's position: x=\(p.x.format(4)),y=\(p.y.format(4)),z=\(p.z.format(4))")
		}
	}
}

fileprivate func ramdonFilter(_ bodies: inout [AstroBody]) {
	print("\(logTime()): Run randomizing filter.")
	bodies = bodies.filter { _ in
		randomFilter(fraction: randomFilterFraction)
	}
	print("\(logTime()): There are \(bodies.count) randomized bodies.")
}

fileprivate func observationBias(_ bodies: [AstroBody]) {
	var lengthDiff = 0.0
	bodies.forEach {
		lengthDiff += $0.semimajorAxis - $0.position.length
	}
	print("\(logTime()): Value of lengthDiff is \(lengthDiff.format(3)).")
	print("\(logTime()): Average observation bias is \((lengthDiff/Double(bodies.count)).format(3)).")
}

// runDevelopmentTests runs left over development test function.
func runDevelopmentTests () {
	testAnomaly()  // Test anomaly computations.
	testTime()     // Test AstroTime class.
	testMatrix()   // Test Matrix multiplication.
}


func printWithLog(_ message: String) {

    print("\(logTime()): \(message)")
}
