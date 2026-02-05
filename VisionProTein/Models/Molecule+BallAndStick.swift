//
//  Molecule+BallAndStick.swift
//  VisionProTein
//
//  Created by Claude Code on 2/4/26.
//

import RealityKit
import UIKit

// Component to store residue information for ball and stick models
class BallAndStickResidueComponent: Component {
    var residue: Residue
    
    init(residue: Residue) {
        self.residue = residue
    }
}

extension Molecule {
    /// Generates a ball and stick representation for a specific residue that can be positioned independently
    /// - Parameters:
    ///   - residue: The residue to render
    ///   - basePosition: Optional base position to offset from (if nil, uses residue's first atom position)
    ///   - atomScale: Scale factor for atom spheres (default 1.0)
    /// - Returns: A ModelEntity representing the residue in ball and stick format
    static func genBallAndStickResidue(residue: Residue, basePosition: SIMD3<Float>? = nil, atomScale: Float = 1.0) -> ModelEntity? {
        guard !residue.atoms.isEmpty else { return nil }
        
        let parent = ModelEntity()
        parent.name = "\(residue.resName)_\(residue.chainID)\(residue.serNum)"
        
        // Use the same 0.01 scale that ProteinRibbon uses
        // If basePosition is provided, use it; otherwise calculate from first atom
        let basePos = basePosition ?? SIMD3(
            x: Float(residue.atoms[0].x) * 0.01,
            y: Float(residue.atoms[0].y) * 0.01,
            z: Float(residue.atoms[0].z) * 0.01
        )
        
        parent.position = basePos
        
        // Group atoms by element for efficient rendering
        let atomGroups = Dictionary(grouping: residue.atoms, by: { $0.element })
        
        for (element, atoms) in atomGroups {
            guard let firstAtom = atoms.first else { continue }
            
            // Create mesh for this element type with scaled radius
            let scaledRadius = Float(firstAtom.radius) * atomScale
            let mesh = MeshResource.generateSphere(radius: scaledRadius)
            let material = SimpleMaterial(color: firstAtom.color, isMetallic: false)
            
            // Use instancing for multiple atoms of same element
            let count = atoms.count
            guard let instanceData = try? LowLevelInstanceData(instanceCount: count) else { continue }
            
            instanceData.withMutableTransforms { transforms in
                for i in 0..<count {
                    let atom = atoms[i]
                    // Use 0.01 scale to match ProteinRibbon
                    let atomPos = SIMD3<Float>(
                        Float(atom.x) * 0.01,
                        Float(atom.y) * 0.01,
                        Float(atom.z) * 0.01
                    )
                    let translation = atomPos - basePos
                    let transform = Transform(
                        scale: .one,
                        rotation: simd_quatf(angle: 0, axis: [0, 0, 1]),
                        translation: translation
                    )
                    transforms[i] = transform.matrix
                }
            }
            
            // Create entity with instances
            if let modelID = mesh.contents.models.first?.id,
               let instancesComponent = try? MeshInstancesComponent(
                mesh: mesh,
                modelID: modelID,
                instances: instanceData
               ) {
                let entity = ModelEntity()
                entity.name = "Atoms_\(element)"
                entity.model = ModelComponent(mesh: mesh, materials: [material])
                entity.components.set(instancesComponent)
                parent.addChild(entity)
            }
        }
        
        // Add bonds if we have connectivity information
        // This would require bond information from the residue
        // For now, we'll just render the atoms
        
        // Add collision shapes and input target to make it interactive
        parent.components.set(InputTargetComponent())
        parent.generateCollisionShapes(recursive: true, static: true)
        
        return parent
    }
    
    /// Finds the residue associated with a ball and stick entity at a tap location
    /// - Parameters:
    ///   - ballAndStickEntity: The root ball and stick entity
    ///   - tapEntity: The entity that was tapped
    ///   - residues: Array of all residues in the protein
    /// - Returns: The residue that corresponds to the tapped location, if found
    static func findResidueFromBallAndStickTap(
        ballAndStickEntity: Entity,
        tapEntity: Entity,
        residues: [Residue]
    ) -> Residue? {
        // The tap entity might be deep in the hierarchy
        // We need to find the nearest parent that has residue information
        var current: Entity? = tapEntity
        
        while let entity = current {
            // Check if this entity has a BallAndStickResidueComponent
            if let component = entity.components[BallAndStickResidueComponent.self] {
                return component.residue
            }
            
            // Move up the hierarchy
            if entity.parent === ballAndStickEntity {
                break
            }
            current = entity.parent
        }
        
        // Fallback: try to match by position
        // Get the world position of the tapped entity
        let tapWorldPos = tapEntity.position(relativeTo: nil)
        
        // Find the closest residue by comparing CA atom positions
        var closestResidue: Residue?
        var minDistance: Float = .infinity
        
        for residue in residues {
            // Look for CA (alpha carbon) atom
            if let caAtom = residue.atoms.first(where: { 
                $0.name.trimmingCharacters(in: .whitespaces) == "CA" 
            }) {
                // Use 0.01 scale to match ProteinRibbon
                let atomPos = SIMD3<Float>(
                    Float(caAtom.x) * 0.01,
                    Float(caAtom.y) * 0.01,
                    Float(caAtom.z) * 0.01
                )
                let dist = distance(tapWorldPos, atomPos)
                
                if dist < minDistance {
                    minDistance = dist
                    closestResidue = residue
                }
            }
        }
        
        // Only return if we found something reasonably close (within 0.05 units)
        return minDistance < 0.05 ? closestResidue : nil
    }
}
