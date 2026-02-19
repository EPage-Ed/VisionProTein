//
//  Ligand.swift
//  VisionProTein
//
//  Ligand data structures for storing HETATM records from PDB files.
//

import Foundation
import simd
import RealityKit
import UIKit

/// Represents a ligand atom from a HETATM record
struct LigandAtom: Codable, Equatable {
    let serial: Int
    let name: String
    let altLoc: String
    let resName: String
    let chainID: String
    let resSeq: Int
    let iCode: String
    let x: Double
    let y: Double
    let z: Double
    let occupancy: Float
    let tempFactor: Double
    let element: String
    let charge: String
    
    /// Position in scene units (Angstroms)
    var position: SIMD3<Float> {
        SIMD3<Float>(Float(x), Float(y), Float(z))
    }
    
    /// Position scaled for RealityKit (multiply by 0.01)
    var scaledPosition: SIMD3<Float> {
        SIMD3<Float>(Float(x) * 0.01, Float(y) * 0.01, Float(z) * 0.01)
    }
}

/// Represents a ligand molecule from HETATM records
struct Ligand: Codable, Equatable, Hashable {
    static func == (lhs: Ligand, rhs: Ligand) -> Bool {
      lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
    
    let id: String  // Unique identifier: chainID-resSeq-resName
    let resName: String  // Residue name (e.g., "ADP", "BTN", "HEM")
    let chainID: String
    let resSeq: Int
    var atoms: [LigandAtom]
    
    /// Center of mass of the ligand
    var center: SIMD3<Float> {
        guard !atoms.isEmpty else { return .zero }
        var sum = SIMD3<Float>.zero
        for atom in atoms {
            sum += atom.position
        }
        return sum / Float(atoms.count)
    }
    
    /// Center of mass scaled for RealityKit
    var scaledCenter: SIMD3<Float> {
        center * 0.01
    }
    
    /// Number of atoms in the ligand
    var atomCount: Int {
        atoms.count
    }
    
    /// Creates a unique identifier for a ligand
    static func makeID(chainID: String, resSeq: Int, resName: String) -> String {
        return "\(chainID)-\(resSeq)-\(resName)"
    }
}

/// Extension to parse ligands from PDB content
extension PDB {
    /// Parses ligands (HETATM records) from a PDB file
    /// - Parameters:
    ///   - named: Name of the PDB file (without extension)
    ///   - excludeWater: Whether to exclude water molecules (HOH)
    ///   - excludeIons: Whether to exclude single-atom ions (NA, CL, MG, etc.)
    /// - Returns: Array of ligands
    static func parseLigands(named: String, excludeWater: Bool = true, excludeIons: Bool = true) -> [Ligand] {
        guard let u = Bundle.main.url(forResource: named, withExtension: "pdb"),
              let s = try? String(contentsOf: u)
        else { return [] }
        
        return parseLigands(pdb: s, excludeWater: excludeWater, excludeIons: excludeIons)
    }
    
