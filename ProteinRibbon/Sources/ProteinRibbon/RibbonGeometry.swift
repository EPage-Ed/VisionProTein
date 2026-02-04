//
//  RibbonGeometry.swift
//  ProteinRibbon
//
//  Ribbon cross-section profiles and width calculations.
//

import Foundation
import simd

// MARK: - Ribbon Profile

/// Defines the cross-section shape of a ribbon segment
public struct RibbonProfile {
    /// Half-width in the normal direction (ribbon width)
    public let halfWidth: Float

    /// Half-thickness in the binormal direction
    public let halfThickness: Float

    /// Whether this is an arrow tip (for sheet endings)
    public let isArrowTip: Bool

    /// Arrow tip width multiplier (only used when isArrowTip is true)
    public let arrowWidthMultiplier: Float

    public init(halfWidth: Float, halfThickness: Float, isArrowTip: Bool = false, arrowWidthMultiplier: Float = 1.0) {
        self.halfWidth = halfWidth
        self.halfThickness = halfThickness
        self.isArrowTip = isArrowTip
        self.arrowWidthMultiplier = arrowWidthMultiplier
    }
}

// MARK: - Ribbon Geometry Generator

/// Generates ribbon cross-sections and profiles for different secondary structures
public struct RibbonGeometry {

    // MARK: - Default Dimensions (in Angstroms)

    /// Default width for alpha helices
    public static let defaultHelixWidth: Float = 1.2

    /// Default width for beta sheets
    public static let defaultSheetWidth: Float = 1.6

    /// Default radius for coils/loops
    public static let defaultCoilRadius: Float = 0.3

    /// Default ribbon thickness
    public static let defaultThickness: Float = 0.4

    /// Arrow head width multiplier for sheet endings
    public static let arrowWidthMultiplier: Float = 2.0

    /// Number of points used for arrow head transition
    public static let arrowTransitionPoints: Int = 4

    // MARK: - Profile Generation

    /// Generates ribbon profiles for a segment based on its secondary structure type
    /// - Parameters:
    ///   - type: Secondary structure type
    ///   - frameCount: Number of frames in the segment
    ///   - options: Rendering options
    /// - Returns: Array of profiles matching the frame count
    public static func profiles(
        for type: SecondaryStructureType,
        frameCount: Int,
        options: ProteinRibbon.Options
    ) -> [RibbonProfile] {
        guard frameCount > 0 else { return [] }

        switch type {
        case .helix:
            return helixProfiles(count: frameCount, options: options)
        case .sheet:
            return sheetProfiles(count: frameCount, options: options)
        case .coil:
            return coilProfiles(count: frameCount, options: options)
        }
    }

    /// Generates profiles for an alpha helix (uniform ribbon)
    private static func helixProfiles(count: Int, options: ProteinRibbon.Options) -> [RibbonProfile] {
        let halfWidth = options.helixWidth / 2.0
        let halfThickness = defaultThickness / 2.0

        return (0..<count).map { _ in
            RibbonProfile(halfWidth: halfWidth, halfThickness: halfThickness)
        }
    }

    /// Generates profiles for a beta sheet (ribbon with arrow at C-terminus)
    private static func sheetProfiles(count: Int, options: ProteinRibbon.Options) -> [RibbonProfile] {
        let baseHalfWidth = options.sheetWidth / 2.0
        let halfThickness = defaultThickness / 2.0

        guard count > arrowTransitionPoints else {
            // Short sheet, just use uniform width
            return (0..<count).map { _ in
                RibbonProfile(halfWidth: baseHalfWidth, halfThickness: halfThickness)
            }
        }

        var profiles: [RibbonProfile] = []

        // Main body of sheet (constant width)
        let bodyCount = count - arrowTransitionPoints
        for _ in 0..<bodyCount {
            profiles.append(RibbonProfile(halfWidth: baseHalfWidth, halfThickness: halfThickness))
        }

        // Arrow head transition (widening then tapering to point)
        let maxArrowHalfWidth = baseHalfWidth * arrowWidthMultiplier

        // First half: widen
        let widenCount = arrowTransitionPoints / 2
        for i in 0..<widenCount {
            let t = Float(i + 1) / Float(widenCount + 1)
            let width = smoothstep(baseHalfWidth, maxArrowHalfWidth, t)
            profiles.append(RibbonProfile(halfWidth: width, halfThickness: halfThickness))
        }

        // Second half: taper to point
        let taperCount = arrowTransitionPoints - widenCount
        for i in 0..<taperCount {
            let t = Float(i + 1) / Float(taperCount)
            let width = smoothstep(maxArrowHalfWidth, 0.0, t)
            let isLast = i == taperCount - 1
            profiles.append(RibbonProfile(
                halfWidth: width,
                halfThickness: halfThickness,
                isArrowTip: isLast,
                arrowWidthMultiplier: isLast ? 0.0 : 1.0
            ))
        }

        return profiles
    }

