//
//  AminoAcid.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 1/26/26.
//

enum AminoAcid: String, Codable {
  case alanine = "ALA"
  case arginine = "ARG"
  case asparagine = "ASN"
  case asparticAcid = "ASP"
  case cysteine = "CYS"
  case glutamicAcid = "GLU"
  case glutamine = "GLN"
  case glycine = "GLY"
  case histidine = "HIS"
  case isoleucine = "ILE"
  case leucine = "LEU"
  case lysine = "LYS"
  case methionine = "MET"
  case phenylalanine = "PHE"
  case proline = "PRO"
  case serine = "SER"
  case threonine = "THR"
  case tryptophan = "TRP"
  case tyrosine = "TYR"
  case valine = "VAL"
}
extension AminoAcid {
  var fullName: String {
    switch self {
    case .alanine: return "Alanine"
    case .arginine: return "Arginine"
    case .asparagine: return "Asparagine"
    case .asparticAcid: return "Aspartic Acid"
    case .cysteine: return "Cysteine"
    case .glutamicAcid: return "Glutamic Acid"
    case .glutamine: return "Glutamine"
    case .glycine: return "Glycine"
    case .histidine: return "Histidine"
    case .isoleucine: return "Isoleucine"
    case .leucine: return "Leucine"
    case .lysine: return "Lysine"
    case .methionine: return "Methionine"
    case .phenylalanine: return "Phenylalanine"
    case .proline: return "Proline"
    case .serine: return "Serine"
    case .threonine: return "Threonine"
    case .tryptophan: return "Tryptophan"
    case .tyrosine: return "Tyrosine"
    case .valine: return "Valine"
    }
  }
  var details: String {
    switch self {
    case .alanine:
      return "Alanine is a small, non-polar amino acid that is often found in the interior of proteins. It plays a key role in protein structure and function."
    case .arginine:
      return "Arginine is a positively charged, polar amino acid that is involved in various cellular processes, including protein synthesis and cell signaling."
    case .asparagine:
      return "Asparagine is a polar amino acid that contains an amide group. It is important for protein stability and is often found on the surface of proteins."
    case .asparticAcid:
      return "Aspartic Acid is a negatively charged, polar amino acid that plays a crucial role in enzyme active sites and protein-protein interactions."
    case .cysteine:
      return "Cysteine is a polar amino acid that contains a thiol group, which can form disulfide bonds. These bonds are important for stabilizing protein structures."
    case .glutamicAcid:
      return "Glutamic Acid is a negatively charged, polar amino acid that functions as a neurotransmitter and plays a role in cellular metabolism."
    case .glutamine:
      return "Glutamine is a polar amino acid that serves as a nitrogen donor in various biosynthetic processes and is important for immune function."
    case .glycine:
      return "Glycine is the smallest amino acid and is non-polar. It provides flexibility to protein structures and is often found in tight turns and loops."
    case .histidine:
      return "Histidine is a positively charged, polar amino acid that plays a key role in enzyme active sites due to its ability to bind and release protons."
    case .isoleucine:
      return "Isoleucine is a non-polar amino acid that contributes to the hydrophobic core of proteins and is important for maintaining protein stability."
    case .leucine:
      return "Leucine is a non-polar amino acid that plays a critical role in protein synthesis and muscle repair. It is also involved in regulating blood sugar levels."
    case .lysine:
      return "Lysine is a positively charged, polar amino acid that is essential for protein synthesis, calcium absorption, and immune function."
    case .methionine:
      return "Methionine is a non-polar amino acid that serves as the starting amino acid for protein synthesis and is important for methylation reactions."
    case .phenylalanine:
      return "Phenylalanine is a non-polar amino acid that is a precursor to important neurotransmitters such as dopamine, norepinephrine, and epinephrine."
    case .proline:
      return "Proline is a non-polar amino acid that introduces kinks in protein chains, affecting their folding and stability."
    case .serine:
      return "Serine is a polar amino acid that plays a key role in enzyme function and signaling pathways."
    case .threonine:
      return "Threonine is a polar amino acid that is important for protein structure and function, as well as for immune function."
    case .tryptophan:
      return "Tryptophan is a non-polar amino acid that is a precursor to serotonin and melatonin, which regulate mood and sleep."
    case .tyrosine:
      return "Tyrosine is a polar amino acid that is a precursor to important neurotransmitters such as dopamine, norepinephrine, and epinephrine."
    case .valine:
      return "Valine is a non-polar amino acid that is essential for muscle metabolism, tissue repair, and energy production."
    }
  }
  var polar: String {
    switch self {
    case .alanine: return "Alanine is a non-polar amino acid."
    case .arginine: return "Arginine is a polar amino acid."
    case .asparagine: return "Asparagine is a polar amino acid."
    case .asparticAcid: return "Aspartic Acid is a polar amino acid."
    case .cysteine: return "Cysteine is a polar amino acid."
    case .glutamicAcid: return "Glutamic Acid is a polar amino acid."
    case .glutamine: return "Glutamine is a polar amino acid."
    case .glycine: return "Glycine is a non-polar amino acid."
    case .histidine: return "Histidine is a polar amino acid."
    case .isoleucine: return "Isoleucine is a non-polar amino acid."
    case .leucine: return "Leucine is a non-polar amino acid."
    case .lysine: return "Lysine is a polar amino acid."
    case .methionine: return "Methionine is a non-polar amino acid."
    case .phenylalanine: return "Phenylalanine is a non-polar amino acid."
    case .proline: return "Proline is a non-polar amino acid."
    case .serine: return "Serine is a polar amino acid."
    case .threonine: return "Threonine is a polar amino acid."
    case .tryptophan: return "Tryptophan is a non-polar amino acid."
    case .tyrosine: return "Tyrosine is a polar amino acid."
    case .valine: return "Valine is a non-polar amino acid."
    }
  }
}