    /// Parses ligands from PDB string content
    /// - Parameters:
    ///   - pdb: PDB file content as string
    ///   - excludeWater: Whether to exclude water molecules (HOH)
    ///   - excludeIons: Whether to exclude single-atom ions
    /// - Returns: Array of ligands
    static func parseLigands(pdb s: String, excludeWater: Bool = true, excludeIons: Bool = true) -> [Ligand] {
        var ligandAtoms = [LigandAtom]()
        
        let lines = s.components(separatedBy: .newlines).filter { $0.hasPrefix("HETATM") }
        
        for line in lines {
            guard line.count >= 54 else { continue }
            
            let paddedLine = line.padding(toLength: 80, withPad: " ", startingAt: 0)
            let chars = Array(paddedLine)
            
            // Parse HETATM record
            guard let serial = Int(String(chars[6..<11]).trimmingCharacters(in: .whitespaces)) else { continue }
            
            let name = String(chars[12..<16]).trimmingCharacters(in: .whitespaces)
            let altLoc = String(chars[16..<17]).trimmingCharacters(in: .whitespaces)
            let resName = String(chars[17..<20]).trimmingCharacters(in: .whitespaces)
            let chainID = String(chars[21..<22]).trimmingCharacters(in: .whitespaces)
            
            guard let resSeq = Int(String(chars[22..<26]).trimmingCharacters(in: .whitespaces)) else { continue }
            
            let iCode = String(chars[26..<27]).trimmingCharacters(in: .whitespaces)
            
            guard let x = Double(String(chars[30..<38]).trimmingCharacters(in: .whitespaces)),
                  let y = Double(String(chars[38..<46]).trimmingCharacters(in: .whitespaces)),
                  let z = Double(String(chars[46..<54]).trimmingCharacters(in: .whitespaces))
            else { continue }
            
            let occupancy = Float(String(chars[54..<60]).trimmingCharacters(in: .whitespaces)) ?? 1.0
            let tempFactor = Double(String(chars[60..<66]).trimmingCharacters(in: .whitespaces)) ?? 0.0
            let element = String(chars[76..<78]).trimmingCharacters(in: .whitespaces)
            let charge = String(chars[78..<80]).trimmingCharacters(in: .whitespaces)
            
            let atom = LigandAtom(
                serial: serial,
                name: name,
                altLoc: altLoc,
                resName: resName,
                chainID: chainID,
                resSeq: resSeq,
                iCode: iCode,
                x: x,
                y: y,
                z: z,
                occupancy: occupancy,
                tempFactor: tempFactor,
                element: element,
                charge: charge
            )
            
            ligandAtoms.append(atom)
        }
        
        // Group atoms by ligand
        var ligandDict: [String: Ligand] = [:]
        
        for atom in ligandAtoms {
            // Skip water if requested
            if excludeWater && atom.resName == "HOH" {
                continue
            }
            
            let id = Ligand.makeID(chainID: atom.chainID, resSeq: atom.resSeq, resName: atom.resName)
            
            if var ligand = ligandDict[id] {
                ligand.atoms.append(atom)
                ligandDict[id] = ligand
            } else {
                ligandDict[id] = Ligand(
                    id: id,
                    resName: atom.resName,
                    chainID: atom.chainID,
                    resSeq: atom.resSeq,
                    atoms: [atom]
                )
            }
        }
        
        // Filter out single-atom ions if requested
        var ligands = Array(ligandDict.values)
        if excludeIons {
            // Common single-atom ions
            let ionNames = ["NA", "CL", "MG", "CA", "K", "ZN", "FE", "MN", "CU"]
            ligands = ligands.filter { ligand in
                !(ligand.atomCount == 1 && ionNames.contains(ligand.resName))
            }
        }
        
        print("[Ligand] Parsed \(ligands.count) ligands from PDB")
        for ligand in ligands {
            print("  \(ligand.resName) (chain \(ligand.chainID), \(ligand.atomCount) atoms)")
        }
        
        return ligands.sorted { $0.id < $1.id }
    }
}

/// Extension to find binding residues near ligands
extension Ligand {
    /// Finds protein residues within a given distance of this ligand
    /// - Parameters:
    ///   - residues: Array of protein residues to search
    ///   - distance: Maximum distance in Angstroms (default: 6.5, industry standard for binding sites)
    /// - Returns: Array of residues within the distance threshold
    func findBindingResidues(in residues: [Residue], maxDistance: Double = 6.5) -> [Residue] {
        var bindingResidues = Set<Residue>()
        
        print("[Ligand] ===== Finding binding residues for \(resName) (chain \(chainID), res# \(resSeq)) =====")
        print("[Ligand] Ligand has \(atoms.count) atoms")
        print("[Ligand] Searching through \(residues.count) protein residues")
        print("[Ligand] Max distance threshold: \(maxDistance)Å")
        
        // Track minimum distance found
        var minDistanceFound: Float = .infinity
        var closestResidue: Residue?
        
        for ligandAtom in atoms {
            let ligandPos = ligandAtom.position
            
            for residue in residues {
                // Skip residues from different chains
                if residue.chainID != chainID {
                    continue
                }
                
                for proteinAtom in residue.atoms {
                    let proteinPos = SIMD3<Float>(
                        Float(proteinAtom.x),
                        Float(proteinAtom.y),
                        Float(proteinAtom.z)
                    )
                    
                    let dist = distance(ligandPos, proteinPos)
                    
                    // Track minimum distance
                    if dist < minDistanceFound {
                        minDistanceFound = dist
                        closestResidue = residue
                    }
                    
                    if Double(dist) <= maxDistance {
                        bindingResidues.insert(residue)
                        break  // No need to check other atoms in this residue
                    }
                }
            }
        }
        
        let sorted = bindingResidues.sorted { $0.id < $1.id }
        print("[Ligand] Found \(sorted.count) binding residues within \(maxDistance)Å")
        print("[Ligand] Minimum distance to any residue: \(minDistanceFound)Å")
        if let closest = closestResidue {
            print("[Ligand] Closest residue: \(closest.resName) \(closest.chainID)\(closest.serNum)")
        }
        print("[Ligand] Binding residues: \(sorted.map { "\($0.resName)\($0.chainID)\($0.serNum)" }.joined(separator: ", "))")
        print("[Ligand] ==============================================")
        
        return sorted
    }
    
