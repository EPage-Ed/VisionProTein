//
//  ColorSchemes.swift
//  ProteinRibbon
//
//  Color schemes for protein ribbon visualization.
//

import Foundation
import PDBKit
import simd

// MARK: - Color Scheme

/// Available coloring schemes for ribbon visualization
public enum ColorScheme: String, CaseIterable {
    /// Color by secondary structure type (helix=red, sheet=blue, coil=green)
    case byStructure

    /// Color by chain ID (different color per chain)
    case byChain

    /// Gradient along backbone (N-terminus to C-terminus)
    case byResidue

    /// Color by amino acid chemical properties
    case byResidueType

    /// Custom single color
    case uniform
}

// MARK: - Color Utilities

/// Color generation for different coloring schemes
public struct ColorSchemes {

    // MARK: - Structure Colors

    /// Default color for alpha helices
    public static let helixColor = SIMD4<Float>(0.9, 0.2, 0.2, 1.0)  // Red

    /// Default color for beta sheets
    public static let sheetColor = SIMD4<Float>(0.2, 0.4, 0.9, 1.0)  // Blue

    /// Default color for coils/loops
    public static let coilColor = SIMD4<Float>(0.2, 0.8, 0.3, 1.0)   // Green

    // MARK: - Chain Colors

    /// Predefined colors for chains (cycles through for many chains)
    public static let chainColors: [SIMD4<Float>] = [
        SIMD4<Float>(0.12, 0.47, 0.71, 1.0),  // Blue
        SIMD4<Float>(1.00, 0.50, 0.05, 1.0),  // Orange
        SIMD4<Float>(0.17, 0.63, 0.17, 1.0),  // Green
        SIMD4<Float>(0.84, 0.15, 0.16, 1.0),  // Red
        SIMD4<Float>(0.58, 0.40, 0.74, 1.0),  // Purple
        SIMD4<Float>(0.55, 0.34, 0.29, 1.0),  // Brown
        SIMD4<Float>(0.89, 0.47, 0.76, 1.0),  // Pink
        SIMD4<Float>(0.50, 0.50, 0.50, 1.0),  // Gray
        SIMD4<Float>(0.74, 0.74, 0.13, 1.0),  // Yellow-green
        SIMD4<Float>(0.09, 0.75, 0.81, 1.0),  // Cyan
    ]

    // MARK: - Residue Type Colors

    /// Colors for hydrophobic amino acids
    public static let hydrophobicColor = SIMD4<Float>(0.8, 0.8, 0.2, 1.0)  // Yellow

    /// Colors for polar amino acids
    public static let polarColor = SIMD4<Float>(0.2, 0.8, 0.8, 1.0)        // Cyan

    /// Colors for positively charged amino acids
    public static let positiveColor = SIMD4<Float>(0.2, 0.4, 0.9, 1.0)     // Blue

    /// Colors for negatively charged amino acids
    public static let negativeColor = SIMD4<Float>(0.9, 0.2, 0.2, 1.0)     // Red

    /// Colors for special amino acids (glycine, proline, cysteine)
    public static let specialColor = SIMD4<Float>(0.8, 0.4, 0.8, 1.0)      // Magenta

    // MARK: - Amino Acid Classification

    /// Hydrophobic amino acids
    private static let hydrophobic = Set(["ALA", "VAL", "LEU", "ILE", "MET", "PHE", "TRP", "TYR"])

    /// Polar (uncharged) amino acids
    private static let polar = Set(["SER", "THR", "ASN", "GLN"])

    /// Positively charged amino acids
    private static let positive = Set(["LYS", "ARG", "HIS"])

    /// Negatively charged amino acids
    private static let negative = Set(["ASP", "GLU"])

    /// Special amino acids
    private static let special = Set(["GLY", "PRO", "CYS"])

    // MARK: - Color Generation

    /// Returns color for a secondary structure type
    public static func color(for structureType: SecondaryStructureType) -> SIMD4<Float> {
        switch structureType {
        case .helix: return helixColor
        case .sheet: return sheetColor
        case .coil: return coilColor
        }
    }

    /// Returns color for a chain ID
    public static func color(forChain chainID: String, chainList: [String]) -> SIMD4<Float> {
        guard let index = chainList.firstIndex(of: chainID) else {
            return chainColors[0]
        }
        return chainColors[index % chainColors.count]
    }

    /// Returns color based on residue position (gradient from N to C terminus)
    /// - Parameters:
    ///   - residueIndex: Index of the residue
    ///   - totalResidues: Total number of residues
    ///   - startColor: Color at N-terminus (default: blue)
    ///   - endColor: Color at C-terminus (default: red)
    public static func color(
        forResidueIndex residueIndex: Int,
        totalResidues: Int,
        startColor: SIMD4<Float> = SIMD4<Float>(0.2, 0.4, 0.9, 1.0),
        endColor: SIMD4<Float> = SIMD4<Float>(0.9, 0.2, 0.2, 1.0)
    ) -> SIMD4<Float> {
        guard totalResidues > 1 else { return startColor }

        let t = Float(residueIndex) / Float(totalResidues - 1)
        return simd_mix(startColor, endColor, SIMD4<Float>(repeating: t))
    }

