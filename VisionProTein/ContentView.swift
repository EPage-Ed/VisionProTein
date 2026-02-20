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

struct ContentHeaderView: View {
  @ObservedObject var model : ARModel
  @Binding var showProteinInfo : Bool

  var body: some View {
    VStack(spacing: 2) {
      Text("Vision \(Text("ProTein").foregroundStyle(Color.green))")
        .font(.largeTitle)
      
      HStack(spacing: 12) {
        Spacer()
        if model.pdbFile != nil {
          Button {
            withAnimation {
              showProteinInfo.toggle()
            }
          } label: {
            Text("?")
              .font(.largeTitle)
          }
//          .opacity(model.pdbFile != nil ? 1 : 0)
        }
        Text(model.pName)
          .font(.largeTitle)
        Text(model.pDetails)
          .font(.footnote)
        Spacer()
      }
      .font(.title2)
      .padding()
      .overlay {
        VStack(spacing: 4) {
          HStack {
            ProgressView(value: model.progress)
              .progressViewStyle(.linear)
              .frame(width: 400)
              .animation(.linear(duration: 1.0), value: model.progress)
            Text(model.progress.formatted(.percent.precision(.fractionLength(0))))
              .font(.caption)
          }
          Text(model.loadingStatus)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.clear)
            .glassBackgroundEffect()
        }
        .opacity(model.loading ? 1 : 0)
        .transform3DEffect(AffineTransform3D(translation: Vector3D(x: 0, y: 0, z: 20)))
      }
    }
  }
}

struct ContentPanelView: View {
  @ObservedObject var model : ARModel
  @State private var showExtension: Bool = false
  
  var body: some View {
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
//            .toggleStyle(.button)
            .labelIconToTitleSpacing(8)
            .disabled(!model.showBallAndStick)
            .frame(maxWidth: .infinity, alignment: .center)
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
              Text("Extension:")
                .padding(.trailing)
              Button {
                withAnimation {
                  showExtension.toggle()
                }
              } label: {
                Text("\(Int(model.tagExtendDistance)) Å")
                  .font(.title)
              }
            }
            if showExtension {
              Slider(
                value: $model.tagExtendDistance,
                in: 0.0...15.0,
                step: 1.0 // This creates the "fixed detents"
              ) { editing in
                if !editing {
                  withAnimation {
                    showExtension.toggle()
                  }
                }
              }
              .frame(width: 240)
            }
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
    }
  }
}

struct ContentDetailsView: View {
  @ObservedObject var model : ARModel
  
  var body: some View {
    HStack {
      VStack {
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
                        withAnimation {
                          if model.selectedResidue == r {
                            model.selectedResidue = nil
                          } else {
                            model.selectedResidue = r
                          }
                        }
                      }
                      .fixedSize()
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
        .padding(.top, 30)
      }
      .padding()
      .frame(minWidth: 400)
      .overlay {
        RoundedRectangle(cornerRadius: 20)
          .stroke(Color.white, lineWidth: 2)
      }
      .background {
        RoundedRectangle(cornerRadius: 20)
          .fill(Color.white.opacity(0.1))
      }
      .overlay(alignment: .top) {
        HStack(spacing: 20) {
          Text("Tagged Residues")
            .font(.title2)
          Button("Clear", role: .destructive) {
            // Remove all highlight entities
            withAnimation {
              model.clearAllSelections()
              model.showBindings = false
            }
          }
          .buttonStyle(.borderedProminent)
          .opacity(model.tagged.isEmpty ? 0.3 : 1.0)
          .disabled(model.tagged.isEmpty)
        }
        .fixedSize()
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
        .overlay {
          Capsule()
//          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white, lineWidth: 2)
        }
        .background {
          Capsule()
//          RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray)
        }
        .offset(x: 0, y: -20)

      }
      .padding(.trailing, 40)
      .frame(maxHeight: model.tagged.count > 0 ? .infinity : 80)
      
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
      } else {
        Text("Select a residue to see details")
          .italic()
          .padding()
          .background {
            RoundedRectangle(cornerRadius: 20)
              .fill(Color.white.opacity(0.1))
          }
          .opacity(model.tagged.count > 0 ? 1 : 0)
      }
      
    }
  }
}

struct ContentView: View {
  @ObservedObject var model : ARModel
  var showOrnaments: Bool
  
//  @State private var showImmersiveSpace = false
//  @State private var immersiveSpaceIsShown = true
  //  @State private var loading = false
  //  @State private var progress : Double = 0
  @State private var rotate : Angle = .zero
  @State private var showSkybox : Bool = false
  @State private var showPDBList : Bool = false
  @State private var showProteinInfo : Bool = false
  @State private var infoProtein: Bool = true
//  let arb = AdvancedRibbonBuilder()

//  @Environment(\.openImmersiveSpace) var openImmersiveSpace
//  @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
  
