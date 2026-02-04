//
//  MeshBuilder.swift
//  ProteinRibbon
//
//  Triangle mesh generation for ribbon geometry.
//

import Foundation
import simd
import RealityKit

// MARK: - Mesh Data

/// Contains all data needed to create a RealityKit mesh
public struct MeshData {
    public var positions: [SIMD3<Float>] = []
    public var normals: [SIMD3<Float>] = []
    public var colors: [SIMD4<Float>] = []
    public var indices: [UInt32] = []

    /// Number of vertices
    public var vertexCount: Int { positions.count }

    /// Number of triangles
    public var triangleCount: Int { indices.count / 3 }

    public init() {}

    /// Appends another mesh data to this one
    public mutating func append(_ other: MeshData) {
        let indexOffset = UInt32(positions.count)

        positions.append(contentsOf: other.positions)
        normals.append(contentsOf: other.normals)
        colors.append(contentsOf: other.colors)
        indices.append(contentsOf: other.indices.map { $0 + indexOffset })
    }
}

// MARK: - Mesh Builder

/// Builds triangle meshes from ribbon geometry
public struct MeshBuilder {

    // MARK: - Ribbon Mesh Generation

    /// Builds a ribbon mesh from TNB frames and profiles
    /// - Parameters:
    ///   - frames: Array of TNB frames along the ribbon path
    ///   - profiles: Array of ribbon profiles (must match frame count)
    ///   - colors: Per-frame colors (must match frame count)
    ///   - addEndCaps: Whether to add end caps
    /// - Returns: MeshData containing vertices, normals, colors, and indices
    public static func buildRibbonMesh(
        frames: [TNBFrame],
        profiles: [RibbonProfile],
        colors: [SIMD4<Float>],
        addEndCaps: Bool = true
    ) -> MeshData {
        guard frames.count >= 2, frames.count == profiles.count, frames.count == colors.count else {
            return MeshData()
        }

        var mesh = MeshData()

        // Generate cross-section vertices for each frame
        var crossSections: [[SIMD3<Float>]] = []

        for (frame, profile) in zip(frames, profiles) {
            let vertices = RibbonGeometry.rectangularCrossSection(frame: frame, profile: profile)
            crossSections.append(vertices)
        }

        // Build the ribbon body (4 faces: top, bottom, left, right)
        buildRibbonBody(crossSections: crossSections, colors: colors, mesh: &mesh)

        // Add end caps if requested
        if addEndCaps {
            addStartCap(crossSection: crossSections[0], normal: -frames[0].tangent, color: colors[0], mesh: &mesh)
            addEndCap(crossSection: crossSections.last!, normal: frames.last!.tangent, color: colors.last!, mesh: &mesh)
        }

        return mesh
    }

    /// Builds a tube mesh from TNB frames
    /// - Parameters:
    ///   - frames: Array of TNB frames along the tube path
    ///   - radius: Tube radius
    ///   - colors: Per-frame colors
    ///   - sides: Number of sides for the tube
    ///   - addEndCaps: Whether to add end caps
    /// - Returns: MeshData for the tube
    public static func buildTubeMesh(
        frames: [TNBFrame],
        radius: Float,
        colors: [SIMD4<Float>],
        sides: Int = 8,
        addEndCaps: Bool = true
    ) -> MeshData {
        guard frames.count >= 2, frames.count == colors.count else {
            return MeshData()
        }

        var mesh = MeshData()

        // Generate circular cross-sections
        var crossSections: [[SIMD3<Float>]] = []
        var crossSectionNormals: [[SIMD3<Float>]] = []

        for frame in frames {
            crossSections.append(RibbonGeometry.circularCrossSection(frame: frame, radius: radius, sides: sides))
            crossSectionNormals.append(RibbonGeometry.circularCrossSectionNormals(frame: frame, sides: sides))
        }

        // Build tube body
        buildTubeBody(
            crossSections: crossSections,
            crossSectionNormals: crossSectionNormals,
            colors: colors,
            sides: sides,
            mesh: &mesh
        )

        // Add end caps
        if addEndCaps {
            addTubeEndCap(
                crossSection: crossSections[0],
                center: frames[0].position,
                normal: -frames[0].tangent,
                color: colors[0],
                sides: sides,
                mesh: &mesh
            )
            addTubeEndCap(
                crossSection: crossSections.last!,
                center: frames.last!.position,
                normal: frames.last!.tangent,
                color: colors.last!,
                sides: sides,
                mesh: &mesh
            )
        }

        return mesh
    }