    /// Generates a sphere-based RealityKit entity for the ligand with a glowing effect
    /// - Parameters:
    ///   - atomScale: Scale factor for atom spheres (default: 1.0)
    ///   - glowColor: Color of the emissive glow (default: cyan)
    ///   - glowIntensity: Intensity of the emissive glow (default: 0.5)
    ///   - opacity: Transparency of the ligand (default: 0.8, range 0.0-1.0)
    ///   - useElementColors: If true, use CPK element colors; if false, use uniform glow color (default: true)
    /// - Returns: A ModelEntity containing the ligand sphere representation
    func generateSphereEntity(
        atomScale: Float = 1.0,
        glowColor: UIColor = .cyan,
        glowIntensity: Float = 0.5,
        opacity: Float = 0.8,
        useElementColors: Bool = true
    ) -> ModelEntity {
        let parent = ModelEntity()
        parent.name = "Ligand_\(resName)_\(chainID)\(resSeq)"
        
        print("[Ligand] Generating sphere entity for \(resName) with \(atoms.count) atoms")
        
        // Group atoms by element for efficient rendering
        let atomsByElement = Dictionary(grouping: atoms, by: { $0.element.uppercased() })
        
        for (element, elementAtoms) in atomsByElement {
            guard !elementAtoms.isEmpty else { continue }
            
            // Get base radius and color for this element
            let baseRadius = vanDerWaalsRadius(for: element)
            let scaledRadius = baseRadius * atomScale * 0.01  // Convert to scene units
            
            // Determine color
            let baseColor = useElementColors ? elementColor(for: element) : glowColor
            
            // Create sphere mesh for this element type
            let mesh = MeshResource.generateSphere(radius: scaledRadius)
            
            // Create glowing material
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: baseColor)
            material.emissiveColor.color = baseColor
            material.emissiveIntensity = glowIntensity
            material.blending = .transparent(opacity: .init(floatLiteral: opacity))
            material.metallic = .init(floatLiteral: 0.3)
            material.roughness = .init(floatLiteral: 0.6)
            
            // Create entity for each atom
            for atom in elementAtoms {
                let atomEntity = ModelEntity(mesh: mesh, materials: [material])
                atomEntity.name = "Ligand_\(element)_\(atom.serial)"
                atomEntity.position = atom.scaledPosition
                
                parent.addChild(atomEntity)
            }
        }
        
        print("[Ligand] Created sphere entity with \(parent.children.count) atom entities")
        
        return parent
    }
    