    /// Returns color based on amino acid type
    public static func color(forResidueName name: String) -> SIMD4<Float> {
        let upperName = name.uppercased()

        if hydrophobic.contains(upperName) {
            return hydrophobicColor
        } else if polar.contains(upperName) {
            return polarColor
        } else if positive.contains(upperName) {
            return positiveColor
        } else if negative.contains(upperName) {
            return negativeColor
        } else if special.contains(upperName) {
            return specialColor
        }

        return coilColor  // Default for unknown
    }

    /// Returns color for a residue type
    public static func colorForResidueType(_ type: AminoAcid.AcidType) -> SIMD4<Float> {
        switch type {
        case .hydrophobic:
            return hydrophobicColor
        case .polar:
            return polarColor
        case .positiveCharged:
            return positiveColor
        case .negativeCharged:
            return negativeColor
        case .special:
            return specialColor
        case .unknown:
            return coilColor
        }
    }

    // MARK: - Batch Color Generation

    /// Generates colors for all residues in a structure using the specified scheme
    public static func generateColors(
        for residues: [PDBResidue],
        segments: [SecondaryStructureSegment],
        scheme: ColorScheme,
        uniformColor: SIMD4<Float> = SIMD4<Float>(0.7, 0.7, 0.7, 1.0)
    ) -> [SIMD4<Float>] {
        switch scheme {
        case .byStructure:
            return colorsByStructure(residues: residues, segments: segments)

        case .byChain:
            let chains = Array(Set(residues.map { $0.chainID })).sorted()
            return residues.map { color(forChain: $0.chainID, chainList: chains) }

        case .byResidue:
            return residues.enumerated().map { index, _ in
                color(forResidueIndex: index, totalResidues: residues.count)
            }

        case .byResidueType:
            return residues.map { color(forResidueName: $0.name) }

        case .uniform:
            return Array(repeating: uniformColor, count: residues.count)
        }
    }

    /// Generates colors based on secondary structure
    private static func colorsByStructure(
        residues: [PDBResidue],
        segments: [SecondaryStructureSegment]
    ) -> [SIMD4<Float>] {
        var colors = Array(repeating: coilColor, count: residues.count)

        for segment in segments {
            let segmentColor = color(for: segment.type)
            for i in segment.startIndex...segment.endIndex {
                if i < colors.count {
                    colors[i] = segmentColor
                }
            }
        }

        return colors
    }

    // MARK: - Interpolated Colors for Spline Points

    /// Generates colors for interpolated spline points based on residue colors
    public static func interpolateColors(
        residueColors: [SIMD4<Float>],
        splinePoints: [SplinePoint]
    ) -> [SIMD4<Float>] {
        guard !residueColors.isEmpty, !splinePoints.isEmpty else { return [] }

        return splinePoints.map { point in
            let index = point.residueIndex
            let t = point.t

            // Get current and next residue colors
            let currentColor = residueColors[min(index, residueColors.count - 1)]

            if index + 1 < residueColors.count {
                let nextColor = residueColors[index + 1]
                return simd_mix(currentColor, nextColor, SIMD4<Float>(repeating: t))
            }

            return currentColor
        }
    }

    // MARK: - Rainbow Gradient

    /// Generates rainbow colors along the backbone
    public static func rainbowColors(count: Int) -> [SIMD4<Float>] {
        guard count > 0 else { return [] }

        return (0..<count).map { i in
            let hue = Float(i) / Float(count)
            return hueToRGB(hue: hue)
        }
    }

    /// Converts hue (0-1) to RGB color
    private static func hueToRGB(hue: Float, saturation: Float = 0.9, brightness: Float = 0.9) -> SIMD4<Float> {
        let h = hue * 6.0
        let i = Int(h)
        let f = h - Float(i)
        let p = brightness * (1.0 - saturation)
        let q = brightness * (1.0 - saturation * f)
        let t = brightness * (1.0 - saturation * (1.0 - f))

        var r: Float, g: Float, b: Float

        switch i % 6 {
        case 0: r = brightness; g = t; b = p
        case 1: r = q; g = brightness; b = p
        case 2: r = p; g = brightness; b = t
        case 3: r = p; g = q; b = brightness
        case 4: r = t; g = p; b = brightness
        default: r = brightness; g = p; b = q
        }

        return SIMD4<Float>(r, g, b, 1.0)
    }
}

// MARK: - Color Blending

extension SIMD4 where Scalar == Float {
    /// Blends two colors
    public func blended(with other: SIMD4<Float>, factor: Float) -> SIMD4<Float> {
        return simd_mix(self, other, SIMD4<Float>(repeating: factor))
    }

    /// Darkens the color by a factor (0-1)
    public func darkened(by factor: Float) -> SIMD4<Float> {
        let clamped = Swift.max(0, Swift.min(1, factor))
        let f = 1.0 - clamped
        return SIMD4<Float>(self.x * f, self.y * f, self.z * f, self.w)
    }

    /// Lightens the color by a factor (0-1)
    public func lightened(by factor: Float) -> SIMD4<Float> {
        let f = Swift.max(0, Swift.min(1, factor))
        return SIMD4<Float>(
            self.x + (1.0 - self.x) * f,
            self.y + (1.0 - self.y) * f,
            self.z + (1.0 - self.z) * f,
            self.w
        )
    }
}