    // MARK: - Smooth Ribbon Mesh

    /// Builds a smooth elliptical ribbon mesh from TNB frames
    /// Creates a more organic-looking ribbon with smooth curved surfaces
    /// - Parameters:
    ///   - frames: Array of TNB frames along the ribbon path
    ///   - profiles: Array of ribbon profiles (must match frame count)
    ///   - colors: Per-frame colors (must match frame count)
    ///   - segments: Number of segments around the ellipse (more = smoother)
    ///   - addEndCaps: Whether to add end caps
    /// - Returns: MeshData for the smooth ribbon
    public static func buildSmoothRibbonMesh(
        frames: [TNBFrame],
        profiles: [RibbonProfile],
        colors: [SIMD4<Float>],
        segments: Int = RibbonGeometry.smoothCrossSectionSegments,
        addEndCaps: Bool = true
    ) -> MeshData {
        guard frames.count >= 2, frames.count == profiles.count, frames.count == colors.count else {
            return MeshData()
        }

        var mesh = MeshData()

        // Generate elliptical cross-sections with smooth normals
        var crossSections: [[SIMD3<Float>]] = []
        var crossSectionNormals: [[SIMD3<Float>]] = []

        for (frame, profile) in zip(frames, profiles) {
            crossSections.append(RibbonGeometry.ellipticalCrossSection(
                frame: frame,
                profile: profile,
                segments: segments
            ))
            crossSectionNormals.append(RibbonGeometry.ellipticalCrossSectionNormals(
                frame: frame,
                profile: profile,
                segments: segments
            ))
        }

        // Build smooth ribbon body (similar to tube but with elliptical cross-sections)
        buildSmoothRibbonBody(
            crossSections: crossSections,
            crossSectionNormals: crossSectionNormals,
            colors: colors,
            segments: segments,
            mesh: &mesh
        )

        // Add elliptical end caps
        if addEndCaps {
            addEllipticalEndCap(
                crossSection: crossSections[0],
                center: frames[0].position,
                normal: -frames[0].tangent,
                color: colors[0],
                segments: segments,
                mesh: &mesh
            )
            addEllipticalEndCap(
                crossSection: crossSections.last!,
                center: frames.last!.position,
                normal: frames.last!.tangent,
                color: colors.last!,
                segments: segments,
                mesh: &mesh
            )
        }

        return mesh
    }

    /// Builds the body of a smooth ribbon from elliptical cross-sections
    private static func buildSmoothRibbonBody(
        crossSections: [[SIMD3<Float>]],
        crossSectionNormals: [[SIMD3<Float>]],
        colors: [SIMD4<Float>],
        segments: Int,
        mesh: inout MeshData
    ) {
        guard crossSections.count >= 2 else { return }

        let n = crossSections.count

        for i in 0..<(n - 1) {
            let cs0 = crossSections[i]
            let cs1 = crossSections[i + 1]
            let ns0 = crossSectionNormals[i]
            let ns1 = crossSectionNormals[i + 1]
            let color0 = colors[i]
            let color1 = colors[i + 1]

            for j in 0..<segments {
                let j1 = (j + 1) % segments

                let baseIndex = UInt32(mesh.positions.count)

                // Four vertices of the quad
                mesh.positions.append(contentsOf: [cs0[j], cs0[j1], cs1[j1], cs1[j]])
                mesh.normals.append(contentsOf: [ns0[j], ns0[j1], ns1[j1], ns1[j]])
                mesh.colors.append(contentsOf: [color0, color0, color1, color1])

                // Two triangles
                mesh.indices.append(contentsOf: [
                    baseIndex, baseIndex + 1, baseIndex + 2,
                    baseIndex, baseIndex + 2, baseIndex + 3
                ])
            }
        }
    }

