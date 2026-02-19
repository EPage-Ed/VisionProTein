//
//  BallAndStick.swift
//  ProteinRibbon
//
//  Ball-and-stick molecular visualization.
//

import Foundation
import PDBKit
import simd
import RealityKit
import UIKit

// MARK: - Ball-and-Stick Options

extension ProteinRibbon {
    /// Configuration options for ball-and-stick rendering
    public struct BallAndStickOptions {
        /// Scale factor for atom spheres
        public var atomScale: Float

        /// Radius of bond cylinders in Angstroms
        public var bondRadius: Float

        /// Number of segments for sphere and cylinder geometry
        public var sphereSegments: Int

        /// Color scheme for atoms
        public var colorScheme: AtomColorScheme

        /// Scale factor to convert Angstroms to scene units
        public var scale: Float

        /// Bond detection tolerance (1.3 = 130% of covalent radii sum)
        public var bondTolerance: Float

        /// Maximum bond length in Angstroms
        public var maxBondLength: Float

        /// Whether to show only backbone atoms (N, CA, C, O)
        public var backboneOnly: Bool

        /// Whether to show hydrogen atoms
        public var showHydrogens: Bool
      
      public var skipUNK: Bool

        /// Creates default ball-and-stick options
        public init(
            atomScale: Float = 0.3,
            bondRadius: Float = 0.15,
            sphereSegments: Int = 6, // 6 = ~80 triangles icosphere (subdivision level 1)
            colorScheme: AtomColorScheme = .byElement,
            scale: Float = 0.01,
            bondTolerance: Float = 1.3,
            maxBondLength: Float = 2.0,
            backboneOnly: Bool = false,
            showHydrogens: Bool = false,
            skipUNK: Bool = true
        ) {
            self.atomScale = atomScale
            self.bondRadius = bondRadius
            self.sphereSegments = sphereSegments
            self.colorScheme = colorScheme
            self.scale = scale
            self.bondTolerance = bondTolerance
            self.maxBondLength = maxBondLength
            self.backboneOnly = backboneOnly
            self.showHydrogens = showHydrogens
          self.skipUNK = skipUNK
        }
    }

    /// Atom coloring schemes
    public enum AtomColorScheme {
        /// Color by element (CPK coloring)
        case byElement

        /// Color by residue type
        case byResidueType

        /// Uniform color
        case uniform(SIMD4<Float>)

        /// Color by chain
        case byChain
    }
}

// MARK: - Element Colors

/// CPK element colors - delegates to PDBKit's CPKColors (single source of truth).
public struct ElementColors {
    public static var colors: [String: SIMD4<Float>] { CPKColors.colors }

    public static func color(for element: String) -> SIMD4<Float> {
        return CPKColors.color(for: element)
    }
}

// MARK: - Ball-and-Stick Builder

/// Builds ball-and-stick molecular geometry
public struct BallAndStickBuilder {

