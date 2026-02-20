//
//  PDBParser.swift
//  ProteinRibbon
//
//  PDB file format parser for protein structures.
//

import Foundation
import simd

// MARK: - PDB Data Structures

/// Represents an atom from a PDB file
public struct PDBAtom: Codable {
    public let serial: Int
    public let name: String
    public let altLoc: String
    public let residueName: String
    public let chainID: String
    public let residueSeq: Int
    public let insertionCode: String
    public let position: SIMD3<Float>
    public let occupancy: Float
    public let tempFactor: Float
    public let element: String
    public let charge: String

    public init(serial: Int, name: String, altLoc: String, residueName: String, chainID: String, residueSeq: Int, insertionCode: String, position: SIMD3<Float>, occupancy: Float, tempFactor: Float, element: String, charge: String) {
        self.serial = serial
        self.name = name
        self.altLoc = altLoc
        self.residueName = residueName
        self.chainID = chainID
        self.residueSeq = residueSeq
        self.insertionCode = insertionCode
        self.position = position
        self.occupancy = occupancy
        self.tempFactor = tempFactor
        self.element = element
        self.charge = charge
    }

    /// Whether this atom is a C-alpha (backbone) atom
    public var isCA: Bool {
        name.trimmingCharacters(in: .whitespaces) == "CA"
    }

    /// Whether this atom is a carbonyl carbon
    public var isC: Bool {
        name.trimmingCharacters(in: .whitespaces) == "C"
    }

    /// Whether this atom is a backbone nitrogen
    public var isN: Bool {
        name.trimmingCharacters(in: .whitespaces) == "N"
    }

    /// Whether this atom is a carbonyl oxygen
    public var isO: Bool {
        name.trimmingCharacters(in: .whitespaces) == "O"
    }
}

/// Represents a residue (amino acid) from a PDB file
public struct PDBResidue: Codable {
    public let sequenceNumber: Int
    public let name: String
    public let chainID: String
    public var atoms: [PDBAtom]

    public init(sequenceNumber: Int, name: String, chainID: String, atoms: [PDBAtom]) {
        self.sequenceNumber = sequenceNumber
        self.name = name
        self.chainID = chainID
        self.atoms = atoms
    }

    /// Returns the C-alpha atom if present
    public var caAtom: PDBAtom? {
        atoms.first { $0.isCA }
    }

    /// Returns the carbonyl carbon atom if present
    public var cAtom: PDBAtom? {
        atoms.first { $0.isC }
    }

    /// Returns the backbone nitrogen atom if present
    public var nAtom: PDBAtom? {
        atoms.first { $0.isN }
    }

    /// Returns the carbonyl oxygen atom if present
    public var oAtom: PDBAtom? {
        atoms.first { $0.isO }
    }
}

/// Represents a helix secondary structure record
public struct PDBHelix: Codable {
    public let serialNumber: Int
    public let helixID: String
    public let startResidue: Int
    public let endResidue: Int
    public let startChain: String
    public let endChain: String
    public let helixClass: Int
    public let length: Int

    public init(serialNumber: Int, helixID: String, startResidue: Int, endResidue: Int, startChain: String, endChain: String, helixClass: Int, length: Int) {
        self.serialNumber = serialNumber
        self.helixID = helixID
        self.startResidue = startResidue
        self.endResidue = endResidue
        self.startChain = startChain
        self.endChain = endChain
        self.helixClass = helixClass
        self.length = length
    }
}

/// Represents a sheet/strand secondary structure record
public struct PDBSheet: Codable {
    public let strandNumber: Int
    public let sheetID: String
    public let startResidue: Int
    public let endResidue: Int
    public let startChain: String
    public let endChain: String
    public let sense: Int

    public init(strandNumber: Int, sheetID: String, startResidue: Int, endResidue: Int, startChain: String, endChain: String, sense: Int) {
        self.strandNumber = strandNumber
        self.sheetID = sheetID
        self.startResidue = startResidue
        self.endResidue = endResidue
        self.startChain = startChain
        self.endChain = endChain
        self.sense = sense
    }
}

/// Represents the complete parsed PDB structure
public struct PDBStructure: Codable {
    public let atoms: [PDBAtom]
    public let residues: [PDBResidue]
    public let helices: [PDBHelix]
    public let sheets: [PDBSheet]
    public let chains: [String]

    public init(atoms: [PDBAtom], residues: [PDBResidue], helices: [PDBHelix], sheets: [PDBSheet], chains: [String]) {
        self.atoms = atoms
        self.residues = residues
        self.helices = helices
        self.sheets = sheets
        self.chains = chains
    }
}

// MARK: - PDB Parser

/// Parser for PDB (Protein Data Bank) file format
public struct PDBParser {