    /// Adds an elliptical end cap
    private static func addEllipticalEndCap(
        crossSection: [SIMD3<Float>],
        center: SIMD3<Float>,
        normal: SIMD3<Float>,
        color: SIMD4<Float>,
        segments: Int,
        mesh: inout MeshData
    ) {
        let baseIndex = UInt32(mesh.positions.count)

        // Add center vertex
        mesh.positions.append(center)
        mesh.normals.append(normal)
        mesh.colors.append(color)

        // Add circumference vertices
        mesh.positions.append(contentsOf: crossSection)
        for _ in 0..<segments {
            mesh.normals.append(normal)
            mesh.colors.append(color)
        }

        // Create triangles from center to each edge
        for i in 0..<segments {
            let i1 = (i + 1) % segments
            mesh.indices.append(contentsOf: [
                baseIndex,
                baseIndex + 1 + UInt32(i),
                baseIndex + 1 + UInt32(i1)
            ])
        }
    }

    // MARK: - Private Methods

    /// Builds the main body of a ribbon from cross-sections
    private static func buildRibbonBody(
        crossSections: [[SIMD3<Float>]],
        colors: [SIMD4<Float>],
        mesh: inout MeshData
    ) {
        guard crossSections.count >= 2 else { return }

        let n = crossSections.count

        // For each pair of adjacent cross-sections
        for i in 0..<(n - 1) {
            let cs0 = crossSections[i]     // Current cross-section (4 vertices)
            let cs1 = crossSections[i + 1] // Next cross-section (4 vertices)
            let color0 = colors[i]
            let color1 = colors[i + 1]

            // Vertices: topLeft=0, topRight=1, bottomRight=2, bottomLeft=3

            // Top face (between vertices 0 and 1)
            addQuad(
                v0: cs0[0], v1: cs0[1], v2: cs1[1], v3: cs1[0],
                c0: color0, c1: color1,
                faceNormal: calculateFaceNormal(cs0[0], cs0[1], cs1[1]),
                mesh: &mesh
            )

            // Right face (between vertices 1 and 2)
            addQuad(
                v0: cs0[1], v1: cs0[2], v2: cs1[2], v3: cs1[1],
                c0: color0, c1: color1,
                faceNormal: calculateFaceNormal(cs0[1], cs0[2], cs1[2]),
                mesh: &mesh
            )

            // Bottom face (between vertices 2 and 3)
            addQuad(
                v0: cs0[2], v1: cs0[3], v2: cs1[3], v3: cs1[2],
                c0: color0, c1: color1,
                faceNormal: calculateFaceNormal(cs0[2], cs0[3], cs1[3]),
                mesh: &mesh
            )

            // Left face (between vertices 3 and 0)
            addQuad(
                v0: cs0[3], v1: cs0[0], v2: cs1[0], v3: cs1[3],
                c0: color0, c1: color1,
                faceNormal: calculateFaceNormal(cs0[3], cs0[0], cs1[0]),
                mesh: &mesh
            )
        }
    }