    /// Builds a ball-and-stick model from a PDB structure
    /// Returns a parent entity containing child entities grouped by color
    @available(visionOS 26.0, *)
    public static func buildEntity(
        from structure: PDBStructure,
        options: ProteinRibbon.BallAndStickOptions
    ) -> ModelEntity {
        // Filter atoms if needed
        var atoms = structure.atoms

        if options.backboneOnly {
            atoms = atoms.filter { atom in
                let name = atom.name.trimmingCharacters(in: .whitespaces)
                return ["N", "CA", "C", "O"].contains(name)
            }
        }

        if !options.showHydrogens {
            atoms = atoms.filter { $0.element.uppercased() != "H" }
        }

        guard !atoms.isEmpty else {
            return ModelEntity()
        }

      print("BallAndStickBuilder: Detecting bonds")
        // Detect bonds using simplified residue-aware detection
        let bonds = BondDetector.detectBondsSimplified(
            in: atoms,
            residues: structure.residues,
            tolerance: options.bondTolerance,
            maxBondLength: options.maxBondLength
        )
      print("BallAndStickBuilder: Found \(bonds.count) bonds")

        // Create parent entity
        let parent = ModelEntity()
        parent.name = "BallAndStick"

        // Group atoms by color for efficient rendering
        var atomsByColor: [SIMD4<Float>: [(atom: PDBAtom, index: Int)]] = [:]

        for (index, atom) in atoms.enumerated() {
            let color = atomColor(for: atom, structure: structure, options: options)
            let key = roundColor(color) // Round to avoid floating point issues
            atomsByColor[key, default: []].append((atom, index))
        }

      /*
      // Create entity for each color group
      for (color, atomGroup) in atomsByColor {
        let atoms = atomGroup.map { $0.atom }
        let atomMesh = buildAtomSpheresForColor(
          atomGroup: atoms,
          color: color,
          options: options
        )

        if !atomMesh.positions.isEmpty {
          let entity = createColoredEntity(from: atomMesh, color: color, options: options, name: "Atoms")
          parent.addChild(entity)
        }
      }
      */
      
      // Mesh Instancing
      for (color, atomGroup) in atomsByColor {
        let atomEntities = buildAtomSpheresWithInstancing(
          atomGroup: atomGroup.map { $0.atom },
          color: color,
          options: options
        )
        
        for entity in atomEntities {
          parent.addChild(entity)
        }
      }


        // Build bond cylinders using simplified gray bonds (much faster)
        if let bondEntity = buildSimplifiedBondEntity(atoms: atoms, bonds: bonds, options: options) {
            parent.addChild(bondEntity)
        }

        return parent
    }

    /// Rounds color components to avoid floating point key issues
    private static func roundColor(_ color: SIMD4<Float>) -> SIMD4<Float> {
        let precision: Float = 100.0
        return SIMD4<Float>(
            round(color.x * precision) / precision,
            round(color.y * precision) / precision,
            round(color.z * precision) / precision,
            round(color.w * precision) / precision
        )
    }

    /// Builds spheres for a group of atoms with the same color using instancing
    @available(visionOS 26.0, *)
    private static func buildAtomSpheresWithInstancing(
        atomGroup: [PDBAtom],
        color: SIMD4<Float>,
        options: ProteinRibbon.BallAndStickOptions
    ) -> [ModelEntity] {
        var entities: [ModelEntity] = []

        // Group atoms by element type for different radii
        let atomsByElement = Dictionary(grouping: atomGroup, by: { $0.element.uppercased() })

        for (element, atoms) in atomsByElement {
            let totalAtoms = atoms.count
            guard totalAtoms > 0 else { continue }

            // Get radius for this element
            let baseRadius = atomRadius(for: element)
            let scaledRadius = baseRadius * options.atomScale * options.scale

            print("[BallAndStick] Creating instanced sphere mesh for \(totalAtoms) \(element) atoms")

            // Create a single sphere mesh for this element type
//            let mesh = MeshResource.generateSphere(radius: scaledRadius)
          // Create low-poly mesh for this element type
          guard let mesh = try? generateLowPolySphere(radius: scaledRadius, segments: options.sphereSegments) else {
            print("[ProteinSpheresMesh] ERROR: Failed to generate low-poly sphere for \(element)")
            continue
          }

            // Split into chunks of 10,000 atoms
            let maxAtomsPerEntity = 10000
            let numChunks = (totalAtoms + maxAtomsPerEntity - 1) / maxAtomsPerEntity

            print("[BallAndStick] Splitting \(element) atoms into \(numChunks) chunk(s)")

            // Create material with element color - match ProteinSpheresMesh approach exactly
            let uiColor = UIColor(
                red: CGFloat(color.x),
                green: CGFloat(color.y),
                blue: CGFloat(color.z),
                alpha: CGFloat(color.w)
            )
            let material = SimpleMaterial(color: uiColor, isMetallic: false)

            for chunkIndex in 0..<numChunks {
                let startIndex = chunkIndex * maxAtomsPerEntity
                let endIndex = min(startIndex + maxAtomsPerEntity, totalAtoms)
                let count = endIndex - startIndex

                let chunkAtoms = Array(atoms[startIndex..<endIndex])

                // Create instance data for this chunk
                guard let instanceData = try? LowLevelInstanceData(instanceCount: count) else {
                    print("[BallAndStick] Failed to create instance data for \(count) atoms")
                    continue
                }

                instanceData.withMutableTransforms { transforms in
                    for i in 0..<count {
                        let atom = chunkAtoms[i]
                        let position = atom.position * options.scale
                        transforms[i] = Transform(scale: .one, rotation: simd_quatf(angle: 0, axis: [0,0,1]), translation: position).matrix
                    }
                }

                // Create entity with instances
                if let modelID = mesh.contents.models.first?.id {
                    let entity = ModelEntity()
                    if numChunks > 1 {
                        entity.name = "BallAndStick_\(element)_\(chunkIndex)"
                    } else {
                        entity.name = "BallAndStick_\(element)"
                    }
                    entity.model = ModelComponent(mesh: mesh, materials: [material])

                    // Create and set component
                    do {
                        let component = try MeshInstancesComponent(
                            mesh: mesh,
                            modelID: modelID,
                            instances: instanceData
                        )
                        entity.components[MeshInstancesComponent.self] = component
                        entities.append(entity)
                        print("[BallAndStick] Created chunk \(chunkIndex) with \(count) \(element) atoms")
                    } catch {
                        print("[BallAndStick] Failed to create MeshInstancesComponent for \(element) chunk \(chunkIndex): \(error)")
                    }
                } else {
                    print("[BallAndStick] No modelID found for \(element) mesh")
                }
            }
        }

        return entities
    }
  
