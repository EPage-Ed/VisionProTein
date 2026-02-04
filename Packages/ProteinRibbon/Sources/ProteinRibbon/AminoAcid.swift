//
//  AminoAcid.swift
//  ProteinRibbon
//
//  Amino acid classification and properties.
//

import Foundation

/// Amino acid classification and utilities
public struct AminoAcid {

    /// Chemical classification of amino acids
    public enum AcidType {
        case hydrophobic      // Nonpolar, aliphatic/aromatic
        case polar            // Polar, uncharged
        case positiveCharged  // Basic amino acids
        case negativeCharged  // Acidic amino acids
        case special          // Glycine, proline, cysteine
        case unknown          // Unrecognized residue
    }

    /// Classifies an amino acid by its three-letter code
    /// - Parameter code: Three-letter amino acid code (e.g., "ALA", "GLY")
    /// - Returns: Chemical type of the amino acid
    public static func type(for code: String) -> AcidType {
        let upperCode = code.uppercased()

        switch upperCode {
        // Hydrophobic (nonpolar)
        case "ALA", "VAL", "LEU", "ILE", "MET", "PHE", "TRP", "TYR":
            return .hydrophobic

        // Polar (uncharged)
        case "SER", "THR", "ASN", "GLN":
            return .polar

        // Positively charged (basic)
        case "LYS", "ARG", "HIS":
            return .positiveCharged

        // Negatively charged (acidic)
        case "ASP", "GLU":
            return .negativeCharged

        // Special
        case "GLY", "PRO", "CYS":
            return .special

        default:
            return .unknown
        }
    }

    /// Standard amino acid three-letter codes
    public static let standardCodes = [
        "ALA", "ARG", "ASN", "ASP", "CYS",
        "GLN", "GLU", "GLY", "HIS", "ILE",
        "LEU", "LYS", "MET", "PHE", "PRO",
        "SER", "THR", "TRP", "TYR", "VAL"
    ]

    /// Checks if a residue name is a standard amino acid
    public static func isStandardAminoAcid(_ name: String) -> Bool {
        return standardCodes.contains(name.uppercased())
    }

    /// One-letter code mapping
    public static let oneLetterCodes: [String: String] = [
        "ALA": "A", "ARG": "R", "ASN": "N", "ASP": "D", "CYS": "C",
        "GLN": "Q", "GLU": "E", "GLY": "G", "HIS": "H", "ILE": "I",
        "LEU": "L", "LYS": "K", "MET": "M", "PHE": "F", "PRO": "P",
        "SER": "S", "THR": "T", "TRP": "W", "TYR": "Y", "VAL": "V"
    ]

    /// Converts three-letter code to one-letter code
    public static func toOneLetterCode(_ threeLetterCode: String) -> String {
        return oneLetterCodes[threeLetterCode.uppercased()] ?? "X"
    }
}