    /// Builds the body of a tube from circular cross-sections
    private static func buildTubeBody(
        crossSections: [[SIMD3<Float>]],
        crossSectionNormals: [[SIMD3<Float>]],
        colors: [SIMD4<Float>],
        sides: Int,
        mesh: inout MeshData
    ) {
        guard crossSections.count >= 2 else { return }

        let n = crossSections.count

        for i in 0..<(n - 1) {
            let cs0 = crossSections[i]
            let cs1 = crossSections[i + 1]
            let ns0 = crossSectionNormals[i]
            let ns1 = crossSectionNormals[i + 1]
            let color0 = colors[i]
            let color1 = colors[i + 1]

            for j in 0..<sides {
                let j1 = (j + 1) % sides

                // Add quad between two adjacent vertices on consecutive cross-sections
                let baseIndex = UInt32(mesh.positions.count)

                // Four vertices of the quad
                mesh.positions.append(contentsOf: [cs0[j], cs0[j1], cs1[j1], cs1[j]])
                mesh.normals.append(contentsOf: [ns0[j], ns0[j1], ns1[j1], ns1[j]])
                mesh.colors.append(contentsOf: [color0, color0, color1, color1])

                // Two triangles
                mesh.indices.append(contentsOf: [
                    baseIndex, baseIndex + 1, baseIndex + 2,
                    baseIndex, baseIndex + 2, baseIndex + 3
                ])
            }
        }
    }

    /// Adds a quad (two triangles) to the mesh
    private static func addQuad(
        v0: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>, v3: SIMD3<Float>,
        c0: SIMD4<Float>, c1: SIMD4<Float>,
        faceNormal: SIMD3<Float>,
        mesh: inout MeshData
    ) {
        let baseIndex = UInt32(mesh.positions.count)

        // Add vertices (v0, v1 are from current cross-section; v2, v3 are from next)
        mesh.positions.append(contentsOf: [v0, v1, v2, v3])
        mesh.normals.append(contentsOf: [faceNormal, faceNormal, faceNormal, faceNormal])
        mesh.colors.append(contentsOf: [c0, c0, c1, c1])

        // Triangle 1: v0, v1, v2
        // Triangle 2: v0, v2, v3
        mesh.indices.append(contentsOf: [
            baseIndex, baseIndex + 1, baseIndex + 2,
            baseIndex, baseIndex + 2, baseIndex + 3
        ])
    }

    /// Calculates face normal from three vertices
    private static func calculateFaceNormal(
        _ v0: SIMD3<Float>,
        _ v1: SIMD3<Float>,
        _ v2: SIMD3<Float>
    ) -> SIMD3<Float> {
        let edge1 = v1 - v0
        let edge2 = v2 - v0
        return simd_normalize(simd_cross(edge1, edge2))
    }

    /// Adds a start cap (rectangular) to close the ribbon end
    private static func addStartCap(
        crossSection: [SIMD3<Float>],
        normal: SIMD3<Float>,
        color: SIMD4<Float>,
        mesh: inout MeshData
    ) {
        guard crossSection.count == 4 else { return }

        let baseIndex = UInt32(mesh.positions.count)

        // Add the four corners
        mesh.positions.append(contentsOf: crossSection)
        mesh.normals.append(contentsOf: [normal, normal, normal, normal])
        mesh.colors.append(contentsOf: [color, color, color, color])

        // Two triangles to fill the rectangle (note: winding order for start cap)
        mesh.indices.append(contentsOf: [
            baseIndex, baseIndex + 3, baseIndex + 2,
            baseIndex, baseIndex + 2, baseIndex + 1
        ])
    }

    /// Adds an end cap (rectangular) to close the ribbon end
    private static func addEndCap(
        crossSection: [SIMD3<Float>],
        normal: SIMD3<Float>,
        color: SIMD4<Float>,
        mesh: inout MeshData
    ) {
        guard crossSection.count == 4 else { return }

        let baseIndex = UInt32(mesh.positions.count)

        // Add the four corners
        mesh.positions.append(contentsOf: crossSection)
        mesh.normals.append(contentsOf: [normal, normal, normal, normal])
        mesh.colors.append(contentsOf: [color, color, color, color])

        // Two triangles (opposite winding from start cap)
        mesh.indices.append(contentsOf: [
            baseIndex, baseIndex + 1, baseIndex + 2,
            baseIndex, baseIndex + 2, baseIndex + 3
        ])
    }

