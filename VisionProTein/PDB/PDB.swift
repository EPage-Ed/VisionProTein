//
//  PDB.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import UIKit
import RealityKit



struct Atom : Codable {
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
  let occupancy: Int
  let tempFactor: Double
  let element: String
  let charge: String
  
  var color : UIColor {
    switch element {
    case "H": .white
    case "C": UIColor(red: 0.5647058823529412, green: 0.5647058823529412, blue: 0.5647058823529412, alpha: 1)
    case "N": UIColor(red: 0.18823529411764706, green: 0.3137254901960784, blue: 0.9725490196078431, alpha: 1)
    case "O": UIColor(red: 1, green: 0.050980392156862744, blue: 0.050980392156862744, alpha: 1)
    case "S": UIColor(red: 1, green: 1, blue: 0.18823529411764706, alpha: 1)
    default: .black
    }
  }
  
  var radius : CGFloat {
    switch element {
    case "H": 0.32 / 100
    case "C": 0.77 / 100
    case "N": 0.75 / 100
    case "O": 0.73 / 100
    case "S": 1.02 / 100
    default: 0.01
    }
  }
}

struct SEQRES : Codable {
  let chainID : String
  let residues : [String]
}

struct HELIX : Codable {
  let start : Int
  let end : Int
  let chain : String
}

struct SHEET : Codable {
  let start : Int
  let end : Int
  let chain : String
}

struct Residue : Codable, Equatable, Hashable {
  static func == (lhs: Residue, rhs: Residue) -> Bool {
    lhs.id == rhs.id
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  let id: Int
  let serNum: Int
  let chainID: String
  let resName: String
  var atoms: [Atom]
  var aminoAcid: AminoAcid? {
    AminoAcid(rawValue: resName)
  }
}

extension Array where Element == Atom {
  var residues : [Residue] {
    var r = [Residue]()
    var curResName = ""
    var curResSeq = -1
    var curRes : Residue?
    self.forEach { a in
      if a.resSeq != curResSeq || a.resName != curResName {
//      if a.resName != curResName {
        if let curRes { r.append(curRes) }
        curRes = Residue(id: r.count + 1, serNum: a.resSeq, chainID: a.chainID, resName: a.resName, atoms: [])
        curResName = a.resName
        curResSeq = a.resSeq
      }
      curRes?.atoms.append(a)
    }
    if let curRes { r.append(curRes) }
    
    return r
  }
}

extension String {
  func removeExtraSpaces() -> String {
    return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
  }
  var condensed: String {
    return replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
  }
}


struct PDB : Codable {
  let atoms : [Atom]
  //  let seqRes : [SeqRes]
  let residues : [Residue]
  let sequences : [SEQRES]
  //  let chains : ChainMap // [String: Chain]
  let helices : [HELIX]
  let sheets : [SHEET]
  
