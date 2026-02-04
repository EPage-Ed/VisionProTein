//
//  ProteinListView.swift
//  VisionProTein
//
//  Created by Lance LeMond on 3/30/24.
//

import SwiftUI

struct LigandItem {
  let name : String
  let text : String
  let image : String
}

struct ProteinItem : Identifiable {
  let id = UUID()
  let code : String
  let name : String
  let text : String
  let image : String?
  let ligand : LigandItem?
}
class ProteinsVM : ObservableObject {
  @Published var items = [ProteinItem]()
//  @Published var loading = false
}

struct ProteinListView: View {
  @ObservedObject var model : ARModel
  @Binding var showImmersiveSpace : Bool

  @StateObject var pvm = ProteinsVM()
  let columns = [
    GridItem(.fixed(150)),
    GridItem(.flexible(minimum: 250)),
    GridItem(.flexible(minimum: 180))
  ]
  
  
  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        Text("")
        Text("Protein")
          .font(.largeTitle)
        Text("Ligand")
          .font(.largeTitle)
        ForEach(pvm.items) { item in
          Button(showImmersiveSpace ? "Close" : "Select") {
            model.proteinItem = item
            showImmersiveSpace.toggle()
          }
          .font(.title2)
          HStack(alignment: .top, spacing: 20) {
            if let image = item.image {
              Image(image)
                .resizable()
                .frame(width: 120, height: 120)
                .background {
                  RoundedRectangle(cornerRadius: 16).fill(.clear)
                    .strokeBorder(style: .init(lineWidth: 2))
                }
            } else {
              Image(systemName: "microbe")
                .resizable()
                .frame(width: 120, height: 120)
            }
            VStack(alignment: .leading) {
              Text(item.code)
                .font(.title).bold()
              Text(item.name)
              Text(item.text)
                .font(.headline)
            }
            Spacer()
          }
          .font(.title2)
          HStack(alignment: .top, spacing: 20) {
            if let ligand = item.ligand {
              Image(ligand.image)
                .resizable()
                .frame(width: 120, height: 120)
                .background {
                  RoundedRectangle(cornerRadius: 16).fill(.clear)
                    .strokeBorder(style: .init(lineWidth: 2))
                }
              VStack(alignment: .leading) {
                Text(ligand.name)
                  .font(.title).bold()
                Text(ligand.text)
                  .font(.title2)
              }
              Spacer()
              
            } else {
              Text("----")
              Text("----")
            }
          }
          
        }
      }
      
    }
    .padding()
    .task {
      //            pvm.items = ["1NC9", "8QE5", "8WLO", "8GIY", "8JTT", "8OZO"].map {
      //                ProteinItem(name: $0)
      pvm.items = [
        ProteinItem(code: "2P6A", name: "Activin:Follistatin", text: "Follistatin is studied for its role in regulation of muscle growth in mice, as an antagonist to myostatin (also known as GDF-8, a TGF superfamily member) which inhibits         excessive muscle growth.", image: nil, ligand: nil),
        ProteinItem(code: "6Y60", name: "Human Polyomavirus", text: "Homologous peptide exhibits similar binding to JC polyomavirus VP1 and inhibits infection with similar potency to BKV in a model cell line.", image: nil, ligand: nil),
      ]
      
      /*
      2ARP  Activin A in complex with
          Fs12 fragment of follistatin
          This protein can bind to activin dimer and form a stable complex containing           two Fs12 molecules and one activin dimer.

      2NYS  Protein AGR_C_3712 from
          Agrobacterium tumefaciens

      1S4Y  activin/actrIIb extracellular domain
          The activin type 2 receptors modulate signals for transforming growth factor beta         ligands. These receptors are involved in a host of processes including, growth, cell       differentiation, homeostasis, osteogenesis, apoptosis and many other functions.

      1JMA    HERPES SIMPLEX VIRUS
          4xal is a 2 chain structure with sequence from Human alphaherpesvirus 1 strain 17.
          GLYCOPROTEIN D

      4XAL    Tegument protein VP22

      108M    SPERM WHALE MYOGLOBIN
          Myoglobin (Mb) is an O2 binding protein whose function is to store O2 within the muscle     and facilitate its diffusion within muscle cells

      9MSI    TYPE III ANTIFREEZE PROTEIN
          Type III antifreeze proteins (AFPIIIs) are a group of small globular proteins found in       some polar fishes to protect them against freezing damage.

      2RJM    Titin - Oryctolagus cuniculus
          Titin is the largest protein chain in your body, with more than 34,000 amino acids. This       titanic protein acts like a big rubber band in our muscles.

      6CFY    Topoisomerases
          The function of topoisomerase is to unwind the chromosomes and DNA double-helix by     creating small, reversible cuts in the DNA. Topoisomerase enzymes can be thought of       as tiny surgeons who wield molecular scissors.

      3HO3    Hedgehog-interacting protein (HHIP)
          This protein is important for development of the brain and spinal cord (central nervous       system), eyes, limbs, and many other parts of the body.

      1FHE    GLUTATHIONE TRANSFERASE (FH47)
          Used for purifying proteins with either known or unknown biochemical properties, from       yeast, bacterial and mammalian cells

      4D1M    Tetramerization domain of zebrafish p53
          A protein that protects the genome when DNA damage causes cancer cells to multiply       uncontrollably

      2ZIY    Crystal structure of squid rhodopsin
          Opsins: Proteins in the eyes that help detect light

      1SVQ    STRUCTURE OF SEVERIN DOMAIN 2 IN SOLUTION
          Actin: Proteins that contract and relax to make muscles flex, which may be interesting if     you're interested in animal movement

      1YP1    non-hemorrhagic fibrin(ogen)olytic metalloproteinase from venom of             Agkistrodon acutus
          Fibrin: A sticky protein that stops bleeding by plugging wounds

      1RY6    Internal Kinesin Motor Domain
          Kinesin: A motor protein that moves proteins from one place to another

      6FS4    NMR structure of Casocidin-II antimicrobial peptide in 60% TFE
          Casein: A storage protein in mammalian milk that provides nutrients for growing babies
       */
      
      
      /*
      pvm.items = [
        ProteinItem(code: "1nc9", name: "Streptavidin", text: "Hydrogen-bonding network contributes to the tight binding of biotin to streptavidin", image: "1nc9",
                    ligand: LigandItem(name: "Biotin", text: "B Vitamin", image: "Biotin")
                   ),
        ProteinItem(code: "3SZI", name: "Shwanavidin", text: "Avidin-like protein from the marine proteobactrium Shewanella denitrificans", image: "3SZI",
                    ligand: LigandItem(name: "Biotin", text: "B Vitamin", image: "Biotin")
                   ),
        ProteinItem(code: "6VJK", name: "Streptavidin M88", text: "Disulfide bonds into opposite sides of a flexible loop critical for biotin binding", image: "6VJK",
                    ligand: LigandItem(name: "Biotin", text: "B Vitamin", image: "Biotin")
                   )
      ]
       */
      
    }
  }
}

#Preview {
  ProteinListView(model: ARModel(), showImmersiveSpace: .constant(false))
}


