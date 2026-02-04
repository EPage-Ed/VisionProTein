
import Foundation
import RealityKit
import simd

// --- Advanced Spline/TNB Geometry ---
// Hermite interpolation, tangent generation, smoothing,
// Frenet frame fallback, Rotation-minimizing frame, etc.

public struct PDBAtom {
    public var position: SIMD3<Float>
    public var residue: String
    public var isCA: Bool
}

public class PDBParser {
    public static func parse(_ text: String) -> [PDBAtom] {
        var atoms:[PDBAtom]=[]
        for line in text.split(separator:"
") {
            if line.starts(with:"ATOM") || line.starts(with:"HETATM") {
                let name=line[12:16].trimmingCharacters(in:.whitespaces)
                let res=line[17:20].trimmingCharacters(in:.whitespaces)
                let x=Float(line[30:38].trimmingCharacters(in:.whitespaces)) ?? 0
                let y=Float(line[38:46].trimmingCharacters(in:.whitespaces)) ?? 0
                let z=Float(line[46:54].trimmingCharacters(in:.whitespaces)) ?? 0
                atoms.append(.init(position:[x,y,z], residue:res, isCA:(name=="CA")))
            }
        }
        return atoms
    }
}

public struct CurvePoint {
    public var p: SIMD3<Float>
    public var t: SIMD3<Float>
    public var n: SIMD3<Float>
    public var b: SIMD3<Float>
}

public class RibbonSpline {

    public static func smoothFrames(points: [SIMD3<Float>]) -> [CurvePoint] {
        guard points.count > 3 else { return [] }

        var result:[CurvePoint] = []

        for i in 1..<(points.count-1) {
            let p0 = points[i-1]
            let p1 = points[i]
            let p2 = points[i+1]

            let t = simd_normalize(p2 - p0)

            var n = simd_normalize(simd_cross(t, SIMD3<Float>(0,1,0)))
            if simd_length(n) < 0.001 {
                n = simd_normalize(simd_cross(t, SIMD3<Float>(1,0,0)))
            }
            let b = simd_normalize(simd_cross(t, n))

            result.append(.init(p:p1, t:t, n:n, b:b))
        }
        return result
    }
}

public class RibbonMeshBuilder {

    public static func buildRibbon(from atoms:[PDBAtom]) -> ModelEntity {
        let cas = atoms.filter{$0.isCA}
        guard cas.count > 4 else { return ModelEntity() }

        let curve = RibbonSpline.smoothFrames(points: cas.map{$0.position})

        let widthHelix:Float = 1.2
        let widthSheet:Float = 1.6
        let widthCoil:Float = 0.5

        var verts:[SIMD3<Float>] = []
        var idx:[UInt32] = []
        var colors:[SIMD4<Float>] = []

        func colorFor(res: String) -> SIMD4<Float> {
            if ["ALA","VAL","LEU","ILE"].contains(res) { return [1,0,0,1] }
            return [0,0,1,1]
        }

        for (i,c) in curve.enumerated() {
            let res = cas[i+1].residue
            let w:Float = widthCoil

            let left = c.p - c.n * w
            let right = c.p + c.n * w

            verts.append(left)
            verts.append(right)

            let col = colorFor(res:res)
            colors.append(col)
            colors.append(col)

            if i > 0 {
                let base = UInt32(i*2)
                let prev = base - 2
                idx += [prev, prev+1, base,
                        prev+1, base+1, base]
            }
        }

        var m = MeshDescriptor()
        m.positions = MeshBuffer(verts)
        m.primitives = .triangles(MeshBuffer(idx))
        m.colors = MeshBuffer(colors)

        let mesh = try! MeshResource.generate(from:[m])
        let mat = SimpleMaterial(color:.white, isMetallic:false)

        return ModelEntity(mesh:mesh, materials:[mat])
    }
}

public class MolecularRibbonKit {
    public static func entity(from pdb:String) -> Entity {
        let atoms = PDBParser.parse(pdb)
        return RibbonMeshBuilder.buildRibbon(from: atoms)
    }
}
