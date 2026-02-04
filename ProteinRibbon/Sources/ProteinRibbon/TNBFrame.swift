//
//  TNBFrame.swift
//  ProteinRibbon
//
//  Tangent-Normal-Binormal frame generation for ribbon geometry.
//

import Foundation
import simd

// MARK: - TNB Frame

/// Represents a local coordinate frame along a curve
public struct TNBFrame {
    /// Tangent vector (direction of curve)
    public var tangent: SIMD3<Float>

    /// Normal vector (perpendicular to tangent, defines ribbon width direction)
    public var normal: SIMD3<Float>

    /// Binormal vector (perpendicular to both tangent and normal)
    public var binormal: SIMD3<Float>

    /// Position on the curve
    public var position: SIMD3<Float>

    /// Initialize with orthonormal basis
    public init(position: SIMD3<Float>, tangent: SIMD3<Float>, normal: SIMD3<Float>, binormal: SIMD3<Float>) {
        self.position = position
        self.tangent = tangent
        self.normal = normal
        self.binormal = binormal
    }

    /// Creates a rotation matrix from this frame
    public var rotationMatrix: simd_float3x3 {
        simd_float3x3(columns: (tangent, normal, binormal))
    }
}

// MARK: - TNB Frame Generator

/// Generates stable TNB frames along a curve
public struct TNBFrameGenerator {

    // MARK: - Frenet-Serret Frames

    /// Generates Frenet-Serret frames along a curve
    /// - Parameter points: Curve points (from spline interpolation)
    /// - Returns: Array of TNB frames
    public static func frenetFrames(along points: [SIMD3<Float>]) -> [TNBFrame] {
        guard points.count >= 3 else {
            return simpleFrames(along: points)
        }

        var frames: [TNBFrame] = []

        for i in 0..<points.count {
            let tangent = computeTangent(at: i, points: points)
            let (normal, binormal) = computeFrenetNormalBinormal(at: i, points: points, tangent: tangent)

            frames.append(TNBFrame(
                position: points[i],
                tangent: tangent,
                normal: normal,
                binormal: binormal
            ))
        }

        return frames
    }

    // MARK: - Rotation-Minimizing Frames (RMF)

    /// Generates rotation-minimizing frames along a curve
    /// These frames avoid the flipping/twisting artifacts of Frenet frames
    /// - Parameters:
    ///   - points: Curve points
    ///   - initialNormal: Optional initial normal direction (uses peptide plane if nil)
    /// - Returns: Array of TNB frames with minimized rotation
    public static func rotationMinimizingFrames(
        along points: [SIMD3<Float>],
        initialNormal: SIMD3<Float>? = nil
    ) -> [TNBFrame] {
        guard points.count >= 2 else {
            return simpleFrames(along: points)
        }

        var frames: [TNBFrame] = []

        // Compute initial frame
        let t0 = computeTangent(at: 0, points: points)
        var n0: SIMD3<Float>

        if let initial = initialNormal {
            // Use provided initial normal, orthogonalized against tangent
            n0 = orthogonalize(initial, against: t0)
        } else {
            // Use a default perpendicular vector
            n0 = computeInitialNormal(tangent: t0)
        }

        let b0 = simd_normalize(simd_cross(t0, n0))

        frames.append(TNBFrame(position: points[0], tangent: t0, normal: n0, binormal: b0))

        // Propagate frames using double reflection method
        for i in 1..<points.count {
            let prevFrame = frames[i - 1]
            let ti = computeTangent(at: i, points: points)

            // Double reflection method for rotation-minimizing frames
            let (ni, bi) = propagateRMF(
                prevTangent: prevFrame.tangent,
                prevNormal: prevFrame.normal,
                prevBinormal: prevFrame.binormal,
                currentTangent: ti
            )

            frames.append(TNBFrame(position: points[i], tangent: ti, normal: ni, binormal: bi))
        }

        return frames
    }

    // MARK: - Peptide Plane Guided Frames

    /// Generates frames using peptide plane orientation from backbone atoms
    /// - Parameters:
    ///   - caPositions: C-alpha positions
    ///   - cPositions: Carbonyl carbon positions (optional)
    ///   - oPositions: Carbonyl oxygen positions (optional)
    ///   - samplesPerSegment: Number of interpolated samples between residues
    /// - Returns: Array of TNB frames
    public static func peptidePlaneFrames(
        caPositions: [SIMD3<Float>],
        cPositions: [SIMD3<Float>]? = nil,
        oPositions: [SIMD3<Float>]? = nil,
        samplesPerSegment: Int = 8
    ) -> [TNBFrame] {
        // First, interpolate the CA positions
        let splinePoints = SplineInterpolation.catmullRom(
            points: caPositions,
            samplesPerSegment: samplesPerSegment
        )

        let positions = splinePoints.map { $0.position }

        // If we have carbonyl oxygen positions, use them to define peptide plane normals
        if let oPos = oPositions, oPos.count == caPositions.count {
            return peptidePlaneGuidedRMF(
                curvePositions: positions,
                caPositions: caPositions,
                oPositions: oPos,
                splinePoints: splinePoints
            )
        }

        // Fall back to rotation-minimizing frames
        return rotationMinimizingFrames(along: positions)
    }

