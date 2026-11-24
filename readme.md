### Kuiper Nearest Neighbors

###### Inroduction

This project is written in Swift. It:

- Reads Data from the Minor Planet Center to get the list of objects in the Kuiper Belt, an area beyond the orbit of Neptune.
- Computes the heliocentric coordinates of each object at the time that the program is run.
- Implements a 3-dimensional KDTree data type to implement a binary search trees holding each object with their heliocentric coordinates.
- Uses the MPC Data and the KD3Tree data type to compute the average nearest neighbor distances of the Kuiper Belt objects.

###### Minor Planet Center

The Minor Planet Center, located in Boston, is part of the Center for Astrophysics. It is the worldwide clearing house for data on the minor planets of the Solar System. The MPC provides access to frequently updated files cataloging the minor planets. This project deals with Kuiper Belt objects which are listed in the MPC's [Distant.txt](https://www.minorplanetcenter.net/iau/MPCORB/Distant.txt) file.

###### Orbital Elements and Heliocentric Coordinates

Orbits are described using orbital elements, parameters which specify the size (*semimajor axis*), shape (*eccentricity*), and orientation (*inclination*, *longitude of ascending node*, *argument of periapsis*) of an orbit, and the *true anomaly* (angular location in orbit) of the object at one instant (*epoch*) of time. From these parameters it is possible to compute the location of a body at any point in time. The MPC file contains the orbital elements of the object as well as many other parameters.

Before nearest neighbor calculations can be made the orbital elements must be used to compute Cartesian coordinates of the objects. This project has functions to convert orbital elements to heliocentric coordinates at any point in time. Heliocentric coordinates are Cartesian coordinates whose origin is the sun, with x axis pointing toward the vernal equinox, y axis pointing 90 degrees counter clockwise in the earth's orbital plane from the x axis, and z axis pointing up from the Sun. The coordinates are measured in astronomical units (AUs), where an AU is the average distance between the Sun and Earth, 149,597,870.7 kilometers.

###### Anomalies and Kepler's Equation

An *anomaly* defines an object's location along its orbit. *True anomaly* is the body's actual angular position in its elliptical orbit, measured from perihelion (closest approach to the Sun). However, since orbital motion follow's Kepler's Second Law (equal areas in equal times) there is no algebraic equation that directly computes true anomaly. 

Instead, astronomers use two intermediate anomalies:

*Mean anomaly* (M) &mdash;the angular position of a hypothetical object moving at constant speed in a circular orbit with the same period.

*Eccentric anomaly* (E)&mdash;a geometric construct that bridges the mean and true anomalies.

These values are related by *Kepler’s Equation:*

`M = E - e *sin E`

where e is the eccentricity of the orbit.

This is a trancendental equation that must be solved numerically, normally by *Newton-Raphson* iteration, which converges rapidly for Solar System objects (4&ndash;6 iterations usually sufficient.)

Once E is determined, true anomaly is found using a simple formula. The AstroBody struct, found in AstroBody.swift has methods and functions for this and many other astronomical calculations.

###### KD3Tree Nodes, Generics and AstroBodies

A KD-Tree is a multidimensional binary tree. This project implements the KD3Tree, a KD-Tree with the three dimensions in Cartesian space. Each node in a KD3Tree has a few properties, including its three Cartesian coordinates and a String intended to uniquely identify it. The *Vector* data type implemented in this project (see `Vector.swift`) is used to hold position.

**KD3Nodes and the Positioned Protocol**



**Generic KD3Nodes: A Flexible Spatial Data Structure**



The *KD3Tree* implemented in this project is a three-dimensional k-d tree (KDTree) that efficiently organizes and queries objects in three-dimensional space. *KD3Nodes* form the building blocks of the trees. Each KD3Node:

- Stores a single object at a specific position in space.
- Tracks which axis (x, y, or z) is uses to partition space.
- Links to left and right child nodes, forming a binary tree structure.

Unlike a specialized KD-tree tailored to a specific type of object (e.g., astronomical bodies), KD3Node is designed as a generic Swift class, allowing it to store any type of object that conforms to the Positioned protocol. This flexibility makes KD3Trees widely reusable for in other domains.

###### The Positioned Protocol

To ensure that all objects stored in a KD3Tree have the necessary information the *Positioned* protocol is used.

```swift
public protocol Positioned {
    var name: String { get }  // Name or identifier of the object.
    var position: Vector { get }  // Position of the object in 3D space.
}
```

Objects stored in KD3Trees must conform to this protocol. Each object must have a String name (that should be unique), and position (a 3D Vector implemented in the software.)

Here's the start of the KD3Node declaration. It is parameterized by the *Object*  type that conforms to the *Positioned* protocol. The first field in KD3Node holds the Object. It must be a structure or class that conforms to the Positioned protocol.  KD3Node provides two computed properties, *name* and *position*, that are delegated to the Object.

```swift
class KD3Node<Object: Positioned> : CustomStringConvertible {
	let object: Object // Object this node holds.
	let axis: Int // Axis that splits the children.
	var left: KD3Node? // Left child.
	var right: KD3Node? // Right child.
	var name: String { object.name } // Name.
	var position: Vector { object.position } // Position.
	...
}
```

Here's the start of the KD3Tree declaration. It is also parameterized by the Object type because it contains the KD3Node at the root of the search tree.

```swift
public class KD3Tree<Object: Positioned> : CustomStringConvertible {
	private var root: KD3Node<Object>? // Root of tree.
    ...
}
```



###### **AstroBodies**

This Swift project uses *AstroBody* (see `AstroBody.swift`) structures to hold the Kuiper Belt objects. An AstroBody is created for each line in an MPC file. It is declared as:

```
public struct AstroBody: CustomStringConvertible, Positioned, Equatable, Hashable {...}
```

The AstroBody struct was conforms to the Positioned protocol and all KD3Trees and KD3Nodes in this project use AstroBody as the generic type.



