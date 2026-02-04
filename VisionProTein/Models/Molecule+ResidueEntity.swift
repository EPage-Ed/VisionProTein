//
//  Molecule+ResidueEntity.swift
//  VisionProTein
//
//  Created by GitHub Copilot on 1/28/26.
//

import RealityKit
import UIKit

extension Molecule {
  /// Generates a RealityKit ModelEntity for a residue, rendering each atom as a colored sphere.
  /// - Parameter residue: The residue to render.
  /// - Returns: A ModelEntity containing all atoms as colored spheres.
  static func genResidueEntity(residue: Residue) -> ModelEntity {
    let parent = ModelEntity()
    parent.name = residue.resName
    let basePos = { residue.atoms.first.map { a in
      SIMD3(x: Float(a.x)/100, y: Float(a.y)/100, z: Float(a.z)/100)
    } }() ?? SIMD3<Float>(0,0,0)
    parent.position = basePos
    // Group atoms by color for efficient instancing
    let colorGroups = Dictionary(grouping: residue.atoms, by: { $0.color })
    for (color, atoms) in colorGroups {
      guard let firstAtom = atoms.first else { continue }
      let mesh = MeshResource.generateSphere(radius: Float(firstAtom.radius))
      let material = SimpleMaterial(color: color, isMetallic: false)
      let count = atoms.count
      guard let instanceData = try? LowLevelInstanceData(instanceCount: count) else { continue }
      instanceData.withMutableTransforms { transforms in
        for i in 0..<count {
          let atom = atoms[i]
          let pos = SIMD3<Float>(Float(atom.x)/100, Float(atom.y)/100, Float(atom.z)/100)
          let rot = simd_quatf(angle: 0, axis: [0,0,1])
          let transform = Transform(scale: .one, rotation: rot, translation: pos - basePos)
          transforms[i] = transform.matrix
        }
      }
      let modelID = mesh.contents.models.first?.id
      if let instancesComponent = try? MeshInstancesComponent(
        mesh: mesh,
        modelID: modelID,
        instances: instanceData
      ) {
        let entity = ModelEntity()
        entity.name = "Atoms_\(color.description)"
        entity.model = ModelComponent(mesh: mesh, materials: [material])
        entity.components.set(instancesComponent)
        parent.addChild(entity)
      }
    }
    return parent
  }
}
