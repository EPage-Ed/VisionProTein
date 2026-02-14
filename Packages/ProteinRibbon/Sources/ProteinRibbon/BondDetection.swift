//
//  BondDetection.swift
//  ProteinRibbon
//
//  Bond detection between atoms based on distance criteria.
//

import Foundation
import PDBKit
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

    /// Fast bond detection optimized for single-mesh rendering
    /// Only checks likely bonds (adjacent residues + close neighbors)
    /// Much faster than full bond detection for large proteins
    /// - Parameters:
    ///   - atoms: Array of atoms to analyze
    ///   - residues: Array of residues (for adjacent residue optimization)
    ///   - tolerance: Distance tolerance factor
    ///   - maxBondLength: Maximum bond length in Angstroms
    /// - Returns: Array of detected bonds
    public static func detectBondsSimplified(
        in atoms: [PDBAtom],
        residues: [PDBResidue],
        tolerance: Float = 1.3,
        maxBondLength: Float = 2.0
    ) -> [Bond] {
        guard atoms.count > 1 else { return [] }

        var bonds: [Bond] = []

        // Build atom index lookup
        var atomIndexMap: [Int: Int] = [:] // serial -> index
        for (index, atom) in atoms.enumerated() {
            atomIndexMap[atom.serial] = index
        }

        // Strategy: Only check bonds within residues and to adjacent residues
        // This is 10-100x faster than checking all pairs

        for (resIndex, residue) in residues.enumerated() {
            let residueAtoms = residue.atoms.compactMap { atom -> (atom: PDBAtom, index: Int)? in
                guard let index = atomIndexMap[atom.serial] else { return nil }
                return (atoms[index], index)
            }

            // Bonds within this residue
            for i in 0..<residueAtoms.count {
                for j in (i+1)..<residueAtoms.count {
                    let atom1 = residueAtoms[i]
                    let atom2 = residueAtoms[j]

                    if areBonded(atom1.atom, atom2.atom, tolerance: tolerance, maxBondLength: maxBondLength) {
                        bonds.append(Bond(atom1: atom1.index, atom2: atom2.index, length: simd_distance(atom1.atom.position, atom2.atom.position)))
                    }
                }
            }

            // Bonds to next residue (peptide bond + any side chain interactions)
            if resIndex < residues.count - 1 {
                let nextResidue = residues[resIndex + 1]
                let nextResidueAtoms = nextResidue.atoms.compactMap { atom -> (atom: PDBAtom, index: Int)? in
                    guard let index = atomIndexMap[atom.serial] else { return nil }
                    return (atoms[index], index)
                }

                // Only check atoms that could plausibly bond (within residue distance)
                for atom1 in residueAtoms {
                    for atom2 in nextResidueAtoms {
                        if areBonded(atom1.atom, atom2.atom, tolerance: tolerance, maxBondLength: maxBondLength) {
                            bonds.append(Bond(atom1: atom1.index, atom2: atom2.index, length: simd_distance(atom1.atom.position, atom2.atom.position)))
                        }
                    }
                }
            }
        }

        return bonds
    }

    /// Helper to check if two atoms are bonded
    private static func areBonded(_ atom1: PDBAtom, _ atom2: PDBAtom, tolerance: Float, maxBondLength: Float) -> Bool {
        let distSq = simd_distance_squared(atom1.position, atom2.position)
        let maxDistSq = maxBondLength * maxBondLength

        guard distSq <= maxDistSq else { return false }

        let distance = sqrt(distSq)
        let r1 = covalentRadius(for: atom1.element)
        let r2 = covalentRadius(for: atom2.element)
        let expectedLength = r1 + r2

        return distance <= expectedLength * tolerance
    }

    /// Detects bonds between atoms based on distance criteria
    /// Uses spatial grid partitioning for O(n) average case performance
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
        guard atoms.count > 1 else { return [] }

        // Use spatial grid for faster neighbor lookup
        // Grid cell size = maxBondLength to ensure we check all neighbors
        let cellSize = maxBondLength * tolerance
        var grid: [SIMD3<Int>: [Int]] = [:]

        // Build spatial grid
        for (index, atom) in atoms.enumerated() {
            let gridPos = SIMD3<Int>(
                Int(floor(atom.position.x / cellSize)),
                Int(floor(atom.position.y / cellSize)),
                Int(floor(atom.position.z / cellSize))
            )
            grid[gridPos, default: []].append(index)
        }

        var bonds: [Bond] = []
        var checkedPairs = Set<String>()

        // Check atoms against neighbors in their cell and adjacent cells
        for i in 0..<atoms.count {
            let atom1 = atoms[i]
            let gridPos = SIMD3<Int>(
                Int(floor(atom1.position.x / cellSize)),
                Int(floor(atom1.position.y / cellSize)),
                Int(floor(atom1.position.z / cellSize))
            )

            // Check 27 neighboring cells (3x3x3 cube)
            for dx in -1...1 {
                for dy in -1...1 {
                    for dz in -1...1 {
                        let neighborPos = SIMD3<Int>(
                            gridPos.x + dx,
                            gridPos.y + dy,
                            gridPos.z + dz
                        )

                        guard let cellAtoms = grid[neighborPos] else { continue }

                        for j in cellAtoms {
                            // Skip if same atom or already checked this pair
                            guard j > i else { continue }

                            let pairKey = "\(i)-\(j)"
                            guard !checkedPairs.contains(pairKey) else { continue }
                            checkedPairs.insert(pairKey)

                            let atom2 = atoms[j]

                            // Quick rejection: check squared distance first (avoids sqrt)
                            let dx = atom1.position.x - atom2.position.x
                            let dy = atom1.position.y - atom2.position.y
                            let dz = atom1.position.z - atom2.position.z
                            let distSq = dx*dx + dy*dy + dz*dz
                            let maxDistSq = maxBondLength * maxBondLength

                            guard distSq <= maxDistSq else { continue }

                            // Calculate actual distance
                            let distance = sqrt(distSq)

                            // Get expected bond length based on covalent radii
                            let r1 = covalentRadius(for: atom1.element)
                            let r2 = covalentRadius(for: atom2.element)
                            let expectedLength = r1 + r2

                            // Bond if distance is within tolerance of expected length
                            if distance <= expectedLength * tolerance {
                                bonds.append(Bond(atom1: i, atom2: j, length: distance))
                            }
                        }
                    }
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
