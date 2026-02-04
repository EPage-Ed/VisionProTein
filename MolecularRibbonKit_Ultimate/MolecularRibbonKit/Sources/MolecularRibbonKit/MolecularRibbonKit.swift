
import Foundation
import RealityKit
import simd

// Ultimate ribbon engine scaffold

public struct PDBAtom {
    public var position: SIMD3<Float>
    public var residue: String
    public var isCA: Bool
    public var chainID: String
}

public class PDBParser {
    public static func parse(_ text: String) -> [PDBAtom] {
        var a:[PDBAtom] = []
        for line in text.split(separator:"\n") {
            if line.starts(with:"ATOM") {
                let name=line[12:16].trimmingCharacters(in:.whitespaces)
                let res=line[17:20].trimmingCharacters(in:.whitespaces)
                let chain=String(line[21])
                let x=Float(line[30:38].trimmingCharacters(in:.whitespaces)) ?? 0
                let y=Float(line[38:46].trimmingCharacters(in:.whitespaces)) ?? 0
                let z=Float(line[46:54].trimmingCharacters(in:.whitespaces)) ?? 0
                a.append(.init(position:[x,y,z], residue:res, isCA:(name=="CA"), chainID:chain))
            }
        }
        return a
    }
}

public enum SecondaryStructure {
    case helix
    case sheet
    case coil
}

public class SecondaryStructureDetector {
    public static func detect(atoms:[PDBAtom]) -> [SecondaryStructure] {
        return atoms.map{ _ in .coil }
    }
}

public struct CurvePoint {
    public var p: SIMD3<Float>
    public var t: SIMD3<Float>
    public var n: SIMD3<Float>
    public var b: SIMD3<Float>
}

public class RibbonSpline {
    public static func generateCurve(from ca:[SIMD3<Float>]) -> [CurvePoint] {
        var out:[CurvePoint] = []
        for i in 1..<(ca.count-1) {
            let p0 = ca[i-1]
            let p1 = ca[i]
            let p2 = ca[i+1]
            let t = simd_normalize(p2 - p0)
            var n = simd_normalize(simd_cross(t,[0,1,0]))
            if simd_length(n) < 0.001 { n = simd_normalize(simd_cross(t,[1,0,0])) }
            let b = simd_normalize(simd_cross(t,n))
            out.append(.init(p:p1, t:t, n:n, b:b))
        }
        return out
    }
}

public class RibbonGeometry {
    public static func buildMesh(curve:[CurvePoint], sse:[SecondaryStructure], residues:[String]) -> ModelEntity {
        var verts:[SIMD3<Float>] = []
        var idx:[UInt32] = []
        var colors:[SIMD4<Float>] = []

        func col(_ s:SecondaryStructure)->SIMD4<Float>{
            switch s {
                case .helix: return [1,0,0,1]
                case .sheet: return [1,1,0,1]
                case .coil: return [0,0,1,1]
            }
        }

        for (i,c) in curve.enumerated() {
            let s = sse[i+1]
            let w:Float = (s == .helix ? 1.4 : s == .sheet ? 1.8 : 0.6)
            let left = c.p - c.n * w
            let right = c.p + c.n * w
            verts.append(left)
            verts.append(right)
            colors.append(col(s))
            colors.append(col(s))

            if i > 0 {
                let base = UInt32(i*2)
                let prev = base - 2
                idx += [prev, prev+1, base,
                        prev+1, base+1, base]
            }
        }

        var d = MeshDescriptor()
        d.positions = MeshBuffer(verts)
        d.colors = MeshBuffer(colors)
        d.primitives = .triangles(MeshBuffer(idx))
        let mesh = try! MeshResource.generate(from:[d])
        return ModelEntity(mesh:mesh, materials:[SimpleMaterial(color:.white, isMetallic:false)])
    }
}

public class SidechainBuilder {
    public static func addSidechains(_ root:Entity, atoms:[PDBAtom]) { }
}

public class MolecularRibbonKit {
    public static func entity(from pdb:String) -> Entity {
        let atoms = PDBParser.parse(pdb)
        let ca = atoms.filter{$0.isCA}
        let curve = RibbonSpline.generateCurve(from: ca.map{$0.position})
        let sse = SecondaryStructureDetector.detect(atoms:atoms)
        let ribbon = RibbonGeometry.buildMesh(curve:curve, sse:sse, residues:ca.map{$0.residue})
        let root = Entity()
        root.addChild(ribbon)
        SidechainBuilder.addSidechains(root, atoms:atoms)
        return root
    }
}
