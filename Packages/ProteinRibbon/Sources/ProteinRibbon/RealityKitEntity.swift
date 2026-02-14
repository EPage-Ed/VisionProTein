//
//  RealityKitEntity.swift
//  ProteinRibbon
//
//  RealityKit ModelEntity assembly for protein ribbons.
//

import Foundation
import PDBKit
import simd
import RealityKit

#if os(iOS) || os(visionOS)
import UIKit
public typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
public typealias PlatformColor = NSColor
#endif

// MARK: - Entity Builder

/// Builds RealityKit ModelEntity from protein ribbon data
public struct RealityKitEntityBuilder {

    // MARK: - Main Entity Building

    @MainActor
    /// Builds a complete protein ribbon entity from parsed PDB structure
    /// - Parameters:
    ///   - structure: Parsed PDB structure
    ///   - options: Rendering options
    /// - Returns: ModelEntity containing the complete ribbon visualization
    public static func buildEntity(
        from structure: PDBStructure,
        options: ProteinRibbon.Options
    ) -> ModelEntity {
        // Build using continuous backbone approach for seamless connections
        let mesh = buildContinuousBackboneMesh(from: structure, options: options)
        return createEntity(from: mesh, options: options)
    }

    // MARK: - Continuous Backbone Building

    /// Data for a continuous backbone spline
    private struct BackboneData {
        let splinePoints: [SplinePoint]
        let frames: [TNBFrame]
        let segments: [SecondaryStructureSegment]
        let residueStructureTypes: [SecondaryStructureType]
    }

    /// Builds backbone data for a chain (spline + frames)
    /// This is shared across all segments to ensure alignment
    private static func buildBackboneData(
        residues: [PDBResidue],
        structure: PDBStructure,
        options: ProteinRibbon.Options
    ) -> BackboneData? {
        let caPositions: [SIMD3<Float>] = residues.compactMap { $0.caAtom?.position }
        guard caPositions.count >= 4 else { return nil }

        // Build ONE continuous spline through all CA atoms
        var splinePoints = SplineInterpolation.catmullRom(
            points: caPositions,
            samplesPerSegment: options.samplesPerResidue
        )

        // Apply position smoothing to remove kinks from the spline
        splinePoints = SplineInterpolation.smoothSplinePoints(
            splinePoints,
            iterations: options.frameSmoothingIterations,
            windowSize: 7
        )

        let positions = splinePoints.map { $0.position }

        // Generate TNB frames along the entire backbone
        var frames = TNBFrameGenerator.rotationMinimizingFrames(along: positions)

        // Apply additional frame smoothing to reduce twisting/spikey artifacts
        if options.frameSmoothingIterations > 0 {
            frames = frames.smoothed(iterations: options.frameSmoothingIterations * 2)
        }

        // Classify secondary structure
        let chainID = residues[0].chainID
        let chainHelices = structure.helices.filter { $0.startChain == chainID }
        let chainSheets = structure.sheets.filter { $0.startChain == chainID }
        print("Chain \(chainID): \(chainHelices.count) helices, \(chainSheets.count) sheets, \(residues.count) residues")
        let segments = SecondaryStructureClassifier.classify(
            residues: residues,
            helices: chainHelices,
            sheets: chainSheets
        )
        print("Chain \(chainID): classified into \(segments.count) segments: \(segments.map { "\($0.type)" }.joined(separator: ", "))")

        // Create lookup for residue index -> structure type
        var residueStructureTypes: [SecondaryStructureType] = Array(repeating: .coil, count: residues.count)
        for segment in segments {
            for i in segment.startIndex...segment.endIndex {
                if i < residueStructureTypes.count {
                    residueStructureTypes[i] = segment.type
                }
            }
        }

        return BackboneData(
            splinePoints: splinePoints,
            frames: frames,
            segments: segments,
            residueStructureTypes: residueStructureTypes
        )
    }

    /// Finds the frame index range for a segment
    private static func frameRange(
        for segment: SecondaryStructureSegment,
        splinePoints: [SplinePoint],
        totalFrames: Int
    ) -> (start: Int, end: Int)? {
        var startIdx: Int?
        var endIdx: Int?

        for (i, point) in splinePoints.enumerated() {
            if point.residueIndex >= segment.startIndex && point.residueIndex <= segment.endIndex {
                if startIdx == nil { startIdx = i }
                endIdx = i
            }
        }

        guard let start = startIdx, let end = endIdx, start < totalFrames, end < totalFrames else {
            return nil
        }

        return (start, end)
    }