  /// Generates an icosphere mesh with specified radius and subdivision level
  /// Icospheres provide better triangle distribution than UV spheres
  /// - Parameters:
  ///   - radius: Radius of the sphere
  ///   - segments: Controls subdivision level (4-16 typical, lower = fewer triangles)
  /// - Returns: MeshResource for the icosphere
  private static func generateLowPolySphere(radius: Float, segments: Int) throws -> MeshResource {
    // Map segments to subdivision levels
    // segments: 4->0, 6->1, 8->1, 12->2, 16->2
    let subdivisionLevel = max(0, min(2, (segments - 4) / 4))

    // Start with icosahedron (12 vertices, 20 faces)
    let t = Float((1.0 + sqrt(5.0)) / 2.0)
    var baseVertices: [SIMD3<Float>] = []
    baseVertices.append(SIMD3<Float>(-1,  t,  0))
    baseVertices.append(SIMD3<Float>( 1,  t,  0))
    baseVertices.append(SIMD3<Float>(-1, -t,  0))
    baseVertices.append(SIMD3<Float>( 1, -t,  0))
    baseVertices.append(SIMD3<Float>( 0, -1,  t))
    baseVertices.append(SIMD3<Float>( 0,  1,  t))
    baseVertices.append(SIMD3<Float>( 0, -1, -t))
    baseVertices.append(SIMD3<Float>( 0,  1, -t))
    baseVertices.append(SIMD3<Float>( t,  0, -1))
    baseVertices.append(SIMD3<Float>( t,  0,  1))
    baseVertices.append(SIMD3<Float>(-t,  0, -1))
    baseVertices.append(SIMD3<Float>(-t,  0,  1))
    baseVertices = baseVertices.map { simd_normalize($0) }

    let baseFaces: [[UInt32]] = [
      [0,11,5], [0,5,1], [0,1,7], [0,7,10], [0,10,11],
      [1,5,9], [5,11,4], [11,10,2], [10,7,6], [7,1,8],
      [3,9,4], [3,4,2], [3,2,6], [3,6,8], [3,8,9],
      [4,9,5], [2,4,11], [6,2,10], [8,6,7], [9,8,1]
    ]

    var positions = baseVertices
    var faces = baseFaces

    // Subdivide
    for _ in 0..<subdivisionLevel {
      var newFaces: [[UInt32]] = []
      var midpointCache: [String: UInt32] = [:]

      for face in faces {
        let v1 = face[0], v2 = face[1], v3 = face[2]

        // Get midpoint indices (with caching to avoid duplicates)
        let m12 = getMidpoint(v1, v2, &positions, &midpointCache)
        let m23 = getMidpoint(v2, v3, &positions, &midpointCache)
        let m31 = getMidpoint(v3, v1, &positions, &midpointCache)

        // Create 4 new triangles
        newFaces.append([v1, m12, m31])
        newFaces.append([v2, m23, m12])
        newFaces.append([v3, m31, m23])
        newFaces.append([m12, m23, m31])
      }

      faces = newFaces
    }

    // Scale to radius and compute normals
    let scaledPositions = positions.map { $0 * radius }
    let normals = positions // Normals are the same as normalized positions for a sphere

    // Flatten faces to indices
    let indices = faces.flatMap { $0 }

    print("[ProteinRibbon] Icosphere: \(positions.count) vertices, \(faces.count) triangles (subdivision level \(subdivisionLevel))")

    var descriptor = MeshDescriptor()
    descriptor.positions = MeshBuffer(scaledPositions)
    descriptor.normals = MeshBuffer(normals)
    descriptor.primitives = .triangles(indices)

    return try MeshResource.generate(from: [descriptor])
  }

