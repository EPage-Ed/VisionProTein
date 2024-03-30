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

struct Residue : Codable {
  let id: Int
  let serNum: Int
  let chainID: String
  let resName: String
  var atoms: [Atom]
}

extension Array where Element == Atom {
  var residues : [Residue] {
    var r = [Residue]()
    var curResName = ""
    var curRes : Residue?
    self.forEach { a in
      if a.resName != curResName {
        if let curRes { r.append(curRes) }
        curRes = Residue(id: r.count + 1, serNum: a.resSeq, chainID: a.chainID, resName: a.resName, atoms: [])
        curResName = a.resName
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
//  let chains : ChainMap // [String: Chain]
  
  static func parse(json: Data) -> PDB? {
    do {
      let pdb = try JSONDecoder().decode(PDB.self, from: json)
      return pdb
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }
  
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

  static func parsePDB(named: String) -> ([Atom],[Residue]) {
    var atoms = [Atom]()
    guard let u = Bundle.main.url(forResource: named, withExtension: "pdb"), // 3aid 6uml (Thilidomide) 1a3n (Hemoglobin) 3nir 6a5j
          let s = try? String(contentsOf: u)
    else { return ([],[]) }
    let lines = s.components(separatedBy: .newlines).filter{$0.hasPrefix("ATOM") || $0.hasPrefix("HETATM") || $0.hasPrefix("ENDMDL") || $0.hasPrefix("TER")}
    for l in lines {
      print(l)
//    lines.forEach { l in
      let c = Array(l)
      let code = String(c[0...5]).trimmingCharacters(in: .whitespaces)
      if code == "ENDMDL" || code == "TER" { break }
      let ser = Int(String(c[6...10]).trimmingCharacters(in: .whitespaces))
      let name = String(c[12...15]).trimmingCharacters(in: .whitespaces)
      let res = String(c[17...19]).trimmingCharacters(in: .whitespaces)
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

    return (atoms,atoms.residues)
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


