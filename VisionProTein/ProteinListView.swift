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
  let image : String
  let ligand : LigandItem
}
class ProteinsVM : ObservableObject {
  @Published var items = [ProteinItem]()
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
          Button("Select") {
            showImmersiveSpace = true
          }
          .font(.title2)
          HStack(alignment: .top, spacing: 20) {
            Image(item.image)
              .resizable()
              .frame(width: 120, height: 120)
              .background {
                RoundedRectangle(cornerRadius: 16).fill(.clear)
                  .strokeBorder(style: .init(lineWidth: 2))
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
            Image(item.ligand.image)
              .resizable()
              .frame(width: 120, height: 120)
              .background {
                RoundedRectangle(cornerRadius: 16).fill(.clear)
                  .strokeBorder(style: .init(lineWidth: 2))
              }
            VStack(alignment: .leading) {
              Text(item.ligand.name)
                .font(.title).bold()
              Text(item.ligand.text)
                .font(.title2)
            }
            Spacer()
            
          }
          
        }
      }
      
    }
    .padding()
    .task {
      //            pvm.items = ["1NC9", "8QE5", "8WLO", "8GIY", "8JTT", "8OZO"].map {
      //                ProteinItem(name: $0)
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
      
    }
  }
}

#Preview {
  ProteinListView(model: ARModel(), showImmersiveSpace: .constant(false))
}


