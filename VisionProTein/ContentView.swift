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
                Text("")
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
            .border(Color.white, width: 2)
            .padding(.top)
          }

          Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
        
        HStack {
          VStack {
            HStack {
              Button("Clear", role: .destructive) {
                // Remove all highlight entities
                withAnimation {
                  model.clearAllSelections()
                }
              }
              .buttonStyle(.borderedProminent)
              .opacity(model.tagged.isEmpty ? 0.3 : 1.0)
              .disabled(model.tagged.isEmpty)
              Text("Tagged Residues")
                .font(.title2)
            }
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
                          .background(model.selectedResidue == r ? Color.yellow.opacity(0.3) : Color.clear)
                      }
                    }
                  }
                }
              }
            }
            .padding(.horizontal)
            
          }
          Spacer()
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
            .frame(maxWidth: 400, alignment: .leading)
          } else {
            Text("Select a residue to see details")
              .italic()
          }
        }
        .frame(height: 300)

      }
      
    }
    .padding()
    .onChange(of: model.showSpheres) { _, newValue in
      model.spheres?.isEnabled = newValue
    }
    .onChange(of: model.showRibbons) { _, newValue in
      model.ribbons?.isEnabled = newValue
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
//        model.ligand = nil
        
        Task {
          await dismissImmersiveSpace()
          immersiveSpaceIsShown = false
        }
        
      }
      
    }

    .onChange(of: immersiveSpaceIsShown) { _, newValue in
      
      if newValue {
        model.loading = true
        model.progress = 0.0
        model.loadingStatus = "Initializing..."
        
        Task { // @MainActor in

          let rbs = ModelEntity()
          rbs.name = "RibbonAndStick"
          model.protein = rbs
                    
          await MainActor.run {
            model.progress = 0.1
            model.loadingStatus = "Loading PDB..."
          }
          if let u = Bundle.main.url(forResource: model.pName, withExtension: "pdb"), // 3aid 6uml (Thilidomide) 1a3n (Hemoglobin) 3nir 4HR9 6a5j 1ERT
             let s = try? String(contentsOf: u, encoding: .utf8) {

            // PARSE ONCE - Get all data needed for all renderers
            await MainActor.run {
              model.progress = 0.15
              model.loadingStatus = "Parsing PDB file..."
            }
            let parseResult = PDB.parseComplete(pdbString: s)
//            let atoms = parseResult.atoms
            let allResidues = parseResult.residues
            let pdbStructure = parseResult.pdbStructure

            await MainActor.run {
              model.progress = 0.2
              model.loadingStatus = "Creating ribbon structure..."
            }

            let entity = ProteinRibbon.structureColoredEntity(from: pdbStructure)  // Red helix, blue sheet, green coil
            entity.name = "Ribbon2"
//            entity.scale *= [0.1,0.1,0.1]
            entity.isEnabled = false
//            entity.position = [0, 2, -1.5]
            rbs.addChild(entity)
            model.ribbons = entity
            print(entity.position)

            await MainActor.run {
              model.progress = 0.4
              model.loadingStatus = "Creating ball-and-stick model..."
            }

            let bse = ProteinRibbon.ballAndStickCPK(from: pdbStructure)
            bse.name = "BallAndStick"
//            bse.position = [0, 3, -2]
            rbs.addChild(bse)
            model.ballAndStick = bse
            print(bse.position)

            // Build spatial index for efficient atom lookup
            await MainActor.run {
              model.progress = 0.6
              model.loadingStatus = "Building spatial index..."
            }
            
            // Filter to only include standard amino acid residues (excludes HETATM ligands, water, etc.)
            let residues = allResidues.filter { $0.aminoAcid != nil }
            print("Filtered residues: \\(allResidues.count) total -> \\(residues.count) amino acids")
            
            model.proteinResidues = residues
            
            // Build spatial index entries
            var indexEntries: [AtomSpatialIndex.AtomEntry] = []
            var atomIndex = 0
            for residue in residues {
              for atom in residue.atoms {
                // Use 0.01 scale to match ball and stick representation
                let atomPos = SIMD3<Float>(
                  Float(atom.x) * 0.01,
                  Float(atom.y) * 0.01,
                  Float(atom.z) * 0.01
                )
                model.atomPositions.append(atomPos)
                model.atomRadii.append(Float(atom.radius))
                model.atomToResidueMap[atomIndex] = residue
                
                indexEntries.append(AtomSpatialIndex.AtomEntry(
                  position: atomPos,
                  atomIndex: atomIndex,
                  residue: residue
                ))
                atomIndex += 1
              }
            }
            model.atomSpatialIndex = AtomSpatialIndex(atoms: indexEntries)
            print("Built spatial index with \(indexEntries.count) atoms for \(residues.count) residues")
            
            
            await MainActor.run {
              model.progress = 0.65
              model.loadingStatus = "Finding binding residues..."
            }
            // Get ligands from consolidated parse result
            let ligands = parseResult.ligands
            print("Ligands found: \(ligands.count):\n\(ligands.map(\.resName).joined(separator: "\n"))")
            
            for ligand in ligands {
              // Generate glowing sphere entity for each ligand
              let ligandEntity = ligand.generateSphereEntity(
                atomScale: 1.0,
                glowColor: .cyan,
                glowIntensity: 0.5,
                opacity: 0.8,
                useElementColors: true
              )
              
              // Add to scene
              model.ballAndStick?.addChild(ligandEntity)
              ligandEntity.isEnabled = false
              model.ligands.append(ligandEntity)
              
              // Also highlight binding residues
              let bindingResidues = ligand.findBindingResidues(in: model.proteinResidues)
              model.bindingResidues.append(contentsOf: bindingResidues)
              
              print("Ligand: \(ligand.resName), Binding residues: \(bindingResidues.map(\.resName).joined(separator: ", "))")
              
              
              // Highlight the binding pocket in yellow
              bindingResidues.forEach { residue in
                // Highlight the selected residue
                if let entity = model.highlightResidue(residue) {
                  model.bindings.append(entity)
                  entity.isEnabled = false
                }
              }
              
              print("\(ligand.resName): \(bindingResidues.count) binding residues")

            }

            
            await MainActor.run {
              model.progress = 0.7
              model.loadingStatus = "Creating sphere representation..."
            }


            let se = ProteinSpheresMesh.spheresCPK(from: pdbStructure, scale: 0.5)
            se.name = "Spheres"
            se.isEnabled = false
            rbs.addChild(se)
            model.spheres = se
            print(se.position)
            

            // Build position-to-residue map for fast lookup
            var posToResidue: [SIMD3<Float>: Residue] = [:]
            for residue in residues {
              for atom in residue.atoms {
                let pos = SIMD3<Float>(
                  Float(atom.x) * 0.01,
                  Float(atom.y) * 0.01,
                  Float(atom.z) * 0.01
                )
                posToResidue[pos] = residue
              }
            }

            // Calculate residue centers for structure-preserving animation
            var residueCenters: [Int: SIMD3<Float>] = [:]  // id -> center
            for residue in residues {
              var center = SIMD3<Float>.zero
              for atom in residue.atoms {
                center += SIMD3<Float>(
                  Float(atom.x) * 0.01,
                  Float(atom.y) * 0.01,
                  Float(atom.z) * 0.01
                )
              }
              center /= Float(residue.atoms.count)
              residueCenters[residue.id] = center
            }

            // Calculate unfolded residue centers (organize chains in parallel)
            var unfoldedResidueCenters: [Int: SIMD3<Float>] = [:]
            
            // Group residues by chain
            var residuesByChain: [String: [Residue]] = [:]
            for residue in residues {
              let chainID = residue.chainID ?? "A"  // Default to chain A if no chainID
              if residuesByChain[chainID] == nil {
                residuesByChain[chainID] = []
              }
              residuesByChain[chainID]?.append(residue)
            }
            
            // Sort chains for consistent ordering
            let sortedChains = residuesByChain.keys.sorted()
            let chainCount = Float(sortedChains.count)
            let chainSpacing: Float = 0.3  // Z-spacing between parallel chains
            
            // Position each chain in parallel
            for (chainIndex, chainID) in sortedChains.enumerated() {
              guard let chainResidues = residuesByChain[chainID] else { continue }
              
              let chainResidueCount = Float(chainResidues.count)
              let zOffset = (Float(chainIndex) - chainCount / 2) * chainSpacing
              
              for (residueIndex, residue) in chainResidues.enumerated() {
                let unfoldedCenter = SIMD3<Float>(
                  (Float(residueIndex) - chainResidueCount / 2) * 0.1,  // X: spread along chain
                  0.5,                                                     // Y: constant height
                  -0.5 + zOffset                                          // Z: offset per chain
                )
                unfoldedResidueCenters[residue.id] = unfoldedCenter
              }
            }

            // Setup animation on each child sphere entity (one per element type)
            for child in se.children {
              if var meshInstances = child.components[MeshInstancesComponent.self],
                 var part = meshInstances[partIndex: 0] {

                var startTranslations: [SIMD3<Float>] = []
                var endTranslations: [SIMD3<Float>] = []

                part.data.withMutableTransforms { transforms in
                  for i in 0..<transforms.count {
                    // Get current atom position
                    let atomPos = SIMD3<Float>(
                      transforms[i].columns.3.x,
                      transforms[i].columns.3.y,
                      transforms[i].columns.3.z
                    )
                    startTranslations.append(atomPos)

                    // Find which residue this atom belongs to via position lookup
                    if let residue = posToResidue[atomPos],
                       let foldedCenter = residueCenters[residue.id],
                       let unfoldedCenter = unfoldedResidueCenters[residue.id] {
                      // Calculate unfolded position: offset from unfolded residue center
                      let offsetFromCenter = atomPos - foldedCenter
                      let unfoldedPos = unfoldedCenter + offsetFromCenter
                      endTranslations.append(unfoldedPos)
                    } else {
                      // Fallback: keep same position
                      endTranslations.append(atomPos)
                    }
                  }
                }

                let animation = InstanceAnimationComponent(
                  startTranslations: startTranslations,
                  endTranslations: endTranslations,
                  duration: 8.0,
                  easing: .easeInOut
                )
                child.components.set(animation)

                // Optional: Add completion callback
                child.setInstanceAnimationCompletion {
                  print("\(child.name) unfold complete!")
                }
              }
            }
            print("Setup structure-preserving animations for \(se.children.count) sphere child entities with \(residues.count) residues")
                        
            await MainActor.run {
              model.progress = 0.9
              model.loadingStatus = "Finalizing..."
            }

          }

          
          model.rootEntity.addChild(rbs)
          rbs.position = [0, 1, -1.85]
          
          let rvb = rbs.visualBounds(recursive: true, relativeTo: rbs, excludeInactive: false)
          print(rvb.extents, rvb.center)
          

          // Offset all children so the visual center becomes the pivot point
          let centerOffset = -rvb.center
          model.proteinCenterOffset = centerOffset
          for child in rbs.children {
            child.position = child.position + centerOffset
          }

          
          ManipulationComponent.configureEntity(rbs)
          rbs.components[ManipulationComponent.self]!.releaseBehavior = .stay
          rbs.components[ManipulationComponent.self]!.dynamics.translationBehavior = .unconstrained
        
          await MainActor.run {
            model.progress = 1.0
            model.loadingStatus = "Complete!"
          }
          try? await Task.sleep(for: .milliseconds(300))
          await MainActor.run {
            model.loading = false
            model.progress = 0.0
            model.loadingStatus = ""
          }
        }
      }
    }
    
  }
}

#Preview(windowStyle: .automatic) {
  ContentView(model: ARModel())
}