  let pdbFiles : [PDBFile] = [
    .init(code: "1A3N", name: "Hemoglobin", details: "Hemoglobin is a protein containing iron that facilitates the transportation of oxygen in red blood cells. Almost all vertebrates contain hemoglobin, with the sole exception of the fish family Channichthyidae.", skipUNK: true, ligand: "The primary ligand for hemoglobin is molecular oxygen, which binds reversibly to the ferrous iron atom within the heme prosthetic group. Each of the four heme groups in a hemoglobin molecule can bind one molecule, allowing cooperative binding where the affinity increases with each oxygen bound."),
    .init(code: "1QQW", name: "Catalase", details: "Catalase is a common enzyme found in nearly all living organisms exposed to oxygen which catalyzes the decomposition of hydrogen peroxide to water and oxygen. It is a very important enzyme in protecting the cell from oxidative damage by reactive oxygen species.", skipUNK: true, ligand: "Catalase uses a heme group (iron-containing pigment) as its primary, tightly bound prosthetic group (ligand) to break down hydrogen peroxide. The heme iron is anchored to the protein by a tyrosine amino acid (proximal ligand) and interacts with the hydrogen peroxide substrate on the other side (distal side) to turn it into water and oxygen."),
    .init(code: "1BMF", name: "Mitochondrial F1-ATPase", details: "F1 is an ATPase that hydrolyzes ATP to rotate its rotor part counterclockwise, thereby driving the synthesis of adenosine triphosphate from inorganic phosphate and adenosine diphosphate. It is a key enzyme in cellular respiration.", skipUNK: true, ligand: "The primary ligands for Mitochondrial F1-ATPase are ADP (adenosine diphosphate) and inorganic phosphate, which bind to the enzyme's beta-subunits to be synthesized into ATP. As a rotary molecular motor, it also binds MG-2 as a cofactor."),
    .init(code: "2GLS", name: "Glutamine Synthetase", details: "Glutamine synthetase monitors the levels of nitrogen-rich amino acids and decides when to make more. It is a key enzyme controlling the use of nitrogen inside cells by catalyzing the ATP-dependent synthesis of glutamine from glutamate and ammonia, acting as a primary mechanism for nitrogen metabolism, ammonium detoxification, and neurotransmitter regulation in both animals and plants. It plays a key role in the brain, liver, and nitrogen assimilation in plants.", skipUNK: true, ligand: "The main ligands (substrates) for Glutamine Synthetase are: Glutamate (an amino acid that acts as the backbone for the new molecule), Ammonia (the nitrogen source that gets attached to glutamate), ATP (Adenosine Triphosphate), Metal Ions (typically Magnesium (MG-2) or Manganese (MN-2)).")
//    .init(code: "1KLN", name: "DNA Polymerase", details: "DNA polymerase is a member of a family of enzymes that catalyze the synthesis of DNA molecules from nucleoside triphosphates, the molecular precursors of DNA. These enzymes are essential for DNA replication and usually work in groups to create two identical DNA duplexes from a single original DNA duplex.", skipUNK: false),

    /*
    .init(code: "1ERT", name: "Human Thioredoxin"),
    .init(code: "1NC9", name: "Streptavidin - Biotin binding"),
    .init(code: "4HR9", name: "Human InterLeukin 17"),
    .init(code: "5JLH", name: "Human Cytoplasmic Actomyosin"),
    .init(code: "4HHB", name: "Human Haemoglobin"),
    .init(code: "5NP0", name: "Human ATM"),
     */
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
      ContentHeaderView(model: model, showProteinInfo: $showProteinInfo)
        .padding(.top)

      ContentPanelView(model: model)
        .fixedSize(horizontal: true, vertical: true)
        .padding(.horizontal)
        .overlay {
          VStack {
            Picker("", selection: $infoProtein) {
              Text("Protein").tag(true)
              Text("Ligand").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 30)
            .padding(.top, 2)
            ScrollView {
              Text(infoProtein ? (model.pdbFile?.details ?? "No Protein Information") : (model.pdbFile?.ligand ?? "No Ligand Information"))
                .padding()
            }
            .hoverEffect()
            .onTapGesture {
              withAnimation {
                showProteinInfo.toggle()
              }
            }
          }
          .background {
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.gray)
              .stroke(Color.white, lineWidth: 2)
          }
          .frame(maxWidth: 500)
          .transform3DEffect(AffineTransform3D(translation: Vector3D(x: 0, y: 0, z: 15)))
          .opacity(showProteinInfo ? 1 : 0)
        }
        .transform3DEffect(AffineTransform3D(translation: Vector3D(x: 0, y: 0, z: 10)))

      
      HStack {
        Spacer()
        ContentDetailsView(model: model)
        Spacer()
      }
      .frame(minHeight: 200)
      .padding()
      .padding(.top, 30)
      .transform3DEffect(AffineTransform3D(translation: Vector3D(x: 0, y: 0, z: 10)))
      .opacity(model.tagged.count > 0 ? 1 : 0)
      
