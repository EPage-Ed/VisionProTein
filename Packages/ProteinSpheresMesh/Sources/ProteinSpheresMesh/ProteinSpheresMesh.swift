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
    
    /// Creates a sphere representation entity with CPK element coloring
  public static func spheresCPK(from pdbString: String, scale: Float = 1.0) -> ModelEntity {
    return spheresEntity(from: pdbString, options: Options(atomScale: scale, colorScheme: .byElement))
  }
    
    /// Creates a sphere representation entity with larger atoms
    public static func spheresLarge(from pdbString: String) -> ModelEntity {
        return spheresEntity(
            from: pdbString,
            options: Options(
                atomScale: 1.5,
                colorScheme: .byElement
            )
        )
    }
    
    /// Creates a sphere representation entity with custom options
    public static func spheresEntity(from pdbString: String, options: Options) -> ModelEntity {
        let structure = PDBParser.parse(pdbString)
        return SpheresBuilder.buildEntity(from: structure, options: options)
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
        
        // Group atoms by element for efficient instancing
        let atomsByElement = Dictionary(grouping: atoms, by: { $0.element.uppercased() })
        
        print("[ProteinSpheresMesh] Atoms grouped by element:")
        for (element, elementAtoms) in atomsByElement.sorted(by: { $0.key < $1.key }) {
            print("  \(element): \(elementAtoms.count) atoms")
        }
        
        // Create one entity per element type
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
            
            // Create instancing data
            let count = elementAtoms.count
            guard let instanceData = try? LowLevelInstanceData(instanceCount: count) else { continue }
            
            instanceData.withMutableTransforms { transforms in
                for i in 0..<count {
                    let atom = elementAtoms[i]
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
                entity.name = "Spheres_\(element)"
                entity.model = ModelComponent(mesh: mesh, materials: [material])
                
                // Create and set component with nonisolated context
                do {
                    let component = try MeshInstancesComponent(
                        mesh: mesh,
                        modelID: modelID,
                        instances: instanceData
                    )
                    entity.components[MeshInstancesComponent.self] = component
                    print("[ProteinSpheresMesh] Successfully created instanced entity for \(element)")
                } catch {
                    print("[ProteinSpheresMesh] ERROR: Failed to create MeshInstancesComponent for \(element): \(error)")
                }
                
                parent.addChild(entity)
                print("[ProteinSpheresMesh] Added \(element) entity to parent")
            } else {
                print("[ProteinSpheresMesh] ERROR: No modelID found for \(element) mesh")
            }
        }
        
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
public struct PDBStructure {
    public var atoms: [PDBAtom]
    public var title: String
    
    public init(atoms: [PDBAtom], title: String = "") {
        self.atoms = atoms
        self.title = title
    }
}

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
    
    static func parse(_ pdbString: String) -> PDBStructure {
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
            } else if recordType == "ATOM" || recordType == "HETATM" {
                if let atom = parseAtom(line) {
                    atoms.append(atom)
                }
            }
        }
        
        print("[PDBParser] Finished parsing: \(atoms.count) atoms total")
        
        return PDBStructure(atoms: atoms, title: title)
    }
    
    private static func parseAtom(_ line: String) -> PDBAtom? {
        guard line.count >= 54 else { return nil }
        
        let paddedLine = line.padding(toLength: 80, withPad: " ", startingAt: 0)
        
        // Parse PDB ATOM/HETATM record format
        guard let serial = Int(paddedLine[6..<11].trimmingCharacters(in: .whitespaces)) else { return nil }
        
        let name = paddedLine[12..<16].trimmingCharacters(in: .whitespaces)
        let altLoc = paddedLine[16..<17].trimmingCharacters(in: .whitespaces)
        let resName = paddedLine[17..<20].trimmingCharacters(in: .whitespaces)
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
        
        // Debug logging for first few atoms and carbon atoms
        if serial <= 5 || element.uppercased() == "C" {
            print("[PDBParser] Atom \(serial) '\(name)': element='\(elementFromPDB)' -> inferred='\(element)'")
        }
        
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

// MARK: - String Extension for Subscripting

extension String {
    subscript(range: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
}
