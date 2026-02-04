//
//  BallAndStick.swift
//  ProteinRibbon
//
//  Ball-and-stick molecular visualization.
//

import Foundation
import simd
import RealityKit

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

        /// Creates default ball-and-stick options
        public init(
            atomScale: Float = 0.3,
            bondRadius: Float = 0.15,
            sphereSegments: Int = 16,
            colorScheme: AtomColorScheme = .byElement,
            scale: Float = 0.01,
            bondTolerance: Float = 1.3,
            maxBondLength: Float = 2.0,
            backboneOnly: Bool = false,
            showHydrogens: Bool = false
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

/// Standard CPK (Corey-Pauling-Koltun) element colors
public struct ElementColors {
    public static let colors: [String: SIMD4<Float>] = [
        "H": SIMD4<Float>(1.0, 1.0, 1.0, 1.0),      // White
        "C": SIMD4<Float>(0.5, 0.5, 0.5, 1.0),      // Gray
        "N": SIMD4<Float>(0.2, 0.3, 1.0, 1.0),      // Blue
        "O": SIMD4<Float>(1.0, 0.2, 0.2, 1.0),      // Red
        "S": SIMD4<Float>(1.0, 1.0, 0.2, 1.0),      // Yellow
        "P": SIMD4<Float>(1.0, 0.5, 0.0, 1.0),      // Orange
        "F": SIMD4<Float>(0.3, 1.0, 0.3, 1.0),      // Light green
        "CL": SIMD4<Float>(0.2, 0.8, 0.2, 1.0),     // Green
        "BR": SIMD4<Float>(0.6, 0.2, 0.2, 1.0),     // Dark red
        "I": SIMD4<Float>(0.5, 0.0, 0.5, 1.0),      // Purple
        "FE": SIMD4<Float>(0.9, 0.5, 0.0, 1.0),     // Orange-brown
        "CA": SIMD4<Float>(0.5, 0.5, 0.5, 1.0),     // Gray
        "MG": SIMD4<Float>(0.0, 0.7, 0.0, 1.0),     // Green
        "ZN": SIMD4<Float>(0.5, 0.5, 0.7, 1.0),     // Blue-gray
        "NA": SIMD4<Float>(0.0, 0.0, 1.0, 1.0),     // Blue
        "K": SIMD4<Float>(0.5, 0.0, 0.5, 1.0),      // Purple
        "SE": SIMD4<Float>(1.0, 0.6, 0.0, 1.0)      // Orange
    ]

    /// Gets color for an element, returns default gray if not found
    public static func color(for element: String) -> SIMD4<Float> {
        return colors[element.uppercased()] ?? SIMD4<Float>(0.7, 0.7, 0.7, 1.0)
    }
}

// MARK: - Ball-and-Stick Builder

/// Builds ball-and-stick molecular geometry
public struct BallAndStickBuilder {

    /// Builds a ball-and-stick model from a PDB structure
    /// Returns a parent entity containing child entities grouped by color
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

        // Detect bonds
        let bonds = BondDetector.detectBonds(
            in: atoms,
            tolerance: options.bondTolerance,
            maxBondLength: options.maxBondLength
        )

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

        // Create entity for each color group
        for (color, atomGroup) in atomsByColor {
            let atomMesh = buildAtomSpheresForColor(
                atomGroup: atomGroup.map { $0.atom },
                color: color,
                options: options
            )

            if !atomMesh.positions.isEmpty {
                let entity = createColoredEntity(from: atomMesh, color: color, options: options, name: "Atoms")
                parent.addChild(entity)
            }
        }

        // Build bond cylinders (group by color pairs)
        let bondEntities = buildBondEntities(atoms: atoms, bonds: bonds, structure: structure, options: options)
        for entity in bondEntities {
            parent.addChild(entity)
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

    /// Builds spheres for a group of atoms with the same color
    private static func buildAtomSpheresForColor(
        atomGroup: [PDBAtom],
        color: SIMD4<Float>,
        options: ProteinRibbon.BallAndStickOptions
    ) -> MeshData {
        var mesh = MeshData()

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

            let midpoint = (atom1.position + atom2.position) * 0.5

            // Get colors for each atom
            let color1 = atomColor(for: atom1, structure: structure, options: options)
            let color2 = atomColor(for: atom2, structure: structure, options: options)

            // Round colors for grouping
            let roundedColor1 = roundColor(color1)
            let roundedColor2 = roundColor(color2)

            // First half-cylinder
            let cylinder1 = createCylinderMesh(
                start: atom1.position,
                end: midpoint,
                radius: options.bondRadius,
                color: roundedColor1,
                segments: options.sphereSegments
            )

            cylindersByColor[roundedColor1, default: MeshData()].append(cylinder1)

            // Second half-cylinder
            let cylinder2 = createCylinderMesh(
                start: midpoint,
                end: atom2.position,
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
        let radii: [String: Float] = [
            "H": 1.20,
            "C": 1.70,
            "N": 1.55,
            "O": 1.52,
            "S": 1.80,
            "P": 1.80,
            "F": 1.47,
            "CL": 1.75,
            "BR": 1.85,
            "I": 1.98
        ]
        return radii[element.uppercased()] ?? 1.70
    }

    /// Creates a sphere mesh
    private static func createSphereMesh(
        center: SIMD3<Float>,
        radius: Float,
        color: SIMD4<Float>,
        segments: Int
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
                alpha: CGFloat(color.w)
            )

            // Create material with the specific color
            var material = SimpleMaterial()
            material.color = .init(tint: platformColor)
            material.metallic = .init(floatLiteral: 0.0)
            material.roughness = .init(floatLiteral: 0.4)

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