    /// Gets the Van der Waals radius for an element (in Angstroms)
    private func vanDerWaalsRadius(for element: String) -> Float {
        let radii: [String: Float] = [
            "H": 1.20,
            "C": 1.70,
            "N": 1.55,
            "O": 1.52,
            "S": 1.80,
            "P": 1.80,
            "F": 1.47,
            "CL": 1.75,
            "BR": 1.85,
            "I": 1.98,
            "FE": 2.00,
            "CA": 2.31,
            "MG": 1.73,
            "ZN": 1.39,
            "NA": 2.27,
            "K": 2.75,
            "SE": 1.90
        ]
        return radii[element.uppercased()] ?? 1.70
    }
    
    /// Gets the CPK element color
    private func elementColor(for element: String) -> UIColor {
        let colors: [String: UIColor] = [
            "H":  UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1),
            "HE": UIColor(red: 0.851, green: 1.000, blue: 1.000, alpha: 1),
            "LI": UIColor(red: 0.800, green: 0.502, blue: 1.000, alpha: 1),
            "BE": UIColor(red: 0.761, green: 1.000, blue: 0.000, alpha: 1),
            "B":  UIColor(red: 1.000, green: 0.710, blue: 0.710, alpha: 1),
            "C":  UIColor(red: 0.565, green: 0.565, blue: 0.565, alpha: 1),
            "N":  UIColor(red: 0.188, green: 0.314, blue: 0.973, alpha: 1),
            "O":  UIColor(red: 1.000, green: 0.051, blue: 0.051, alpha: 1),
            "F":  UIColor(red: 0.565, green: 0.878, blue: 0.314, alpha: 1),
            "NE": UIColor(red: 0.702, green: 0.890, blue: 0.961, alpha: 1),
            "NA": UIColor(red: 0.671, green: 0.361, blue: 0.949, alpha: 1),
            "MG": UIColor(red: 0.541, green: 1.000, blue: 0.000, alpha: 1),
            "AL": UIColor(red: 0.749, green: 0.651, blue: 0.651, alpha: 1),
            "SI": UIColor(red: 0.941, green: 0.784, blue: 0.627, alpha: 1),
            "P":  UIColor(red: 1.000, green: 0.502, blue: 0.000, alpha: 1),
            "S":  UIColor(red: 1.000, green: 1.000, blue: 0.188, alpha: 1),
            "CL": UIColor(red: 0.122, green: 0.941, blue: 0.122, alpha: 1),
            "AR": UIColor(red: 0.502, green: 0.820, blue: 0.890, alpha: 1),
            "K":  UIColor(red: 0.561, green: 0.251, blue: 0.831, alpha: 1),
            "CA": UIColor(red: 0.239, green: 1.000, blue: 0.000, alpha: 1),
            "SC": UIColor(red: 0.902, green: 0.902, blue: 0.902, alpha: 1),
            "TI": UIColor(red: 0.749, green: 0.761, blue: 0.780, alpha: 1),
            "V":  UIColor(red: 0.651, green: 0.651, blue: 0.671, alpha: 1),
            "CR": UIColor(red: 0.541, green: 0.600, blue: 0.780, alpha: 1),
            "MN": UIColor(red: 0.612, green: 0.478, blue: 0.780, alpha: 1),
            "FE": UIColor(red: 0.878, green: 0.400, blue: 0.200, alpha: 1),
            "CO": UIColor(red: 0.941, green: 0.565, blue: 0.627, alpha: 1),
            "NI": UIColor(red: 0.314, green: 0.816, blue: 0.314, alpha: 1),
            "CU": UIColor(red: 0.784, green: 0.502, blue: 0.200, alpha: 1),
            "ZN": UIColor(red: 0.490, green: 0.502, blue: 0.690, alpha: 1),
            "GA": UIColor(red: 0.761, green: 0.561, blue: 0.561, alpha: 1),
            "GE": UIColor(red: 0.400, green: 0.561, blue: 0.561, alpha: 1),
            "AS": UIColor(red: 0.741, green: 0.502, blue: 0.890, alpha: 1),
            "SE": UIColor(red: 1.000, green: 0.631, blue: 0.000, alpha: 1),
            "BR": UIColor(red: 0.651, green: 0.161, blue: 0.161, alpha: 1),
            "KR": UIColor(red: 0.361, green: 0.722, blue: 0.820, alpha: 1),
            "RB": UIColor(red: 0.439, green: 0.180, blue: 0.690, alpha: 1),
            "SR": UIColor(red: 0.000, green: 1.000, blue: 0.000, alpha: 1),
            "Y":  UIColor(red: 0.580, green: 1.000, blue: 1.000, alpha: 1),
            "ZR": UIColor(red: 0.580, green: 0.878, blue: 0.878, alpha: 1),
            "NB": UIColor(red: 0.451, green: 0.761, blue: 0.788, alpha: 1),
            "MO": UIColor(red: 0.329, green: 0.710, blue: 0.710, alpha: 1),
            "TC": UIColor(red: 0.231, green: 0.620, blue: 0.620, alpha: 1),
            "RU": UIColor(red: 0.141, green: 0.561, blue: 0.561, alpha: 1),
            "RH": UIColor(red: 0.039, green: 0.490, blue: 0.549, alpha: 1),
            "PD": UIColor(red: 0.000, green: 0.412, blue: 0.522, alpha: 1),
            "AG": UIColor(red: 0.753, green: 0.753, blue: 0.753, alpha: 1),
            "CD": UIColor(red: 1.000, green: 0.851, blue: 0.561, alpha: 1),
            "IN": UIColor(red: 0.651, green: 0.459, blue: 0.451, alpha: 1),
            "SN": UIColor(red: 0.400, green: 0.502, blue: 0.502, alpha: 1),
            "SB": UIColor(red: 0.620, green: 0.388, blue: 0.710, alpha: 1),
            "TE": UIColor(red: 0.831, green: 0.478, blue: 0.000, alpha: 1),
            "I":  UIColor(red: 0.580, green: 0.000, blue: 0.580, alpha: 1),
            "XE": UIColor(red: 0.259, green: 0.620, blue: 0.690, alpha: 1),
            "CS": UIColor(red: 0.341, green: 0.090, blue: 0.561, alpha: 1),
            "BA": UIColor(red: 0.000, green: 0.788, blue: 0.000, alpha: 1),
            "LA": UIColor(red: 0.439, green: 0.831, blue: 1.000, alpha: 1),
            "CE": UIColor(red: 1.000, green: 1.000, blue: 0.780, alpha: 1),
            "PR": UIColor(red: 0.851, green: 1.000, blue: 0.780, alpha: 1),
            "ND": UIColor(red: 0.780, green: 1.000, blue: 0.780, alpha: 1),
            "PM": UIColor(red: 0.639, green: 1.000, blue: 0.780, alpha: 1),
            "SM": UIColor(red: 0.561, green: 1.000, blue: 0.780, alpha: 1),
            "EU": UIColor(red: 0.380, green: 1.000, blue: 0.780, alpha: 1),
            "GD": UIColor(red: 0.271, green: 1.000, blue: 0.780, alpha: 1),
            "TB": UIColor(red: 0.188, green: 1.000, blue: 0.780, alpha: 1),
            "DY": UIColor(red: 0.122, green: 1.000, blue: 0.780, alpha: 1),
            "HO": UIColor(red: 0.000, green: 1.000, blue: 0.612, alpha: 1),
            "ER": UIColor(red: 0.000, green: 0.902, blue: 0.459, alpha: 1),
            "TM": UIColor(red: 0.000, green: 0.831, blue: 0.322, alpha: 1),
            "YB": UIColor(red: 0.000, green: 0.749, blue: 0.220, alpha: 1),
            "LU": UIColor(red: 0.000, green: 0.671, blue: 0.141, alpha: 1),
            "HF": UIColor(red: 0.302, green: 0.761, blue: 1.000, alpha: 1),
            "TA": UIColor(red: 0.302, green: 0.651, blue: 1.000, alpha: 1),
            "W":  UIColor(red: 0.129, green: 0.580, blue: 0.839, alpha: 1),
            "RE": UIColor(red: 0.149, green: 0.490, blue: 0.671, alpha: 1),
            "OS": UIColor(red: 0.149, green: 0.400, blue: 0.588, alpha: 1),
            "IR": UIColor(red: 0.090, green: 0.329, blue: 0.529, alpha: 1),
            "PT": UIColor(red: 0.816, green: 0.816, blue: 0.878, alpha: 1),
            "AU": UIColor(red: 1.000, green: 0.820, blue: 0.137, alpha: 1),
            "HG": UIColor(red: 0.722, green: 0.722, blue: 0.816, alpha: 1),
            "TL": UIColor(red: 0.651, green: 0.329, blue: 0.302, alpha: 1),
            "PB": UIColor(red: 0.341, green: 0.349, blue: 0.380, alpha: 1),
            "BI": UIColor(red: 0.620, green: 0.310, blue: 0.710, alpha: 1),
            "PO": UIColor(red: 0.671, green: 0.361, blue: 0.000, alpha: 1),
            "AT": UIColor(red: 0.459, green: 0.310, blue: 0.271, alpha: 1),
            "RN": UIColor(red: 0.259, green: 0.510, blue: 0.588, alpha: 1),
            "FR": UIColor(red: 0.259, green: 0.000, blue: 0.400, alpha: 1),
            "RA": UIColor(red: 0.000, green: 0.490, blue: 0.000, alpha: 1),
            "AC": UIColor(red: 0.439, green: 0.671, blue: 0.980, alpha: 1),
            "TH": UIColor(red: 0.000, green: 0.729, blue: 1.000, alpha: 1),
            "PA": UIColor(red: 0.000, green: 0.631, blue: 1.000, alpha: 1),
            "U":  UIColor(red: 0.000, green: 0.561, blue: 1.000, alpha: 1),
            "NP": UIColor(red: 0.000, green: 0.502, blue: 1.000, alpha: 1),
            "PU": UIColor(red: 0.000, green: 0.420, blue: 1.000, alpha: 1),
            "AM": UIColor(red: 0.329, green: 0.361, blue: 0.949, alpha: 1),
            "CM": UIColor(red: 0.471, green: 0.361, blue: 0.890, alpha: 1),
            "BK": UIColor(red: 0.541, green: 0.310, blue: 0.890, alpha: 1),
            "CF": UIColor(red: 0.631, green: 0.212, blue: 0.831, alpha: 1),
            "ES": UIColor(red: 0.702, green: 0.122, blue: 0.831, alpha: 1),
            "FM": UIColor(red: 0.702, green: 0.122, blue: 0.729, alpha: 1),
            "MD": UIColor(red: 0.702, green: 0.051, blue: 0.651, alpha: 1),
            "NO": UIColor(red: 0.741, green: 0.051, blue: 0.529, alpha: 1),
            "LR": UIColor(red: 0.780, green: 0.000, blue: 0.400, alpha: 1),
            "RF": UIColor(red: 0.800, green: 0.000, blue: 0.349, alpha: 1),
            "DB": UIColor(red: 0.820, green: 0.000, blue: 0.310, alpha: 1),
            "SG": UIColor(red: 0.851, green: 0.000, blue: 0.271, alpha: 1),
            "BH": UIColor(red: 0.878, green: 0.000, blue: 0.220, alpha: 1),
            "HS": UIColor(red: 0.902, green: 0.000, blue: 0.180, alpha: 1),
            "MT": UIColor(red: 0.922, green: 0.000, blue: 0.149, alpha: 1),
        ]
        return colors[element.uppercased()] ?? UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    }
}
