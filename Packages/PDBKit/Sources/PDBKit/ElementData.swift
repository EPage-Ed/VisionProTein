//
//  ElementData.swift
//  PDBKit
//
//  Canonical CPK element colors and van der Waals radii.
//  All other packages and the main app should source these values from here.
//

import simd

// MARK: - CPK Element Colors

/// Standard CPK (Corey-Pauling-Koltun) element colors as SIMD4<Float> RGBA.
/// RGB values are derived from the Jmol/CPK color table.
/// Isotope variants with dashes (D, T, C-13, etc.) are omitted.
/// Unknown elements fall back to mid-gray (0.5, 0.5, 0.5, 1.0).
public struct CPKColors {
    public static let colors: [String: SIMD4<Float>] = [
        "H":  SIMD4<Float>(1.000, 1.000, 1.000, 1.0),
        "HE": SIMD4<Float>(0.851, 1.000, 1.000, 1.0),
        "LI": SIMD4<Float>(0.800, 0.502, 1.000, 1.0),
        "BE": SIMD4<Float>(0.761, 1.000, 0.000, 1.0),
        "B":  SIMD4<Float>(1.000, 0.710, 0.710, 1.0),
        "C":  SIMD4<Float>(0.565, 0.565, 0.565, 1.0),
        "N":  SIMD4<Float>(0.188, 0.314, 0.973, 1.0),
        "O":  SIMD4<Float>(1.000, 0.051, 0.051, 1.0),
        "F":  SIMD4<Float>(0.565, 0.878, 0.314, 1.0),
        "NE": SIMD4<Float>(0.702, 0.890, 0.961, 1.0),
        "NA": SIMD4<Float>(0.671, 0.361, 0.949, 1.0),
        "MG": SIMD4<Float>(0.541, 1.000, 0.000, 1.0),
        "AL": SIMD4<Float>(0.749, 0.651, 0.651, 1.0),
        "SI": SIMD4<Float>(0.941, 0.784, 0.627, 1.0),
        "P":  SIMD4<Float>(1.000, 0.502, 0.000, 1.0),
        "S":  SIMD4<Float>(1.000, 1.000, 0.188, 1.0),
        "CL": SIMD4<Float>(0.122, 0.941, 0.122, 1.0),
        "AR": SIMD4<Float>(0.502, 0.820, 0.890, 1.0),
        "K":  SIMD4<Float>(0.561, 0.251, 0.831, 1.0),
        "CA": SIMD4<Float>(0.239, 1.000, 0.000, 1.0),
        "SC": SIMD4<Float>(0.902, 0.902, 0.902, 1.0),
        "TI": SIMD4<Float>(0.749, 0.761, 0.780, 1.0),
        "V":  SIMD4<Float>(0.651, 0.651, 0.671, 1.0),
        "CR": SIMD4<Float>(0.541, 0.600, 0.780, 1.0),
        "MN": SIMD4<Float>(0.612, 0.478, 0.780, 1.0),
        "FE": SIMD4<Float>(0.878, 0.400, 0.200, 1.0),
        "CO": SIMD4<Float>(0.941, 0.565, 0.627, 1.0),
        "NI": SIMD4<Float>(0.314, 0.816, 0.314, 1.0),
        "CU": SIMD4<Float>(0.784, 0.502, 0.200, 1.0),
        "ZN": SIMD4<Float>(0.490, 0.502, 0.690, 1.0),
        "GA": SIMD4<Float>(0.761, 0.561, 0.561, 1.0),
        "GE": SIMD4<Float>(0.400, 0.561, 0.561, 1.0),
        "AS": SIMD4<Float>(0.741, 0.502, 0.890, 1.0),
        "SE": SIMD4<Float>(1.000, 0.631, 0.000, 1.0),
        "BR": SIMD4<Float>(0.651, 0.161, 0.161, 1.0),
        "KR": SIMD4<Float>(0.361, 0.722, 0.820, 1.0),
        "RB": SIMD4<Float>(0.439, 0.180, 0.690, 1.0),
        "SR": SIMD4<Float>(0.000, 1.000, 0.000, 1.0),
        "Y":  SIMD4<Float>(0.580, 1.000, 1.000, 1.0),
        "ZR": SIMD4<Float>(0.580, 0.878, 0.878, 1.0),
        "NB": SIMD4<Float>(0.451, 0.761, 0.788, 1.0),
        "MO": SIMD4<Float>(0.329, 0.710, 0.710, 1.0),
        "TC": SIMD4<Float>(0.231, 0.620, 0.620, 1.0),
        "RU": SIMD4<Float>(0.141, 0.561, 0.561, 1.0),
        "RH": SIMD4<Float>(0.039, 0.490, 0.549, 1.0),
        "PD": SIMD4<Float>(0.000, 0.412, 0.522, 1.0),
        "AG": SIMD4<Float>(0.753, 0.753, 0.753, 1.0),
        "CD": SIMD4<Float>(1.000, 0.851, 0.561, 1.0),
        "IN": SIMD4<Float>(0.651, 0.459, 0.451, 1.0),
        "SN": SIMD4<Float>(0.400, 0.502, 0.502, 1.0),
        "SB": SIMD4<Float>(0.620, 0.388, 0.710, 1.0),
        "TE": SIMD4<Float>(0.831, 0.478, 0.000, 1.0),
        "I":  SIMD4<Float>(0.580, 0.000, 0.580, 1.0),
        "XE": SIMD4<Float>(0.259, 0.620, 0.690, 1.0),
        "CS": SIMD4<Float>(0.341, 0.090, 0.561, 1.0),
        "BA": SIMD4<Float>(0.000, 0.788, 0.000, 1.0),
        "LA": SIMD4<Float>(0.439, 0.831, 1.000, 1.0),
        "CE": SIMD4<Float>(1.000, 1.000, 0.780, 1.0),
        "PR": SIMD4<Float>(0.851, 1.000, 0.780, 1.0),
        "ND": SIMD4<Float>(0.780, 1.000, 0.780, 1.0),
        "PM": SIMD4<Float>(0.639, 1.000, 0.780, 1.0),
        "SM": SIMD4<Float>(0.561, 1.000, 0.780, 1.0),
        "EU": SIMD4<Float>(0.380, 1.000, 0.780, 1.0),
        "GD": SIMD4<Float>(0.271, 1.000, 0.780, 1.0),
        "TB": SIMD4<Float>(0.188, 1.000, 0.780, 1.0),
        "DY": SIMD4<Float>(0.122, 1.000, 0.780, 1.0),
        "HO": SIMD4<Float>(0.000, 1.000, 0.612, 1.0),
        "ER": SIMD4<Float>(0.000, 0.902, 0.459, 1.0),
        "TM": SIMD4<Float>(0.000, 0.831, 0.322, 1.0),
        "YB": SIMD4<Float>(0.000, 0.749, 0.220, 1.0),
        "LU": SIMD4<Float>(0.000, 0.671, 0.141, 1.0),
        "HF": SIMD4<Float>(0.302, 0.761, 1.000, 1.0),
        "TA": SIMD4<Float>(0.302, 0.651, 1.000, 1.0),
        "W":  SIMD4<Float>(0.129, 0.580, 0.839, 1.0),
        "RE": SIMD4<Float>(0.149, 0.490, 0.671, 1.0),
        "OS": SIMD4<Float>(0.149, 0.400, 0.588, 1.0),
        "IR": SIMD4<Float>(0.090, 0.329, 0.529, 1.0),
        "PT": SIMD4<Float>(0.816, 0.816, 0.878, 1.0),
        "AU": SIMD4<Float>(1.000, 0.820, 0.137, 1.0),
        "HG": SIMD4<Float>(0.722, 0.722, 0.816, 1.0),
        "TL": SIMD4<Float>(0.651, 0.329, 0.302, 1.0),
        "PB": SIMD4<Float>(0.341, 0.349, 0.380, 1.0),
        "BI": SIMD4<Float>(0.620, 0.310, 0.710, 1.0),
        "PO": SIMD4<Float>(0.671, 0.361, 0.000, 1.0),
        "AT": SIMD4<Float>(0.459, 0.310, 0.271, 1.0),
        "RN": SIMD4<Float>(0.259, 0.510, 0.588, 1.0),
        "FR": SIMD4<Float>(0.259, 0.000, 0.400, 1.0),
        "RA": SIMD4<Float>(0.000, 0.490, 0.000, 1.0),
        "AC": SIMD4<Float>(0.439, 0.671, 0.980, 1.0),
        "TH": SIMD4<Float>(0.000, 0.729, 1.000, 1.0),
        "PA": SIMD4<Float>(0.000, 0.631, 1.000, 1.0),
        "U":  SIMD4<Float>(0.000, 0.561, 1.000, 1.0),
        "NP": SIMD4<Float>(0.000, 0.502, 1.000, 1.0),
        "PU": SIMD4<Float>(0.000, 0.420, 1.000, 1.0),
        "AM": SIMD4<Float>(0.329, 0.361, 0.949, 1.0),
        "CM": SIMD4<Float>(0.471, 0.361, 0.890, 1.0),
        "BK": SIMD4<Float>(0.541, 0.310, 0.890, 1.0),
        "CF": SIMD4<Float>(0.631, 0.212, 0.831, 1.0),
        "ES": SIMD4<Float>(0.702, 0.122, 0.831, 1.0),
        "FM": SIMD4<Float>(0.702, 0.122, 0.729, 1.0),
        "MD": SIMD4<Float>(0.702, 0.051, 0.651, 1.0),
        "NO": SIMD4<Float>(0.741, 0.051, 0.529, 1.0),
        "LR": SIMD4<Float>(0.780, 0.000, 0.400, 1.0),
        "RF": SIMD4<Float>(0.800, 0.000, 0.349, 1.0),
        "DB": SIMD4<Float>(0.820, 0.000, 0.310, 1.0),
        "SG": SIMD4<Float>(0.851, 0.000, 0.271, 1.0),
        "BH": SIMD4<Float>(0.878, 0.000, 0.220, 1.0),
        "HS": SIMD4<Float>(0.902, 0.000, 0.180, 1.0),
        "MT": SIMD4<Float>(0.922, 0.000, 0.149, 1.0),
    ]

