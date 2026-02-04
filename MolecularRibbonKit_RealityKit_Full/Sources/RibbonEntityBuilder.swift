
import RealityKit
import simd

public class RibbonEntityBuilder {
    let classifier = SecondaryStructureClassifier()
    let colorScheme = RibbonColorScheme()
    let ribbonBuilder = RibbonGeometryBuilder()

    public init() {}

    public func buildProteinEntity(from atoms:[Atom]) -> Entity {
        let root = Entity()

        let segments = classifier.classify(atoms: atoms)

        for segment in segments {
            let curve = atomsForResidueIndices(atoms, segment.residueIndices)
            let color = colorScheme.color(for: segment.type)
            let entity = ribbonBuilder.buildRibbon(curve: curve, width: 0.2, color: color)
            root.addChild(entity)
        }
        return root
    }

    private func atomsForResidueIndices(_ atoms:[Atom], _ indices:[Int]) -> [SIMD3<Float>] {
        return indices.compactMap { idx in
            guard idx < atoms.count else { return nil }
            let a = atoms[idx]
            return SIMD3<Float>(a.x,a.y,a.z)
        }
    }
}
