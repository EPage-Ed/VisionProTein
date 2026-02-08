//
//  ProteinSpheres.swift
//  ProteinSpheres
//
//  High-performance sphere representation for protein structures
//

import RealityKit
import UIKit

/// Atom structure for sphere rendering
public struct Atom {
    public let serial: Int
    public let name: String
    public let resName: String
    public let chainID: String
    public let resSeq: Int
    public let x: Double
    public let y: Double
    public let z: Double
    public let element: String
    
    public init(serial: Int, name: String, resName: String, chainID: String, resSeq: Int, x: Double, y: Double, z: Double, element: String) {
        self.serial = serial
        self.name = name
        self.resName = resName
        self.chainID = chainID
        self.resSeq = resSeq
        self.x = x
        self.y = y
        self.z = z
        self.element = element
    }
    
    public var color: UIColor {
        switch element {
        case "H": return .white
        case "C": return UIColor(red: 0.565, green: 0.565, blue: 0.565, alpha: 1)
        case "N": return UIColor(red: 0.188, green: 0.314, blue: 0.973, alpha: 1)
        case "O": return UIColor(red: 1, green: 0.051, blue: 0.051, alpha: 1)
        case "S": return UIColor(red: 1, green: 1, blue: 0.188, alpha: 1)
        case "P": return UIColor(red: 1, green: 0.502, blue: 0, alpha: 1)
        default: return .black
        }
    }
    
    public var radius: CGFloat {
        switch element {
        case "H": return 0.32 / 100
        case "C": return 0.77 / 100
        case "N": return 0.75 / 100
        case "O": return 0.73 / 100
        case "S": return 1.02 / 100
        case "P": return 1.06 / 100
        default: return 0.5 / 100
        }
    }
}

/// Residue structure for sphere rendering
public struct Residue {
    public let id: Int
    public let serNum: Int
    public let chainID: String
    public let resName: String
    public let atoms: [Atom]
    
    public init(id: Int, serNum: Int, chainID: String, resName: String, atoms: [Atom]) {
        self.id = id
        self.serNum = serNum
        self.chainID = chainID
        self.resName = resName
        self.atoms = atoms
    }
}

/// High-performance sphere-based protein visualization
@available(visionOS 26.0, *)
public class ProteinSpheres {
    
    /// Generate a sphere entity for a single residue using GPU instancing
    /// - Parameters:
    ///   - residue: The residue to render
    ///   - scale: Scale factor for atom radii (default 1.0)
    /// - Returns: A ModelEntity containing instanced spheres for all atoms
    public static func generateResidueEntity(residue: Residue, scale: Float = 1.0) -> ModelEntity {
        let parent = ModelEntity()
        parent.name = residue.resName
        
        // Calculate base position (first atom position)
        let basePos = residue.atoms.first.map { atom in
            SIMD3<Float>(Float(atom.x) / 100, Float(atom.y) / 100, Float(atom.z) / 100)
        } ?? SIMD3<Float>(0, 0, 0)
        
        parent.position = basePos
        
        // Group atoms by color for efficient GPU instancing
        let colorGroups = Dictionary(grouping: residue.atoms) { $0.color }
        
        for (color, atoms) in colorGroups {
            guard let firstAtom = atoms.first else { continue }
            
            // Create mesh and material
            let radius = Float(firstAtom.radius) * scale
            let mesh = MeshResource.generateSphere(radius: radius)
            let material = SimpleMaterial(color: color, isMetallic: false)
            
            let count = atoms.count
            guard let instanceData = try? LowLevelInstanceData(instanceCount: count) else { continue }
            
            // Set transform for each atom instance
            instanceData.withMutableTransforms { transforms in
                for i in 0..<count {
                    let atom = atoms[i]
                    let pos = SIMD3<Float>(Float(atom.x) / 100, Float(atom.y) / 100, Float(atom.z) / 100)
                    let translation = pos - basePos
                    
                    let transform = Transform(
                        scale: .one,
                        rotation: simd_quatf(angle: 0, axis: [0, 0, 1]),
                        translation: translation
                    )
                    transforms[i] = transform.matrix
                }
            }
            
            // Create instanced component
            let modelID = mesh.contents.models.first?.id
            if let instancesComponent = try? MeshInstancesComponent(
                mesh: mesh,
                modelID: modelID,
                instances: instanceData
            ) {
                let entity = ModelEntity()
                entity.name = "Atoms_\(color.description)"
                entity.model = ModelComponent(mesh: mesh, materials: [material])
                nonisolated(unsafe) let component = instancesComponent
                entity.components.set(component)
                parent.addChild(entity)
            }
        }
        
        return parent
    }
    
    /// Generate a complete protein entity from multiple residues
    /// - Parameters:
    ///   - residues: Array of residues to render
    ///   - scale: Scale factor for atom radii (default 1.0)
    /// - Returns: A ModelEntity containing all residues as sphere representations
    public static func generateProteinEntity(residues: [Residue], scale: Float = 1.0) -> ModelEntity {
        let proteinEntity = ModelEntity()
        proteinEntity.name = "ProteinSpheres"
        
        for residue in residues {
            let residueEntity = generateResidueEntity(residue: residue, scale: scale)
            proteinEntity.addChild(residueEntity)
        }
        
        return proteinEntity
    }
    
    /// Generate a protein entity with custom atom positions (for animations like unfolding)
    /// - Parameters:
    ///   - residues: Array of residues to render
    ///   - positions: Custom positions for each residue center
    ///   - scale: Scale factor for atom radii (default 1.0)
    /// - Returns: A ModelEntity containing all residues positioned at custom locations
    public static func generateProteinEntityWithPositions(
        residues: [Residue],
        positions: [SIMD3<Float>],
        scale: Float = 1.0
    ) -> ModelEntity {
        let proteinEntity = ModelEntity()
        proteinEntity.name = "ProteinSpheres"
        
        for (index, residue) in residues.enumerated() {
            let residueEntity = generateResidueEntity(residue: residue, scale: scale)
            
            // Override position if provided
            if index < positions.count {
                residueEntity.position = positions[index]
            }
            
            proteinEntity.addChild(residueEntity)
        }
        
        return proteinEntity
    }
    
    /// Generate a sphere entity with level-of-detail support
    /// - Parameters:
    ///   - residues: Array of residues to render
    ///   - scale: Scale factor for atom radii (default 1.0)
    ///   - lodDistances: Array of distances for LOD switching
    /// - Returns: A ModelEntity with LOD components
    public static func generateProteinEntityWithLOD(
        residues: [Residue],
        scale: Float = 1.0,
        lodDistances: [Float] = [2.0, 5.0, 10.0]
    ) -> ModelEntity {
        // Start with standard entity
        let proteinEntity = generateProteinEntity(residues: residues, scale: scale)
        
        // TODO: Implement LOD switching based on camera distance
        // This would require monitoring camera position and switching between
        // different detail levels (full atoms, alpha carbon only, ribbon, etc.)
        
        return proteinEntity
    }
}
