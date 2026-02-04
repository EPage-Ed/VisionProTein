//
//  Molecule+Ribbon.swift
//  VisionProTein
//
//  Created by GitHub Copilot on 1/27/26.
//

import RealityKit
import UIKit

extension Molecule {
  // MARK: - Ribbon Representation
  /// Generates a ribbon representation of a protein as a RealityKit ModelEntity.
  /// - Parameters:
  ///   - atoms: The list of all atoms in the protein.
  ///   - residues: The list of residues in the protein.
  ///   - color: The color of the ribbon (optional).
  /// - Returns: A ModelEntity representing the ribbon.
  static func genRibbonEntity(residues: [Residue], color: UIColor = .systemBlue) -> ModelEntity? {
    // 1. Extract CA atoms for the backbone path
    let caAtoms = residues.compactMap { res in
      res.atoms.first(where: { $0.name.trimmingCharacters(in: .whitespaces) == "CA" })
    }
    guard caAtoms.count >= 4 else { return nil } // Need at least 4 for spline
    
    // 2. Convert CA atom positions to SIMD3<Float>
    let points: [SIMD3<Float>] = caAtoms.map { atom in
      SIMD3<Float>(Float(atom.x)/100, Float(atom.y)/100, Float(atom.z)/100)
    }
    
    // 3. Interpolate a smooth path (Catmull-Rom spline)
    let interpolatedPoints = interpolateCatmullRom(points: points, samplesPerSegment: 8)
    
    // 4. Generate ribbon mesh along the path
    let ribbonWidth: Float = 0.04 // 0.08
    let ribbonThickness: Float = 0.01 // 0.02
    let mesh = generateRibbonMesh(path: interpolatedPoints, width: ribbonWidth, thickness: ribbonThickness)
    
    // 5. Create ModelEntity
    let material = SimpleMaterial(color: color, isMetallic: false)
    let entity = ModelEntity(mesh: mesh, materials: [material])
    entity.name = "Ribbon"
    return entity
  }
  
  /// Catmull-Rom spline interpolation for smooth backbone path
  private static func interpolateCatmullRom(points: [SIMD3<Float>], samplesPerSegment: Int) -> [SIMD3<Float>] {
    guard points.count >= 4 else { return points }
    var result: [SIMD3<Float>] = []
    for i in 0..<(points.count - 3) {
      let p0 = points[i]
      let p1 = points[i+1]
      let p2 = points[i+2]
      let p3 = points[i+3]
      for j in 0..<samplesPerSegment {
        let t = Float(j) / Float(samplesPerSegment)
        let t2 = t * t
        let t3 = t2 * t
        var p : SIMD3<Float> = (2 * p1)
        p += (-p0 + p2) * t
        p += (2*p0 - 5*p1 + 4*p2 - p3) * t2
        p += (-p0 + 3*p1 - 3*p2 + p3) * t3
        let point : SIMD3<Float> = 0.5 * ( p )
        result.append(point)
      }
    }
    result.append(points[points.count-2]) // Add last point
    return result
  }
  
  /// Generates a ribbon mesh along a path using a rectangular cross-section
  private static func generateRibbonMesh(path: [SIMD3<Float>], width: Float, thickness: Float) -> MeshResource {
    var vertices: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    let up = SIMD3<Float>(0, 1, 0)
    for i in 0..<path.count {
      let p = path[i]
      // Tangent direction
      let tangent: SIMD3<Float>
      if i == 0 {
        tangent = normalize(path[i+1] - p)
      } else if i == path.count-1 {
        tangent = normalize(p - path[i-1])
      } else {
        tangent = normalize(path[i+1] - path[i-1])
      }
      // Normal and binormal
      let binormal = normalize(cross(up, tangent))
      let normal = normalize(cross(tangent, binormal))
      // Four corners of the ribbon cross-section
      let v0 = p + (width/2)*binormal + (thickness/2)*normal
      let v1 = p - (width/2)*binormal + (thickness/2)*normal
      let v2 = p - (width/2)*binormal - (thickness/2)*normal
      let v3 = p + (width/2)*binormal - (thickness/2)*normal
      let base = UInt32(vertices.count)
      vertices.append(contentsOf: [v0, v1, v2, v3])
      normals.append(contentsOf: [normal, normal, normal, normal])
      if i > 0 {
        // Connect previous quad to current quad
        let prev = base - 4
        indices.append(contentsOf: [prev, prev+1, base, base, prev+1, base+1])
        indices.append(contentsOf: [prev+1, prev+2, base+1, base+1, prev+2, base+2])
        indices.append(contentsOf: [prev+2, prev+3, base+2, base+2, prev+3, base+3])
        indices.append(contentsOf: [prev+3, prev, base+3, base+3, prev, base])
      }
    }
    var meshDesc = MeshDescriptor()
    meshDesc.positions = MeshBuffer(vertices)
    meshDesc.normals = MeshBuffer(normals)
    meshDesc.primitives = .triangles(indices)
    return try! MeshResource.generate(from: [meshDesc])
  }
}
