//
//  RibbonDiagramGenerator.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 1/30/26.
//

//
//  RibbonDiagramGenerator.swift
//  RealityKit4 Ribbon Engine
//
//  Generates helix ribbons, beta-sheet arrows, and coil tubes
//  from a PDB string with adaptive resolution, cubic B-splines,
//  parallel-transport frames, and double-sided geometry.
//

import Foundation
import simd
import RealityKit
import UIKit

// ===============================================================
// MARK: - GLOBAL PARAMETERS
// ===============================================================

/// Global rendering parameters for ribbons.
struct RibbonParameters {
  /// All geometry is scaled by this factor (hybrid AR scale).
  static let scaleFactor: Float = 8.0
  
  /// Adaptive sampling thresholds
  static let minSegmentLength: Float = 0.8
  static let maxSegmentLength: Float = 2.5
  static let curvatureThreshold: Float = 0.25
  
  /// Geometry widths
  static let helixWidth: Float = 3.0
  static let helixThickness: Float = 0.75
  
  static let sheetWidth: Float = 4.0
  static let sheetThickness: Float = 0.75
  static let sheetArrowHeadLength: Float = 5.0
  
  static let coilRadius: Float = 0.8
  static let coilSides: Int = 14
}


// ===============================================================
// MARK: - VECTOR / MATRIX UTILITIES
// ===============================================================

extension SIMD3 where Scalar == Float {
  
  @inline(__always)
  func normalized() -> SIMD3<Float> {
    let len = simd_length(self)
    return len > 0 ? self / len : SIMD3<Float>(0, 0, 0)
  }
  
  @inline(__always)
  static func cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
    simd_cross(a, b)
  }
}

extension simd_float4x4 {
  static func fromBasis(right: SIMD3<Float>,
                        up: SIMD3<Float>,
                        forward: SIMD3<Float>,
                        origin: SIMD3<Float>) -> simd_float4x4 {
    .init(columns: (
      SIMD4<Float>(right, 0),
      SIMD4<Float>(up, 0),
      SIMD4<Float>(forward, 0),
      SIMD4<Float>(origin, 1)
    ))
  }
}


// ===============================================================
// MARK: - MESH STRUCTURES
// ===============================================================

/// A single vertex with position, normal, uv.
struct RibbonVertex {
  var position: SIMD3<Float>
  var normal: SIMD3<Float>
  var uv: SIMD2<Float>
}

/// A mesh accumulator before building RealityKit geometry.
struct RibbonMesh {
  var vertices: [RibbonVertex] = []
  var indices: [UInt32] = []
  
  mutating func append(_ other: RibbonMesh) {
    let offset = UInt32(vertices.count)
    vertices.append(contentsOf: other.vertices)
    indices.append(contentsOf: other.indices.map { $0 + offset })
  }
}


// ===============================================================
// MARK: - PDB DATA MODELS
// ===============================================================

struct Atom {
  let name: String
  let residueName: String
  let residueIndex: Int
  let position: SIMD3<Float>
}

struct Residue {
  let index: Int
  let name: String
  let atoms: [Atom]
}

struct Chain {
  let id: String
  let residues: [Residue]
}

struct Structure {
  let chains: [Chain]
}


// ===============================================================
// MARK: - SECONDARY STRUCTURE TYPES
// ===============================================================

enum SecondaryStructureType {
  case helix
  case betaSheet
  case coil
}

/// For spline construction and ribbon generation.
struct SSResidue {
  let residue: Residue
  let type: SecondaryStructureType
  let guidePoint: SIMD3<Float>
}


// ===============================================================
// MARK: - RIBBON DIAGRAM GENERATOR
// ===============================================================

final class RibbonDiagramGenerator {
  
  // MARK: - PUBLIC API
  
  /// Main public method to build a full AR-ready ribbon diagram.
  func makeRibbonEntity(from pdbString: String) -> Entity {
    let structure = parsePDB(pdbString)
    let ssResidues = assignSecondaryStructure(structure)
    let splineGroups = buildSplines(from: ssResidues)
    let meshes = buildMeshesFromSplines(splineGroups)
    return assembleEntity(meshes)
  }
  
  
  // ===========================================================
  // MARK: - (1) PDB PARSER
  // ===========================================================
  
