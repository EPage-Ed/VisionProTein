//
//  ProteinSpheresMesh.swift
//  ProteinSpheresMesh
//
//  Sphere representation of proteins using mesh instancing.
//  One mesh per atom type (element) for efficient rendering.
//

import Foundation
import RealityKit
import UIKit
import simd
import PDBKit  // For PDBStructure type

// MARK: - Public API

public struct ProteinSpheresMesh {
    
    /// Configuration options for sphere rendering
    public struct Options {
        /// Scale factor for atom spheres (1.0 = van der Waals radius)
        public var atomScale: Float
        
        /// Number of segments for sphere geometry quality
        public var sphereSegments: Int
        
        /// Color scheme for atoms
        public var colorScheme: AtomColorScheme
        
        /// Scale factor to convert PDB Angstroms to scene units
        public var scale: Float
        
        /// Whether to show hydrogen atoms
        public var showHydrogens: Bool
        
        /// Creates default sphere options
        public init(
            atomScale: Float = 1.0,
            sphereSegments: Int = 8,
            colorScheme: AtomColorScheme = .byElement,
            scale: Float = 0.01,
            showHydrogens: Bool = false
        ) {
            self.atomScale = atomScale
            self.sphereSegments = sphereSegments
            self.colorScheme = colorScheme
            self.scale = scale
            self.showHydrogens = showHydrogens
        }
    }
    
    /// Atom coloring schemes
    public enum AtomColorScheme {
        /// Color by element (CPK coloring)
        case byElement
        
        /// Uniform color
        case uniform(SIMD4<Float>)
        
        /// Color by chain
        case byChain
    }
    
    /// Creates a sphere representation entity with CPK element coloring from a pre-parsed structure
    public static func spheresCPK(from structure: PDBStructure, scale: Float = 1.0) -> ModelEntity {
        return spheresEntity(from: structure, options: Options(atomScale: scale, colorScheme: .byElement))
    }

    /// Creates a sphere representation entity with larger atoms from a pre-parsed structure
    public static func spheresLarge(from structure: PDBStructure) -> ModelEntity {
        return spheresEntity(
            from: structure,
            options: Options(
                atomScale: 1.5,
                colorScheme: .byElement
            )
        )
    }

    /// Creates a sphere representation entity with custom options from a pre-parsed structure
    public static func spheresEntity(from structure: PDBStructure, options: Options) -> ModelEntity {
        return SpheresBuilder.buildEntity(from: structure, options: options)
    }

    // MARK: - OLD API (backwards compatibility)

    /// OLD: Creates a sphere representation entity with CPK element coloring
    /// This method is kept for backwards compatibility but parses the PDB string each time.
    /// For better performance, use parseComplete() and pass the PDBStructure directly.
    /*
    public static func spheresCPK(from pdbString: String, scale: Float = 1.0) -> ModelEntity {
        let structure = PDBParser.parse(pdbString)
        return spheresCPK(from: structure, scale: scale)
    }

    /// OLD: Creates a sphere representation entity with larger atoms
    public static func spheresLarge(from pdbString: String) -> ModelEntity {
        let structure = PDBParser.parse(pdbString)
        return spheresLarge(from: structure)
    }

    /// OLD: Creates a sphere representation entity with custom options
    public static func spheresEntity(from pdbString: String, options: Options) -> ModelEntity {
        let structure = PDBParser.parse(pdbString)
        return spheresEntity(from: structure, options: options)
    }
     */
}

// MARK: - Element Colors