    /// Generates RMF frames guided by peptide plane orientation
    private static func peptidePlaneGuidedRMF(
        curvePositions: [SIMD3<Float>],
        caPositions: [SIMD3<Float>],
        oPositions: [SIMD3<Float>],
        splinePoints: [SplinePoint]
    ) -> [TNBFrame] {
        guard curvePositions.count >= 2 else {
            return simpleFrames(along: curvePositions)
        }

        // Compute peptide plane normals at each residue
        var peptideNormals: [SIMD3<Float>] = []
        for i in 0..<caPositions.count {
            if i < oPositions.count {
                // Normal points from CA to O (roughly perpendicular to backbone)
                let caToO = oPositions[i] - caPositions[i]
                peptideNormals.append(simd_normalize(caToO))
            } else {
                peptideNormals.append(SIMD3<Float>(0, 1, 0))
            }
        }

        var frames: [TNBFrame] = []

        // First frame
        let t0 = computeTangent(at: 0, points: curvePositions)
        let n0 = orthogonalize(peptideNormals[0], against: t0)
        let b0 = simd_normalize(simd_cross(t0, n0))

        frames.append(TNBFrame(position: curvePositions[0], tangent: t0, normal: n0, binormal: b0))

        // Propagate with RMF
        for i in 1..<curvePositions.count {
            let prevFrame = frames[i - 1]
            let ti = computeTangent(at: i, points: curvePositions)

            let (ni, bi) = propagateRMF(
                prevTangent: prevFrame.tangent,
                prevNormal: prevFrame.normal,
                prevBinormal: prevFrame.binormal,
                currentTangent: ti
            )

            frames.append(TNBFrame(position: curvePositions[i], tangent: ti, normal: ni, binormal: bi))
        }

        return frames
    }

    // MARK: - Private Helpers

    /// Computes tangent vector at a point using finite differences
    private static func computeTangent(at index: Int, points: [SIMD3<Float>]) -> SIMD3<Float> {
        if index == 0 {
            return simd_normalize(points[1] - points[0])
        } else if index == points.count - 1 {
            return simd_normalize(points[index] - points[index - 1])
        } else {
            return simd_normalize(points[index + 1] - points[index - 1])
        }
    }

    /// Computes Frenet normal and binormal from curvature
    private static func computeFrenetNormalBinormal(
        at index: Int,
        points: [SIMD3<Float>],
        tangent: SIMD3<Float>
    ) -> (normal: SIMD3<Float>, binormal: SIMD3<Float>) {
        // Compute second derivative for curvature direction
        var secondDeriv: SIMD3<Float>

        if index == 0 {
            secondDeriv = points[2] - 2 * points[1] + points[0]
        } else if index == points.count - 1 {
            secondDeriv = points[index] - 2 * points[index - 1] + points[index - 2]
        } else {
            secondDeriv = points[index + 1] - 2 * points[index] + points[index - 1]
        }

        // Normal is in the direction of curvature
        let curvatureNormal = secondDeriv - simd_dot(secondDeriv, tangent) * tangent
        let curvatureMag = simd_length(curvatureNormal)

        // If curvature is near zero, use arbitrary perpendicular
        if curvatureMag < 0.0001 {
            let normal = computeInitialNormal(tangent: tangent)
            let binormal = simd_normalize(simd_cross(tangent, normal))
            return (normal, binormal)
        }

        let normal = simd_normalize(curvatureNormal)
        let binormal = simd_normalize(simd_cross(tangent, normal))

        return (normal, binormal)
    }

    /// Computes an initial normal perpendicular to the tangent
    private static func computeInitialNormal(tangent: SIMD3<Float>) -> SIMD3<Float> {
        // Choose a reference vector not parallel to tangent
        let up = SIMD3<Float>(0, 1, 0)
        let right = SIMD3<Float>(1, 0, 0)

        let ref = abs(simd_dot(tangent, up)) > 0.9 ? right : up
        return simd_normalize(simd_cross(ref, tangent))
    }

