//
//  SplineInterpolation.swift
//  ProteinRibbon
//
//  Spline interpolation for smooth backbone curves.
//

import Foundation
import simd

// MARK: - Spline Point

/// A point on an interpolated curve with position and parameter
public struct SplinePoint {
    /// Position in 3D space
    public let position: SIMD3<Float>

    /// Parameter t along the spline segment (0-1)
    public let t: Float

    /// Index of the original control point segment this belongs to
    public let segmentIndex: Int

    /// Index of the original residue this corresponds to (for color assignment)
    public let residueIndex: Int
}

// MARK: - Spline Interpolation

/// Catmull-Rom and B-spline interpolation for smooth curves
public struct SplineInterpolation {

    // MARK: - Catmull-Rom Spline

    /// Interpolates a smooth curve through control points using Catmull-Rom spline
    /// - Parameters:
    ///   - points: Control points (e.g., C-alpha positions)
    ///   - samplesPerSegment: Number of samples between each pair of control points
    ///   - tension: Spline tension (0.5 is standard Catmull-Rom)
    /// - Returns: Array of interpolated spline points
    public static func catmullRom(
        points: [SIMD3<Float>],
        samplesPerSegment: Int = 8,
        tension: Float = 0.5
    ) -> [SplinePoint] {
        guard points.count >= 4 else {
            // Not enough points for Catmull-Rom, return original points
            return points.enumerated().map { index, point in
                SplinePoint(position: point, t: 0, segmentIndex: index, residueIndex: index)
            }
        }

        var result: [SplinePoint] = []
        let alpha = tension

        // Extend control points at start and end for smooth endpoints
        let extendedPoints = extendEndpoints(points)

        // Iterate through segments (using original point indices)
        for i in 0..<(points.count - 1) {
            // Get four control points (with offset due to extension)
            let p0 = extendedPoints[i]
            let p1 = extendedPoints[i + 1]
            let p2 = extendedPoints[i + 2]
            let p3 = extendedPoints[i + 3]

            // Generate samples for this segment
            for j in 0..<samplesPerSegment {
                let t = Float(j) / Float(samplesPerSegment)
                let position = catmullRomPoint(p0: p0, p1: p1, p2: p2, p3: p3, t: t, alpha: alpha)

                // Calculate residue index (interpolate between i and i+1)
                let residueIndex = i

                result.append(SplinePoint(
                    position: position,
                    t: t,
                    segmentIndex: i,
                    residueIndex: residueIndex
                ))
            }
        }

        // Add the final point
        result.append(SplinePoint(
            position: points.last!,
            t: 1.0,
            segmentIndex: points.count - 2,
            residueIndex: points.count - 1
        ))

        return result
    }

    /// Evaluates a single point on a Catmull-Rom spline segment
    private static func catmullRomPoint(
        p0: SIMD3<Float>,
        p1: SIMD3<Float>,
        p2: SIMD3<Float>,
        p3: SIMD3<Float>,
        t: Float,
        alpha: Float
    ) -> SIMD3<Float> {
        let t2 = t * t
        let t3 = t2 * t

        // Standard Catmull-Rom formula (broken into sub-expressions for compiler)
        let term1 = 2.0 * p1
        let term2 = (-p0 + p2) * t
        let term3a = 2.0 * p0 - 5.0 * p1
        let term3b = 4.0 * p2 - p3
        let term3 = (term3a + term3b) * t2
        let term4a = -p0 + 3.0 * p1
        let term4b = -3.0 * p2 + p3
        let term4 = (term4a + term4b) * t3

        let result = 0.5 * (term1 + term2 + term3 + term4)

        return result
    }

    // MARK: - B-Spline