    /// Parses a PDB format string and returns a PDBStructure
    /// - Parameter pdbString: The raw PDB file content
    /// - Returns: Parsed PDBStructure containing atoms, residues, and secondary structure
  public static func parse(_ pdbString: String, skipUNK: Bool = true) -> PDBStructure {
        var atoms: [PDBAtom] = []
        var helices: [PDBHelix] = []
        var sheets: [PDBSheet] = []
        var chains = Set<String>()

        let lines = pdbString.components(separatedBy: .newlines)

        for line in lines {
            guard line.count >= 6 else { continue }

            let recordType = String(line.prefix(6)).trimmingCharacters(in: .whitespaces)

            switch recordType {
            case "ATOM":
                // Only parse ATOM records, not HETATM (which includes ligands, water, ions, etc.)
                // This matches the behavior of the sphere representation
              if let atom = parseAtom(line: line, isHetAtm: false, skipUNK: skipUNK) {
                    atoms.append(atom)
                    chains.insert(atom.chainID)
                }

            case "HELIX":
                if let helix = parseHelix(line: line) {
                    helices.append(helix)
                }

            case "SHEET":
                if let sheet = parseSheet(line: line) {
                    sheets.append(sheet)
                }

            case "ENDMDL":
                break

            case "TER":
                continue

            default:
                continue
            }
        }

        // Build residues from atoms
        let residues = buildResidues(from: atoms)

        // Sort secondary structure records
        let sortedHelices = helices.sorted {
            if $0.startChain == $1.startChain {
                return $0.startResidue < $1.startResidue
            }
            return $0.startChain < $1.startChain
        }

        let sortedSheets = sheets.sorted {
            if $0.startChain == $1.startChain {
                return $0.startResidue < $1.startResidue
            }
            return $0.startChain < $1.startChain
        }

        return PDBStructure(
            atoms: atoms,
            residues: residues,
            helices: sortedHelices,
            sheets: sortedSheets,
            chains: Array(chains).sorted()
        )
    }

    // MARK: - Private Parsing Methods
  static let rnaNucleotides = ["A", "U", "G", "C", "I", "PSU", "5MU", "1MA", "2MG", "M2G", "7MG", "OMC", "OMG", "YG"]
  static let dnaNucleotides = ["DA", "DT", "DG", "DC", "DU", "DI"]

  private static func parseAtom(line: String, isHetAtm: Bool, skipUNK: Bool = true) -> PDBAtom? {
        guard line.count >= 54 else { return nil }

        let chars = Array(line)

        // Serial number (columns 7-11)
        guard let serial = Int(substring(chars, 6, 11).trimmingCharacters(in: .whitespaces)) else { return nil }

        // Atom name (columns 13-16)
        let name = substring(chars, 12, 16)

        // Alternate location indicator (column 17)
        let altLoc = String(chars.indices.contains(16) ? chars[16] : " ")

        // Residue name (columns 18-20)
        let residueName = substring(chars, 17, 20).trimmingCharacters(in: .whitespaces)

        // Skip water molecules and unknown residues (non-standard amino acids, DNA/RNA, etc.)
        if residueName == "HOH" || (skipUNK && residueName == "UNK") { return nil }

        // Skip RNA nucleotides
        if rnaNucleotides.contains(residueName) { return nil }

        // Skip DNA nucleotides
        if dnaNucleotides.contains(residueName) { return nil }

        // Chain ID (column 22)
        let chainID = String(chars.indices.contains(21) ? chars[21] : " ")

        // Residue sequence number (columns 23-26)
        guard let residueSeq = Int(substring(chars, 22, 26).trimmingCharacters(in: .whitespaces)) else { return nil }

        // Insertion code (column 27)
        let insertionCode = String(chars.indices.contains(26) ? chars[26] : " ")

        // Coordinates (columns 31-38, 39-46, 47-54)
        guard let x = Float(substring(chars, 30, 38).trimmingCharacters(in: .whitespaces)),
              let y = Float(substring(chars, 38, 46).trimmingCharacters(in: .whitespaces)),
              let z = Float(substring(chars, 46, 54).trimmingCharacters(in: .whitespaces)) else { return nil }

        // Occupancy (columns 55-60) - optional
        let occupancy = Float(substring(chars, 54, 60).trimmingCharacters(in: .whitespaces)) ?? 1.0

        // Temperature factor (columns 61-66) - optional
        let tempFactor = Float(substring(chars, 60, 66).trimmingCharacters(in: .whitespaces)) ?? 0.0

        // Element symbol (columns 77-78) - optional
        let element: String
        if line.count >= 78 {
            element = substring(chars, 76, 78).trimmingCharacters(in: .whitespaces)
        } else {
            // Infer from atom name
            element = inferElement(from: name)
        }

        // Charge (columns 79-80) - optional
        let charge = line.count >= 80 ? substring(chars, 78, 80).trimmingCharacters(in: .whitespaces) : ""

        return PDBAtom(
            serial: serial,
            name: name,
            altLoc: altLoc,
            residueName: residueName,
            chainID: chainID,
            residueSeq: residueSeq,
            insertionCode: insertionCode,
            position: SIMD3<Float>(x, y, z),
            occupancy: occupancy,
            tempFactor: tempFactor,
            element: element,
            charge: charge
        )
    }