    /// Adds a circular end cap for tubes
    private static func addTubeEndCap(
        crossSection: [SIMD3<Float>],
        center: SIMD3<Float>,
        normal: SIMD3<Float>,
        color: SIMD4<Float>,
        sides: Int,
        mesh: inout MeshData
    ) {
        let baseIndex = UInt32(mesh.positions.count)

        // Add center vertex
        mesh.positions.append(center)
        mesh.normals.append(normal)
        mesh.colors.append(color)

        // Add circumference vertices
        mesh.positions.append(contentsOf: crossSection)
        for _ in 0..<sides {
            mesh.normals.append(normal)
            mesh.colors.append(color)
        }

        // Create triangles from center to each edge
        for i in 0..<sides {
            let i1 = (i + 1) % sides
            mesh.indices.append(contentsOf: [
                baseIndex,                    // Center
                baseIndex + 1 + UInt32(i),    // Current edge vertex
                baseIndex + 1 + UInt32(i1)    // Next edge vertex
            ])
        }
    }

    // MARK: - Arrow Head Generation

    /// Builds a proper 3D arrow head for beta sheet termini
    /// The arrow has wings extending outward and a tip pointing forward
    /// - Parameters:
    ///   - lastFrame: TNB frame at the end of the ribbon (arrow base)
    ///   - ribbonHalfWidth: Half-width of the ribbon body
    ///   - ribbonHalfThickness: Half-thickness of the ribbon
    ///   - arrowLength: Length of the arrow tip extending forward
    ///   - wingExtension: How much the wings extend beyond the ribbon width
    ///   - color: Color for the arrow head
    /// - Returns: MeshData for the arrow head
    public static func buildSheetArrowHead(
        lastFrame: TNBFrame,
        ribbonHalfWidth: Float,
        ribbonHalfThickness: Float,
        arrowLength: Float,
        wingExtension: Float,
        color: SIMD4<Float>
    ) -> MeshData {
        var mesh = MeshData()

        let pos = lastFrame.position
        let T = lastFrame.tangent
        let N = lastFrame.normal
        let B = lastFrame.binormal

        // Arrow geometry:
        // - Notch vertices: where the ribbon ends (at ribbon width)
        // - Wing vertices: extended outward beyond ribbon width
        // - Tip vertex: extends forward from the center

        let wingHalfWidth = ribbonHalfWidth + wingExtension
        let ht = ribbonHalfThickness

        // Vertices at the base (where arrow meets ribbon)
        // Top surface
        let notchTopLeft = pos + ribbonHalfWidth * N + ht * B
        let notchTopRight = pos - ribbonHalfWidth * N + ht * B
        let wingTopLeft = pos + wingHalfWidth * N + ht * B
        let wingTopRight = pos - wingHalfWidth * N + ht * B

        // Bottom surface
        let notchBottomLeft = pos + ribbonHalfWidth * N - ht * B
        let notchBottomRight = pos - ribbonHalfWidth * N - ht * B
        let wingBottomLeft = pos + wingHalfWidth * N - ht * B
        let wingBottomRight = pos - wingHalfWidth * N - ht * B

        // Tip vertices (top and bottom for thickness)
        let tipTop = pos + arrowLength * T + ht * B
        let tipBottom = pos + arrowLength * T - ht * B

        // === TOP FACE (two triangles forming the arrow) ===
        let topNormal = B

        // Left triangle: wingTopLeft -> tipTop -> notchTopLeft
        var baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [wingTopLeft, tipTop, notchTopLeft])
        mesh.normals.append(contentsOf: [topNormal, topNormal, topNormal])
        mesh.colors.append(contentsOf: [color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2])