  func parsePDB(_ pdb: String) -> Structure {
    var chainAtoms: [String: [Atom]] = [:]
    
    for line in pdb.split(separator: "\n") {
      guard line.hasPrefix("ATOM") || line.hasPrefix("HETATM") else { continue }
      
      let name = String(line[12..<16]).trimmingCharacters(in: .whitespaces)
      let resName = String(line[17..<20]).trimmingCharacters(in: .whitespaces)
      let chainID = String(line[21])
      let resSeq = Int(line[22..<26].trimmingCharacters(in: .whitespaces)) ?? 0
      
      let x = Float(line[30..<38].trimmingCharacters(in: .whitespaces)) ?? 0
      let y = Float(line[38..<46].trimmingCharacters(in: .whitespaces)) ?? 0
      let z = Float(line[46..<54].trimmingCharacters(in: .whitespaces)) ?? 0
      
      let atom = Atom(name: name,
                      residueName: resName,
                      residueIndex: resSeq,
                      position: SIMD3<Float>(x, y, z))
      
      chainAtoms[chainID, default: []].append(atom)
    }
    
    let chains: [Chain] = chainAtoms.map { (id, atoms) in
      let groups = Dictionary(grouping: atoms, by: { $0.residueIndex })
      let residues = groups.keys.sorted().map { idx in
        Residue(index: idx,
                name: groups[idx]!.first!.residueName,
                atoms: groups[idx]!)
      }
      return Chain(id: id, residues: residues)
    }
    
    return Structure(chains: chains)
  }
  
  
  // ===========================================================
  // MARK: - (2) SECONDARY STRUCTURE ASSIGNMENT
  // ===========================================================
  
  func assignSecondaryStructure(_ structure: Structure) -> [SSResidue] {
    var result: [SSResidue] = []
    
    for chain in structure.chains {
      for res in chain.residues {
        let ca = res.atoms.first { $0.name == "CA" }
        let pos = ca?.position ?? SIMD3<Float>(0,0,0)
        
        // Placeholder secondary structure logic; can be replaced by DSSP.
        let type = inferSecondaryStructure(residue: res)
        
        result.append(SSResidue(residue: res,
                                type: type,
                                guidePoint: pos))
      }
    }
    
    return result
  }
  
  func inferSecondaryStructure(residue: Residue) -> SecondaryStructureType {
    // Simplified placeholder
    if residue.index % 10 < 4 { return .helix }
    if residue.index % 10 < 7 { return .betaSheet }
    return .coil
  }
  
  
  // ===========================================================
  // MARK: - (3) SPLINE GENERATION
  // ===========================================================
  
  struct SplineResult {
    let type: SecondaryStructureType
    let points: [SIMD3<Float>]     // adaptive-res sampled points
    let tangents: [SIMD3<Float>]   // tangent vectors
    let normals: [SIMD3<Float>]    // normal vectors (parallel-transport)
  }
  
  func buildSplines(from residues: [SSResidue]) -> [SplineResult] {
    
    // 1. Group residues by contiguous SS type.
    var groups: [[SSResidue]] = []
    var current: [SSResidue] = []
    
    for r in residues {
      if current.isEmpty || current.last!.type == r.type {
        current.append(r)
      } else {
        groups.append(current)
        current = [r]
      }
    }
    if !current.isEmpty { groups.append(current) }
    
    // 2. Build a spline for each group.
    return groups.map(buildSpline)
  }
  
  /// Construct a spline with adaptive sampling and PTF frames.
  func buildSpline(for group: [SSResidue]) -> SplineResult {
    
    // Extract points
    let basePoints = group.map { $0.guidePoint * RibbonParameters.scaleFactor }
    
    // Build cubic B-spline with adaptive sampling
    let sampled = adaptiveSampleCubicBSpline(basePoints)
    
    // Generate stable orientation frames
    let tangents = computeTangents(sampled)
    let normals = computeParallelTransportFrames(points: sampled, tangents: tangents)
    
    return SplineResult(type: group.first!.type,
                        points: sampled,
                        tangents: tangents,
                        normals: normals)
  }
  
  
  // ===========================================================
  // MARK: - (3a) CUBIC B-SPLINE + ADAPTIVE SAMPLING
  // ===========================================================
  