/// Standard CPK (Corey-Pauling-Koltun) element colors
public struct ElementColors {
    public static let colors: [String: SIMD4<Float>] = [
        "H":  SIMD4<Float>(1.000, 1.000, 1.000, 1.0), // White
        "HE": SIMD4<Float>(0.851, 1.000, 1.000, 1.0),
        "LI": SIMD4<Float>(0.800, 0.502, 1.000, 1.0),
        "BE": SIMD4<Float>(0.761, 1.000, 0.000, 1.0),
        "B":  SIMD4<Float>(1.000, 0.710, 0.710, 1.0),
        "C":  SIMD4<Float>(0.565, 0.565, 0.565, 1.0), // Gray
        "N":  SIMD4<Float>(0.188, 0.314, 0.973, 1.0), // Blue
        "O":  SIMD4<Float>(1.000, 0.051, 0.051, 1.0), // Red
        "F":  SIMD4<Float>(0.565, 0.878, 0.314, 1.0),
        "NE": SIMD4<Float>(0.702, 0.890, 0.961, 1.0),
        "NA": SIMD4<Float>(0.671, 0.361, 0.949, 1.0),
        "MG": SIMD4<Float>(0.541, 1.000, 0.000, 1.0),
        "AL": SIMD4<Float>(0.749, 0.651, 0.651, 1.0),
        "SI": SIMD4<Float>(0.941, 0.784, 0.627, 1.0),
        "P":  SIMD4<Float>(1.000, 0.502, 0.000, 1.0), // Orange
        "S":  SIMD4<Float>(1.000, 1.000, 0.188, 1.0), // Yellow
        "CL": SIMD4<Float>(0.122, 0.941, 0.122, 1.0),
        "AR": SIMD4<Float>(0.502, 0.820, 0.890, 1.0),
        "K":  SIMD4<Float>(0.561, 0.251, 0.831, 1.0),
        "CA": SIMD4<Float>(0.239, 1.000, 0.000, 1.0),
        "SC": SIMD4<Float>(0.902, 0.902, 0.902, 1.0),
        "TI": SIMD4<Float>(0.749, 0.761, 0.780, 1.0),
        "V":  SIMD4<Float>(0.651, 0.651, 0.671, 1.0),
        "CR": SIMD4<Float>(0.541, 0.600, 0.780, 1.0),
        "MN": SIMD4<Float>(0.612, 0.478, 0.780, 1.0),
        "FE": SIMD4<Float>(0.878, 0.400, 0.200, 1.0),
        "CO": SIMD4<Float>(0.941, 0.565, 0.627, 1.0),
        "NI": SIMD4<Float>(0.314, 0.816, 0.314, 1.0),
        "CU": SIMD4<Float>(0.784, 0.502, 0.200, 1.0),
        "ZN": SIMD4<Float>(0.490, 0.502, 0.690, 1.0),
        "GA": SIMD4<Float>(0.761, 0.561, 0.561, 1.0),
        "GE": SIMD4<Float>(0.400, 0.561, 0.561, 1.0),
        "AS": SIMD4<Float>(0.741, 0.502, 0.890, 1.0),
        "SE": SIMD4<Float>(1.000, 0.631, 0.000, 1.0),
        "BR": SIMD4<Float>(0.651, 0.161, 0.161, 1.0),
        "KR": SIMD4<Float>(0.361, 0.722, 0.820, 1.0),
        "RB": SIMD4<Float>(0.439, 0.180, 0.690, 1.0),
        "SR": SIMD4<Float>(0.000, 1.000, 0.000, 1.0),
        "Y":  SIMD4<Float>(0.580, 1.000, 1.000, 1.0),
        "ZR": SIMD4<Float>(0.580, 0.878, 0.878, 1.0),
        "NB": SIMD4<Float>(0.451, 0.761, 0.788, 1.0),
        "MO": SIMD4<Float>(0.329, 0.710, 0.710, 1.0),
        "TC": SIMD4<Float>(0.231, 0.620, 0.620, 1.0),
        "RU": SIMD4<Float>(0.141, 0.561, 0.561, 1.0),
        "RH": SIMD4<Float>(0.039, 0.490, 0.549, 1.0),
        "PD": SIMD4<Float>(0.000, 0.412, 0.522, 1.0),
        "AG": SIMD4<Float>(0.753, 0.753, 0.753, 1.0),
        "CD": SIMD4<Float>(1.000, 0.851, 0.561, 1.0),
        "IN": SIMD4<Float>(0.651, 0.459, 0.451, 1.0),
        "SN": SIMD4<Float>(0.400, 0.502, 0.502, 1.0),
        "SB": SIMD4<Float>(0.620, 0.388, 0.710, 1.0),
        "TE": SIMD4<Float>(0.831, 0.478, 0.000, 1.0),
        "I":  SIMD4<Float>(0.580, 0.000, 0.580, 1.0),
        "XE": SIMD4<Float>(0.259, 0.620, 0.690, 1.0),
        "CS": SIMD4<Float>(0.341, 0.090, 0.561, 1.0),
        "BA": SIMD4<Float>(0.000, 0.788, 0.000, 1.0),
        "LA": SIMD4<Float>(0.439, 0.831, 1.000, 1.0),
        "CE": SIMD4<Float>(1.000, 1.000, 0.780, 1.0),
        "PR": SIMD4<Float>(0.851, 1.000, 0.780, 1.0),
        "ND": SIMD4<Float>(0.780, 1.000, 0.780, 1.0),
        "PM": SIMD4<Float>(0.639, 1.000, 0.780, 1.0),
        "SM": SIMD4<Float>(0.561, 1.000, 0.780, 1.0),
        "EU": SIMD4<Float>(0.380, 1.000, 0.780, 1.0),
        "GD": SIMD4<Float>(0.271, 1.000, 0.780, 1.0),
        "TB": SIMD4<Float>(0.188, 1.000, 0.780, 1.0),
        "DY": SIMD4<Float>(0.122, 1.000, 0.780, 1.0),
        "HO": SIMD4<Float>(0.000, 1.000, 0.612, 1.0),
        "ER": SIMD4<Float>(0.000, 0.902, 0.459, 1.0),
        "TM": SIMD4<Float>(0.000, 0.831, 0.322, 1.0),
        "YB": SIMD4<Float>(0.000, 0.749, 0.220, 1.0),
        "LU": SIMD4<Float>(0.000, 0.671, 0.141, 1.0),
        "HF": SIMD4<Float>(0.302, 0.761, 1.000, 1.0),
        "TA": SIMD4<Float>(0.302, 0.651, 1.000, 1.0),
        "W":  SIMD4<Float>(0.129, 0.580, 0.839, 1.0),
        "RE": SIMD4<Float>(0.149, 0.490, 0.671, 1.0),
        "OS": SIMD4<Float>(0.149, 0.400, 0.588, 1.0),
        "IR": SIMD4<Float>(0.090, 0.329, 0.529, 1.0),
        "PT": SIMD4<Float>(0.816, 0.816, 0.878, 1.0),
        "AU": SIMD4<Float>(1.000, 0.820, 0.137, 1.0),
        "HG": SIMD4<Float>(0.722, 0.722, 0.816, 1.0),
        "TL": SIMD4<Float>(0.651, 0.329, 0.302, 1.0),
        "PB": SIMD4<Float>(0.341, 0.349, 0.380, 1.0),
        "BI": SIMD4<Float>(0.620, 0.310, 0.710, 1.0),
        "PO": SIMD4<Float>(0.671, 0.361, 0.000, 1.0),
        "AT": SIMD4<Float>(0.459, 0.310, 0.271, 1.0),
        "RN": SIMD4<Float>(0.259, 0.510, 0.588, 1.0),
        "FR": SIMD4<Float>(0.259, 0.000, 0.400, 1.0),
        "RA": SIMD4<Float>(0.000, 0.490, 0.000, 1.0),
        "AC": SIMD4<Float>(0.439, 0.671, 0.980, 1.0),
        "TH": SIMD4<Float>(0.000, 0.729, 1.000, 1.0),
        "PA": SIMD4<Float>(0.000, 0.631, 1.000, 1.0),
        "U":  SIMD4<Float>(0.000, 0.561, 1.000, 1.0),
        "NP": SIMD4<Float>(0.000, 0.502, 1.000, 1.0),
        "PU": SIMD4<Float>(0.000, 0.420, 1.000, 1.0),
        "AM": SIMD4<Float>(0.329, 0.361, 0.949, 1.0),
        "CM": SIMD4<Float>(0.471, 0.361, 0.890, 1.0),
        "BK": SIMD4<Float>(0.541, 0.310, 0.890, 1.0),
        "CF": SIMD4<Float>(0.631, 0.212, 0.831, 1.0),
        "ES": SIMD4<Float>(0.702, 0.122, 0.831, 1.0),
        "FM": SIMD4<Float>(0.702, 0.122, 0.729, 1.0),
        "MD": SIMD4<Float>(0.702, 0.051, 0.651, 1.0),
        "NO": SIMD4<Float>(0.741, 0.051, 0.529, 1.0),
        "LR": SIMD4<Float>(0.780, 0.000, 0.400, 1.0),
        "RF": SIMD4<Float>(0.800, 0.000, 0.349, 1.0),
        "DB": SIMD4<Float>(0.820, 0.000, 0.310, 1.0),
        "SG": SIMD4<Float>(0.851, 0.000, 0.271, 1.0),
        "BH": SIMD4<Float>(0.878, 0.000, 0.220, 1.0),
        "HS": SIMD4<Float>(0.902, 0.000, 0.180, 1.0),
        "MT": SIMD4<Float>(0.922, 0.000, 0.149, 1.0),
    ]
    