    /// Generates profiles for a coil (thin tube)
    private static func coilProfiles(count: Int, options: ProteinRibbon.Options) -> [RibbonProfile] {
        let radius = options.coilRadius

        return (0..<count).map { _ in
            RibbonProfile(halfWidth: radius, halfThickness: radius)
        }
    }

    // MARK: - Transition Profiles

    /// Generates smooth transition profiles between two structure types
    /// - Parameters:
    ///   - fromType: Starting structure type
    ///   - toType: Ending structure type
    ///   - transitionLength: Number of frames for the transition
    ///   - options: Rendering options
    /// - Returns: Array of transition profiles
    public static func transitionProfiles(
        from fromType: SecondaryStructureType,
        to toType: SecondaryStructureType,
        transitionLength: Int,
        options: ProteinRibbon.Options
    ) -> [RibbonProfile] {
        guard transitionLength > 0 else { return [] }

        let startProfile = defaultProfile(for: fromType, options: options)
        let endProfile = defaultProfile(for: toType, options: options)

        return (0..<transitionLength).map { i in
            let t = Float(i) / Float(transitionLength - 1)
            return interpolateProfile(from: startProfile, to: endProfile, t: smoothstep(0, 1, t))
        }
    }

    /// Returns the default profile for a structure type
    private static func defaultProfile(
        for type: SecondaryStructureType,
        options: ProteinRibbon.Options
    ) -> RibbonProfile {
        switch type {
        case .helix:
            return RibbonProfile(halfWidth: options.helixWidth / 2.0, halfThickness: defaultThickness / 2.0)
        case .sheet:
            return RibbonProfile(halfWidth: options.sheetWidth / 2.0, halfThickness: defaultThickness / 2.0)
        case .coil:
            return RibbonProfile(halfWidth: options.coilRadius, halfThickness: options.coilRadius)
        }
    }

    /// Interpolates between two profiles
    private static func interpolateProfile(
        from: RibbonProfile,
        to: RibbonProfile,
        t: Float
    ) -> RibbonProfile {
        return RibbonProfile(
            halfWidth: mix(from.halfWidth, to.halfWidth, t),
            halfThickness: mix(from.halfThickness, to.halfThickness, t)
        )
    }

    // MARK: - Cross-Section Vertices

    /// Generates vertices for a rectangular ribbon cross-section
    /// - Parameters:
    ///   - frame: TNB frame at this point
    ///   - profile: Ribbon profile defining dimensions
    /// - Returns: Four corner vertices (top-left, top-right, bottom-right, bottom-left)
    public static func rectangularCrossSection(
        frame: TNBFrame,
        profile: RibbonProfile
    ) -> [SIMD3<Float>] {
        let p = frame.position
        let n = frame.normal
        let b = frame.binormal

        let hw = profile.halfWidth
        let ht = profile.halfThickness

        // Four corners of the ribbon cross-section
        let topLeft = p + hw * n + ht * b
        let topRight = p - hw * n + ht * b
        let bottomRight = p - hw * n - ht * b
        let bottomLeft = p + hw * n - ht * b

        return [topLeft, topRight, bottomRight, bottomLeft]
    }

    /// Generates vertices for a circular (tube) cross-section
    /// - Parameters:
    ///   - frame: TNB frame at this point
    ///   - radius: Tube radius
    ///   - sides: Number of sides for the tube
    /// - Returns: Array of vertices around the tube circumference
    public static func circularCrossSection(
        frame: TNBFrame,
        radius: Float,
        sides: Int = 8
    ) -> [SIMD3<Float>] {
        let p = frame.position
        let n = frame.normal
        let b = frame.binormal

        var vertices: [SIMD3<Float>] = []

        for i in 0..<sides {
            let angle = Float(i) / Float(sides) * 2.0 * Float.pi
            let dir = cos(angle) * n + sin(angle) * b
            vertices.append(p + radius * dir)
        }

        return vertices
    }

    /// Generates normals for a circular cross-section
    public static func circularCrossSectionNormals(
        frame: TNBFrame,
        sides: Int = 8
    ) -> [SIMD3<Float>] {
        let n = frame.normal
        let b = frame.binormal

        var normals: [SIMD3<Float>] = []

        for i in 0..<sides {
            let angle = Float(i) / Float(sides) * 2.0 * Float.pi
            let normal = cos(angle) * n + sin(angle) * b
            normals.append(normal)
        }

        return normals
    }

    // MARK: - Utilities

    /// Linear interpolation
    private static func mix(_ a: Float, _ b: Float, _ t: Float) -> Float {
        return a + (b - a) * t
    }

    /// Smooth interpolation (cubic Hermite)
    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Smooth Elliptical Cross-Section

extension RibbonGeometry {
    /// Number of vertices per smooth cross-section
    public static let smoothCrossSectionSegments: Int = 12