  /// Evaluate cubic B-spline using uniform basis functions.
  func cubicBSpline(_ control: [SIMD3<Float>], t: Float) -> SIMD3<Float> {
    let n = control.count
    let p = 3
    
    // Clamp t into [0, 1]
    let t = max(0, min(1, t))
    
    // Uniform knot vector
    let knotCount = n + p + 1
    let knot = (0..<knotCount).map { Float($0) }
    
    // Map t to knot span
    let u = t * Float(knotCount - 2*p - 2) + Float(p+1)
    let k = Int(u)
    let uLocal = u - Float(k)
    
    // Evaluate basis
    func B(_ i: Int, _ k: Int, _ u: Float) -> Float {
      if k == 0 {
        let left = Float(i)
        let right = Float(i+1)
        return (u >= left && u < right) ? 1 : 0
      }
      let leftDen = Float(i+k) - Float(i)
      let rightDen = Float(i+k+1) - Float(i+1)
      let leftPart: Float = leftDen == 0 ? 0 :
      (u - Float(i)) / leftDen * B(i, k-1, u)
      let rightPart: Float = rightDen == 0 ? 0 :
      (Float(i+k+1) - u) / rightDen * B(i+1, k-1, u)
      return leftPart + rightPart
    }
    
    var result = SIMD3<Float>(0,0,0)
    for i in 0..<n {
      let w = B(i, p, u)
      result += control[i] * w
    }
    return result
  }
  
  
  /// Sample spline at adaptive resolution based on curvature.
  func adaptiveSampleCubicBSpline(_ control: [SIMD3<Float>]) -> [SIMD3<Float>] {
    var result: [SIMD3<Float>] = []
    let steps = 200  // upper bound
    
    var prev = cubicBSpline(control, t: 0)
    result.append(prev)
    
    for i in 1...steps {
      let t = Float(i) / Float(steps)
      let cur = cubicBSpline(control, t: t)
      let delta = simd_length(cur - prev)
      
      // measure local curvature by midpoint evaluation
      let mid = cubicBSpline(control, t: (t + (Float(i-1) / Float(steps))) * 0.5)
      let curvature = simd_length(mid - (prev + cur) * 0.5)
      
      // refine sample if curvature high or segment long
      if delta > RibbonParameters.maxSegmentLength ||
          curvature > RibbonParameters.curvatureThreshold {
        // subdivide
        let tMid = (Float(i) - 0.5) / Float(steps)
        result.append(cubicBSpline(control, t: tMid))
      }
      
      result.append(cur)
      prev = cur
    }
    
    return result
  }
  
  
  // ===========================================================
  // MARK: - (3b) TANGENTS & PARALLEL TRANSPORT FRAMES
  // ===========================================================
  
  func computeTangents(_ pts: [SIMD3<Float>]) -> [SIMD3<Float>] {
    var tangents: [SIMD3<Float>] = []
    for i in 0..<pts.count {
      if i == 0 {
        tangents.append((pts[1] - pts[0]).normalized())
      } else if i == pts.count - 1 {
        tangents.append((pts[i] - pts[i-1]).normalized())
      } else {
        tangents.append((pts[i+1] - pts[i-1]).normalized())
      }
    }
    return tangents
  }
  
  func computeParallelTransportFrames(points: [SIMD3<Float>],
                                      tangents: [SIMD3<Float>]) -> [SIMD3<Float>] {
    
    var normals: [SIMD3<Float>] = []
    
    // initial normal: pick any vector not collinear with tangent
    var n0 = SIMD3<Float>(0, 1, 0)
    if abs(simd_dot(n0, tangents[0])) > 0.9 {
      n0 = SIMD3<Float>(1, 0, 0)
    }
    n0 = (n0 - tangents[0] * simd_dot(n0, tangents[0])).normalized()
    normals.append(n0)
    
    // propagate
    for i in 1..<points.count {
      let prevT = tangents[i-1]
      let curT  = tangents[i]
      
      let axis = SIMD3<Float>.cross(prevT, curT)
      let angle = acos(max(-1, min(1, simd_dot(prevT, curT))))
      
      var n = normals[i-1]
      
      if simd_length(axis) > 1e-5 {
        // rotate n around axis by angle
        let axisNorm = axis.normalized()
        n = simd_normalize(
          n * cos(angle)
          + SIMD3<Float>.cross(axisNorm, n) * sin(angle)
          + axisNorm * simd_dot(axisNorm, n) * (1 - cos(angle))
        )
      }
      
      normals.append(n)
    }
    
    return normals
  }
  
  
  // ===========================================================
  // MARK: - (4) MESH GENERATION PER SPLINE
  // ===========================================================
  