    /// Gets color for an element, returns default gray if not found
    public static func color(for element: String) -> SIMD4<Float> {
        return colors[element.uppercased()] ?? SIMD4<Float>(0.7, 0.7, 0.7, 1.0)
    }
}

// MARK: - Van der Waals Radii

/// Van der Waals radii for elements in Angstroms
public struct VanDerWaalsRadii {
    public static let radii: [String: Float] = [
        "H": 1.20,
        "C": 1.70,
        "N": 1.55,
        "O": 1.52,
        "S": 1.80,
        "P": 1.80,
        "F": 1.47,
        "CL": 1.75,
        "BR": 1.85,
        "I": 1.98,
        "FE": 2.00,
        "CA": 2.31,
        "MG": 1.73,
        "ZN": 1.39,
        "NA": 2.27,
        "K": 2.75,
        "SE": 1.90
    ]
    
    /// Gets van der Waals radius for an element, returns 1.7 (carbon) if not found
    public static func radius(for element: String) -> Float {
        return radii[element.uppercased()] ?? 1.70
    }
}

// MARK: - Spheres Builder

/// Builds sphere molecular geometry using mesh instancing
struct SpheresBuilder {
    
    /// Builds a sphere model from a PDB structure
    /// Returns a parent entity containing child entities for each element type
    static func buildEntity(
        from structure: PDBStructure,
        options: ProteinSpheresMesh.Options
    ) -> ModelEntity {
        // Filter atoms if needed
        var atoms = structure.atoms
        
        print("[ProteinSpheresMesh] Total atoms parsed: \(atoms.count)")
        print("[Memory] Starting sphere build - Estimated memory: \(atoms.count * 12) bytes for positions")
        
        if !options.showHydrogens {
            atoms = atoms.filter { $0.element.uppercased() != "H" }
        }
        
        print("[ProteinSpheresMesh] Atoms after hydrogen filter: \(atoms.count)")
        
        guard !atoms.isEmpty else {
            print("[ProteinSpheresMesh] WARNING: No atoms to render!")
            return ModelEntity()
        }
        
        // Create parent entity
        let parent = ModelEntity()
        parent.name = "Spheres"
        print("[Memory] Created parent entity")
        
        // Group atoms by element for efficient instancing
        let atomsByElement = Dictionary(grouping: atoms, by: { $0.element.uppercased() })
        
        print("[ProteinSpheresMesh] Atoms grouped by element:")
        for (element, elementAtoms) in atomsByElement.sorted(by: { $0.key < $1.key }) {
            print("  \(element): \(elementAtoms.count) atoms")
        }
        
        // Create one or more entities per element type
        // Split into chunks of 10,000 atoms if needed
        for (element, elementAtoms) in atomsByElement {
            guard !elementAtoms.isEmpty else { continue }
            
            let color = atomColor(for: elementAtoms[0], structure: structure, options: options)
            let baseRadius = VanDerWaalsRadii.radius(for: element)
            let radius = baseRadius * options.atomScale * options.scale
            
            print("[ProteinSpheresMesh] Creating spheres for element \(element):")
            print("  Count: \(elementAtoms.count)")
            print("  Color: RGB(\(color.x), \(color.y), \(color.z)) Alpha: \(color.w)")
            print("  Base radius: \(baseRadius)Å, Scaled radius: \(radius)")
            
            // Create low-poly mesh for this element type
            guard let mesh = try? generateLowPolySphere(radius: radius, segments: options.sphereSegments) else {
                print("[ProteinSpheresMesh] ERROR: Failed to generate low-poly sphere for \(element)")
                continue
            }
            
            // Create material with element color
            let uiColor = UIColor(
                red: CGFloat(color.x),
                green: CGFloat(color.y),
                blue: CGFloat(color.z),
                alpha: CGFloat(color.w)
            )
            let material = SimpleMaterial(color: uiColor, isMetallic: false)
            
            // Split into chunks of 10,000 if needed
            let maxAtomsPerEntity = 10000
            let totalAtoms = elementAtoms.count
            let numChunks = (totalAtoms + maxAtomsPerEntity - 1) / maxAtomsPerEntity
            
            if numChunks > 1 {
                print("[ProteinSpheresMesh] Splitting \(totalAtoms) \(element) atoms into \(numChunks) chunks of max \(maxAtomsPerEntity)")
            }
            
            for chunkIndex in 0..<numChunks {
                let startIndex = chunkIndex * maxAtomsPerEntity
                let endIndex = min(startIndex + maxAtomsPerEntity, totalAtoms)
                let chunkAtoms = Array(elementAtoms[startIndex..<endIndex])
                let count = chunkAtoms.count
                
                print("[ProteinSpheresMesh] Processing chunk \(chunkIndex + 1)/\(numChunks) with \(count) atoms")
                print("[Memory] Chunk \(chunkIndex): Allocating \(count * 64) bytes for instance transforms")
                
                // Create instancing data for this chunk
                guard let instanceData = try? LowLevelInstanceData(instanceCount: count) else {
                    print("[ProteinSpheresMesh] ERROR: Failed to create instance data for chunk \(chunkIndex)")
                    print("[Memory] ERROR: Instance data allocation failed - possible out of memory")
                    continue
                }
                
                instanceData.withMutableTransforms { transforms in
                    for i in 0..<count {
                        let atom = chunkAtoms[i]
                        // Scale positions from Angstroms to scene units
                        let position = atom.position * options.scale
                        let transform = Transform(
                            scale: .one,
                            rotation: simd_quatf(angle: 0, axis: [0, 0, 1]),
                            translation: position
                        )
                        transforms[i] = transform.matrix
                    }
                }
                
                // Create entity with instances
                if let modelID = mesh.contents.models.first?.id {
                    let entity = ModelEntity()
                    // Add chunk suffix if there are multiple chunks
                    if numChunks > 1 {
                        entity.name = "Spheres_\(element)_\(chunkIndex)"
                    } else {
                        entity.name = "Spheres_\(element)"
                    }
                    entity.model = ModelComponent(mesh: mesh, materials: [material])
                    
                    // Create and set component with nonisolated context
                    do {
                        let component = try MeshInstancesComponent(
                            mesh: mesh,
                            modelID: modelID,
                            instances: instanceData
                        )
                        entity.components[MeshInstancesComponent.self] = component
                        print("[ProteinSpheresMesh] Successfully created instanced entity for \(element) chunk \(chunkIndex)")
                        print("[Memory] Entity created - Total children in parent: \(parent.children.count + 1)")
                    } catch {
                        print("[ProteinSpheresMesh] ERROR: Failed to create MeshInstancesComponent for \(element) chunk \(chunkIndex): \(error)")
                        print("[Memory] ERROR: MeshInstancesComponent creation failed - possible resource limit")
                    }
                    
                    parent.addChild(entity)
                    print("[ProteinSpheresMesh] Added \(element) chunk \(chunkIndex) entity to parent")
                } else {
                    print("[ProteinSpheresMesh] ERROR: No modelID found for \(element) mesh")
                }
            }
        }
        
        print("[Memory] Sphere build complete - Total entities: \(parent.children.count)")
        return parent
    }
    