    /// Orthogonalizes a vector against another (Gram-Schmidt)
    private static func orthogonalize(_ v: SIMD3<Float>, against t: SIMD3<Float>) -> SIMD3<Float> {
        let projection = simd_dot(v, t) * t
        let orthogonal = v - projection
        let length = simd_length(orthogonal)

        if length < 0.0001 {
            return computeInitialNormal(tangent: t)
        }

        return simd_normalize(orthogonal)
    }

    /// Propagates frame using double reflection method (rotation-minimizing)
    private static func propagateRMF(
        prevTangent: SIMD3<Float>,
        prevNormal: SIMD3<Float>,
        prevBinormal: SIMD3<Float>,
        currentTangent: SIMD3<Float>
    ) -> (normal: SIMD3<Float>, binormal: SIMD3<Float>) {
        // Reflection 1: across the bisector plane
        let v1 = currentTangent - prevTangent
        let c1 = simd_dot(v1, v1)

        if c1 < 0.0001 {
            // Tangents nearly identical, keep previous frame
            return (prevNormal, prevBinormal)
        }

        // Reflect normal across bisector
        let rL = prevNormal - (2.0 / c1) * simd_dot(v1, prevNormal) * v1
        let tL = prevTangent - (2.0 / c1) * simd_dot(v1, prevTangent) * v1

        // Reflection 2: across tangent plane
        let v2 = currentTangent - tL
        let c2 = simd_dot(v2, v2)

        var normal: SIMD3<Float>
        if c2 < 0.0001 {
            normal = rL
        } else {
            normal = rL - (2.0 / c2) * simd_dot(v2, rL) * v2
        }

        normal = simd_normalize(normal)
        let binormal = simd_normalize(simd_cross(currentTangent, normal))

        return (normal, binormal)
    }

    /// Simple frames for degenerate cases
    private static func simpleFrames(along points: [SIMD3<Float>]) -> [TNBFrame] {
        guard !points.isEmpty else { return [] }

        if points.count == 1 {
            return [TNBFrame(
                position: points[0],
                tangent: SIMD3<Float>(1, 0, 0),
                normal: SIMD3<Float>(0, 1, 0),
                binormal: SIMD3<Float>(0, 0, 1)
            )]
        }

        var frames: [TNBFrame] = []
        for i in 0..<points.count {
            let tangent = computeTangent(at: i, points: points)
            let normal = computeInitialNormal(tangent: tangent)
            let binormal = simd_normalize(simd_cross(tangent, normal))

            frames.append(TNBFrame(
                position: points[i],
                tangent: tangent,
                normal: normal,
                binormal: binormal
            ))
        }

        return frames
    }
}

// MARK: - Frame Smoothing

extension Array where Element == TNBFrame {
    /// Smooths frame normals to reduce visual discontinuities
    /// Uses a wider averaging window for smoother results
    public func smoothed(iterations: Int = 2, windowSize: Int = 5) -> [TNBFrame] {
        guard count >= 3 else { return self }

        var frames = self
        let halfWindow = windowSize / 2

        for _ in 0..<iterations {
            var newFrames: [TNBFrame] = []

            for i in 0..<frames.count {
                // Keep endpoints fixed to maintain overall orientation
                if i < halfWindow || i >= frames.count - halfWindow {
                    newFrames.append(frames[i])
                    continue
                }

                // Weighted average of normals within window
                var avgNormal = SIMD3<Float>.zero
                var totalWeight: Float = 0

                for j in -halfWindow...halfWindow {
                    let idx = i + j
                    if idx >= 0 && idx < frames.count {
                        // Gaussian-like weighting: closer frames have more weight
                        let distance = abs(Float(j))
                        let weight = exp(-distance * distance / Float(halfWindow))
                        avgNormal += frames[idx].normal * weight
                        totalWeight += weight
                    }
                }

                avgNormal = simd_normalize(avgNormal / totalWeight)

                // Orthogonalize against tangent to maintain valid frame
                let tangent = frames[i].tangent
                let projectedNormal = avgNormal - simd_dot(avgNormal, tangent) * tangent
                let normalLength = simd_length(projectedNormal)

                // If projected normal is too small, keep original
                let normal: SIMD3<Float>
                if normalLength > 0.001 {
                    normal = projectedNormal / normalLength
                } else {
                    normal = frames[i].normal
                }

                let binormal = simd_normalize(simd_cross(tangent, normal))

                newFrames.append(TNBFrame(
                    position: frames[i].position,
                    tangent: tangent,
                    normal: normal,
                    binormal: binormal
                ))
            }

            frames = newFrames
        }

        return frames
    }
}
