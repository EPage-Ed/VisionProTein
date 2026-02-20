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
  static func genBallAndStickResidue(residue: Residue, basePosition: SIMD3<Float>? = nil, atomScale: Float = 1.0, unify: Bool = false, targetable: Bool = true) -> ModelEntity? {
        guard !residue.atoms.isEmpty else { return nil }
        
//        print("[Memory] Creating ball-and-stick for residue \(residue.resName)\(residue.serNum) with \(residue.atoms.count) atoms")
        
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
    let atomGroups = unify ? ["X" : residue.atoms] : Dictionary(grouping: residue.atoms, by: { $0.element })
        
        for (element, atoms) in atomGroups {
            guard let firstAtom = atoms.first else { continue }
            
            // CRITICAL FIX: Create mesh ONCE per element type, BEFORE chunking
            // This prevents creating duplicate meshes for each chunk
            let scaledRadius = Float(firstAtom.radius) * atomScale
            let mesh = MeshResource.generateSphere(radius: scaledRadius)
            let material = SimpleMaterial(color: firstAtom.color, isMetallic: false)
            
//            print("[Memory] Created mesh for element \(element) with radius \(scaledRadius)")
            
            // Split into chunks of 10,000 atoms if needed
            let maxAtomsPerEntity = 10000
            let totalAtoms = atoms.count
            let numChunks = (totalAtoms + maxAtomsPerEntity - 1) / maxAtomsPerEntity
            
            if numChunks > 1 {
//                print("[Memory] Splitting \(totalAtoms) \(element) atoms into \(numChunks) chunks (reusing same mesh)")
            }
            
            for chunkIndex in 0..<numChunks {
                let startIndex = chunkIndex * maxAtomsPerEntity
                let endIndex = min(startIndex + maxAtomsPerEntity, totalAtoms)
                let chunkAtoms = Array(atoms[startIndex..<endIndex])
                let count = chunkAtoms.count
                
//                print("[Memory] Ball-and-stick chunk \(chunkIndex): \(count) \(element) atoms")
                guard let instanceData = try? LowLevelInstanceData(instanceCount: count) else {
                    print("[Memory] ERROR: Failed to allocate instance data for \(count) atoms")
                    continue
                }
                
                instanceData.withMutableTransforms { transforms in
                    for i in 0..<count {
                        let atom = chunkAtoms[i]
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
                    // Add chunk suffix if there are multiple chunks
                    if numChunks > 1 {
                        entity.name = "Atoms_\(element)_\(chunkIndex)"
                    } else {
                        entity.name = "Atoms_\(element)"
                    }
                    entity.model = ModelComponent(mesh: mesh, materials: [material])
                    entity.components.set(instancesComponent)
                    parent.addChild(entity)
                }
            }
        }
        
        // Add bonds if we have connectivity information
        // This would require bond information from the residue
        // For now, we'll just render the atoms
        
        // Add collision shapes and input target to make it interactive
    if targetable {
      parent.components.set(InputTargetComponent())
      parent.generateCollisionShapes(recursive: true, static: true)
    }
        
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
    
    /// Finds and highlights the nearest residue to a world space coordinate using direct coordinate comparison
    /// - Parameters:
    ///   - ballAndStickEntity: The root ball and stick entity
    ///   - worldPosition: The world space coordinate to search from
    ///   - residues: Array of all residues in the protein
    ///   - maxDistance: Maximum distance threshold for selection (default 0.05 meters)
    /// - Returns: A tuple containing the found residue and a highlighted ModelEntity, or nil if none found
    static func findAndHighlightNearestResidue(
        ballAndStickEntity: Entity,
        worldPosition: SIMD3<Float>,
        residues: [Residue],
        maxDistance: Float = 0.05
    ) -> (residue: Residue, highlightEntity: ModelEntity)? {
        // Convert world position to ball and stick local space
        let localPosition = ballAndStickEntity.convert(position: worldPosition, from: nil)
        
        // Find the closest atom by comparing distances
        var closestResidue: Residue?
        var closestAtomDistance: Float = .infinity
        
        for residue in residues {
            for atom in residue.atoms {
                // Use 0.01 scale to match ball and stick representation
                let atomLocalPos = SIMD3<Float>(
                    Float(atom.x) * 0.01,
                    Float(atom.y) * 0.01,
                    Float(atom.z) * 0.01
                )
                
                let dist = distance(localPosition, atomLocalPos)
                
                if dist < closestAtomDistance {
                    closestAtomDistance = dist
                    closestResidue = residue
                }
            }
        }
        
        // Only proceed if we found an atom within the max distance threshold
        guard let residue = closestResidue, closestAtomDistance < maxDistance else {
            return nil
        }
        
        // Create a highlighted version of this residue with larger atom radius
        guard let residueEntity = genBallAndStickResidue(residue: residue, atomScale: 1.5, unify: true, targetable: false) else {
            return nil
        }
        
        residueEntity.name = "Selected_\(residue.resName)_\(residue.chainID)\(residue.serNum)"
        
        // Add emissive material for highlight with transparency
        var material = PhysicallyBasedMaterial()
        material.emissiveColor.color = .yellow
        material.emissiveIntensity = 0.3
        material.blending = .transparent(opacity: 0.3)
        
        // Apply material to all children
        residueEntity.children.forEach { child in
            if var modelEntity = child as? ModelEntity,
               let model = modelEntity.model {
                modelEntity.model?.materials = model.materials.map { _ in material }
            }
        }
        
        // Add collision shapes and input target to make it interactive
        residueEntity.components.set(InputTargetComponent())
        residueEntity.generateCollisionShapes(recursive: true, static: true)
        
        return (residue: residue, highlightEntity: residueEntity)
    }
    
    /// Highlights multiple residues in the ball and stick representation
    /// - Parameters:
    ///   - residues: Array of residues to highlight
    ///   - ballAndStickEntity: The root ball and stick entity to add highlights to
    ///   - atomScale: Scale factor for highlighted atoms (default: 1.5)
    ///   - color: Highlight color (default: yellow)
    ///   - intensity: Emissive intensity (default: 0.3)
    ///   - opacity: Transparency of highlights (default: 0.3)
    ///   - groupName: Name for the parent entity containing all highlights (default: "HighlightedResidues")
    /// - Returns: A parent entity containing all highlighted residue entities, or nil if no residues could be highlighted
    @MainActor
    static func highlightResidues(
        _ residues: [Residue],
        in ballAndStickEntity: Entity,
        atomScale: Float = 1.5,
        color: UIColor = .yellow,
        intensity: Float = 0.3,
        opacity: Float = 0.3,
        groupName: String = "HighlightedResidues"
    ) -> ModelEntity? {
        guard !residues.isEmpty else { return nil }
        
        let parentEntity = ModelEntity()
        parentEntity.name = groupName
        
        print("[Molecule] Highlighting \(residues.count) residues in ball and stick")
        
        var highlightedCount = 0
        
        for residue in residues {
            guard let residueEntity = genBallAndStickResidue(residue: residue, atomScale: atomScale, unify: true, targetable: false) else {
                continue
            }
            
            residueEntity.name = "Highlight_\(residue.resName)_\(residue.chainID)\(residue.serNum)"
            
            // Create emissive material for highlight
            var material = PhysicallyBasedMaterial()
            material.emissiveColor.color = color
            material.emissiveIntensity = intensity
            material.blending = .transparent(opacity: .init(floatLiteral: opacity))
            
            // Apply material to all children
            residueEntity.children.forEach { child in
                if var modelEntity = child as? ModelEntity,
                   let model = modelEntity.model {
                    modelEntity.model?.materials = model.materials.map { _ in material }
                }
            }
            
            parentEntity.addChild(residueEntity)
            highlightedCount += 1
        }
        
        guard highlightedCount > 0 else {
            print("[Molecule] Warning: Could not highlight any residues")
            return nil
        }
        
        print("[Molecule] Successfully highlighted \(highlightedCount) residues")
        
        // Add to ball and stick entity
        ballAndStickEntity.addChild(parentEntity)
        
        return parentEntity
    }
    
    /// Removes all highlighted residues from the ball and stick entity
    /// - Parameters:
    ///   - ballAndStickEntity: The root ball and stick entity
    ///   - groupName: Name of the highlight group to remove (default: "HighlightedResidues")
    @MainActor
    static func removeHighlights(from ballAndStickEntity: Entity, groupName: String = "HighlightedResidues") {
        if let highlightEntity = ballAndStickEntity.findEntity(named: groupName) {
            highlightEntity.removeFromParent()
            print("[Molecule] Removed highlight group: \(groupName)")
        }
    }
}
