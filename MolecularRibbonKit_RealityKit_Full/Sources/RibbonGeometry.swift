
import RealityKit
import simd

public class RibbonGeometryBuilder {
    public init() {}

    public func buildRibbon(curve:[SIMD3<Float>], width:Float, color:UIColor) -> ModelEntity {
        var vertices:[SIMD3<Float>] = []
        var colors:[SIMD4<Float>] = []

        for i in 0..<curve.count {
            let p = curve[i]
            let c = SIMD4<Float>(Float(color.cgColor.components?[0] ?? 1),
                                 Float(color.cgColor.components?[1] ?? 1),
                                 Float(color.cgColor.components?[2] ?? 1),
                                 1.0)
            vertices.append(p)
            colors.append(c)
        }

        let mesh = MeshResource.generateCurveRibbon(points: vertices, width: width, colors: colors)
        return ModelEntity(mesh: mesh, materials:[UnlitMaterial(color:color)])
    }
}

// placeholder mesh generator
extension MeshResource {
    static func generateCurveRibbon(points:[SIMD3<Float>], width:Float, colors:[SIMD4<Float>]) -> MeshResource {
        var positions:[SIMD3<Float>] = []
        var indices:[UInt32] = []
        for (i,p) in points.enumerated() {
            positions.append(p + SIMD3<Float>(width,0,0))
            positions.append(p - SIMD3<Float>(width,0,0))
            if i>0 {
                let base = UInt32(i*2)
                indices += [base-2, base-1, base, base-1, base+1, base]
            }
        }
        return try! MeshResource.generate(from: .init(positions:positions, indices:indices))
    }
}