    /// Gets color for an atom based on color scheme
    private static func atomColor(
        for atom: PDBAtom,
        structure: PDBStructure,
        options: ProteinSpheresMesh.Options
    ) -> SIMD4<Float> {
        switch options.colorScheme {
        case .byElement:
            return ElementColors.color(for: atom.element)
        case .uniform(let color):
            return color
        case .byChain:
            return chainColor(for: atom.chainID)
        }
    }
    
    /// Gets color for a chain
    private static func chainColor(for chainID: String) -> SIMD4<Float> {
        let chainColors: [SIMD4<Float>] = [
            SIMD4<Float>(0.2, 0.6, 1.0, 1.0),  // Blue
            SIMD4<Float>(1.0, 0.4, 0.2, 1.0),  // Orange
            SIMD4<Float>(0.2, 1.0, 0.4, 1.0),  // Green
            SIMD4<Float>(1.0, 0.2, 0.8, 1.0),  // Magenta
            SIMD4<Float>(1.0, 1.0, 0.2, 1.0),  // Yellow
            SIMD4<Float>(0.6, 0.2, 1.0, 1.0)   // Purple
        ]
        
        let index = abs(chainID.hashValue) % chainColors.count
        return chainColors[index]
    }
    
    /// Generates a low-poly icosphere mesh with specified radius and subdivision level
    private static func generateLowPolySphere(radius: Float, segments: Int) throws -> MeshResource {
        // Use UV sphere with specified number of segments
        // segments controls both latitude and longitude divisions
        let latSegments = max(4, segments)
        let lonSegments = max(4, segments * 2)
        
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        
        // Generate vertices
        for lat in 0...latSegments {
            let theta = Float(lat) * .pi / Float(latSegments)
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)
            
            for lon in 0...lonSegments {
                let phi = Float(lon) * 2 * .pi / Float(lonSegments)
                let sinPhi = sin(phi)
                let cosPhi = cos(phi)
                
                let x = cosPhi * sinTheta
                let y = cosTheta
                let z = sinPhi * sinTheta
                
                let normal = SIMD3<Float>(x, y, z)
                positions.append(normal * radius)
                normals.append(normal)
            }
        }
        
