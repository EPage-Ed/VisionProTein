//
//  ContentView.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
//import MolecularRender
import ProteinRibbon
//import ProteinSpheres
import ProteinSpheresMesh
import PDBKit


struct ContentView: View {
  @ObservedObject var model : ARModel
  
  @State private var showImmersiveSpace = false
  @State private var immersiveSpaceIsShown = false
  //  @State private var loading = false
  //  @State private var progress : Double = 0
  @State private var rotate : Angle = .zero
//  let arb = AdvancedRibbonBuilder()

  @Environment(\.openImmersiveSpace) var openImmersiveSpace
  @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
  
  struct PDBFile {
    let name: String
    let details: String
  }
  let pdbFiles : [PDBFile] = [
    .init(name: "1ERT", details: "Human Thioredoxin"),
    .init(name: "1NC9", details: "Streptavidin - Biotin binding"),
    .init(name: "4HR9", details: "Human InterLeukin 17"),
    .init(name: "5JLH", details: "Human Cytoplasmic Actomyosin"),
    .init(name: "4HHB", details: "Human Haemoglobin"),
    .init(name: "5NP0", details: "Human ATM"),
    .init(name: "1A3N", details: "Human Hemoglobin"),
  ]
  
  var body: some View {
    VStack {
      /*
      Model3D(named: "protein") { model in
        model
          .resizable()
          .aspectRatio(contentMode: .fit)
          .rotation3DEffect(rotate, axis: .y, anchor: .bottomBack)
        
      } placeholder: {
        VStack {
          Text("Loading...")
          ProgressView()
        }
      }
      .frame(height: 160)
       */
      
      Text("Vision \(Text("ProTein").foregroundStyle(Color.green))")
        .font(.largeTitle)
      
      VStack(spacing: 4) {
        HStack {
          ProgressView(value: model.progress)
            .frame(width: 400)
          Text(model.progress.formatted(.percent.precision(.fractionLength(0))))
            .font(.caption)
        }
        Text(model.loadingStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .opacity(model.loading ? 1 : 0)

     
      HStack {
        if immersiveSpaceIsShown {
          Spacer()
          Group {
            Button("Close") {
              //          model.proteinItem = ProteinItem(code: "2P6A", name: "Activin:Follistatin", text: "Follistatin is studied for its role in regulation of muscle growth in mice, as an antagonist to myostatin (also known as GDF-8, a TGF superfamily member) which inhibits         excessive muscle growth.", image: nil, ligand: nil)
              showImmersiveSpace.toggle()
            }
            .padding(.trailing)
            Text(model.pName)
              .font(.title)
            Text(model.pDetails)
              .font(.caption)
          }
          Spacer()
          VStack {
            Text("Skybox")
            Slider(
              value: $model.skyboxOpacity,
              in: 0.0...1.0
            )
            .frame(width: 240)
          }
          .padding(.trailing)

        } else {
          ForEach(pdbFiles, id:\.name) { p in
            VStack {
              Button(p.name) {
                model.pName = p.name
                model.pDetails = p.details
                showImmersiveSpace.toggle()
              }
              Text(p.details)
                .font(.caption)
            }
            .disabled(showImmersiveSpace)
          }
        }
      }
      .font(.title2)
      .padding()
      
      if immersiveSpaceIsShown {
        HStack {
          Spacer()
          VStack(spacing: 20) {

            Grid(alignment: .center, horizontalSpacing: 40, verticalSpacing: 0) {
              GridRow {
                Toggle("Sphere", isOn: $model.showSpheres)
                  .toggleStyle(.button)
                  .padding(.leading, 40)
                Divider() // Vertical separator
                  .frame(width:2,height:100)
                  .overlay(Color.white)
                  .gridCellUnsizedAxes(.horizontal)
                Toggle("Ribbon", isOn: $model.showRibbons)
                  .toggleStyle(.button)
                Divider() // Vertical separator
                  .frame(width:2,height:100)
                  .overlay(Color.white)
                  .gridCellUnsizedAxes(.horizontal)
                Toggle("Ball & Stick", isOn: $model.showBallAndStick)
                  .toggleStyle(.button)
                Toggle("Tag Mode", isOn: $model.tagMode)
                  .toggleStyle(.button)
                  .disabled(!model.showBallAndStick)
                  .padding(.trailing, 40)
              }
              GridRow {
                HStack {
                  Text("Folded")
                    .foregroundColor(model.showSpheres ? .primary : .gray)
                  Toggle("Folded", isOn: $model.foldedState).labelsHidden()
                    .disabled(!model.showSpheres)
                }
                .padding(.leading, 40)
                Divider() // Vertical separator
                  .frame(width:2,height:100)
                  .overlay(Color.white)
                  .gridCellUnsizedAxes(.horizontal)
                /*
                 • Structure: Red helices, blue sheets, green coils
                 • Chain: Different color per chain
                 • Residue: Blue-to-red gradient (N-terminus to C-terminus)
                 • Type: Colors based on amino acid properties (hydrophobic=yellow, polar=cyan, charged=red/blue, etc.)
                 • Uniform: Single gray color
                 */
                Picker("Coloring", selection: $model.ribbonColorScheme) {
                  Text("Structure").tag(ColorScheme.byStructure)
                  Text("Chain").tag(ColorScheme.byChain)
                  Text("Residue").tag(ColorScheme.byResidue)
                  Text("Type").tag(ColorScheme.byResidueType)
                  Text("Uniform").tag(ColorScheme.uniform)
                }
                .pickerStyle(MenuPickerStyle())
                Divider() // Vertical separator
                  .frame(width:2,height:100)
                  .overlay(Color.white)
                  .gridCellUnsizedAxes(.horizontal)
                HStack {
                  Toggle("Ligands", isOn: $model.showLigands)
                    .toggleStyle(.button)
                    .disabled(!model.showBallAndStick)
                  Toggle("Bindings", isOn: $model.showBindings)
                    .toggleStyle(.button)
                    .disabled(!model.showBallAndStick)
                }
                VStack {
                  HStack {
                    Text("Tag Extension:")
                      .padding(.trailing)
                    Text("\(Int(model.tagExtendDistance)) Å")
                      .font(.title)
                  }
                  Slider(
                    value: $model.tagExtendDistance,
                    in: 0.0...15.0,
                    step: 1.0 // This creates the "fixed detents"
                  )
                  .frame(width: 240)
                }
                .padding(.trailing, 40)

              }
            }
            .overlay {
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 2)
            }
            .background {
              RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
            }
            .padding(.top)
          }
          .transform3DEffect(AffineTransform3D(translation: Vector3D(x: 0, y: 0, z: 50)))

          Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
        
        HStack {
          Spacer()
          VStack {
            HStack(spacing: 20) {
              Text("Tagged Residues")
                .font(.title2)
              Button("Clear", role: .destructive) {
                // Remove all highlight entities
                withAnimation {
                  model.clearAllSelections()
                }
              }
              .buttonStyle(.borderedProminent)
              .opacity(model.tagged.isEmpty ? 0.3 : 1.0)
              .disabled(model.tagged.isEmpty)
            }
            .padding(.horizontal)
            ScrollView {
              Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                let tagged = Array(model.tagged)
                ForEach(Array(stride(from: 0, to: tagged.count, by: 4)), id:\.self) { row in
                  GridRow {
                    ForEach(0..<4, id:\.self) { c in
                      if row + c < tagged.count {
                        let r = tagged[row+c]
                        Text("\(r.resName) \(r.chainID)\(r.serNum)")
                          .onTapGesture {
                            if model.selectedResidue == r {
                              model.selectedResidue = nil
                            } else {
                              model.selectedResidue = r
                            }
                          }
                          .hoverEffect(.lift)
                          .padding(4)
                          .padding(.horizontal, 2)
                          .background(
                            Capsule()
                              .fill(model.selectedResidue == r ? Color.pink.opacity(0.3) : Color.clear)
                          )
//                          .background(model.selectedResidue == r ? Color.yellow.opacity(0.3) : Color.clear)
                      }
                    }
                  }
                }
              }
            }
            .padding(.horizontal)
            
          }
          .padding()
          .overlay {
            RoundedRectangle(cornerRadius: 20)
              .stroke(Color.white, lineWidth: 2)
          }
          .background {
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.white.opacity(0.1))
          }
          .padding(.trailing, 40)

          if let r = model.selectedResidue {
            ScrollView {
              VStack(alignment: .leading) {
                Text("Residue Details")
                  .font(.title2)
                Text("Name: \(r.resName)")
                Text("Chain: \(r.chainID)")
                Text("Sequence Number: \(r.serNum)")
                Text("Number of Atoms: \(r.atoms.count)")
                Text("Amino Acid: \(r.aminoAcid?.fullName ?? "Unknown")")
                Text("Details:")
                Text(r.aminoAcid?.details ?? "No description available.")
              }
            }
            .padding()
            .overlay {
              RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 2)
            }
            .background {
              RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
            }
            .frame(maxWidth: 400, alignment: .leading)
            Spacer()
          } else {
            Text("Select a residue to see details")
              .italic()
            Spacer()
          }
        }
        .frame(minHeight: 200)
        .padding()

      }
      
    }
    .padding()
    .onChange(of: model.showSpheres) { _, newValue in
      model.spheres?.isEnabled = newValue
    }
    .onChange(of: model.showRibbons) { _, newValue in
      model.ribbons?.isEnabled = newValue
    }
    .onChange(of: model.ribbonColorScheme) { _, newValue in
      model.changeRibbonColorScheme(to: newValue)
    }
    .onChange(of: model.showBallAndStick) { _, newValue in
      model.ballAndStick?.isEnabled = newValue
      model.ligands.forEach { $0.isEnabled = model.showLigands && newValue }
      model.bindings.forEach { $0.isEnabled = model.showBindings && newValue }
    }
    .onChange(of: model.showLigands) { _, newValue in
      model.ligands.forEach { $0.isEnabled = newValue }
    }
    .onChange(of: model.showBindings) { _, newValue in
      model.bindings.forEach { $0.isEnabled = newValue }
      if newValue {
        model.tagged.formUnion(model.bindingResidues)
      } else {
        model.bindingResidues.forEach { model.tagged.remove($0) }
      }
    }
    .onChange(of: model.skyboxOpacity) { _, newValue in
      model.rootEntity.parent?.findEntity(named: "SkyboxModel")?.components.set(OpacityComponent(opacity: newValue))
    }
    .onChange(of: model.tagMode) { _, newValue in
      model.leftThumbIndicator?.isEnabled = newValue
      model.leftMiddleFingerIndicator?.isEnabled = newValue
    }
    .onChange(of: model.foldedState) { _, folded in
      //      model.tagState = !newValue
      Task { @MainActor in

        if folded {
          // Fold back - reverse animation on all child entities
          model.spheres?.children.forEach { child in
            child.reverseInstanceAnimation()
          }

        } else {
          // Unfold - play animation on all child entities
          model.spheres?.children.forEach { child in
            child.playInstanceAnimation()
          }

        }

      }
    }
    .onChange(of: showImmersiveSpace) { _, newValue in
      if newValue {
        model.loading = true
        Task {
          await openImmersiveSpace(id: "ImmersiveSpace")
          Task { @MainActor in
            immersiveSpaceIsShown = true
          }
        }
        
      } else if immersiveSpaceIsShown {
        model.loading = false
        model.clearProteinData()
        model.protein?.removeFromParent()
        model.proteinTag?.removeFromParent()
        model.ligands.forEach { $0.removeFromParent() }
        model.ligands.removeAll()
        model.bindings.forEach { $0.removeFromParent() }
        model.bindings.removeAll()
        model.bindingResidues.removeAll()
        model.protein = nil
        model.proteinTag = nil
        model.tagged.removeAll()
        model.showSpheres = false
        model.showRibbons = false
        model.showBallAndStick = true
        model.showLigands = false
        model.showBindings = false
        model.selectedResidue = nil
//        model.ligand = nil
        
        Task {
          await dismissImmersiveSpace()
          immersiveSpaceIsShown = false
        }
        
      }
      
    }

    .onChange(of: immersiveSpaceIsShown) { _, newValue in
      
      if newValue {
        model.buildImmersive()
      }
    }
    .onChange(of: model.selectedResidue) { oldValue, newValue in
      // Update highlight colors when selection changes
      if let old = oldValue {
        model.updateResidueHighlightColor(old, isSelected: false)
      }
      if let new = newValue {
        model.updateResidueHighlightColor(new, isSelected: true)
      }
    }
    
  }
  
}

#Preview(windowStyle: .automatic) {
  ContentView(model: ARModel())
}