      Spacer()
        
    }
    

    .ornament(
      visibility: (showOrnaments ? .visible : .hidden),
      attachmentAnchor: .scene(.topTrailing),
      contentAlignment: .top
    ) {
      VStack(spacing: 20) {
        Button("Load", systemImage: "document") {
          // new action
          showPDBList.toggle()
        }
        .popover(isPresented: $showPDBList,
                 attachmentAnchor: .point(.bottom),
                 arrowEdge: .top,
                 content: {
          VStack {
            ForEach(pdbFiles, id:\.code) { p in
              VStack {
                Button(p.code) {
                  Task { @MainActor in
                    withAnimation {
                      showProteinInfo = false
                      infoProtein = true
                      model.loading = true
                      model.pdbFile = p
                      model.pName = p.code
                      model.pDetails = p.name
                    }
                  }
                  model.clearProteinData()
                  model.buildImmersive()
//                  Task { @MainActor in
//                    withAnimation {
//                      model.loading = false
//                    }
//                  }
                  showPDBList.toggle()
//                  showImmersiveSpace.toggle()
                }
                Text(p.name)
                  .font(.caption)
              }
//              .disabled(showImmersiveSpace)
            }
          }
          .padding()
          // Crucial for the native visionOS look
          .glassBackgroundEffect()
          .presentationCompactAdaptation(.none)
          .transform3DEffect(AffineTransform3D(translation: Vector3D(x: 0, y: 0, z: 15)))
        })

        
        Button("Skybox", systemImage: "fossil.shell") {
          showSkybox.toggle()
        }
        .popover(isPresented: $showSkybox,
                 attachmentAnchor: .point(.bottom),
                 arrowEdge: .top,
                 content: {
          VStack {
            Text("Skybox: \(model.skyboxOpacity.formatted(.percent.precision(.fractionLength(0))))")
            Slider(
              value: $model.skyboxOpacity,
              in: 0.0...1.0
            ) { editing in
              if !editing {
                withAnimation {
                  showSkybox.toggle()
                }
              }
            }
            .frame(width: 240)
          }
          .padding()
          // Crucial for the native visionOS look
          .glassBackgroundEffect()
          .presentationCompactAdaptation(.none)
        })
      }
      .labelStyle(.iconOnly)
      .padding()
      .glassBackgroundEffect()
    }

    /*
    .task {
      model.pName = pdbFiles[0].code
      model.pDetails = pdbFiles[0].name
//      showImmersiveSpace.toggle()
    }
     */
//    Text("Skybox: \(model.skyboxOpacity.formatted(.percent.precision(.fractionLength(0))))")
//      .onTapGesture {
//        showSkybox.toggle()
//      }
    //          }
    .onChange(of: model.showSpheres) { _, newValue in
      model.spheres?.isEnabled = newValue
    }
    .onChange(of: model.showRibbons) { _, newValue in
      model.ribbons?.isEnabled = newValue
    }
    .onChange(of: model.ribbonColorScheme) { _, newValue in
      Task { @MainActor in
        withAnimation {
          model.loading = true
          model.progress = 0.1
          model.loadingStatus = "Updating ribbon colors..."
        }
      }
      model.changeRibbonColorScheme(to: newValue)
      Task { @MainActor in
        withAnimation {
          model.loading = false
          model.progress = 1.0
          model.loadingStatus = "Updated ribbon colors"
        }
      }
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
      withAnimation {
        if newValue {
          model.tagged.formUnion(model.bindingResidues)
        } else {
          model.bindingResidues.forEach { model.tagged.remove($0) }
        }
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
          
          // Remove chain labels when folding
          model.removeChainLabels()

        } else {
          // Unfold - play animation on all child entities
          model.spheres?.children.forEach { child in
            child.playInstanceAnimation()
          }
          
          // Create chain labels when unfolding
          model.createChainLabels(
            residuesByChain: model.residuesByChain,
            unfoldedResidueCenters: model.unfoldedResidueCenters
          )

        }

      }
    }
    /*
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
     */
    /*
    .onChange(of: immersiveSpaceIsShown) { _, newValue in
      
      if newValue {
        model.buildImmersive()
      }
    }
     */
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
  ContentView(model: ARModel(), showOrnaments: true)
}