    /// Builds a seamless mesh using continuous backbone spline
    /// Creates separate sub-meshes per segment type for proper coloring
    private static func buildContinuousBackboneMesh(
        from structure: PDBStructure,
        options: ProteinRibbon.Options
    ) -> MeshData {
        var combinedMesh = MeshData()

        // Process each chain separately
        for chainID in structure.chains {
            let chainResidues = structure.residues.filter { $0.chainID == chainID }
            guard chainResidues.count >= 4 else { continue }

            // Build shared backbone data for the chain
            guard let backbone = buildBackboneData(
                residues: chainResidues,
                structure: structure,
                options: options
            ) else { continue }

            // Build mesh for each segment using the shared backbone frames
            for segment in backbone.segments {
                guard let range = frameRange(
                    for: segment,
                    splinePoints: backbone.splinePoints,
                    totalFrames: backbone.frames.count
                ) else { continue }

                // Extract frames for this segment (with 1 frame overlap for continuity)
                let startIdx = max(0, range.start - 1)
                let endIdx = min(backbone.frames.count - 1, range.end + 1)
                let segmentFrames = Array(backbone.frames[startIdx...endIdx])

                guard segmentFrames.count >= 2 else { continue }

                // Get the color for this segment type
                let segmentColor = ColorSchemes.color(for: segment.type)
                let colors = Array(repeating: segmentColor, count: segmentFrames.count)

                // Build appropriate mesh for segment type
                let segmentMesh: MeshData
                switch segment.type {
                case .helix:
                    segmentMesh = buildHelixMesh(frames: segmentFrames, colors: colors, options: options)
                case .sheet:
                    segmentMesh = buildSheetMeshWithArrow(
                        frames: segmentFrames,
                        colors: colors,
                        options: options,
                        isAtChainEnd: range.end >= backbone.frames.count - 2
                    )
                case .coil:
                    segmentMesh = buildCoilMesh(frames: segmentFrames, colors: colors, options: options)
                }

                combinedMesh.append(segmentMesh)
            }
        }

        return combinedMesh
    }

    /// Builds sheet mesh with arrow head
    private static func buildSheetMeshWithArrow(
        frames: [TNBFrame],
        colors: [SIMD4<Float>],
        options: ProteinRibbon.Options,
        isAtChainEnd: Bool
    ) -> MeshData {
        guard frames.count >= 2 else { return MeshData() }

        let halfWidth = options.sheetWidth / 2.0
        let halfThickness = RibbonGeometry.defaultThickness / 2.0
        let uniformProfile = RibbonProfile(halfWidth: halfWidth, halfThickness: halfThickness)
        let profiles = Array(repeating: uniformProfile, count: frames.count)

        // Build smooth ribbon body without end caps (arrow will cap the end)
        var mesh = MeshBuilder.buildSmoothRibbonMesh(
            frames: frames,
            profiles: profiles,
            colors: colors,
            segments: options.smoothSegments,
            addEndCaps: false
        )

        // Add elliptical start cap
        let segments = options.smoothSegments
        let startCrossSection = RibbonGeometry.ellipticalCrossSection(
            frame: frames[0],
            profile: profiles[0],
            segments: segments
        )
        addEllipticalCapToMesh(
            crossSection: startCrossSection,
            center: frames[0].position,
            normal: -frames[0].tangent,
            color: colors[0],
            segments: segments,
            mesh: &mesh
        )

        // Add arrow head at the end
        let lastFrame = frames[frames.count - 1]
        let lastColor = colors[colors.count - 1]

        let arrowMesh = MeshBuilder.buildSheetArrowHead(
            lastFrame: lastFrame,
            ribbonHalfWidth: halfWidth,
            ribbonHalfThickness: halfThickness,
            arrowLength: options.sheetArrowLength,
            wingExtension: options.sheetArrowWingExtension,
            color: lastColor
        )

        mesh.append(arrowMesh)

        return mesh
    }