  func buildMeshesFromSplines(_ splines: [SplineResult]) -> [RibbonMesh] {
    var result: [RibbonMesh] = []
    
    for s in splines {
      switch s.type {
      case .helix:
        result.append(buildHelixRibbon(s))
      case .betaSheet:
        result.append(buildBetaSheetRibbon(s))
      case .coil:
        result.append(buildCoilTube(s))
      }
    }
    return result
  }
  
  
  // ===========================================================
  // MARK: - (4a) HELIX RIBBON GENERATOR (DOUBLE-SIDED)
  // ===========================================================
  
  func buildHelixRibbon(_ s: SplineResult) -> RibbonMesh {
    var mesh = RibbonMesh()
    
    let halfW = RibbonParameters.helixWidth * 0.5
    let thickness = RibbonParameters.helixThickness
    
    for i in 0..<s.points.count {
      let p = s.points[i]
      let t = s.tangents[i]
      let n = s.normals[i]
      let b = SIMD3<Float>.cross(t, n)
      
      // top & bottom edges
      let left  = p - b * halfW
      let right = p + b * halfW
      
      // face normal = ±n
      
      // front face tri strip
      if i > 0 {
        let prev = i - 1
        
        let left0  = s.points[prev] - s.normals[prev].cross(s.tangents[prev]) * halfW
        let right0 = s.points[prev] + s.normals[prev].cross(s.tangents[prev]) * halfW
        
        // front
        addQuad(&mesh,
                left0,  n,
                right0, n,
                right,  n,
                left,   n)
        
        // back (double-sided)
        addQuad(&mesh,
                right0, -n,
                left0,  -n,
                left,   -n,
                right,  -n)
      }
    }
    
    return mesh
  }
  
  
  // ===========================================================
  // MARK: - (4b) BETA-SHEET ARROW (DOUBLE-SIDED)
  // ===========================================================
  
  func buildBetaSheetRibbon(_ s: SplineResult) -> RibbonMesh {
    var mesh = RibbonMesh()
    
    let halfW = RibbonParameters.sheetWidth * 0.5
    let thickness = RibbonParameters.sheetThickness
    let arrowLen = RibbonParameters.sheetArrowHeadLength
    
    for i in 0..<s.points.count {
      let p = s.points[i]
      let t = s.tangents[i]
      let n = s.normals[i]
      let b = SIMD3<Float>.cross(t, n)
      
      var lw = halfW
      var rw = halfW
      
      // arrow tip widening at end
      if i > s.points.count - 6 {
        let alpha = Float(i - (s.points.count - 6)) / 5
        lw *= 1 + alpha * 1.5
        rw *= 1 + alpha * 1.5
      }
      
      let left  = p - b * lw
      let right = p + b * rw
      
      if i > 0 {
        let prev = i - 1
        
        let p0 = s.points[prev]
        let t0 = s.tangents[prev]
        let n0 = s.normals[prev]
        let b0 = SIMD3<Float>.cross(t0, n0)
        
        var lw0 = halfW
        var rw0 = halfW
        if prev > s.points.count - 6 {
          let alpha0 = Float(prev - (s.points.count - 6)) / 5
          lw0 *= 1 + alpha0 * 1.5
          rw0 *= 1 + alpha0 * 1.5
        }
        
        let left0  = p0 - b0 * lw0
        let right0 = p0 + b0 * rw0
        
        // front
        addQuad(&mesh, left0, n0,
                right0, n0,
                right,  n,
                left,   n)
        
        // back
        addQuad(&mesh, right0, -n0,
                left0,  -n0,
                left,   -n,
                right,  -n)
      }
    }
    
    return mesh
  }
  
  
  // ===========================================================
  // MARK: - (4c) COIL TUBE GENERATOR (CYLINDER)
  // ===========================================================
  