        // Generate indices
        for lat in 0..<latSegments {
            for lon in 0..<lonSegments {
                let first = UInt32(lat * (lonSegments + 1) + lon)
                let second = first + UInt32(lonSegments + 1)
                
                indices.append(first)
                indices.append(second)
                indices.append(first + 1)
                
                indices.append(second)
                indices.append(second + 1)
                indices.append(first + 1)
            }
        }
        
        print("[ProteinSpheresMesh] Low-poly sphere: \(positions.count) vertices, \(indices.count / 3) triangles")
        
        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        
        return try MeshResource.generate(from: [descriptor])
    }
}

// MARK: - PDB Parser

/// Simplified PDB structure
public struct PDBStructureSimple {
    public var atoms: [PDBAtom]
    public var title: String
    
    public init(atoms: [PDBAtom], title: String = "") {
        self.atoms = atoms
        self.title = title
    }
}

/*
/// PDB atom record
public struct PDBAtom {
    public var serial: Int
    public var name: String
    public var altLoc: String
    public var resName: String
    public var chainID: String
    public var resSeq: Int
    public var position: SIMD3<Float>
    public var occupancy: Float
    public var tempFactor: Float
    public var element: String
    public var charge: String
    
    public init(
        serial: Int,
        name: String,
        altLoc: String,
        resName: String,
        chainID: String,
        resSeq: Int,
        position: SIMD3<Float>,
        occupancy: Float,
        tempFactor: Float,
        element: String,
        charge: String
    ) {
        self.serial = serial
        self.name = name
        self.altLoc = altLoc
        self.resName = resName
        self.chainID = chainID
        self.resSeq = resSeq
        self.position = position
        self.occupancy = occupancy
        self.tempFactor = tempFactor
        self.element = element
        self.charge = charge
    }
}

/// Simple PDB parser
struct PDBParser {
    
    static func parse(_ pdbString: String) -> PDBStructureSimple {
        var atoms: [PDBAtom] = []
        var title = ""
        
        let lines = pdbString.components(separatedBy: .newlines)
        
        print("[PDBParser] Starting to parse PDB with \(lines.count) lines")
        
        for line in lines {
            guard line.count >= 6 else { continue }
            
            let recordType = line.prefix(6).trimmingCharacters(in: .whitespaces)
            
            if recordType == "TITLE" && title.isEmpty {
                if line.count > 10 {
                    title = String(line.dropFirst(10)).trimmingCharacters(in: .whitespaces)
                }
            } else if recordType == "ATOM" {
                // Only parse ATOM records, not HETATM (which includes water, ligands, etc.)
                // This matches the behavior of the main PDB parser which excludes HETATM by default
                if let atom = parseAtom(line) {
                    atoms.append(atom)
                }
            }
        }
        
        print("[PDBParser] Finished parsing: \(atoms.count) atoms total")
        
        return PDBStructureSimple(atoms: atoms, title: title)
    }
    
    private static func parseAtom(_ line: String) -> PDBAtom? {
        guard line.count >= 54 else { return nil }
        
        let paddedLine = line.padding(toLength: 80, withPad: " ", startingAt: 0)
        
        // Parse PDB ATOM/HETATM record format
        guard let serial = Int(paddedLine[6..<11].trimmingCharacters(in: .whitespaces)) else { return nil }
        
        let name = paddedLine[12..<16].trimmingCharacters(in: .whitespaces)
        let altLoc = paddedLine[16..<17].trimmingCharacters(in: .whitespaces)
        let resName = paddedLine[17..<20].trimmingCharacters(in: .whitespaces)
        
        // Skip water molecules and unknown residues (non-standard amino acids, DNA/RNA, etc.)
        if resName == "HOH" || resName == "UNK" { return nil }
        
        let chainID = paddedLine[21..<22].trimmingCharacters(in: .whitespaces)
        
        guard let resSeq = Int(paddedLine[22..<26].trimmingCharacters(in: .whitespaces)) else { return nil }
        
        guard let x = Float(paddedLine[30..<38].trimmingCharacters(in: .whitespaces)),
              let y = Float(paddedLine[38..<46].trimmingCharacters(in: .whitespaces)),
              let z = Float(paddedLine[46..<54].trimmingCharacters(in: .whitespaces)) else { return nil }
        
        let occupancy = Float(paddedLine[54..<60].trimmingCharacters(in: .whitespaces)) ?? 1.0
        let tempFactor = Float(paddedLine[60..<66].trimmingCharacters(in: .whitespaces)) ?? 0.0
        
        // Element symbol is in columns 77-78, but often missing
        var element = paddedLine.count > 77 ? paddedLine[76..<78].trimmingCharacters(in: .whitespaces) : ""
        let elementFromPDB = element
        
        // If element is empty, infer from atom name
        if element.isEmpty {
            element = inferElement(from: name)
        }
        
      /*
        // Debug logging for first few atoms and carbon atoms
        if serial <= 5 || element.uppercased() == "C" {
            print("[PDBParser] Atom \(serial) '\(name)': element='\(elementFromPDB)' -> inferred='\(element)'")
        }
       */
        
        let charge = paddedLine.count > 79 ? paddedLine[78..<80].trimmingCharacters(in: .whitespaces) : ""
        
        return PDBAtom(
            serial: serial,
            name: name,
            altLoc: altLoc,
            resName: resName,
            chainID: chainID,
            resSeq: resSeq,
            position: SIMD3<Float>(x, y, z),
            occupancy: occupancy,
            tempFactor: tempFactor,
            element: element,
            charge: charge
        )
    }
    
    /// Infers element from atom name
    private static func inferElement(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        // Common atom name patterns
        if trimmed.hasPrefix("CA") { // && trimmed != "CA" {
            return "C"  // C-alpha (not calcium)
        } else if trimmed.starts(with: "C") {
            return "C"
        } else if trimmed.starts(with: "N") {
            return "N"
        } else if trimmed.starts(with: "O") {
            return "O"
        } else if trimmed.starts(with: "S") {
            return "S"
        } else if trimmed.starts(with: "P") {
            return "P"
        } else if trimmed.starts(with: "H") {
            return "H"
        }
        
        // Take first character as fallback
        return String(trimmed.prefix(1))
    }
}
 */

// MARK: - String Extension for Subscripting

extension String {
    subscript(range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
}