    private static func parseHelix(line: String) -> PDBHelix? {
        guard line.count >= 40 else { return nil }

        let chars = Array(line)

        // Serial number (columns 8-10)
        let serialNumber = Int(substring(chars, 7, 10).trimmingCharacters(in: .whitespaces)) ?? 0

        // Helix ID (columns 12-14)
        let helixID = substring(chars, 11, 14).trimmingCharacters(in: .whitespaces)

        // Start chain (column 20)
        let startChain = String(chars.indices.contains(19) ? chars[19] : " ")

        // Start residue (columns 22-25)
        guard let startResidue = Int(substring(chars, 21, 25).trimmingCharacters(in: .whitespaces)) else { return nil }

        // End chain (column 32)
        let endChain = String(chars.indices.contains(31) ? chars[31] : " ")

        // End residue (columns 34-37)
        guard let endResidue = Int(substring(chars, 33, 37).trimmingCharacters(in: .whitespaces)) else { return nil }

        // Helix class (columns 39-40)
        let helixClass = Int(substring(chars, 38, 40).trimmingCharacters(in: .whitespaces)) ?? 1

        // Length (columns 72-76) - optional
        let length: Int
        if line.count >= 76 {
            length = Int(substring(chars, 71, 76).trimmingCharacters(in: .whitespaces)) ?? (endResidue - startResidue + 1)
        } else {
            length = endResidue - startResidue + 1
        }

        return PDBHelix(
            serialNumber: serialNumber,
            helixID: helixID,
            startResidue: startResidue,
            endResidue: endResidue,
            startChain: startChain,
            endChain: endChain,
            helixClass: helixClass,
            length: length
        )
    }

    private static func parseSheet(line: String) -> PDBSheet? {
        guard line.count >= 38 else { return nil }

        let chars = Array(line)

        // Strand number (columns 8-10)
        let strandNumber = Int(substring(chars, 7, 10).trimmingCharacters(in: .whitespaces)) ?? 0

        // Sheet ID (columns 12-14)
        let sheetID = substring(chars, 11, 14).trimmingCharacters(in: .whitespaces)

        // Start chain (column 22)
        let startChain = String(chars.indices.contains(21) ? chars[21] : " ")

        // Start residue (columns 23-26)
        guard let startResidue = Int(substring(chars, 22, 26).trimmingCharacters(in: .whitespaces)) else { return nil }

        // End chain (column 33)
        let endChain = String(chars.indices.contains(32) ? chars[32] : " ")

        // End residue (columns 34-37)
        guard let endResidue = Int(substring(chars, 33, 37).trimmingCharacters(in: .whitespaces)) else { return nil }

        // Sense (columns 39-40)
        let sense = Int(substring(chars, 38, 40).trimmingCharacters(in: .whitespaces)) ?? 0

        return PDBSheet(
            strandNumber: strandNumber,
            sheetID: sheetID,
            startResidue: startResidue,
            endResidue: endResidue,
            startChain: startChain,
            endChain: endChain,
            sense: sense
        )
    }

    private static func buildResidues(from atoms: [PDBAtom]) -> [PDBResidue] {
        var residues: [PDBResidue] = []
        var currentResidue: PDBResidue?
        var currentKey: String = ""

        for atom in atoms {
            let key = "\(atom.chainID)-\(atom.residueSeq)-\(atom.residueName)"

            if key != currentKey {
                if let residue = currentResidue {
                    residues.append(residue)
                }
                currentResidue = PDBResidue(
                    sequenceNumber: atom.residueSeq,
                    name: atom.residueName,
                    chainID: atom.chainID,
                    atoms: [atom]
                )
                currentKey = key
            } else {
                currentResidue?.atoms.append(atom)
            }
        }

        if let residue = currentResidue {
            residues.append(residue)
        }

        return residues
    }

    private static func substring(_ chars: [Character], _ start: Int, _ end: Int) -> String {
        let safeStart = max(0, min(start, chars.count))
        let safeEnd = max(safeStart, min(end, chars.count))
        return String(chars[safeStart..<safeEnd])
    }

    private static func inferElement(from atomName: String) -> String {
        let trimmed = atomName.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "C" }

        let first = trimmed.first!
        switch first {
        case "C": return "C"
        case "N": return "N"
        case "O": return "O"
        case "S": return "S"
        case "H": return "H"
        case "P": return "P"
        default: return String(first)
        }
    }
}