  static func parse(json: Data) -> PDB? {
    do {
      let pdb = try JSONDecoder().decode(PDB.self, from: json)
      return pdb
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }
  //  01234567890123456789012345678901234567890123456789012345678901234567890123456789
  //  ATOM    339  CG  MET A  36     -14.475  -4.427  14.916  1.00 14.27           C
  //  ATOM      1  N   SER A   2      46.039  18.054 -52.126  1.00 78.61           N
  
  static func parseFile() -> ([Atom],[Residue]) {
    var atoms = [Atom]()
    guard let u = Bundle.main.url(forResource: "6a5j", withExtension: "pdb"), // 3aid 6uml (Thilidomide) 1a3n (Hemoglobin) 3nir 6a5j
          let s = try? String(contentsOf: u)
    else { return ([],[]) }
    let lines = s.components(separatedBy: .newlines).filter{$0.hasPrefix("ATOM") || $0.hasPrefix("ENDMDL")}
    for l in lines {
      //    lines.forEach { l in
      let c = l.condensed.components(separatedBy: .whitespaces)
      if c[0] == "ENDMDL" { break }
      guard let x = Double(c[6]),
            let y = Double(c[7]),
            let z = Double(c[8]),
            let rs = Int(c[5])
      else { continue }
      let a = Atom(serial: Int(c[1])!, name: c[2], altLoc: "", resName: c[3], chainID: c[4], resSeq: rs, iCode: "", x: x, y:y, z: z, occupancy: 0, tempFactor: 0, element: c[11], charge: "")
      atoms.append(a)
    }
    
    return (atoms,atoms.residues)
  }
  
  // HETATM 1857  O12ABTN A5100      32.721  19.445  13.867  0.62 14.89           O
  
  static func parsePDB(named: String, maxChains: Int = 99, atom: Bool = true, hexatm: Bool = false, water: Bool = false) -> ([Atom],[Residue],[HELIX],[SHEET],[SEQRES]) {
    guard let u = Bundle.main.url(forResource: named, withExtension: "pdb"), // 3aid 6uml (Thilidomide) 1a3n (Hemoglobin) 3nir 6a5j
          let s = try? String(contentsOf: u)
    else { return ([],[],[],[],[]) }
    return parsePDB(pdb: s, maxChains: maxChains, atom: atom, hexatm: hexatm, water: water)
  }
  
/*
01234567890123456789012345678901234567890123456789012345678901234567890123456789
HELIX    1   1 SER A    6  LEU A   18  1                                  13
SHEET    1   A 2 THR A   2  CYS A   3  0
SHEET    2   A 2 ILE A  33  ILE A  34 -1  O  ILE A  33   N  CYS A   3
01234567890123456789012345678901234567890123456789012345678901234567890123456789
HELIX    1   1 THR A  115  LYS A  121  5                                   7
HELIX    2   2 ASN B   49  ARG B   53  5                                   5
HELIX    3   3 THR B  115  LYS B  121  5                                   7
SHEET    1   A 9 GLY A  19  TYR A  22  0
SHEET    2   A 9 THR A  28  ALA A  33 -1  O  PHE A  29   N  TRP A  21
SHEET    3   A 9 ALA A  38  GLU A  44 -1  O  THR A  40   N  THR A  32
*/

  static func parsePDB(pdb s: String, maxChains: Int = 99, atom: Bool = true, hexatm: Bool = false, water: Bool = false) -> ([Atom],[Residue],[HELIX],[SHEET],[SEQRES]) {
    var atoms = [Atom]()
    var helix = [HELIX]()
    var sheet = [SHEET]()
    var seqres = [SEQRES]()
    var ccnt = maxChains
    let lines = s.components(separatedBy: .newlines).filter{(atom && ($0.hasPrefix("ATOM") || $0.hasPrefix("HELIX") || $0.hasPrefix("SHEET") || $0.hasPrefix("SEQRES"))) || (hexatm && $0.hasPrefix("HETATM")) || $0.hasPrefix("ENDMDL") || $0.hasPrefix("TER")}
    for l in lines {
      //      print(l)
      //    lines.forEach { l in
      let c = Array(l)
      let code = String(c[0...5]).trimmingCharacters(in: .whitespaces)
      if code == "ENDMDL" { break }
      if code == "TER" {
        ccnt -= 1
        if ccnt <= 0 { break }
      }
      if code == "HELIX" {
        let chain = String(c[21])
        let start = Int(String(c[21...24]).trimmingCharacters(in: .whitespaces)) ?? 0
        let end = Int(String(c[33...36]).trimmingCharacters(in: .whitespaces)) ?? 0
        //        print("HELIX \(chain) \(start)-\(end)")
        let h = HELIX(start: start, end: end, chain: chain)
        helix.append(h)
        continue
      } else if code == "SHEET" {
        let chain = String(c[21])
        let start = Int(String(c[22...25]).trimmingCharacters(in: .whitespaces)) ?? 0
        let end = Int(String(c[33...36]).trimmingCharacters(in: .whitespaces)) ?? 0
        //        print("SHEET \(chain) \(start)-\(end)")
        let sh = SHEET(start: start, end: end, chain: chain)
        sheet.append(sh)
        continue
      } else if code == "SEQRES" {
        let chain = String(c[11])
        let resStr = String(c[19...]).trimmingCharacters(in: .whitespaces)
        let residues = resStr.components(separatedBy: .whitespaces)
        let s = SEQRES(chainID: chain, residues: residues)
        seqres.append(s)
        continue
      }
                  
      let ser = Int(String(c[6...10]).trimmingCharacters(in: .whitespaces))
      let name = String(c[12...15]).trimmingCharacters(in: .whitespaces)
      let res = String(c[17...19]).trimmingCharacters(in: .whitespaces)
      if (!water && res == "HOH") { continue }
      let chain = String(c[21])
      let rs = Int(String(c[22...25]).trimmingCharacters(in: .whitespaces))
      let x = Double(String(c[30...37]).trimmingCharacters(in: .whitespaces))
      let y = Double(String(c[38...45]).trimmingCharacters(in: .whitespaces))
      let z = Double(String(c[46...53]).trimmingCharacters(in: .whitespaces))
      let ele = String(c[76...77]).trimmingCharacters(in: .whitespaces)
      guard let ser, let x, let y, let z, let rs else { continue }
      let a = Atom(serial: ser, name: name, altLoc: "", resName: res, chainID: chain, resSeq: rs, iCode: "", x: x, y:y, z: z, occupancy: 0, tempFactor: 0, element: ele, charge: "")
      atoms.append(a)
      //      print(ser,ele)
      
      /*
       let c = l.condensed.components(separatedBy: .whitespaces)
       if c[0] == "ENDMDL" { break }
       guard let x = Double(c[6]),
       let y = Double(c[7]),
       let z = Double(c[8]),
       let rs = Int(c[5])
       else { continue }
       let a = Atom(serial: Int(c[1])!, name: c[2], altLoc: "", resName: c[3], chainID: c[4], resSeq: rs, iCode: "", x: x, y:y, z: z, occupancy: 0, tempFactor: 0, element: c[11], charge: "")
       atoms.append(a)
       */
    }
    print("Found \(atoms.count) atoms\n    \(helix.count) helices\n    \(sheet.count) sheets")
    
    helix = helix.sorted { (h1,h2) -> Bool in
      if h1.chain == h2.chain {
        return h1.start < h2.start
      }
      return h1.chain < h2.chain
    }
    sheet = sheet.sorted { (s1,s2) -> Bool in
      if s1.chain == s2.chain {
        return s1.start < s2.start
      }
      return s1.chain < s2.chain
    }
    
    helix.forEach { h in
      print("HELIX \(h.chain) \(h.start)-\(h.end)")
    }
    sheet.forEach { s in
      print("SHEET \(s.chain) \(s.start)-\(s.end)")
    }
    
    return (atoms,atoms.residues, helix, sheet, seqres)
  }
  
}

class ProteinComponent: Component {
  //  var residue: Residue
  //  var outline = false
  
  //  init(player: Player, state: State = .new) {
  init() {
    //    self.residue = residue
  }
  
  func update(entity: Entity, with deltaTime: TimeInterval) {
    //    if popEntity?.parent == nil {
    //      entity.addChild(popEntity!)
    //    }
  }
}