    /// Interpolates a smooth curve using uniform cubic B-spline
    /// - Parameters:
    ///   - points: Control points
    ///   - samplesPerSegment: Number of samples between control points
    /// - Returns: Array of interpolated spline points
    public static func bSpline(
        points: [SIMD3<Float>],
        samplesPerSegment: Int = 8
    ) -> [SplinePoint] {
        guard points.count >= 4 else {
            return points.enumerated().map { index, point in
                SplinePoint(position: point, t: 0, segmentIndex: index, residueIndex: index)
            }
        }

        var result: [SplinePoint] = []

        // B-spline doesn't pass through control points, but is smoother
        for i in 0..<(points.count - 3) {
            let p0 = points[i]
            let p1 = points[i + 1]
            let p2 = points[i + 2]
            let p3 = points[i + 3]

            for j in 0..<samplesPerSegment {
                let t = Float(j) / Float(samplesPerSegment)
                let position = bSplinePoint(p0: p0, p1: p1, p2: p2, p3: p3, t: t)

                // Map to residue index (B-spline center is between p1 and p2)
                let residueIndex = i + 1

                result.append(SplinePoint(
                    position: position,
                    t: t,
                    segmentIndex: i,
                    residueIndex: residueIndex
                ))
            }
        }

        // Add final point
        if let last = points.last {
            result.append(SplinePoint(
                position: last,
                t: 1.0,
                segmentIndex: points.count - 4,
                residueIndex: points.count - 1
            ))
        }

        return result
    }

    /// Evaluates a single point on a uniform cubic B-spline segment
    private static func bSplinePoint(
        p0: SIMD3<Float>,
        p1: SIMD3<Float>,
        p2: SIMD3<Float>,
        p3: SIMD3<Float>,
        t: Float
    ) -> SIMD3<Float> {
        let t2 = t * t
        let t3 = t2 * t

        // B-spline basis functions
        let b0 = (1.0 - t) * (1.0 - t) * (1.0 - t) / 6.0
        let b1 = (3.0 * t3 - 6.0 * t2 + 4.0) / 6.0
        let b2 = (-3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0) / 6.0
        let b3 = t3 / 6.0

        return p0 * b0 + p1 * b1 + p2 * b2 + p3 * b3
    }

    // MARK: - Hermite Spline

    /// Interpolates using Hermite spline with automatic tangent calculation
    /// - Parameters:
    ///   - points: Control points
    ///   - samplesPerSegment: Number of samples between control points
    /// - Returns: Array of interpolated spline points
    public static func hermite(
        points: [SIMD3<Float>],
        samplesPerSegment: Int = 8
    ) -> [SplinePoint] {
        guard points.count >= 2 else {
            return points.enumerated().map { index, point in
                SplinePoint(position: point, t: 0, segmentIndex: index, residueIndex: index)
            }
        }

        // Calculate tangents using finite differences
        var tangents: [SIMD3<Float>] = []
        for i in 0..<points.count {
            if i == 0 {
                tangents.append(points[1] - points[0])
            } else if i == points.count - 1 {
                tangents.append(points[i] - points[i - 1])
            } else {
                tangents.append(0.5 * (points[i + 1] - points[i - 1]))
            }
        }

        var result: [SplinePoint] = []

        for i in 0..<(points.count - 1) {
            let p0 = points[i]
            let p1 = points[i + 1]
            let m0 = tangents[i]
            let m1 = tangents[i + 1]

            for j in 0..<samplesPerSegment {
                let t = Float(j) / Float(samplesPerSegment)
                let position = hermitePoint(p0: p0, p1: p1, m0: m0, m1: m1, t: t)

                result.append(SplinePoint(
                    position: position,
                    t: t,
                    segmentIndex: i,
                    residueIndex: i
                ))
            }
        }

        // Add final point
        result.append(SplinePoint(
            position: points.last!,
            t: 1.0,
            segmentIndex: points.count - 2,
            residueIndex: points.count - 1
        ))

        return result
    }

    /// Evaluates a single point on a Hermite spline segment
    private static func hermitePoint(
        p0: SIMD3<Float>,
        p1: SIMD3<Float>,
        m0: SIMD3<Float>,
        m1: SIMD3<Float>,
        t: Float
    ) -> SIMD3<Float> {
        let t2 = t * t
        let t3 = t2 * t

        // Hermite basis functions
        let h00 = 2.0 * t3 - 3.0 * t2 + 1.0
        let h10 = t3 - 2.0 * t2 + t
        let h01 = -2.0 * t3 + 3.0 * t2
        let h11 = t3 - t2

        return h00 * p0 + h10 * m0 + h01 * p1 + h11 * m1
    }