  /// Helper to get or create midpoint between two vertices
  private static func getMidpoint(
    _ v1: UInt32,
    _ v2: UInt32,
    _ positions: inout [SIMD3<Float>],
    _ cache: inout [String: UInt32]
  ) -> UInt32 {
    let key = v1 < v2 ? "\(v1)-\(v2)" : "\(v2)-\(v1)"

    if let cached = cache[key] {
      return cached
    }

    let p1 = positions[Int(v1)]
    let p2 = positions[Int(v2)]
    let midpoint = simd_normalize((p1 + p2) * 0.5)

    let index = UInt32(positions.count)
    positions.append(midpoint)
    cache[key] = index

    return index
  }


  /// Builds spheres for a group of atoms with the same color
  private static func buildAtomSpheresForColor(
    atomGroup: [PDBAtom],
    color: SIMD4<Float>,
    options: ProteinRibbon.BallAndStickOptions
  ) -> MeshData {
    var mesh = MeshData()
    
    print("[BallAndStickBuilder] Building sphere MeshData for atom group \(atomGroup[0].name) with \(atomGroup.count) atoms")
    for atom in atomGroup {
      // Determine atom radius based on element
      let baseRadius = atomRadius(for: atom.element)
      let radius = baseRadius * options.atomScale
      
      // Create sphere mesh
      let sphereMesh = createSphereMesh(
        center: atom.position,
        radius: radius,
        color: color,
        segments: options.sphereSegments
      )
      
      mesh.append(sphereMesh)
    }
    
    return mesh
  }

  /// Builds all bonds as a single gray mesh (optimized for performance)
    private static func buildSimplifiedBondEntity(
        atoms: [PDBAtom],
        bonds: [Bond],
        options: ProteinRibbon.BallAndStickOptions
    ) -> ModelEntity? {
        guard !bonds.isEmpty else { return nil }

        print("[BallAndStick] Building simplified bonds: \(bonds.count) bonds")

        var mesh = MeshData()
        let grayColor = SIMD4<Float>(0.5, 0.5, 0.5, 1.0) // Uniform gray color

        // Use fewer segments for cylinders (4-6 is enough for small radius bonds)
        let cylinderSegments = max(4, options.sphereSegments / 2)

        for bond in bonds {
            guard bond.atom1 < atoms.count && bond.atom2 < atoms.count else { continue }

            let atom1 = atoms[bond.atom1]
            let atom2 = atoms[bond.atom2]

            // Adjust bond endpoints to account for atom radii
            let atom1Radius = atomRadius(for: atom1.element) * options.atomScale
            let atom2Radius = atomRadius(for: atom2.element) * options.atomScale

            let direction = simd_normalize(atom2.position - atom1.position)
            let adjustedStart = atom1.position + direction * atom1Radius
            let adjustedEnd = atom2.position - direction * atom2Radius

            // Create single cylinder for entire bond (not split by color)
            let cylinder = createCylinderMesh(
                start: adjustedStart,
                end: adjustedEnd,
                radius: options.bondRadius,
                color: grayColor,
                segments: cylinderSegments
            )

            mesh.append(cylinder)
        }

        guard !mesh.positions.isEmpty else { return nil }

        print("[BallAndStick] Created bond mesh: \(mesh.positions.count) vertices")

        return createColoredEntity(from: mesh, color: grayColor, options: options, name: "Bonds_Simplified")
    }