    /// Returns the CPK color for the given element symbol (case-insensitive).
    /// Falls back to mid-gray for unknown elements.
    public static func color(for element: String) -> SIMD4<Float> {
        return colors[element.uppercased()] ?? SIMD4<Float>(0.5, 0.5, 0.5, 1.0)
    }
}

// MARK: - Van der Waals Radii

/// Van der Waals radii for elements in Angstroms.
/// Unknown elements fall back to 1.70 Å (carbon).
public struct VanDerWaalsRadii {
    public static let radii: [String: Float] = [
        "H":  1.20,
        "C":  1.70,
        "N":  1.55,
        "O":  1.52,
        "S":  1.80,
        "P":  1.80,
        "F":  1.47,
        "CL": 1.75,
        "BR": 1.85,
        "I":  1.98,
        "FE": 2.00,
        "CA": 2.31,
        "MG": 1.73,
        "ZN": 1.39,
        "NA": 2.27,
        "K":  2.75,
        "SE": 1.90,
        "CU": 1.40,
        "MN": 1.61,
        "CO": 1.52,
        "NI": 1.63,
        "HG": 1.55,
        "CD": 1.58,
        "PT": 1.72,
        "AU": 1.66,
        "AG": 1.72,
    ]

    /// Returns the van der Waals radius for the given element symbol (case-insensitive).
    /// Falls back to 1.70 Å for unknown elements.
    public static func radius(for element: String) -> Float {
        return radii[element.uppercased()] ?? 1.70
    }
}