        // Right triangle: notchTopRight -> tipTop -> wingTopRight
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [notchTopRight, tipTop, wingTopRight])
        mesh.normals.append(contentsOf: [topNormal, topNormal, topNormal])
        mesh.colors.append(contentsOf: [color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2])

        // Center quad connecting notches to tip (fills the gap)
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [notchTopLeft, tipTop, notchTopRight])
        mesh.normals.append(contentsOf: [topNormal, topNormal, topNormal])
        mesh.colors.append(contentsOf: [color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2])

        // === BOTTOM FACE (mirror of top, opposite winding) ===
        let bottomNormal = -B

        // Left triangle
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [wingBottomLeft, notchBottomLeft, tipBottom])
        mesh.normals.append(contentsOf: [bottomNormal, bottomNormal, bottomNormal])
        mesh.colors.append(contentsOf: [color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2])

        // Right triangle
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [notchBottomRight, wingBottomRight, tipBottom])
        mesh.normals.append(contentsOf: [bottomNormal, bottomNormal, bottomNormal])
        mesh.colors.append(contentsOf: [color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2])

        // Center triangle
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [notchBottomLeft, notchBottomRight, tipBottom])
        mesh.normals.append(contentsOf: [bottomNormal, bottomNormal, bottomNormal])
        mesh.colors.append(contentsOf: [color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2])

        // === SIDE EDGES (give the arrow thickness) ===

        // Left edge (from wingTopLeft to tipTop to wingBottomLeft to tipBottom)
        let leftEdgeNormal = simd_normalize(simd_cross(T, B) + N)
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [wingTopLeft, tipTop, tipBottom, wingBottomLeft])
        mesh.normals.append(contentsOf: [leftEdgeNormal, leftEdgeNormal, leftEdgeNormal, leftEdgeNormal])
        mesh.colors.append(contentsOf: [color, color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2, baseIdx, baseIdx + 2, baseIdx + 3])

        // Right edge
        let rightEdgeNormal = simd_normalize(simd_cross(T, B) - N)
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [wingTopRight, wingBottomRight, tipBottom, tipTop])
        mesh.normals.append(contentsOf: [rightEdgeNormal, rightEdgeNormal, rightEdgeNormal, rightEdgeNormal])
        mesh.colors.append(contentsOf: [color, color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2, baseIdx, baseIdx + 2, baseIdx + 3])

        // Back edges (wings extending from ribbon edge)
        // Left wing back
        let leftBackNormal = -T
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [notchTopLeft, notchBottomLeft, wingBottomLeft, wingTopLeft])
        mesh.normals.append(contentsOf: [leftBackNormal, leftBackNormal, leftBackNormal, leftBackNormal])
        mesh.colors.append(contentsOf: [color, color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2, baseIdx, baseIdx + 2, baseIdx + 3])

        // Right wing back
        let rightBackNormal = -T
        baseIdx = UInt32(mesh.positions.count)
        mesh.positions.append(contentsOf: [notchTopRight, wingTopRight, wingBottomRight, notchBottomRight])
        mesh.normals.append(contentsOf: [rightBackNormal, rightBackNormal, rightBackNormal, rightBackNormal])
        mesh.colors.append(contentsOf: [color, color, color, color])
        mesh.indices.append(contentsOf: [baseIdx, baseIdx + 1, baseIdx + 2, baseIdx, baseIdx + 2, baseIdx + 3])

        return mesh
    }
}

// MARK: - MeshResource Generation

extension MeshData {
    /// Creates a RealityKit MeshResource from this mesh data
    public func toMeshResource() throws -> MeshResource {
        guard !positions.isEmpty, !indices.isEmpty else {
            throw MeshBuilderError.emptyMesh
        }

        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)

        return try MeshResource.generate(from: [descriptor])
    }
}

// MARK: - Errors

public enum MeshBuilderError: Error {
    case emptyMesh
    case invalidData
}