  /// Builds bond entities grouped by color
    private static func buildBondEntities(
        atoms: [PDBAtom],
        bonds: [Bond],
        structure: PDBStructure,
        options: ProteinRibbon.BallAndStickOptions
    ) -> [ModelEntity] {
        var entities: [ModelEntity] = []

        // Group bond halves by color
        var cylindersByColor: [SIMD4<Float>: MeshData] = [:]

        for bond in bonds {
            guard bond.atom1 < atoms.count && bond.atom2 < atoms.count else { continue }

            let atom1 = atoms[bond.atom1]
            let atom2 = atoms[bond.atom2]

          let atom1Radius = atomRadius(for: atom1.element) * options.atomScale
          let atom2Radius = atomRadius(for: atom2.element) * options.atomScale
          
          let direction = simd_normalize(atom2.position - atom1.position)
          let adjustedStart = atom1.position + direction * atom1Radius
          let adjustedEnd = atom2.position - direction * atom2Radius
          let midpoint = (adjustedStart + adjustedEnd) * 0.5
//          let midpoint = (atom1.position + atom2.position) * 0.5

            // Get colors for each atom
            let color1 = atomColor(for: atom1, structure: structure, options: options)
            let color2 = atomColor(for: atom2, structure: structure, options: options)

            // Round colors for grouping
            let roundedColor1 = roundColor(color1)
            let roundedColor2 = roundColor(color2)

            // First half-cylinder
            let cylinder1 = createCylinderMesh(
                start: adjustedStart, // atom1.position,
                end: midpoint,
                radius: options.bondRadius,
                color: roundedColor1,
                segments: options.sphereSegments
            )

            cylindersByColor[roundedColor1, default: MeshData()].append(cylinder1)

            // Second half-cylinder
            let cylinder2 = createCylinderMesh(
                start: midpoint,
                end: adjustedEnd, // atom2.position,
                radius: options.bondRadius,
                color: roundedColor2,
                segments: options.sphereSegments
            )

            cylindersByColor[roundedColor2, default: MeshData()].append(cylinder2)
        }

        // Create entity for each color group
        for (color, mesh) in cylindersByColor {
            if !mesh.positions.isEmpty {
                let entity = createColoredEntity(from: mesh, color: color, options: options, name: "Bonds")
                entities.append(entity)
            }
        }

        return entities
    }

    /// Gets color for an atom based on color scheme
    private static func atomColor(
        for atom: PDBAtom,
        structure: PDBStructure,
        options: ProteinRibbon.BallAndStickOptions
    ) -> SIMD4<Float> {
        switch options.colorScheme {
        case .byElement:
            return ElementColors.color(for: atom.element)

        case .byResidueType:
            // Find residue for this atom
            if let residue = structure.residues.first(where: { res in
                res.atoms.contains(where: { $0.serial == atom.serial })
            }) {
                let type = AminoAcid.type(for: residue.name)
                return ColorSchemes.colorForResidueType(type)
            }
            return SIMD4<Float>(0.7, 0.7, 0.7, 1.0)

        case .uniform(let color):
            return color

        case .byChain:
            // Use chain-based coloring
            let chainIndex = structure.chains.firstIndex(of: atom.chainID) ?? 0
            return ColorSchemes.chainColors[chainIndex % ColorSchemes.chainColors.count]
        }
    }

    /// Gets van der Waals radius for an element (in Angstroms)
    private static func atomRadius(for element: String) -> Float {
        return VanDerWaalsRadii.radius(for: element)
    }