    /// Adds an elliptical cap to a mesh
    private static func addEllipticalCapToMesh(
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

    // MARK: - Legacy Segment-Based Building (kept for reference)

    /// Builds mesh for a single secondary structure segment
    /// Note: This method builds segments independently which can cause gaps
    /// Use buildContinuousBackboneMesh for seamless results
    private static func buildSegmentMesh(
        segment: SecondaryStructureSegment,
        residueColors: [SIMD4<Float>],
        options: ProteinRibbon.Options
    ) -> MeshData {
        // Extract CA positions from segment
        let caPositions = segment.caPositions

        guard caPositions.count >= 2 else {
            return MeshData()
        }

        // Get colors for this segment's residues
        let segmentColors = (segment.startIndex...segment.endIndex).map { i in
            i < residueColors.count ? residueColors[i] : ColorSchemes.coilColor
        }

        // Interpolate spline through CA positions
        let splinePoints = SplineInterpolation.catmullRom(
            points: caPositions,
            samplesPerSegment: options.samplesPerResidue
        )

        let positions = splinePoints.map { $0.position }

        // Generate TNB frames along the spline
        let frames = TNBFrameGenerator.rotationMinimizingFrames(along: positions)

        // Interpolate colors for spline points
        let splineColors = ColorSchemes.interpolateColors(
            residueColors: segmentColors,
            splinePoints: splinePoints
        )

        // Generate mesh based on segment type
        switch segment.type {
        case .helix:
            return buildHelixMesh(frames: frames, colors: splineColors, options: options)

        case .sheet:
            return buildSheetMesh(frames: frames, colors: splineColors, options: options)

        case .coil:
            return buildCoilMesh(frames: frames, colors: splineColors, options: options)
        }
    }

    /// Builds helix ribbon mesh with smooth elliptical cross-section
    private static func buildHelixMesh(
        frames: [TNBFrame],
        colors: [SIMD4<Float>],
        options: ProteinRibbon.Options
    ) -> MeshData {
        let profiles = RibbonGeometry.profiles(
            for: .helix,
            frameCount: frames.count,
            options: options
        )

        // Use smooth ribbon mesh for organic appearance
        return MeshBuilder.buildSmoothRibbonMesh(
            frames: frames,
            profiles: profiles,
            colors: colors,
            segments: options.smoothSegments,
            addEndCaps: true
        )
    }

    /// Builds sheet ribbon mesh with arrow head (legacy method)
    private static func buildSheetMesh(
        frames: [TNBFrame],
        colors: [SIMD4<Float>],
        options: ProteinRibbon.Options
    ) -> MeshData {
        return buildSheetMeshWithArrow(frames: frames, colors: colors, options: options, isAtChainEnd: true)
    }

    /// Builds coil tube mesh
    private static func buildCoilMesh(
        frames: [TNBFrame],
        colors: [SIMD4<Float>],
        options: ProteinRibbon.Options
    ) -> MeshData {
        // Use smoothSegments for tube sides to ensure smooth coils
        let tubeSides = Swift.max(8, options.smoothSegments)
        return MeshBuilder.buildTubeMesh(
            frames: frames,
            radius: options.coilRadius,
            colors: colors,
            sides: tubeSides,
            addEndCaps: true
        )
    }

    // MARK: - Entity Creation

    @MainActor
    /// Creates a RealityKit ModelEntity from mesh data
    private static func createEntity(
        from meshData: MeshData,
        options: ProteinRibbon.Options
    ) -> ModelEntity {
        guard !meshData.positions.isEmpty else {
            return ModelEntity()
        }

        do {
            // Scale positions
            let scaledMeshData = scaleMeshData(meshData, scale: options.scale)

            // Create mesh resource
            let meshResource = try scaledMeshData.toMeshResource()

            // Create material
            let material = createMaterial(options: options)

            // Create entity
            let entity = ModelEntity(mesh: meshResource, materials: [material])
            entity.name = "ProteinRibbon"

            return entity

        } catch {
            print("ProteinRibbon: Failed to create mesh - \(error)")
            return ModelEntity()
        }
    }

    /// Scales mesh positions from Angstroms to scene units
    private static func scaleMeshData(_ meshData: MeshData, scale: Float) -> MeshData {
        var scaled = meshData
        scaled.positions = meshData.positions.map { $0 * scale }
        return scaled
    }

    @MainActor
    /// Creates a RealityKit material
    private static func createMaterial(options: ProteinRibbon.Options) -> Material {
        var material = SimpleMaterial()

        // Use a neutral base color since we have per-vertex colors
        // Unfortunately, RealityKit doesn't directly support per-vertex colors
        // in SimpleMaterial, so we use a base color and rely on lighting
        material.color = .init(tint: .white)
        material.metallic = .init(floatLiteral: 0.0)
        material.roughness = .init(floatLiteral: 0.5)

        return material
    }

    // MARK: - Alternative: Per-Segment Entities with Proper Colors

    @MainActor
    /// Builds separate entities for each segment with proper material colors
    /// Uses shared backbone for seamless connections between segments
    public static func buildSegmentedEntities(
        from structure: PDBStructure,
        options: ProteinRibbon.Options
    ) -> [ModelEntity] {
        var entities: [ModelEntity] = []

        // Process each chain
        for chainID in structure.chains {
            let chainResidues = structure.residues.filter { $0.chainID == chainID }
            guard chainResidues.count >= 4 else { continue }

            // Build shared backbone data for the chain
            guard let backbone = buildBackboneData(
                residues: chainResidues,
                structure: structure,
                options: options
            ) else { continue }

            // Build separate entity for each segment
            for segment in backbone.segments {
                guard let range = frameRange(
                    for: segment,
                    splinePoints: backbone.splinePoints,
                    totalFrames: backbone.frames.count
                ) else { continue }

                // Extract frames for this segment (with overlap for continuity)
                let startIdx = max(0, range.start - 1)
                let endIdx = min(backbone.frames.count - 1, range.end + 1)
                let segmentFrames = Array(backbone.frames[startIdx...endIdx])

                guard segmentFrames.count >= 2 else { continue }

                // Get the color for this segment type
                let segmentColor = ColorSchemes.color(for: segment.type)
                let colors = Array(repeating: segmentColor, count: segmentFrames.count)

                // Build appropriate mesh for segment type
                let segmentMesh: MeshData
                switch segment.type {
                case .helix:
                    segmentMesh = buildHelixMesh(frames: segmentFrames, colors: colors, options: options)
                case .sheet:
                    segmentMesh = buildSheetMeshWithArrow(
                        frames: segmentFrames,
                        colors: colors,
                        options: options,
                        isAtChainEnd: range.end >= backbone.frames.count - 2
                    )
                case .coil:
                    segmentMesh = buildCoilMesh(frames: segmentFrames, colors: colors, options: options)
                }

                if !segmentMesh.positions.isEmpty {
                    let entity = createSegmentEntity(
                        meshData: segmentMesh,
                        type: segment.type,
                        chainID: chainID,
                        options: options
                    )
                    entities.append(entity)
                }
            }
        }

        return entities
    }

    @MainActor
    /// Creates an entity for a single segment with appropriate material color
    private static func createSegmentEntity(
        meshData: MeshData,
        type: SecondaryStructureType,
        chainID: String,
        options: ProteinRibbon.Options
    ) -> ModelEntity {
        guard !meshData.positions.isEmpty else {
            return ModelEntity()
        }

        do {
            let scaledMeshData = scaleMeshData(meshData, scale: options.scale)
            let meshResource = try scaledMeshData.toMeshResource()

            // Create material with structure-based color
            let color = ColorSchemes.color(for: type)
            let platformColor = PlatformColor(
                red: CGFloat(color.x),
                green: CGFloat(color.y),
                blue: CGFloat(color.z),
                alpha: CGFloat(color.w)
            )

            var material = SimpleMaterial()
            material.color = .init(tint: platformColor)
            material.metallic = .init(floatLiteral: 0.0)
            material.roughness = .init(floatLiteral: 0.5)

            let entity = ModelEntity(mesh: meshResource, materials: [material])
            entity.name = "\(type.rawValue.capitalized)_\(chainID)"

            return entity

        } catch {
            print("ProteinRibbon: Failed to create segment entity - \(error)")
            return ModelEntity()
        }
    }

    // MARK: - Parent Entity Builder

    @MainActor
    /// Creates a parent entity containing segment entities as children
    /// Segments use shared backbone for seamless connections
    public static func buildParentEntity(
        from structure: PDBStructure,
        options: ProteinRibbon.Options
    ) -> Entity {
        let parent = Entity()
        parent.name = "ProteinRibbon"

        let segmentEntities = buildSegmentedEntities(from: structure, options: options)

        for entity in segmentEntities {
            parent.addChild(entity)
        }

        return parent
    }
}

// MARK: - Convenience Extensions

extension ModelEntity {
    @MainActor
    /// Centers the entity at the origin based on its bounding box
    public func centerAtOrigin() {
        let bounds = self.visualBounds(relativeTo: nil)
        let center = bounds.center
        self.position = -center
    }
}

