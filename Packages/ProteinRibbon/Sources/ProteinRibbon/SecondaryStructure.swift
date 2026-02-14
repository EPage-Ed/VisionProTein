//
//  SecondaryStructure.swift
//  ProteinRibbon
//
//  Secondary structure classification and segment grouping.
//

import Foundation
import PDBKit
import simd

// MARK: - Secondary Structure Types

/// Types of protein secondary structure
public enum SecondaryStructureType: String, CaseIterable {
    case helix = "helix"
    case sheet = "sheet"
    case coil = "coil"
}

/// A segment of protein backbone with consistent secondary structure
public struct SecondaryStructureSegment {
    public let type: SecondaryStructureType
    public let startIndex: Int
    public let endIndex: Int
    public let chainID: String
    public let residues: [PDBResidue]

    /// Number of residues in this segment
    public var length: Int {
        endIndex - startIndex + 1
    }
}

// MARK: - Secondary Structure Classifier

/// Assigns secondary structure types to residues based on PDB HELIX/SHEET records
public struct SecondaryStructureClassifier {

    /// Classifies residues into secondary structure segments
    /// - Parameters:
    ///   - residues: Array of parsed residues
    ///   - helices: HELIX records from PDB
    ///   - sheets: SHEET records from PDB
    /// - Returns: Array of secondary structure segments covering all residues
    public static func classify(
        residues: [PDBResidue],
        helices: [PDBHelix],
        sheets: [PDBSheet]
    ) -> [SecondaryStructureSegment] {
        guard !residues.isEmpty else { return [] }

        // Create lookup for secondary structure assignment
        var structureAssignment: [String: SecondaryStructureType] = [:]

        // Assign helices
        for helix in helices {
            for seq in helix.startResidue...helix.endResidue {
                let key = makeKey(chain: helix.startChain, seq: seq)
                structureAssignment[key] = .helix
            }
        }

        // Assign sheets (overwrites if overlap, sheets typically don't overlap with helices)
        for sheet in sheets {
            for seq in sheet.startResidue...sheet.endResidue {
                let key = makeKey(chain: sheet.startChain, seq: seq)
                structureAssignment[key] = .sheet
            }
        }

        // Build segments by grouping contiguous residues of the same type
        var segments: [SecondaryStructureSegment] = []
        var currentType: SecondaryStructureType?
        var currentChain: String?
        var segmentStart: Int = 0
        var segmentResidues: [PDBResidue] = []

        for (index, residue) in residues.enumerated() {
            let key = makeKey(chain: residue.chainID, seq: residue.sequenceNumber)
            let type = structureAssignment[key] ?? .coil

            // Check if we need to start a new segment
            let shouldStartNew = currentType == nil ||
                                 currentType != type ||
                                 currentChain != residue.chainID

            if shouldStartNew {
                // Save previous segment if exists
                if let prevType = currentType, let prevChain = currentChain, !segmentResidues.isEmpty {
                    segments.append(SecondaryStructureSegment(
                        type: prevType,
                        startIndex: segmentStart,
                        endIndex: index - 1,
                        chainID: prevChain,
                        residues: segmentResidues
                    ))
                }

                // Start new segment
                currentType = type
                currentChain = residue.chainID
                segmentStart = index
                segmentResidues = [residue]
            } else {
                segmentResidues.append(residue)
            }
        }

        // Don't forget the last segment
        if let lastType = currentType, let lastChain = currentChain, !segmentResidues.isEmpty {
            segments.append(SecondaryStructureSegment(
                type: lastType,
                startIndex: segmentStart,
                endIndex: residues.count - 1,
                chainID: lastChain,
                residues: segmentResidues
            ))
        }

        return segments
    }

    /// Creates a lookup key for a residue
    private static func makeKey(chain: String, seq: Int) -> String {
        return "\(chain)-\(seq)"
    }

    /// Returns the secondary structure type for a specific residue
    public static func structureType(
        for residue: PDBResidue,
        helices: [PDBHelix],
        sheets: [PDBSheet]
    ) -> SecondaryStructureType {
        // Check helices
        for helix in helices {
            if residue.chainID == helix.startChain &&
               residue.sequenceNumber >= helix.startResidue &&
               residue.sequenceNumber <= helix.endResidue {
                return .helix
            }
        }

        // Check sheets
        for sheet in sheets {
            if residue.chainID == sheet.startChain &&
               residue.sequenceNumber >= sheet.startResidue &&
               residue.sequenceNumber <= sheet.endResidue {
                return .sheet
            }
        }

        return .coil
    }
}

// MARK: - Segment Extensions

extension SecondaryStructureSegment {
    /// Extracts C-alpha positions from the segment's residues
    public var caPositions: [SIMD3<Float>] {
        residues.compactMap { $0.caAtom?.position }
    }

    /// Extracts backbone nitrogen positions
    public var nPositions: [SIMD3<Float>] {
        residues.compactMap { $0.nAtom?.position }
    }

    /// Extracts carbonyl carbon positions
    public var cPositions: [SIMD3<Float>] {
        residues.compactMap { $0.cAtom?.position }
    }

    /// Extracts carbonyl oxygen positions
    public var oPositions: [SIMD3<Float>] {
        residues.compactMap { $0.oAtom?.position }
    }
}

// MARK: - Chain Utilities

extension Array where Element == SecondaryStructureSegment {
    /// Groups segments by chain ID
    public func groupedByChain() -> [String: [SecondaryStructureSegment]] {
        Dictionary(grouping: self, by: { $0.chainID })
    }

    /// Returns segments for a specific chain
    public func segments(forChain chainID: String) -> [SecondaryStructureSegment] {
        filter { $0.chainID == chainID }
    }
}
