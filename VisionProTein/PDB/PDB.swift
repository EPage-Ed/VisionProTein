//
//  PDB.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import UIKit
import RealityKit
import PDBKit


struct PDBFile {
  let code: String
  let name: String
  let details: String
  let skipUNK: Bool
}

/* Atom Colors
Number  Element  RGB Color  Hexadecimal Web Color
1  H  [255,255,255]  FFFFFF
1  D, H-2  [255,255,192]  FFFFC0
1  T, H-3  [255,255,160]  FFFFA0
2  He  [217,255,255]  D9FFFF
3  Li  [204,128,255]  CC80FF
4  Be  [194,255,0]  C2FF00
5  B  [255,181,181]  FFB5B5
6  C  [144,144,144]  909090
6  C-13  [80,80,80]  505050
6  C-14  [64,64,64]  404040
7  N  [48,80,248]  3050F8
7  N-15  [16,80,80]  105050
8  O  [255,13,13]  FF0D0D
9  F  [144,224,80]  90E050
10  Ne  [179,227,245]  B3E3F5
11  Na  [171,92,242]  AB5CF2
12  Mg  [138,255,0]  8AFF00
13  Al  [191,166,166]  BFA6A6
14  Si  [240,200,160]  F0C8A0
15  P  [255,128,0]  FF8000
16  S  [255,255,48]  FFFF30
17  Cl  [31,240,31]  1FF01F
18  Ar  [128,209,227]  80D1E3
19  K  [143,64,212]  8F40D4
20  Ca  [61,255,0]  3DFF00
21  Sc  [230,230,230]  E6E6E6
22  Ti  [191,194,199]  BFC2C7
23  V  [166,166,171]  A6A6AB
24  Cr  [138,153,199]  8A99C7
25  Mn  [156,122,199]  9C7AC7
26  Fe  [224,102,51]  E06633
27  Co  [240,144,160]  F090A0
28  Ni  [80,208,80]  50D050
29  Cu  [200,128,51]  C88033
30  Zn  [125,128,176]  7D80B0
31  Ga  [194,143,143]  C28F8F
32  Ge  [102,143,143]  668F8F
33  As  [189,128,227]  BD80E3
34  Se  [255,161,0]  FFA100
35  Br  [166,41,41]  A62929
36  Kr  [92,184,209]  5CB8D1
37  Rb  [112,46,176]  702EB0
38  Sr  [0,255,0]  00FF00
39  Y  [148,255,255]  94FFFF
40  Zr  [148,224,224]  94E0E0
41  Nb  [115,194,201]  73C2C9
42  Mo  [84,181,181]  54B5B5
43  Tc  [59,158,158]  3B9E9E
44  Ru  [36,143,143]  248F8F
45  Rh  [10,125,140]  0A7D8C
46  Pd  [0,105,133]  006985
47  Ag  [192,192,192]  C0C0C0
48  Cd  [255,217,143]  FFD98F
49  In  [166,117,115]  A67573
50  Sn  [102,128,128]  668080
51  Sb  [158,99,181]  9E63B5
52  Te  [212,122,0]  D47A00
53  I  [148,0,148]  940094
54  Xe  [66,158,176]  429EB0
55  Cs  [87,23,143]  57178F
56  Ba  [0,201,0]  00C900
57  La  [112,212,255]  70D4FF
58  Ce  [255,255,199]  FFFFC7
59  Pr  [217,255,199]  D9FFC7
60  Nd  [199,255,199]  C7FFC7
61  Pm  [163,255,199]  A3FFC7
62  Sm  [143,255,199]  8FFFC7
63  Eu  [97,255,199]  61FFC7
64  Gd  [69,255,199]  45FFC7
65  Tb  [48,255,199]  30FFC7
66  Dy  [31,255,199]  1FFFC7
67  Ho  [0,255,156]  00FF9C
68  Er  [0,230,117]  00E675
69  Tm  [0,212,82]  00D452
70  Yb  [0,191,56]  00BF38
71  Lu  [0,171,36]  00AB24
72  Hf  [77,194,255]  4DC2FF
73  Ta  [77,166,255]  4DA6FF
74  W  [33,148,214]  2194D6
75  Re  [38,125,171]  267DAB
76  Os  [38,102,150]  266696
77  Ir  [23,84,135]  175487
78  Pt  [208,208,224]  D0D0E0
79  Au  [255,209,35]  FFD123
80  Hg  [184,184,208]  B8B8D0
81  Tl  [166,84,77]  A6544D
82  Pb  [87,89,97]  575961
83  Bi  [158,79,181]  9E4FB5
84  Po  [171,92,0]  AB5C00
85  At  [117,79,69]  754F45
86  Rn  [66,130,150]  428296
87  Fr  [66,0,102]  420066
88  Ra  [0,125,0]  007D00
89  Ac  [112,171,250]  70ABFA
90  Th  [0,186,255]  00BAFF
91  Pa  [0,161,255]  00A1FF
92  U  [0,143,255]  008FFF
93  Np  [0,128,255]  0080FF
94  Pu  [0,107,255]  006BFF
95  Am  [84,92,242]  545CF2
96  Cm  [120,92,227]  785CE3
97  Bk  [138,79,227]  8A4FE3
98  Cf  [161,54,212]  A136D4
99  Es  [179,31,212]  B31FD4
100  Fm  [179,31,186]  B31FBA
101  Md  [179,13,166]  B30DA6
102  No  [189,13,135]  BD0D87
103  Lr  [199,0,102]  C70066
104  Rf  [204,0,89]  CC0059
105  Db  [209,0,79]  D1004F
106  Sg  [217,0,69]  D90045
107  Bh  [224,0,56]  E00038
108  Hs  [230,0,46]  E6002E
109  Mt  [235,0,38]  EB0026
*/

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
    let c = CPKColors.color(for: element)
    return UIColor(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: CGFloat(c.w))
  }

  var radius : CGFloat {
    return CGFloat(VanDerWaalsRadii.radius(for: element)) / 100
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

struct Residue : Codable, Equatable, Hashable, Comparable {
  static func == (lhs: Residue, rhs: Residue) -> Bool {
    lhs.id == rhs.id
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func < (lhs: Residue, rhs: Residue) -> Bool {
    return lhs.id < rhs.id
    /*
    if lhs.chainID != rhs.chainID {
      return lhs.chainID < rhs.chainID
    }
    return lhs.serNum < rhs.serNum
     */
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

  /// Extract a fixed-column PDB substring without allocating a Character array.
  /// Columns are 0-based, end is exclusive.
  func pdbColumn(_ start: Int, _ end: Int) -> Substring {
    guard start < count else { return Substring("") }
    let clampedEnd = min(end, count)
    let startIdx = index(startIndex, offsetBy: start)
    let endIdx = index(startIndex, offsetBy: clampedEnd)
    return self[startIdx..<endIdx]
  }

  func pdbInt(_ start: Int, _ end: Int) -> Int? {
    let sub = pdbColumn(start, end)
    guard !sub.isEmpty else { return nil }
    return Int(sub.trimmingCharacters(in: .whitespaces))
  }

  func pdbDouble(_ start: Int, _ end: Int) -> Double? {
    let sub = pdbColumn(start, end)
    guard !sub.isEmpty else { return nil }
    return Double(sub.trimmingCharacters(in: .whitespaces))
  }

  func pdbString(_ start: Int, _ end: Int) -> String {
    return String(pdbColumn(start, end)).trimmingCharacters(in: .whitespaces)
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

  static func parsePDB(pdb s: String, maxChains: Int = 99, atom: Bool = true, hexatm: Bool = false, water: Bool = false, skipUNK: Bool = true) -> ([Atom],[Residue],[HELIX],[SHEET],[SEQRES]) {
    var atoms = [Atom]()
    var helix = [HELIX]()
    var sheet = [SHEET]()
    var seqres = [SEQRES]()
    var ccnt = maxChains
    var stop = false
    s.enumerateLines { l, stopFlag in
      guard !stop, l.count >= 6 else { return }
      let code = l.pdbString(0, 6)
      if code == "ENDMDL" { stop = true; stopFlag = true; return }
      if code == "TER" {
        ccnt -= 1
        if ccnt <= 0 { stop = true; stopFlag = true }
        return
      }
      if code == "HELIX" {
        let chain = l.count > 19 ? String(l.pdbColumn(19, 20)) : " "
        let start = l.pdbInt(21, 25) ?? 0
        let end = l.pdbInt(33, 37) ?? 0
        helix.append(HELIX(start: start, end: end, chain: chain))
        return
      } else if code == "SHEET" {
        let chain = l.count > 21 ? String(l.pdbColumn(21, 22)) : " "
        let start = l.pdbInt(22, 26) ?? 0
        let end = l.pdbInt(33, 37) ?? 0
        sheet.append(SHEET(start: start, end: end, chain: chain))
        return
      } else if code == "SEQRES" {
        let chain = l.count > 11 ? String(l.pdbColumn(11, 12)) : " "
        let resStr = l.count > 19 ? l.pdbString(19, l.count) : ""
        let residues = resStr.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        seqres.append(SEQRES(chainID: chain, residues: residues))
        return
      }
      guard atom && (l.hasPrefix("ATOM") || (hexatm && l.hasPrefix("HETATM"))) else { return }

      let res = l.pdbString(17, 20)
      if (!water && res == "HOH") { return }
      if (skipUNK && res == "UNK") { return }
      guard let ser = l.pdbInt(6, 11),
            let rs  = l.pdbInt(22, 26),
            let x   = l.pdbDouble(30, 38),
            let y   = l.pdbDouble(38, 46),
            let z   = l.pdbDouble(46, 54) else { return }
      let name  = l.pdbString(12, 16)
      let chain = l.count > 21 ? String(l.pdbColumn(21, 22)) : " "
      let ele   = l.count >= 78 ? l.pdbString(76, 78) : ""
      let a = Atom(serial: ser, name: name, altLoc: "", resName: res, chainID: chain, resSeq: rs, iCode: "", x: x, y: y, z: z, occupancy: 0, tempFactor: 0, element: ele, charge: "")
      atoms.append(a)
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

// MARK: - Consolidated PDB Parsing

extension PDB {
  /// Complete PDB parsing result with all data needed by renderers
  struct CompleteParseResult {
    let atoms: [Atom]
    let residues: [Residue]
    let ligands: [Ligand]
    let helices: [HELIX]
    let sheets: [SHEET]
    let sequences: [SEQRES]
    let pdbStructure: PDBStructure  // For ProteinRibbon/ProteinSpheresMesh packages
  }

  /// Parse PDB once and return all data needed by all renderers.
  /// A single enumerateLines pass extracts ATOM, HETATM, HELIX, SHEET, and SEQRES records
  /// simultaneously, eliminating redundant file iteration.
  static func parseComplete(pdbString: String, skipUNK: Bool = true, progress: ((Double)->())? = nil) -> CompleteParseResult {
    var atoms   = [Atom]()
    var helix   = [HELIX]()
    var sheet   = [SHEET]()
    var seqres  = [SEQRES]()

    // Accumulate HETATM atoms grouped by (resName, chainID, resSeq)
    struct LigandKey: Hashable { let resName: String; let chainID: String; let resSeq: Int }
    var ligandAtomsByKey = [LigandKey: [LigandAtom]]()
    var ligandKeyOrder   = [LigandKey]()   // preserve insertion order

    var stop = false
    pdbString.enumerateLines { l, stopFlag in
      guard !stop, l.count >= 6 else { return }
      let code = l.pdbString(0, 6)
      switch code {
      case "ENDMDL":
        stop = true; stopFlag = true; return
      case "TER":
        return
      case "HELIX":
        let chain = l.count > 19 ? String(l.pdbColumn(19, 20)) : " "
        let start = l.pdbInt(21, 25) ?? 0
        let end   = l.pdbInt(33, 37) ?? 0
        helix.append(HELIX(start: start, end: end, chain: chain))
        return
      case "SHEET":
        let chain = l.count > 21 ? String(l.pdbColumn(21, 22)) : " "
        let start = l.pdbInt(22, 26) ?? 0
        let end   = l.pdbInt(33, 37) ?? 0
        sheet.append(SHEET(start: start, end: end, chain: chain))
        return
      case "SEQRES":
        let chain   = l.count > 11 ? String(l.pdbColumn(11, 12)) : " "
        let resStr  = l.count > 19 ? l.pdbString(19, l.count) : ""
        let residues = resStr.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        seqres.append(SEQRES(chainID: chain, residues: residues))
        return
      case "ATOM":
        let res = l.pdbString(17, 20)
        if res == "HOH" || (skipUNK && res == "UNK") { return }
        guard let ser = l.pdbInt(6, 11),
              let rs  = l.pdbInt(22, 26),
              let x   = l.pdbDouble(30, 38),
              let y   = l.pdbDouble(38, 46),
              let z   = l.pdbDouble(46, 54) else { return }
        let name  = l.pdbString(12, 16)
        let chain = l.count > 21 ? String(l.pdbColumn(21, 22)) : " "
        let ele   = l.count >= 78 ? l.pdbString(76, 78) : ""
        atoms.append(Atom(serial: ser, name: name, altLoc: "", resName: res, chainID: chain,
                          resSeq: rs, iCode: "", x: x, y: y, z: z,
                          occupancy: 0, tempFactor: 0, element: ele, charge: ""))
        return
      case "HETATM":
        guard l.count >= 54 else { return }
        let resName = l.pdbString(17, 20)
        if resName == "HOH" { return }
        let chain = l.count > 21 ? String(l.pdbColumn(21, 22)) : " "
        guard let serial = l.pdbInt(6, 11),
              let resSeq  = l.pdbInt(22, 26),
              let x       = l.pdbDouble(30, 38),
              let y       = l.pdbDouble(38, 46),
              let z       = l.pdbDouble(46, 54) else { return }
        let name      = l.pdbString(12, 16)
        let ele       = l.count >= 78 ? l.pdbString(76, 78) : ""
        let occupancy = l.count >= 60 ? Float(l.pdbString(54, 60)) ?? 1.0 : 1.0
        let tempFactor = l.count >= 66 ? Double(l.pdbString(60, 66)) ?? 0.0 : 0.0
        let ligAtom   = LigandAtom(serial: serial, name: name, altLoc: "", resName: resName,
                                   chainID: chain, resSeq: resSeq, iCode: "", x: x, y: y, z: z,
                                   occupancy: occupancy, tempFactor: tempFactor, element: ele, charge: "")
        let key = LigandKey(resName: resName, chainID: chain, resSeq: resSeq)
        if ligandAtomsByKey[key] == nil {
          ligandKeyOrder.append(key)
          ligandAtomsByKey[key] = [ligAtom]
        } else {
          ligandAtomsByKey[key]!.append(ligAtom)
        }
        return
      default:
        return
      }
    }
    progress?(0.75)

    let residues = atoms.residues

    // Build Ligand objects in original order
    let ligands: [Ligand] = ligandKeyOrder.compactMap { key in
      guard let ligAtoms = ligandAtomsByKey[key], !ligAtoms.isEmpty else { return nil }
      return Ligand(
        id: Ligand.makeID(chainID: key.chainID, resSeq: key.resSeq, resName: key.resName),
        resName: key.resName, chainID: key.chainID, resSeq: key.resSeq, atoms: ligAtoms
      )
    }
    progress?(0.8)

    let pdbStructure = convertToPDBStructure(
      atoms: atoms, residues: residues, helices: helix, sheets: sheet, pdbString: pdbString
    )
    progress?(0.85)

    print("Found \(atoms.count) atoms, \(residues.count) residues, \(ligands.count) ligands, \(helix.count) helices, \(sheet.count) sheets")

    return CompleteParseResult(
      atoms: atoms, residues: residues, ligands: ligands,
      helices: helix, sheets: sheet, sequences: seqres, pdbStructure: pdbStructure
    )
  }

  /// Convert VisionProTein types to ProteinRibbon PDBStructure
  private static func convertToPDBStructure(
    atoms: [Atom],
    residues: [Residue],
    helices: [HELIX],
    sheets: [SHEET],
    pdbString: String
  ) -> PDBStructure {
    // Convert atoms
    let pdbAtoms = atoms.map { atom -> PDBAtom in
      PDBAtom(
        serial: atom.serial,
        name: atom.name,
        altLoc: atom.altLoc,
        residueName: atom.resName,
        chainID: atom.chainID,
        residueSeq: atom.resSeq,
        insertionCode: atom.iCode,
        position: SIMD3<Float>(Float(atom.x), Float(atom.y), Float(atom.z)),
        occupancy: Float(atom.occupancy),
        tempFactor: Float(atom.tempFactor),
        element: atom.element,
        charge: atom.charge
      )
    }

    // Convert residues
    let pdbResidues = residues.map { residue -> PDBResidue in
      let residueAtoms = residue.atoms.map { atom -> PDBAtom in
        PDBAtom(
          serial: atom.serial,
          name: atom.name,
          altLoc: atom.altLoc,
          residueName: atom.resName,
          chainID: atom.chainID,
          residueSeq: atom.resSeq,
          insertionCode: atom.iCode,
          position: SIMD3<Float>(Float(atom.x), Float(atom.y), Float(atom.z)),
          occupancy: Float(atom.occupancy),
          tempFactor: Float(atom.tempFactor),
          element: atom.element,
          charge: atom.charge
        )
      }
      return PDBResidue(
        sequenceNumber: residue.serNum,
        name: residue.resName,
        chainID: residue.chainID,
        atoms: residueAtoms
      )
    }

    // Convert helices
    let pdbHelices = helices.map { helix -> PDBHelix in
      PDBHelix(
        serialNumber: 0,
        helixID: "",
        startResidue: helix.start,
        endResidue: helix.end,
        startChain: helix.chain,
        endChain: helix.chain,
        helixClass: 1,
        length: helix.end - helix.start + 1
      )
    }
    print("Converting \(pdbHelices.count) helices to PDBStructure")
    if !pdbHelices.isEmpty {
      print("First helix: chain '\(pdbHelices[0].startChain)' residues \(pdbHelices[0].startResidue)-\(pdbHelices[0].endResidue)")
    }
    if !pdbResidues.isEmpty {
      print("First residue: chain '\(pdbResidues[0].chainID)' seq \(pdbResidues[0].sequenceNumber)")
    }

    // Convert sheets
    let pdbSheets = sheets.map { sheet -> PDBSheet in
      PDBSheet(
        strandNumber: 0,
        sheetID: "",
        startResidue: sheet.start,
        endResidue: sheet.end,
        startChain: sheet.chain,
        endChain: sheet.chain,
        sense: 0
      )
    }

    // Get unique chains
    let chains = Array(Set(atoms.map { $0.chainID })).sorted()

    return PDBStructure(
      atoms: pdbAtoms,
      residues: pdbResidues,
      helices: pdbHelices,
      sheets: pdbSheets,
      chains: chains
    )
  }

  /// OLD: Parse ligands from PDB string (kept for reference)
  /// Use parseComplete() instead for better performance
  static func parseLigands(_ pdbString: String) -> [Ligand] {
    var ligands: [Ligand] = []
    let lines = pdbString.components(separatedBy: .newlines)

    var currentLigand: (resName: String, chainID: String, resSeq: Int, atoms: [LigandAtom])?

    for line in lines {
      guard line.count >= 6 else { continue }

      let recordType = String(line.prefix(6)).trimmingCharacters(in: .whitespaces)

      if recordType == "HETATM" {
        let chars = Array(line)
        guard chars.count >= 54 else { continue }

        // Parse atom data
        guard let serial = Int(String(chars[6...10]).trimmingCharacters(in: .whitespaces)) else { continue }
        let name = String(chars[12...15]).trimmingCharacters(in: .whitespaces)
        let resName = String(chars[17...19]).trimmingCharacters(in: .whitespaces)

        // Skip water molecules
        if resName == "HOH" { continue }

        let chainID = String(chars[21])
        guard let resSeq = Int(String(chars[22...25]).trimmingCharacters(in: .whitespaces)) else { continue }
        guard let x = Double(String(chars[30...37]).trimmingCharacters(in: .whitespaces)),
              let y = Double(String(chars[38...45]).trimmingCharacters(in: .whitespaces)),
              let z = Double(String(chars[46...53]).trimmingCharacters(in: .whitespaces)) else { continue }

        let element = chars.count >= 78 ? String(chars[76...77]).trimmingCharacters(in: .whitespaces) : ""
        let occupancy = chars.count >= 60 ? Float(String(chars[54...59]).trimmingCharacters(in: .whitespaces)) ?? 1.0 : 1.0
        let tempFactor = chars.count >= 66 ? Double(String(chars[60...65]).trimmingCharacters(in: .whitespaces)) ?? 0.0 : 0.0

        let atom = LigandAtom(
          serial: serial,
          name: name,
          altLoc: "",
          resName: resName,
          chainID: chainID,
          resSeq: resSeq,
          iCode: "",
          x: x,
          y: y,
          z: z,
          occupancy: occupancy,
          tempFactor: tempFactor,
          element: element,
          charge: ""
        )

        // Check if this belongs to current ligand or is a new one
        if let current = currentLigand,
           current.resName == resName && current.chainID == chainID && current.resSeq == resSeq {
          // Same ligand, add atom
          currentLigand?.atoms.append(atom)
        } else {
          // New ligand - save previous if exists
          if let current = currentLigand {
            let ligand = Ligand(
              id: Ligand.makeID(chainID: current.chainID, resSeq: current.resSeq, resName: current.resName),
              resName: current.resName,
              chainID: current.chainID,
              resSeq: current.resSeq,
              atoms: current.atoms
            )
            ligands.append(ligand)
          }
          // Start new ligand
          currentLigand = (resName: resName, chainID: chainID, resSeq: resSeq, atoms: [atom])
        }
      }
    }

    // Don't forget the last ligand
    if let current = currentLigand {
      let ligand = Ligand(
        id: Ligand.makeID(chainID: current.chainID, resSeq: current.resSeq, resName: current.resName),
        resName: current.resName,
        chainID: current.chainID,
        resSeq: current.resSeq,
        atoms: current.atoms
      )
      ligands.append(ligand)
    }

    return ligands
  }
}