    /// Creates a sphere mesh
    private static func createSphereMesh(
        center: SIMD3<Float>,
        radius: Float,
        color: SIMD4<Float>,
        segments: Int,
        residueName: String? = nil,
        residueIndex: Int? = nil
    ) -> MeshData {
        var mesh = MeshData()

        let rings = segments
        let sectors = segments * 2

        // Generate sphere vertices using spherical coordinates
        for i in 0...rings {
            let theta = Float(i) / Float(rings) * Float.pi  // 0 to π
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)

            for j in 0...sectors {
                let phi = Float(j) / Float(sectors) * 2.0 * Float.pi  // 0 to 2π
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)

                // Vertex position
                let x = radius * sinTheta * cosPhi
                let y = radius * cosTheta
                let z = radius * sinTheta * sinPhi

                let position = center + SIMD3<Float>(x, y, z)
                let normal = simd_normalize(SIMD3<Float>(x, y, z))

                mesh.positions.append(position)
                mesh.normals.append(normal)
                mesh.colors.append(color)
            }
        }

        // Generate sphere indices
        for i in 0..<rings {
            for j in 0..<sectors {
                let first = UInt32(i * (sectors + 1) + j)
                let second = first + UInt32(sectors + 1)

                // Two triangles per quad
                mesh.indices.append(contentsOf: [first, second, first + 1])
                mesh.indices.append(contentsOf: [second, second + 1, first + 1])
            }
        }

        return mesh
    }

    /// Creates a cylinder mesh between two points
    private static func createCylinderMesh(
        start: SIMD3<Float>,
        end: SIMD3<Float>,
        radius: Float,
        color: SIMD4<Float>,
        segments: Int
    ) -> MeshData {
        var mesh = MeshData()

        let direction = end - start
        let length = simd_length(direction)

        guard length > 0.001 else { return mesh }

        let axis = simd_normalize(direction)

        // Create a perpendicular vector for the cylinder
        let up = abs(axis.y) < 0.9 ? SIMD3<Float>(0, 1, 0) : SIMD3<Float>(1, 0, 0)
        let right = simd_normalize(simd_cross(axis, up))
        let forward = simd_normalize(simd_cross(right, axis))

        // Generate cylinder vertices
        for i in 0...1 {
            let position = i == 0 ? start : end

            for j in 0..<segments {
                let angle = Float(j) / Float(segments) * 2.0 * Float.pi
                let x = radius * cos(angle)
                let z = radius * sin(angle)

                let offset = x * right + z * forward
                let vertex = position + offset
                let normal = simd_normalize(offset)

                mesh.positions.append(vertex)
                mesh.normals.append(normal)
                mesh.colors.append(color)
            }
        }

        // Generate cylinder indices (side faces)
        for j in 0..<segments {
            let j1 = (j + 1) % segments

            let baseIdx = UInt32(0)
            let i0j0 = baseIdx + UInt32(j)
            let i0j1 = baseIdx + UInt32(j1)
            let i1j0 = baseIdx + UInt32(segments + j)
            let i1j1 = baseIdx + UInt32(segments + j1)

            // Two triangles per quad
            mesh.indices.append(contentsOf: [i0j0, i1j0, i0j1])
            mesh.indices.append(contentsOf: [i1j0, i1j1, i0j1])
        }

        return mesh
    }

    /// Creates a colored entity from mesh data with proper material
    private static func createColoredEntity(
        from meshData: MeshData,
        color: SIMD4<Float>,
        options: ProteinRibbon.BallAndStickOptions,
        name: String
    ) -> ModelEntity {
        guard !meshData.positions.isEmpty else {
            return ModelEntity()
        }

        do {
            // Scale mesh
            var scaledMesh = meshData
            scaledMesh.positions = meshData.positions.map { $0 * options.scale }

            // Create mesh resource
            let meshResource = try scaledMesh.toMeshResource()

            // Convert color to platform color
            let platformColor = PlatformColor(
                red: CGFloat(color.x),
                green: CGFloat(color.y),
                blue: CGFloat(color.z),
                alpha: CGFloat(1.0)
//                alpha: CGFloat(color.w)
            )

          /*
            // Create material with the specific color
            var material = SimpleMaterial()
            material.color = .init(tint: platformColor)
            material.metallic = .init(floatLiteral: 0.0)
            material.roughness = .init(floatLiteral: 0.4)
           */

          // Use PhysicallyBasedMaterial for better control
          var material = PhysicallyBasedMaterial()
          material.baseColor = .init(tint: platformColor)
          material.metallic = 0.0
          material.roughness = 0.4
          material.faceCulling = .back  // Cull back faces for better performance

            // Create entity
            let entity = ModelEntity(mesh: meshResource, materials: [material])
            entity.name = name

            return entity

        } catch {
            print("ProteinRibbon: Failed to create ball-and-stick mesh - \(error)")
            return ModelEntity()
        }
    }
}