    /// Generates an elliptical (smooth) cross-section for ribbons
    /// Creates a smooth curved shape that's wide in the normal direction and thin in the binormal direction
    /// - Parameters:
    ///   - frame: TNB frame at this point
    ///   - profile: Ribbon profile defining dimensions
    ///   - segments: Number of segments around the ellipse (more = smoother)
    /// - Returns: Array of vertices around the ellipse perimeter
    public static func ellipticalCrossSection(
        frame: TNBFrame,
        profile: RibbonProfile,
        segments: Int = smoothCrossSectionSegments
    ) -> [SIMD3<Float>] {
        let p = frame.position
        let n = frame.normal
        let b = frame.binormal

        let hw = profile.halfWidth      // Semi-major axis (width direction)
        let ht = profile.halfThickness  // Semi-minor axis (thickness direction)

        var vertices: [SIMD3<Float>] = []

        for i in 0..<segments {
            let angle = Float(i) / Float(segments) * 2.0 * Float.pi
            // Ellipse: x = a*cos(θ), y = b*sin(θ)
            let offsetN = hw * cos(angle)  // Width direction
            let offsetB = ht * sin(angle)  // Thickness direction
            vertices.append(p + offsetN * n + offsetB * b)
        }

        return vertices
    }

    /// Generates smooth normals for an elliptical cross-section
    /// - Parameters:
    ///   - frame: TNB frame at this point
    ///   - profile: Ribbon profile defining dimensions
    ///   - segments: Number of segments (must match ellipticalCrossSection)
    /// - Returns: Array of outward-pointing normals for each vertex
    public static func ellipticalCrossSectionNormals(
        frame: TNBFrame,
        profile: RibbonProfile,
        segments: Int = smoothCrossSectionSegments
    ) -> [SIMD3<Float>] {
        let n = frame.normal
        let b = frame.binormal

        let hw = profile.halfWidth
        let ht = profile.halfThickness

        var normals: [SIMD3<Float>] = []

        for i in 0..<segments {
            let angle = Float(i) / Float(segments) * 2.0 * Float.pi

            // For an ellipse, the outward normal at angle θ is:
            // n = (b*cos(θ), a*sin(θ)) normalized
            // where a is semi-major (hw) and b is semi-minor (ht)
            let normalN = ht * cos(angle)  // Note: swapped for proper normal direction
            let normalB = hw * sin(angle)

            let normal = simd_normalize(normalN * n + normalB * b)
            normals.append(normal)
        }

        return normals
    }

    /// Generates a smooth ribbon cross-section with flat top/bottom and rounded edges
    /// This creates a "pill" or "capsule" shape that's more ribbon-like
    /// - Parameters:
    ///   - frame: TNB frame at this point
    ///   - profile: Ribbon profile defining dimensions
    ///   - edgeSegments: Number of segments for each rounded edge
    /// - Returns: Tuple of (vertices, normals) around the cross-section
    public static func smoothRibbonCrossSection(
        frame: TNBFrame,
        profile: RibbonProfile,
        edgeSegments: Int = 4
    ) -> (vertices: [SIMD3<Float>], normals: [SIMD3<Float>]) {
        let p = frame.position
        let n = frame.normal
        let b = frame.binormal

        let hw = profile.halfWidth
        let ht = profile.halfThickness

        var vertices: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []

        // Top edge (flat, pointing up in binormal direction)
        let topFlatSegments = max(2, edgeSegments)
        for i in 0..<topFlatSegments {
            let t = Float(i) / Float(topFlatSegments)
            let x = hw * (1.0 - 2.0 * t)  // From +hw to -hw
            vertices.append(p + x * n + ht * b)
            normals.append(b)  // Top normal points up
        }

        // Right rounded edge (from top-right to bottom-right)
        for i in 0..<edgeSegments {
            let angle = Float(i) / Float(edgeSegments) * Float.pi  // 0 to π
            let offsetB = ht * cos(angle)
            vertices.append(p - hw * n + offsetB * b)
            normals.append(simd_normalize(-n + b * cos(angle)))
        }

        // Bottom edge (flat, pointing down)
        for i in 0..<topFlatSegments {
            let t = Float(i) / Float(topFlatSegments)
            let x = -hw + 2.0 * hw * t  // From -hw to +hw
            vertices.append(p + x * n - ht * b)
            normals.append(-b)  // Bottom normal points down
        }

        // Left rounded edge (from bottom-left to top-left)
        for i in 0..<edgeSegments {
            let angle = Float(i) / Float(edgeSegments) * Float.pi
            let offsetB = -ht * cos(angle)
            vertices.append(p + hw * n + offsetB * b)
            normals.append(simd_normalize(n + b * cos(angle)))
        }

        return (vertices, normals)
    }
}
