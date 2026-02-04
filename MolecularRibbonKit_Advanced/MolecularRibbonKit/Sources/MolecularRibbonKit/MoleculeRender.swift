// MoleculeRender.swift
// Moved from VisionProTein/Models to MolecularRibbonKit_Advanced/MolecularRibbonKit/Sources/MolecularRibbonKit
// Created: 2026-01-31

import Foundation
import RealityKit
import simd
import UIKit

// MARK: - Basic PDB Atom Model

public struct Atom {
  let name: String
  let residue: String
  let chain: String
  let index: Int
  let position: SIMD3<Float>
}

public enum SecondaryStructureType {
  case helix
  case sheet
  case coil
}

public struct ResidueInfo {
  let residue: String
  let chain: String
  let atomIndex: Int
  let caPosition: SIMD3<Float>
  var structure: SecondaryStructureType = .coil
}

// MARK: - MAIN CLASS

public final class AdvancedRibbonBuilder {
  // PUBLIC ENTRY POINT
  public func buildEntity(from pdbString: String,
                          colorMode: ColorMode = .byStructure) -> Entity {
    let atoms = parsePDB(pdbString)
    let residues = extractResidues(atoms)
    let classified = classifySecondaryStructure(residues)
    let entity = Entity()
    let helixSegments = classified.filter {$0.structure == .helix }
    let sheetSegments = classified.filter {$0.structure == .sheet }
    let coilSegments  = classified.filter {$0.structure == .coil  }
    if helixSegments.count > 3 {
      entity.addChild(buildHelixRibbon(helixSegments, colorMode: colorMode))
    }
    if sheetSegments.count > 3 {
      entity.addChild(buildSheetRibbon(sheetSegments, colorMode: colorMode))
    }
    if coilSegments.count > 3 {
      entity.addChild(buildCoilTube(coilSegments, colorMode: colorMode))
    }
    return entity
  }
  // MARK: - STEP 1: Parse PDB
  private func parsePDB(_ pdb: String) -> [Atom] {
    var atoms: [Atom] = []
    let lines = pdb.split(separator: "\n")
    var index = 0
    for line in lines {
      guard line.starts(with: "ATOM") || line.starts(with: "HETATM") else { continue }
      guard line.count >= 54 else { continue }
      let name  = String(line[12..<16]).trimmingCharacters(in: .whitespaces)
      let res   = String(line[17..<20]).trimmingCharacters(in: .whitespaces)
      let chain = String(line[21..<22])
      let x = Float(line[30..<38].trimmingCharacters(in: .whitespaces)) ?? 0
      let y = Float(line[38..<46].trimmingCharacters(in: .whitespaces)) ?? 0
      let z = Float(line[46..<54].trimmingCharacters(in: .whitespaces)) ?? 0
      atoms.append(.init(
        name: name,
        residue: res,
        chain: chain,
        index: index,
        position: SIMD3<Float>(x,y,z)
      ))
      index += 1
    }
    return atoms
  }
  // MARK: - STEP 2: Extract CA Backbone
  private func extractResidues(_ atoms: [Atom]) -> [ResidueInfo] {
    atoms
      .filter { $0.name == "CA" }
      .map {
        ResidueInfo(
          residue: $0.residue,
          chain: $0.chain,
          atomIndex: $0.index,
          caPosition: $0.position
        )
      }
  }
  // MARK: - STEP 3: Secondary Structure Classification (simple DSSP-like logic)
  private func classifySecondaryStructure(_ residues: [ResidueInfo]) -> [ResidueInfo] {
    guard residues.count > 4 else { return residues }
    var result = residues
    for i in 1..<(residues.count - 3) {
      let p0 = residues[i].caPosition
      let p1 = residues[i+1].caPosition
      let p2 = residues[i+2].caPosition
      let p3 = residues[i+3].caPosition
      let d13 = distance(p0, p3)
      // Helix detection
      if d13 < 6.2 {
        result[i].structure = .helix
        result[i+1].structure = .helix
        result[i+2].structure = .helix
        result[i+3].structure = .helix
      }
      // Sheet detection (simple version)
      if abs(d13 - 4.7) < 1.0 {
        result[i].structure = .sheet
        result[i+3].structure = .sheet
      }
    }
    return result
  }
  // MARK: - Mesh Builders
  private func buildHelixRibbon(_ residues: [ResidueInfo], colorMode: ColorMode) -> Entity {
    let pts = residues.map { $0.caPosition }
    let spline = catmullRom(points: pts)
    let mesh = ribbonExtrude(path: spline,
                             width: 1.1,
                             thickness: 0.25)
    let entity = ModelEntity(mesh: mesh, materials: [material(for: .helix, mode: colorMode)])
    return entity
  }
  private func buildSheetRibbon(_ residues: [ResidueInfo], colorMode: ColorMode) -> Entity {
    let pts = residues.map { $0.caPosition }
    let spline = catmullRom(points: pts)
    let mesh = ribbonExtrude(path: spline,
                             width: 1.6,
                             thickness: 0.15,
                             arrowHead: true)
    let entity = ModelEntity(mesh: mesh, materials: [material(for: .sheet, mode: colorMode)])
    return entity
  }
  private func buildCoilTube(_ residues: [ResidueInfo], colorMode: ColorMode) -> Entity {
    let pts = residues.map { $0.caPosition }
    let spline = catmullRom(points: pts)
    let mesh = tubeMesh(path: spline, radius: 0.35)
    let entity = ModelEntity(mesh: mesh, materials: [material(for: .coil, mode: colorMode)])
    return entity
  }
  // MARK: - Spline (Catmull-Rom)
  private func catmullRom(points: [SIMD3<Float>], segments: Int = 12) -> [SIMD3<Float>] {
    guard points.count > 3 else { return points }
    var out: [SIMD3<Float>] = []
    for i in 1..<(points.count - 2) {
      let p0 = points[i-1]
      let p1 = points[i]
      let p2 = points[i+1]
      let p3 = points[i+2]
      for j in 0..<segments {
        let t = Float(j)/Float(segments)
        let t2 = t*t
        let t3 = t2*t
        let pt = 0.5 * ((2*p1) +
                        (-p0 + p2)*t +
                        (2*p0 - 5*p1 + 4*p2 - p3)*t2 +
                        (-p0 + 3*p1 - 3*p2 + p3)*t3)
        out.append(pt)
      }
    }
    return out
  }
  // MARK: - Full Tube Mesh Generator
  private func tubeMesh(path: [SIMD3<Float>],
                        radius: Float,
                        radialSegments: Int = 20) -> MeshResource {
    var vertices: [MeshResource.Vertex] = []
    var indices: [UInt32] = []
    let count = path.count
    guard count > 1 else {
      return MeshResource.generateSphere(radius: radius)
    }
    func basis(at index: Int) -> (right: SIMD3<Float>, up: SIMD3<Float>, forward: SIMD3<Float>) {
      let forward: SIMD3<Float>
      if index < count - 1 {
        forward = simd_normalize(path[index + 1] - path[index])
      } else {
        forward = simd_normalize(path[index] - path[index - 1])
      }
      let upGuess = abs(forward.y) < 0.8 ? SIMD3<Float>(0, 1, 0) : SIMD3<Float>(1, 0, 0)
      let right = simd_normalize(simd_cross(forward, upGuess))
      let up = simd_cross(right, forward)
      return (right, up, forward)
    }
    for i in 0..<count {
      let center = path[i]
      let (right, up, _) = basis(at: i)
      for s in 0..<radialSegments {
        let angle = Float(s) / Float(radialSegments) * 2 * Float.pi
        let offset = cos(angle) * right * radius + sin(angle) * up * radius
        let pos = center + offset
        let normal = simd_normalize(offset)
        vertices.append(
          .init(position: pos,
                normal: normal,
                uv: SIMD2<Float>(Float(s)/Float(radialSegments),
                                 Float(i)/Float(count)))
        )
      }
    }
    for i in 0..<count - 1 {
      let ringA = i * radialSegments
      let ringB = (i + 1) * radialSegments
      for s in 0..<radialSegments {
        let a = UInt32(ringA + s)
        let b = UInt32(ringA + (s+1) % radialSegments)
        let c = UInt32(ringB + s)
        let d = UInt32(ringB + (s+1) % radialSegments)
        indices.append(contentsOf: [a, b, c])
        indices.append(contentsOf: [b, d, c])
      }
    }
    return try! MeshResource.generate(from: vertices, indices: indices)
  }
  // MARK: - Ribbon Extrusion (Helices & Sheets)
  private func ribbonExtrude(path: [SIMD3<Float>],
                             width: Float,
                             thickness: Float,
                             arrowHead: Bool = false) -> MeshResource {
    var vertices: [MeshResource.Vertex] = []
    var indices: [UInt32] = []
    let n = path.count
    guard n > 1 else { return MeshResource.generateBox(size: width) }
    func basis(at index: Int) -> (right: SIMD3<Float>, up: SIMD3<Float>, forward: SIMD3<Float>) {
      let forward: SIMD3<Float>
      if index < n - 1 {
        forward = simd_normalize(path[index + 1] - path[index])
      } else {
        forward = simd_normalize(path[index] - path[index - 1])
      }
      let upGuess = abs(forward.y) < 0.8 ? SIMD3<Float>(0, 1, 0) : SIMD3<Float>(1, 0, 0)
      let right = simd_normalize(simd_cross(forward, upGuess))
      let up = simd_cross(right, forward)
      return (right, up, forward)
    }
    let halfW = width / 2
    let halfT = thickness / 2
    for i in 0..<n {
      let center = path[i]
      let (right, up, _) = basis(at: i)
      var leftEdge  = center - right * halfW
      var rightEdge = center + right * halfW
      if arrowHead && i > n - 8 {
        let t = Float(i - (n - 8)) / 8.0
        let scale = 1.0 + t * 1.5
        leftEdge  = center - right * (halfW * scale)
        rightEdge = center + right * (halfW * scale)
      }
      let topLeft = leftEdge + up * halfT
      let topRight = rightEdge + up * halfT
      let bottomLeft = leftEdge - up * halfT
      let bottomRight = rightEdge - up * halfT
      let normals: [SIMD3<Float>] = [
        up, up,  -up, -up
      ]
      let sliceVertices = [
        MeshResource.Vertex(position: topLeft,    normal: normals[0], uv: SIMD2<Float>(0, Float(i)/Float(n))),
        MeshResource.Vertex(position: topRight,   normal: normals[1], uv: SIMD2<Float>(1, Float(i)/Float(n))),
        MeshResource.Vertex(position: bottomLeft, normal: normals[2], uv: SIMD2<Float>(0, Float(i)/Float(n))),
        MeshResource.Vertex(position: bottomRight,normal: normals[3], uv: SIMD2<Float>(1, Float(i)/Float(n)))
      ]
      vertices.append(contentsOf: sliceVertices)
    }
    for i in 0..<n - 1 {
      let a = UInt32(i * 4)
      let b = UInt32(i * 4 + 1)
      let c = UInt32(i * 4 + 2)
      let d = UInt32(i * 4 + 3)
      let a2 = UInt32((i+1) * 4)
      let b2 = UInt32((i+1) * 4 + 1)
      let c2 = UInt32((i+1) * 4 + 2)
      let d2 = UInt32((i+1) * 4 + 3)
      indices.append(contentsOf: [a, b, a2])
      indices.append(contentsOf: [b, b2, a2])
      indices.append(contentsOf: [c, c2, d])
      indices.append(contentsOf: [d, c2, d2])
    }
    return try! MeshResource.generate(from: vertices, indices: indices)
  }
  // MARK: - Color Modes
  public enum ColorMode {
    case single(UIColor)
    case byChain
    case byStructure
    case byResidue
  }
  private func material(for type: SecondaryStructureType,
                        chain: String? = nil,
                        residue: String? = nil,
                        mode: ColorMode) -> SimpleMaterial {
    let color: UIColor = {
      switch mode {
      case .single(let c):
        return c
      case .byStructure:
        switch type {
        case .helix: return UIColor(red: 0.95, green: 0.35, blue: 0.35, alpha: 1)
        case .sheet: return UIColor(red: 0.35, green: 0.55, blue: 0.95, alpha: 1)
        case .coil:  return UIColor.systemGray
        }
      case .byChain:
        return colorForChain(chain)
      case .byResidue:
        return colorForResidue(residue)
      }
    }()
    return SimpleMaterial(color: color, isMetallic: false)
  }
  private func colorForChain(_ chain: String?) -> UIColor {
    guard let ch = chain else { return .white }
    let palette: [String: UIColor] = [
      "A": .systemRed, "B": .systemBlue, "C": .systemGreen,
      "D": .systemOrange, "E": .systemPurple, "F": .systemTeal
    ]
    return palette[ch] ?? .white
  }
  private func colorForResidue(_ res: String?) -> UIColor {
    guard let r = res else { return .white }
    let palette: [String: UIColor] = [
      "ALA": .systemGray,
      "GLY": .lightGray,
      "LYS": .systemBlue,
      "GLU": .systemRed,
      "VAL": .systemGreen,
      "PHE": .purple
    ]
    return palette[r] ?? .white
  }
}
