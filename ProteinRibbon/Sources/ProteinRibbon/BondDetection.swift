//
//  BondDetection.swift
//  ProteinRibbon
//
//  Bond detection between atoms based on distance criteria.
//

import Foundation
import simd

// MARK: - Bond

/// Represents a covalent bond between two atoms
public struct Bond {
    /// Index of the first atom
    public let atom1: Int

    /// Index of the second atom
    public let atom2: Int

    /// Bond length in Angstroms
    public let length: Float

    public init(atom1: Int, atom2: Int, length: Float) {
        self.atom1 = atom1
        self.atom2 = atom2
        self.length = length
    }
}

// MARK: - Bond Detector

/// Detects covalent bonds between atoms
public struct BondDetector {

    // MARK: - Covalent Radii (in Angstroms)

    /// Standard covalent radii for common elements
    private static let covalentRadii: [String: Float] = [
        "H": 0.31,
        "C": 0.76,
        "N": 0.71,
        "O": 0.66,
        "P": 1.07,
        "S": 1.05,
        "F": 0.57,
        "CL": 1.02,
        "BR": 1.20,
        "I": 1.39,
        "SE": 1.20,
        "FE": 1.32,
        "ZN": 1.22,
        "MG": 1.41,
        "CA": 1.76,
        "NA": 1.66,
        "K": 2.03
    ]

    /// Gets covalent radius for an element, returns default if not found
    private static func covalentRadius(for element: String) -> Float {
        return covalentRadii[element.uppercased()] ?? 0.77  // Default ~carbon
    }

    // MARK: - Bond Detection

    /// Detects bonds between atoms based on distance criteria
    /// - Parameters:
    ///   - atoms: Array of atoms to analyze
    ///   - tolerance: Distance tolerance factor (1.3 = 130% of sum of covalent radii)
    ///   - maxBondLength: Maximum bond length in Angstroms
    /// - Returns: Array of detected bonds
    public static func detectBonds(
        in atoms: [PDBAtom],
        tolerance: Float = 1.3,
        maxBondLength: Float = 2.0
    ) -> [Bond] {
        var bonds: [Bond] = []

        // Check all pairs of atoms
        for i in 0..<atoms.count {
            for j in (i + 1)..<atoms.count {
                let atom1 = atoms[i]
                let atom2 = atoms[j]

                // Calculate distance
                let distance = simd_distance(atom1.position, atom2.position)

                // Get expected bond length based on covalent radii
                let r1 = covalentRadius(for: atom1.element)
                let r2 = covalentRadius(for: atom2.element)
                let expectedLength = r1 + r2

                // Bond if distance is within tolerance of expected length and below max
                if distance <= expectedLength * tolerance && distance <= maxBondLength {
                    bonds.append(Bond(atom1: i, atom2: j, length: distance))
                }
            }
        }

        return bonds
    }

    /// Detects backbone bonds (N-CA-C-O chain) in a protein
    /// More efficient than full bond detection, only checks sequential residues
    /// - Parameter residues: Array of residues
    /// - Returns: Array of backbone bonds (atom indices in flattened atom array)
    public static func detectBackboneBonds(in residues: [PDBResidue]) -> [Bond] {
        var bonds: [Bond] = []
        var atomOffset = 0

        for i in 0..<residues.count {
            let residue = residues[i]

            // Find backbone atoms in this residue
            let nIndex = residue.atoms.firstIndex { $0.name.trimmingCharacters(in: .whitespaces) == "N" }
            let caIndex = residue.atoms.firstIndex { $0.name.trimmingCharacters(in: .whitespaces) == "CA" }
            let cIndex = residue.atoms.firstIndex { $0.name.trimmingCharacters(in: .whitespaces) == "C" }
            let oIndex = residue.atoms.firstIndex { $0.name.trimmingCharacters(in: .whitespaces) == "O" }

            // Bonds within residue: N-CA, CA-C, C-O
            if let n = nIndex, let ca = caIndex {
                let nAtom = residue.atoms[n]
                let caAtom = residue.atoms[ca]
                let distance = simd_distance(nAtom.position, caAtom.position)
                bonds.append(Bond(atom1: atomOffset + n, atom2: atomOffset + ca, length: distance))
            }

            if let ca = caIndex, let c = cIndex {
                let caAtom = residue.atoms[ca]
                let cAtom = residue.atoms[c]
                let distance = simd_distance(caAtom.position, cAtom.position)
                bonds.append(Bond(atom1: atomOffset + ca, atom2: atomOffset + c, length: distance))
            }

            if let c = cIndex, let o = oIndex {
                let cAtom = residue.atoms[c]
                let oAtom = residue.atoms[o]
                let distance = simd_distance(cAtom.position, oAtom.position)
                bonds.append(Bond(atom1: atomOffset + c, atom2: atomOffset + o, length: distance))
            }

            // Peptide bond to next residue: C(i) - N(i+1)
            if i < residues.count - 1 {
                let nextResidue = residues[i + 1]
                let nextNIndex = nextResidue.atoms.firstIndex { $0.name.trimmingCharacters(in: .whitespaces) == "N" }

                if let c = cIndex, let nextN = nextNIndex {
                    let cAtom = residue.atoms[c]
                    let nextNAtom = nextResidue.atoms[nextN]
                    let distance = simd_distance(cAtom.position, nextNAtom.position)

                    // Only add if reasonable peptide bond distance (1.2 - 1.5 Å)
                    if distance >= 1.2 && distance <= 1.5 {
                        let nextAtomOffset = atomOffset + residue.atoms.count
                        bonds.append(Bond(atom1: atomOffset + c, atom2: nextAtomOffset + nextN, length: distance))
                    }
                }
            }

            atomOffset += residue.atoms.count
        }

        return bonds
    }

    /// Detects all bonds within residues (including sidechains)
    /// - Parameters:
    ///   - residues: Array of residues
    ///   - includeBackbone: Whether to include backbone bonds
    ///   - tolerance: Distance tolerance for bond detection
    /// - Returns: Array of bonds
    public static func detectAllBonds(
        in residues: [PDBResidue],
        includeBackbone: Bool = true,
        tolerance: Float = 1.3
    ) -> [Bond] {
        // Flatten atoms
        let allAtoms = residues.flatMap { $0.atoms }

        // Detect all bonds
        var bonds = detectBonds(in: allAtoms, tolerance: tolerance)

        if !includeBackbone {
            // Filter out backbone bonds
            // This is a simplified approach - could be more sophisticated
            bonds = bonds.filter { bond in
                let atom1 = allAtoms[bond.atom1]
                let atom2 = allAtoms[bond.atom2]
                let backboneNames = ["N", "CA", "C", "O"]
                let name1 = atom1.name.trimmingCharacters(in: .whitespaces)
                let name2 = atom2.name.trimmingCharacters(in: .whitespaces)
                return !(backboneNames.contains(name1) && backboneNames.contains(name2))
            }
        }

        return bonds
    }
}