  func buildCoilTube(_ s: SplineResult) -> RibbonMesh {
    var mesh = RibbonMesh()
    
    let sides = RibbonParameters.coilSides
    let radius = RibbonParameters.coilRadius
    
    for i in 0..<s.points.count {
      let p = s.points[i]
      let t = s.tangents[i]
      let n = s.normals[i]
      let b = SIMD3<Float>.cross(t, n)
      
      for j in 0..<sides {
        let ang = Float(j) / Float(sides) * 2 * Float.pi
        let dir = (n * cos(ang) + b * sin(ang))
        let pos = p + dir * radius
        
        let uv = SIMD2<Float>(Float(j)/Float(sides),
                              Float(i)/Float(s.points.count))
        
        mesh.vertices.append(
          RibbonVertex(position: pos,
                       normal: dir.normalized(),
                       uv: uv)
        )
      }
      
      // build quads between rings
      if i > 0 {
        let base0 = (i-1) * sides
        let base1 = i * sides
        
        for j in 0..<sides {
          let next = (j+1) % sides
          
          let v0 = UInt32(base0 + j)
          let v1 = UInt32(base0 + next)
          let v2 = UInt32(base1 + next)
          let v3 = UInt32(base1 + j)
          
          mesh.indices.append(contentsOf: [
            v0, v1, v2,
            v0, v2, v3
          ])
        }
      }
    }
    
    return mesh
  }
  
  
  // ===========================================================
  // MARK: - QUAD UTILITY (for double-sided ribbons)
  // ===========================================================
  
  func addQuad(_ mesh: inout RibbonMesh,
               _ a: SIMD3<Float>, _ na: SIMD3<Float>,
               _ b: SIMD3<Float>, _ nb: SIMD3<Float>,
               _ c: SIMD3<Float>, _ nc: SIMD3<Float>,
               _ d: SIMD3<Float>, _ nd: SIMD3<Float>) {
    
    let base = UInt32(mesh.vertices.count)
    
    mesh.vertices.append(RibbonVertex(position: a, normal: na, uv: SIMD2<Float>(0,0)))
    mesh.vertices.append(RibbonVertex(position: b, normal: nb, uv: SIMD2<Float>(1,0)))
    mesh.vertices.append(RibbonVertex(position: c, normal: nc, uv: SIMD2<Float>(1,1)))
    mesh.vertices.append(RibbonVertex(position: d, normal: nd, uv: SIMD2<Float>(0,1)))
    
    mesh.indices.append(contentsOf: [
      base, base+1, base+2,
      base, base+2, base+3
    ])
  }
  
  
  // ===========================================================
  // MARK: - (5) REALITYKIT MESH ASSEMBLY
  // ===========================================================
  
  func assembleEntity(_ meshes: [RibbonMesh]) -> Entity {
    let root = Entity()
    
    for mesh in meshes {
      let entity = buildModelEntity(from: mesh)
      root.addChild(entity)
    }
    
    return root
  }
  
  /// Convert RibbonMesh → RealityKit ModelEntity via MeshDescriptor.
  func buildModelEntity(from rm: RibbonMesh) -> ModelEntity {
    
    var descriptor = MeshDescriptor()
    
    descriptor.positions = MeshBuffer(rm.vertices.map { $0.position })
    descriptor.normals   = MeshBuffer(rm.vertices.map { $0.normal })
    descriptor.textureCoordinates = MeshBuffer(rm.vertices.map { $0.uv })
    
    descriptor.primitives = .triangles(rm.indices)
    
    let mesh = try! MeshResource.generate(from: [descriptor])
    
    let material = PhysicallyBasedMaterial()
    var mutableMaterial = material
    mutableMaterial.baseColor = .init(tint: .white)
    mutableMaterial.roughness = 0.5
    mutableMaterial.metallic = 0.0
    
    return ModelEntity(mesh: mesh, materials: [mutableMaterial])
  }
}