    // MARK: - Utilities

    /// Extends endpoints to create smoother curve ends
    private static func extendEndpoints(_ points: [SIMD3<Float>]) -> [SIMD3<Float>] {
        guard points.count >= 2 else { return points }

        var extended = points

        // Extend start: reflect first point about second
        let startExtension = 2.0 * points[0] - points[1]
        extended.insert(startExtension, at: 0)

        // Extend end: reflect last point about second-to-last
        let endExtension = 2.0 * points[points.count - 1] - points[points.count - 2]
        extended.append(endExtension)

        return extended
    }

    /// Calculates arc length along the spline
    public static func arcLength(of points: [SplinePoint]) -> Float {
        guard points.count >= 2 else { return 0 }

        var length: Float = 0
        for i in 1..<points.count {
            length += simd_distance(points[i - 1].position, points[i].position)
        }
        return length
    }

    /// Smooths an array of positions using a moving average filter
    /// - Parameters:
    ///   - positions: Input positions
    ///   - iterations: Number of smoothing passes
    ///   - windowSize: Size of averaging window (must be odd, will be adjusted if even)
    /// - Returns: Smoothed positions
    public static func smoothPositions(
        _ positions: [SIMD3<Float>],
        iterations: Int = 2,
        windowSize: Int = 5
    ) -> [SIMD3<Float>] {
        guard positions.count >= 3 else { return positions }

        let halfWindow = windowSize / 2
        var result = positions

        for _ in 0..<iterations {
            var smoothed: [SIMD3<Float>] = []

            for i in 0..<result.count {
                // Calculate weighted average within window
                var sum = SIMD3<Float>.zero
                var weightSum: Float = 0

                for j in -halfWindow...halfWindow {
                    let idx = i + j
                    if idx >= 0 && idx < result.count {
                        // Gaussian-like weighting: closer points have more weight
                        let distance = abs(Float(j))
                        let weight = 1.0 / (1.0 + distance * 0.5)
                        sum += result[idx] * weight
                        weightSum += weight
                    }
                }

                smoothed.append(sum / weightSum)
            }

            result = smoothed
        }

        return result
    }

    /// Smooths spline points while preserving their metadata
    public static func smoothSplinePoints(
        _ points: [SplinePoint],
        iterations: Int = 2,
        windowSize: Int = 5
    ) -> [SplinePoint] {
        guard points.count >= 3 else { return points }

        let positions = points.map { $0.position }
        let smoothedPositions = smoothPositions(positions, iterations: iterations, windowSize: windowSize)

        return zip(points, smoothedPositions).map { original, newPosition in
            SplinePoint(
                position: newPosition,
                t: original.t,
                segmentIndex: original.segmentIndex,
                residueIndex: original.residueIndex
            )
        }
    }

    /// Resamples spline points to have uniform arc length spacing
    public static func resampleUniform(
        points: [SplinePoint],
        targetCount: Int
    ) -> [SplinePoint] {
        guard points.count >= 2, targetCount >= 2 else { return points }

        let totalLength = arcLength(of: points)
        let segmentLength = totalLength / Float(targetCount - 1)

        var result: [SplinePoint] = [points[0]]
        var accumulatedLength: Float = 0
        var targetLength = segmentLength

        for i in 1..<points.count {
            let distance = simd_distance(points[i - 1].position, points[i].position)
            accumulatedLength += distance

            while accumulatedLength >= targetLength && result.count < targetCount - 1 {
                // Interpolate position
                let overshoot = accumulatedLength - targetLength
                let ratio = 1.0 - overshoot / distance
                let position = simd_mix(points[i - 1].position, points[i].position, SIMD3<Float>(repeating: ratio))

                result.append(SplinePoint(
                    position: position,
                    t: ratio,
                    segmentIndex: points[i].segmentIndex,
                    residueIndex: points[i].residueIndex
                ))

                targetLength += segmentLength
            }
        }

        // Ensure we have the last point
        if result.count < targetCount {
            result.append(points.last!)
        }

        return result
    }
}
