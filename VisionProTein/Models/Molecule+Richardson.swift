//
//  Molecule+Richardson.swift
//  VisionProTein
//
//  Created by GitHub Copilot on 1/28/26.
//

import RealityKit
import UIKit

extension Molecule {
  /// Generates a Richardson diagram (cartoon ribbon representation) as a RealityKit ModelEntity from an array of residues.
  /// - Parameter residues: The array of residues representing the protein chain.
  /// - Returns: A ModelEntity representing the Richardson diagram.
  static func genRichardsonDiagramEntity(residues: [Residue], helices:[HELIX], sheets:[SHEET]) -> ModelEntity? {
    enum SecondaryStructureType : String { case helix, sheet, loop }
    struct Segment { let type: SecondaryStructureType; let range: Range<Int> }
    guard residues.count >= 4 else { return nil }
    // --- 1. Assign secondary structure (demo: alternate every 10 residues) ---
    var segments: [Segment] = []
    let n = residues.count
    //    let segSize = 10
    var i = 0
    //    var types: [SecondaryStructureType] = [.helix, .sheet, .loop]
    //    var t = 0
    var hIdx = 0
    var sIdx = 0
    var loopIndex = 0
    var helix = helices.first
    var sheet = sheets.first
    
    while i < n {
      let serNum = residues[i].serNum
      if serNum == helix?.start {
        if loopIndex < i {
          segments.append(Segment(type: .loop, range: loopIndex..<i))
        }
        let e = residues.firstIndex(where: { $0.serNum == helix!.end }) ?? n - 1
        segments.append(Segment(type: .helix, range: i..<e+1))
        hIdx += 1
        loopIndex = e + 1
        i = e
        if hIdx < helices.count {
          helix = helices[hIdx]
        } else {
          helix = nil
        }
      } else if serNum == sheet?.start {
        if loopIndex < i {
          segments.append(Segment(type: .loop, range: loopIndex..<i))
        }
        let e = residues.firstIndex(where: { $0.serNum == sheet!.end }) ?? n - 1
        segments.append(Segment(type: .sheet, range: i..<e+1))
        sIdx += 1
        loopIndex = e + 1
        i = e
        if sIdx < sheets.count {
          sheet = sheets[sIdx]
        } else {
          sheet = nil
        }
      }
      i += 1
    }
    if loopIndex < n {
      segments.append(Segment(type: .loop, range: loopIndex..<n))
    }
    
//    segments = segments.sorted(by: { $0.range.lowerBound < $1.range.lowerBound })
    
    print(segments)
    
    /*
     while i < n {
     let serNum = residues[i].serNum
     
     let end = min(i+segSize, n)
     segments.append(Segment(type: types[t%3], range: i..<end))
     i = end
     t += 1
     }
     */
    
    // --- 2. Generate mesh for each segment using helpers ---
    let parent = ModelEntity()
    for segment in segments {
      print(segment.type.rawValue, segment.range)
      let caAtoms = segment.range.compactMap { idx in
        residues[idx].atoms.first(where: { $0.name.trimmingCharacters(in: .whitespaces) == "CA" })
      }
      //      if caAtoms.count < 4 { continue }
      let points: [SIMD3<Float>] = caAtoms.map { atom in
        SIMD3<Float>(Float(atom.x)/100, Float(atom.y)/100, Float(atom.z)/100)
      }
      let interpolated = interpolateCatmullRom(points: points, samplesPerSegment: 8)
      let entity: ModelEntity?
      switch segment.type {
      case .helix:
        print("Generating helix segment")
        entity = generateHelixEntity(path: interpolated, radius: 0.02, pitch: 0.001, color: .systemRed)
        //        entity = generateHelixEntity(path: interpolated, radius: 0.12, pitch: 0.5, color: .systemRed)
      case .sheet:
        print("Generating sheet segment")
        entity = generateSheetEntity(path: interpolated, width: 0.03, thickness: 0.002, color: .systemBlue)
        //        entity = generateSheetEntity(path: interpolated, width: 0.18, thickness: 0.03, color: .systemBlue)
      case .loop:
        print("Generating loop segment")
        entity = generateRopeEntity(path: interpolated, radius: 0.001, color: .systemGreen)
        //        entity = generateRopeEntity(path: interpolated, radius: 0.05, color: .systemGreen)
      }
      if let entity { parent.addChild(entity) }
    }
    parent.name = "RichardsonDiagram"
    return parent
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
        /*
         let point = 0.5 * (
         (2 * p1) +
         (-p0 + p2) * t +
         (2*p0 - 5*p1 + 4*p2 - p3) * t2 +
         (-p0 + 3*p1 - 3*p2 + p3) * t3
         )
         */
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
  
  // --- Helper: Helix (coil) mesh ---
  private static func generateHelixEntity(path: [SIMD3<Float>], radius: Float, pitch: Float, color: UIColor) -> ModelEntity? {
    guard path.count >= 2 else { return nil }
    
    let m = generateRibbonMesh(path: path, width: radius, thickness: pitch)
    let materialRibbon = SimpleMaterial(color: color, isMetallic: false)
    let entityRibbon = ModelEntity(mesh: m, materials: [materialRibbon])
    entityRibbon.name = "Helix_Ribbon"
    return entityRibbon
    
    // Generate a tube (coil) along the path
    let tubeRadius: Float = 0.01 // 0.05
    let sides = 8
    let (vertices, normals, indices) = generateTubeMesh(path: path, tubeRadius: tubeRadius, sides: sides)
    var meshDesc = MeshDescriptor()
    meshDesc.positions = MeshBuffer(vertices)
    meshDesc.normals = MeshBuffer(normals)
    meshDesc.primitives = .triangles(indices)
    let mesh = try! MeshResource.generate(from: [meshDesc])
    let material = SimpleMaterial(color: color, isMetallic: false)
    let entity = ModelEntity(mesh: mesh, materials: [material])
    entity.name = "Helix"
    return entity
  }
  
  // --- Helper: Sheet (arrow) mesh ---
  private static func generateSheetEntity(path: [SIMD3<Float>], width: Float, thickness: Float, color: UIColor) -> ModelEntity? {
    guard path.count >= 2 else { return nil }
    // Flat ribbon with distinct arrowhead at end
    var vertices: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    let up = SIMD3<Float>(0, 1, 0)
    let arrowLength: Float = width * 2.5
    let arrowWidth: Float = width * 2.0
    let notchInset: Float = width * 0.5
    for i in 0..<path.count {
      let p = path[i]
      let tangent: SIMD3<Float>
      if i == 0 { tangent = normalize(path[i+1] - p) }
      else if i == path.count-1 { tangent = normalize(p - path[i-1]) }
      else { tangent = normalize(path[i+1] - path[i-1]) }
      let binormal = normalize(cross(up, tangent))
      let normal = normalize(cross(tangent, binormal))
      let w = (i == path.count-1) ? width : width
      let v0 = p + (w/2)*binormal + (thickness/2)*normal
      let v1 = p - (w/2)*binormal + (thickness/2)*normal
      let v2 = p - (w/2)*binormal - (thickness/2)*normal
      let v3 = p + (w/2)*binormal - (thickness/2)*normal
      let base = UInt32(vertices.count)
      vertices.append(contentsOf: [v0, v1, v2, v3])
      normals.append(contentsOf: [normal, normal, normal, normal])
      if i > 0 {
        let prev = base - 4
        indices.append(contentsOf: [prev, prev+1, base, base, prev+1, base+1])
        indices.append(contentsOf: [prev+1, prev+2, base+1, base+1, prev+2, base+2])
        indices.append(contentsOf: [prev+2, prev+3, base+2, base+2, prev+3, base+3])
        indices.append(contentsOf: [prev+3, prev, base+3, base+3, prev, base])
      }
    }
    // Add arrowhead at the end
    let tipIdx = path.count - 1
    let tip = path[tipIdx]
    let tangent: SIMD3<Float> = tipIdx > 0 ? normalize(tip - path[tipIdx-1]) : SIMD3<Float>(1,0,0)
    let binormal = normalize(cross(up, tangent))
    let normal = normalize(cross(tangent, binormal))
    let arrowTip = tip + tangent * arrowLength
    let leftWing = tip + binormal * (arrowWidth/2)
    let rightWing = tip - binormal * (arrowWidth/2)
    let notchLeft = tip + binormal * (width/2 - notchInset)
    let notchRight = tip - binormal * (width/2 - notchInset)
    let arrowBase = UInt32(vertices.count)
    vertices.append(contentsOf: [leftWing, rightWing, arrowTip, notchLeft, notchRight])
    normals.append(contentsOf: [normal, normal, normal, normal, normal])
    // Arrowhead triangles
    // leftWing, arrowTip, rightWing
    indices.append(contentsOf: [arrowBase, arrowBase+2, arrowBase+1])
    // leftWing, notchLeft, arrowTip
    indices.append(contentsOf: [arrowBase, arrowBase+3, arrowBase+2])
    // rightWing, arrowTip, notchRight
    indices.append(contentsOf: [arrowBase+1, arrowBase+2, arrowBase+4])
    // Connect ribbon end to arrowhead base
    let lastBase = UInt32(vertices.count - 9)
    indices.append(contentsOf: [lastBase, arrowBase, arrowBase+3])
    indices.append(contentsOf: [lastBase+1, arrowBase+4, arrowBase+1])
    var meshDesc = MeshDescriptor()
    meshDesc.positions = MeshBuffer(vertices)
    meshDesc.normals = MeshBuffer(normals)
    meshDesc.primitives = .triangles(indices)
    let mesh = try! MeshResource.generate(from: [meshDesc])
    let material = SimpleMaterial(color: color, isMetallic: false)
    let entity = ModelEntity(mesh: mesh, materials: [material])
    entity.name = "Sheet"
    return entity
  }
  
  private static func generateFlatEntity(path: [SIMD3<Float>], width: Float, thickness: Float, color: UIColor) -> ModelEntity? {
    guard path.count >= 2 else { return nil }
    // Flat ribbon with arrowhead at end
    var vertices: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    let up = SIMD3<Float>(0, 1, 0)
    for i in 0..<path.count {
      let p = path[i]
      let tangent: SIMD3<Float>
      if i == 0 { tangent = normalize(path[i+1] - p) }
      else if i == path.count-1 { tangent = normalize(p - path[i-1]) }
      else { tangent = normalize(path[i+1] - path[i-1]) }
      let binormal = normalize(cross(up, tangent))
      let normal = normalize(cross(tangent, binormal))
      let w = (i == path.count-1) ? width*1.7 : width
      let v0 = p + (w/2)*binormal + (thickness/2)*normal
      let v1 = p - (w/2)*binormal + (thickness/2)*normal
      let v2 = p - (w/2)*binormal - (thickness/2)*normal
      let v3 = p + (w/2)*binormal - (thickness/2)*normal
      let base = UInt32(vertices.count)
      vertices.append(contentsOf: [v0, v1, v2, v3])
      normals.append(contentsOf: [normal, normal, normal, normal])
      if i > 0 {
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
    let mesh = try! MeshResource.generate(from: [meshDesc])
    let material = SimpleMaterial(color: color, isMetallic: false)
    let entity = ModelEntity(mesh: mesh, materials: [material])
    entity.name = "Sheet"
    return entity
  }
  
  
  
  // --- Helper: Rope (loop/turn) mesh ---
  private static func generateRopeEntity(path: [SIMD3<Float>], radius: Float, color: UIColor) -> ModelEntity? {
    guard path.count >= 2 else { return nil }
    // Generate a tube (rope) along the path
    let sides = 6
    let (vertices, normals, indices) = generateTubeMesh(path: path, tubeRadius: radius, sides: sides)
    var meshDesc = MeshDescriptor()
    meshDesc.positions = MeshBuffer(vertices)
    meshDesc.normals = MeshBuffer(normals)
    meshDesc.primitives = .triangles(indices)
    let mesh = try! MeshResource.generate(from: [meshDesc])
    let material = SimpleMaterial(color: color, isMetallic: false)
    let entity = ModelEntity(mesh: mesh, materials: [material])
    entity.name = "Rope"
    return entity
  }
  
  // --- Helper: Tube mesh generation ---
  private static func generateTubeMesh(path: [SIMD3<Float>], tubeRadius: Float, sides: Int) -> ([SIMD3<Float>], [SIMD3<Float>], [UInt32]) {
    var vertices: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var indices: [UInt32] = []
    let up = SIMD3<Float>(0, 1, 0)
    let n = path.count
    for i in 0..<n {
      let p = path[i]
      // Tangent direction
      let tangent: SIMD3<Float>
      if i == 0 {
        tangent = normalize(path[i+1] - p)
      } else if i == n-1 {
        tangent = normalize(p - path[i-1])
      } else {
        tangent = normalize(path[i+1] - path[i-1])
      }
      // Find a vector not parallel to tangent
      let ref = abs(dot(tangent, up)) > 0.9 ? SIMD3<Float>(1,0,0) : up
      let binormal = normalize(cross(ref, tangent))
      let normal = normalize(cross(tangent, binormal))
      for j in 0..<sides {
        let theta = 2 * Float.pi * Float(j) / Float(sides)
        let dir = cos(theta) * binormal + sin(theta) * normal
        vertices.append(p + tubeRadius * dir)
        normals.append(dir)
      }
    }
    // Create triangles
    for i in 0..<(n-1) {
      let base0 = i * sides
      let base1 = (i+1) * sides
      for j in 0..<sides {
        let next = (j+1)%sides
        indices.append(UInt32(base0 + j))
        indices.append(UInt32(base1 + j))
        indices.append(UInt32(base1 + next))
        indices.append(UInt32(base0 + j))
        indices.append(UInt32(base1 + next))
        indices.append(UInt32(base0 + next))
      }
    }
    return (vertices, normals, indices)
  }
}
