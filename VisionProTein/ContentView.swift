//
//  ContentView.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import MolecularRender
import ProteinRibbon
import ProteinSpheres
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
//            .disabled(!model.showSpheres || model.modelState != .tagging)
          Spacer()
          VStack(spacing: 20) {
            /*
            Picker("Mode", selection: $model.modelState) {
              Text("Resize").tag(ModelState.resizing)
              Text("Tag").tag(ModelState.tagging)
            }
            .pickerStyle(.segmented)
            .disabled(model.showRibbons || (model.showSpheres && model.showBallAndStick))
            .frame(width: 300)
             */

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

//          Text("Tag Residues")
//          Toggle("", isOn: $model.tagState).labelsHidden()
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
//                  for c in 0..<4 {
//                    let r = model.tagged[r+c]
//                    GridRow {
//                  }
                }
              }
            }
            .padding(.horizontal)
            
            /*
            List(Array(model.tagged).sorted(by: { $0.serNum < $1.serNum }), id: \.id) { r in
              Text("\(r.resName) \(r.chainID)\(r.serNum)")
                .onTapGesture {
                  if model.selectedResidue == r {
                    model.selectedResidue = nil
                  } else {
                    model.selectedResidue = r
                  }
                }
                .background(model.selectedResidue == r ? Color.blue.opacity(0.3) : Color.clear)
            }
             */
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
      
//      ProteinListView(model: model, showImmersiveSpace: $showImmersiveSpace)
      
      /*
       HStack(spacing: 20) {
       Spacer()
       Toggle("\(showImmersiveSpace ? "Hide" : "Show") Immersive Space", isOn: $showImmersiveSpace)
       .toggleStyle(.button)
       .disabled(model.loading)
       Spacer()
       
       }
       .padding(.top, 50)
       */
      
      //      Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
      //        .font(.title)
      //        .frame(width: 360)
      //        .padding(24)
      //        .glassBackgroundEffect()
    }
    .padding()
    /*
    .onChange(of: model.modelState) { _, newValue in
      switch newValue {
      case .resizing:
//        model.ribbon?.isEnabled = false
        if model.proteinCollision != nil {
          model.protein?.components.set(model.proteinCollision!)
        }
//        model.protein?.children.forEach { c in
//          if c.name != "Ribbon" {
//            c.isEnabled = true
//          }
//        }
      case .tagging:
//        model.ribbon?.isEnabled = false
        model.protein?.components.remove(CollisionComponent.self)
//        model.protein?.children.forEach { c in
//          if c.name != "Ribbon" {
//            c.isEnabled = true
//          }
//        }
      case .ribbon:
        model.ribbon?.isEnabled = true
        if model.proteinCollision != nil {
          model.protein?.components.set(model.proteinCollision!)
        }
//        model.protein?.children.forEach { c in
//          if c.name != "Ribbon" {
//            c.isEnabled = false
//          }
//        }
      }
    }
     */
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

          /*
          for (i,r) in model.spheres!.children.enumerated() {
            var t = r.transform
            t.translation = model.foldedPositions[i] - r.position
            r.move(to: t, relativeTo: r, duration: 8)
//            r.move(to: model.foldedPositions[i]!, relativeTo: nil, duration: 8)
          }
           */
        } else {
          // Unfold - play animation on all child entities
          model.spheres?.children.forEach { child in
            child.playInstanceAnimation()
          }

          /*
          let tot = Float(model.spheres!.children.count)
          for (i,r) in model.spheres!.children.enumerated() {
            let p : SIMD3<Float> = [(Float(i) - tot/2) * 0.1, 0.5, -0.5]
            model.foldedPositions.append(r.position)
            var t = r.transform
            t.translation = p - r.position
            r.move(to: t, relativeTo: r, duration: 8)
          }
           */

        }

        /*
        if !folded {
          model.foldedPositions.removeAll()
          model.proteinTransform = model.spheres!.transform // proteinTag
        } else {
          model.spheres!.move(to: model.proteinTransform, relativeTo: nil, duration: 8) // proteinTag
          //          model.proteinTag!.transform = model.proteinTransform
//          model.protein!.transform = model.proteinTransform
        }
        //        let offset = model.proteinTag!.transform.translation - model.proteinTransform
        //        print("offset",offset)
        let tot = Float(model.spheres!.children.count) // proteinTag
        for (i,r) in model.spheres!.children.enumerated() { // proteinTag
          if !folded {
            model.foldedPositions.append(r.position)
          }
          if i < model.foldedPositions.count {
            let p : SIMD3<Float> = [(Float(i) - tot/2) * 0.1, 0.5, -0.5]
            let tr = folded ? model.foldedPositions[i] - p : p - r.position
            //          let tr = folded ? model.foldedPositions[i] - p - offset : p - r.position
            var t = r.transform
            t.translation = tr
            let ac = r.move(to: t, relativeTo: r, duration: 8)
          }
          
        }
         */

      }
    }
    /*
    .onChange(of: model.modelState) { _, newValue in
      if model.protein == nil || model.proteinTag == nil { return }
      /*
      if newValue {
        model.proteinTag?.isEnabled = true
        model.protein?.isEnabled = false
//        model.proteinTag?.transform.scale = model.protein?.children.first?.transform.scale ?? .one
//        model.proteinTag?.transform.rotation = model.protein?.children.first?.transform.rotation ?? simd_quatf(vector:[0,0,0,0])
        //        model.rootEntity.addChild(model.proteinTag!)
        //        model.rootEntity.removeChild(model.protein!)
      } else {
        model.proteinTag?.isEnabled = false
        model.protein?.isEnabled = true
        //        model.rootEntity.addChild(model.protein!)
        //        model.rootEntity.removeChild(model.proteinTag!)
      }
       */
    }
     */
    .onChange(of: showImmersiveSpace) { _, newValue in
      
      //      Task {
      if newValue {
        model.loading = true
        Task {
          await openImmersiveSpace(id: "ImmersiveSpace")
          Task { @MainActor in
            immersiveSpaceIsShown = true
          }
        }
        
        /*
         switch result {
         case .success:
         immersiveSpaceIsShown = true
         case .failure:
         immersiveSpaceIsShown = false
         showImmersiveSpace = false
         }
         */
        //          }
        
        /*
         switch await openImmersiveSpace(id: "ImmersiveSpace") {
         case .opened:
         immersiveSpaceIsShown = true
         //            model.loading = false
         case .error, .userCancelled:
         fallthrough
         @unknown default:
         immersiveSpaceIsShown = false
         showImmersiveSpace = false
         }
         */
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
        
        //          return
      }
      
      
      //      }
    }

    .onChange(of: immersiveSpaceIsShown) { _, newValue in
      
      if newValue {
        model.loading = true
        model.progress = 0.0
        model.loadingStatus = "Initializing..."
        
        Task { // @MainActor in
          
//          let pName = "1nc9" // 1hqq Biotin 3nir 1nc9 4HR9 1ERT
          
          // Get the Ligand
          /*
          let (latoms,lresidues,lhelices,lsheets,lseqres) = PDB.parsePDB(named: pName, maxChains: 99, atom: false, hexatm: true)
          if latoms.count > 0 {
            let le = ModelEntity()
//            Task { @MainActor in
            le.name = "Ligand"
//            }
            
            if let l = Molecule.protein(atoms: latoms, saveCloud: false) {
              //            print(p.name)
              l.components.set(HoverEffectComponent())
              l.components.set(InputTargetComponent())
              l.generateCollisionShapes(recursive: true, static: true)
//              l.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: false, canRotate: true))
              le.addChild(l)
              
              //            pe.position = pte.position + firstPos // pte.position
              le.setPosition([0.5, 1, -0.5], relativeTo: nil)
              //            let pc = ProteinComponent()
              //            pe.components.set(pc)
//              Task { @MainActor in
                model.ligand = le
                
                model.rootEntity.addChild(le)
//              }
              
            }
          }
           */
          
          /*
          let (atoms,residues,helices,sheets,seqres) = PDB.parsePDB(named: model.pName, maxChains: 4)
          
          // Cache protein data for tap selection
          model.proteinResidues = residues
          var atomIndex = 0
          for residue in residues {
            for atom in residue.atoms {
              let atomPos = SIMD3<Float>(
                Float(atom.x) * 0.01,
                Float(atom.y) * 0.01,
                Float(atom.z) * 0.01
              )
              model.atomPositions.append(atomPos)
              model.atomRadii.append(Float(atom.radius))  // Store actual visual radius
              model.atomToResidueMap[atomIndex] = residue
              atomIndex += 1
            }
          }
          print("Cached \(model.atomPositions.count) atom positions for \(residues.count) residues")
          */
          
          /*
          let pe = ModelEntity()
          let pte = ModelEntity()
//          Task {@MainActor in
            pe.name = "Protein"
            pte.name = "ProteinTag"
//          }
          //        let pc = ProteinComponent()
          //        pe.components.set(pc)
          let firstPos : SIMD3<Float> = {
            if let r = residues.first, r.atoms.count > 0 {
              SIMD3(Float(r.atoms[0].x/100), Float(r.atoms[0].y/100), Float(r.atoms[0].z/100))
            } else {
              .zero
            }
          }()

//          print(pte.components)
          
//          let topGroupID = HoverEffectComponent.GroupID()
          
          //        if model.showResidues {
          print("Residues = \(residues.count)")
          residues.forEach {
            print("\($0.serNum) \($0.resName) \($0.chainID)")
          }
//          print(residues.map { "\($0.resName) \($0.chainID) \($0.serNum)" })


          /*
          if let me = Molecule.genRichardsonDiagramEntity(residues: residues, helices: helices, sheets: sheets) {
            me.transform.translation = -firstPos
            me.name = "Ribbon"
            /*
            let hoverA = HoverEffectComponent(
              .highlight(HoverEffectComponent.HighlightHoverEffectStyle(
                color: .blue, strength: 0.25
              )))
            //                hoverA.hoverEffect.groupID = topGroupID
            me.components.set(hoverA)
             */
            me.isEnabled = false
            pte.addChild(me)
            model.ribbon = me
          }
           */


          
          var cnt : Double = 0
          let tot = Double(residues.count)
          for r in residues { // .prefix(100) {
            //          residues.forEach { r in
            let me = Molecule.genResidueEntity(residue: r)
//            if let me = Molecule.genMolecule(residue: r) {
              //              if let me = await Molecule.entity(residue: r) {
            let mc = MoleculeComponent(residue: r)
            me.children.forEach { c in
              c.components.set(mc)
            }
              //                me.components.set(mc)
              
            let p = r.atoms.first!
            let pos : SIMD3<Float> = [Float(p.x/100), Float(p.y/100), Float(p.z/100)]
//              if cnt == 0 {
//                firstPos = pos
//              }
//            Task {@MainActor in
            me.position = pos // - firstPos
//              me.transform.translation = pos - firstPos
                
            me.name = r.resName
//            }
            
            /*
            let hoverA = HoverEffectComponent(
              .highlight(HoverEffectComponent.HighlightHoverEffectStyle(
                color: .green, strength: 0.35
              )))
              //                hoverA.hoverEffect.groupID = topGroupID
            me.components.set(hoverA)
             */
              //                me.components.set(InputTargetComponent())
              //                me.generateCollisionShapes(recursive: true, static: true)
              //              me.components.remove(CollisionComponent.self)
              //              me.components.remove(InputTargetComponent.self)
              
              //            print(me.name, r.resName)
              
            pte.addChild(me)
              
              //              if cnt == 0 {
              //                print(me.name)
//            print(me.name, me.position)
              //              }
                          
            
            //            DispatchQueue.main.async {
//            Task { @MainActor in
              cnt += 1
              model.progress = cnt / tot
//              print("Building",model.progress)
//            }
            //            }
            //            }
            
          }
          
          /*
           let hoverA = HoverEffectComponent(
           .highlight(HoverEffectComponent.HighlightHoverEffectStyle(
           color: .white, strength: 0.5
           )))
           //            hoverA.hoverEffect.groupID = topGroupID
           pm.components.set(hoverA)
           //            pte.components.set(hoverA)
           */
                    
          //        pte.setPosition([0, 1, -0.5], relativeTo: nil)
          let ptc = ProteinComponent()
          pte.components.set(ptc)
          
          pte.isEnabled = false
          model.spheres = pte
          
          */
          
          /*

          pte.position = [0, 1, -0.85]
          pte.isEnabled = true
          //              model.proteinTag = pte
          
          model.protein = pte
          model.rootEntity.addChild(pte)
          
          pte.components.set(InputTargetComponent())
          pte.generateCollisionShapes(recursive: true, static: true)
          pte.components.set(GestureComponent(canDrag: false, pivotOnDrag: false, preserveOrientationOnPivotDrag: true, canScale: true, canRotate: true))
          
          
          let vb = pte.visualBounds(recursive: true, relativeTo: pte, excludeInactive: false)
          print(vb.extents, vb.center)
          let collisionShape = ShapeResource.generateBox(size: vb.extents)
            .offsetBy(translation: vb.center)
          let collisionComponent = CollisionComponent(shapes: [collisionShape], isStatic: true)
          model.proteinCollision = collisionComponent
          pte.components.set(collisionComponent)
           
           */
          
          
          

          let rbs = ModelEntity()
          rbs.name = "RibbonAndStick"
          model.protein = rbs
          
//          rbs.addChild(pte)
//          print(pte.position)
//          print(pte.children.first!.position)

          /*
          let hoverA = HoverEffectComponent(
            .highlight(HoverEffectComponent.HighlightHoverEffectStyle(
              color: .white, strength: 0.15
            )))
          rbs.components.set(hoverA)
           */

          
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

            /*
            let vb = entity.visualBounds(recursive: true, relativeTo: entity, excludeInactive: false)
            print(vb.extents, vb.center)
            let collisionShape = ShapeResource.generateBox(size: vb.extents)
              .offsetBy(translation: vb.center)
            let collisionComponent = CollisionComponent(shapes: [collisionShape], isStatic: true)
            entity.components.set(collisionComponent)

            entity.components.set(InputTargetComponent())
            entity.generateCollisionShapes(recursive: true, static: true)
            entity.components.set(GestureComponent(canDrag: true, pivotOnDrag: false, preserveOrientationOnPivotDrag: true, canScale: true, canRotate: true))
            */

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
              
              /*
              if let bindingsEntity = Molecule.highlightResidues(
                model.bindingResidues,
                in: model.ballAndStick!,
                atomScale: 1.5,
                color: .yellow,
                intensity: 0.3,
                opacity: 0.3
              ) {
                rbs.addChild(bindingsEntity)
                model.bindings = bindingsEntity
              }
               */

//              Molecule.highlightResidues(bindingResidues, in: model.ballAndStick!)
              print("\(ligand.resName): \(bindingResidues.count) binding residues")


            }

            
            await MainActor.run {
              model.progress = 0.7
              model.loadingStatus = "Creating sphere representation..."
            }

            // Enable collision and input for tap gestures
//            bse.components.set(InputTargetComponent())
//            bse.generateCollisionShapes(recursive: true, static: true)

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
            

            /*
            // Highlight the binding pocket in yellow
            if let bindingsEntity = Molecule.highlightResidues(
              model.bindingResidues,
              in: model.ballAndStick!,
              atomScale: 1.5,
              color: .yellow,
              intensity: 0.3,
              opacity: 0.3
            ) {
              rbs.addChild(bindingsEntity)
              model.bindings = bindingsEntity
            }
             */
            
            
            await MainActor.run {
              model.progress = 0.9
              model.loadingStatus = "Finalizing..."
            }

            /*
            let se = ProteinSpheres.
            se.name = "Spheres"
            se.isEnabled = false
            rbs.addChild(se)
            model.spheres = se
            print(se.position)
             */


            /*
            let arb = AdvancedRibbonBuilder()
            let me = arb.buildEntity(from: s, colorMode: .byStructure)
            me.name = "AdvancedRibbon"
            me.scale *= [0.1,0.1,0.1]
            me.isEnabled = true
            me.position = [0, 4, -3.5]
            model.rootEntity.addChild(me)
             */
            
          }

//          let pivotEntity = Entity()
          
          model.rootEntity.addChild(rbs)
          rbs.position = [0, 1, -1.85]
//          model.rootEntity.addChild(pivotEntity)
          
          let rvb = rbs.visualBounds(recursive: true, relativeTo: rbs, excludeInactive: false)
          print(rvb.extents, rvb.center)
          

          // Offset all children so the visual center becomes the pivot point
          let centerOffset = -rvb.center
          model.proteinCenterOffset = centerOffset
          for child in rbs.children {
            child.position = child.position + centerOffset
          }

          
//          pivotEntity.position = rvb.center
//          rbs.setParent(pivotEntity, preservingWorldTransform: true)
//          pivotEntity.scale = SIMD3(2, 2, 2)
          
//          pivotEntity.components[InputTargetComponent.self] = InputTargetComponent()
//          pivotEntity.generateCollisionShapes(recursive: true)

//          pivotEntity.position = [0, 1, -0.85]

          /*
          rbs.generateCollisionShapes(recursive: true, static: true)
//          model.ballAndStick!.generateCollisionShapes(recursive: true, static: true)

          let meshes = model.ballAndStick!.children.map { $0.components[ModelComponent.self]!.mesh }
          let mr = meshes.first!
//          let a = mr.formUnion(mr)
//          let ss = ShapeResource.generateConvex(from: mr)
          
          let sr = try! await ShapeResource.generateStaticMesh(from: mr)
//          let sr = await ShapeResource.generateConvex(from: model.ballAndStick!.model?.mesh ?? nil)
//          let shapes = rbs.components[CollisionComponent.self]!.shapes
          let collisionComponent = CollisionComponent(shapes: [sr], isStatic: true)

//          rbs.components.set(collisionComponent)
          model.proteinCollision = collisionComponent
          */
//          rbs.components.set(InputTargetComponent())
          
//          let sh = rbs.components[CollisionComponent.self]!.shapes[0]
//          let sh = shapes[0]
//          let mesh = await MeshResource(shape: sr)
          
          /*
          var boundsMat: PhysicallyBasedMaterial {
            var boundsMat = PhysicallyBasedMaterial()
            boundsMat.baseColor = .init(tint: .red)
            boundsMat.blending = .transparent(opacity: .init(floatLiteral:0.4))
            return boundsMat
          }
          let pBox = ModelEntity(mesh: .generateBox(size: rvb.extents), materials: [boundsMat])
//          let pBox = ModelEntity(mesh: mr, materials: [boundsMat])
//          pBox.position = rvb.center // rbs.position // + vb.center
//          rbs.addChild(pBox)
          */

          
          
          ManipulationComponent.configureEntity(rbs)
          rbs.components[ManipulationComponent.self]!.releaseBehavior = .stay
          rbs.components[ManipulationComponent.self]!.dynamics.translationBehavior = .unconstrained

          /*
          var mc = ManipulationComponent()
          mc.releaseBehavior = .stay
          mc.dynamics.primaryRotationBehavior = .unconstrained
          mc.dynamics.secondaryRotationBehavior = .unconstrained
          mc.dynamics.scalingBehavior = .unconstrained
          mc.dynamics.translationBehavior = .unconstrained
          
          rbs.components.set(mc)
           */

          /*
          ManipulationComponent.configureEntity(
            rbs,
            hoverEffect: .highlight(.default),  // .highlight(color: .blue, duration: 0.25)
            allowedInputTypes: .direct,
            collisionShapes: [collisionShape]
            )
          rbs.components[ManipulationComponent.self]!.releaseBehavior = .stay
           */
          
          
//          rbs.components.set(GestureComponent(canDrag: true, pivotOnDrag: false, preserveOrientationOnPivotDrag: true, canScale: true, canRotate: true))

          
//            model.arView.installGestures(.translation, for: pte)

            /*
            var boundsMat: PhysicallyBasedMaterial {
              var boundsMat = PhysicallyBasedMaterial()
              boundsMat.baseColor = .init(tint: .red)
              boundsMat.blending = .transparent(opacity: .init(floatLiteral:0.4))
              return boundsMat
            }
            
//            let vb = pte.visualBounds(recursive: true, relativeTo: pte, excludeInactive: false)
//            let material = SimpleMaterial(color: UIColor.red.withAlphaComponent(0.4), isMetallic: false)
            let pBox = ModelEntity(mesh: .generateBox(size: vb.extents), materials: [boundsMat])
            //            pBox.position = SIMD3<Float>(vb.center.x - vb.extents.x / 2, vb.center.y - vb.extents.y / 2, vb.center.z - vb.extents.z / 2)
            pBox.position = pte.position + vb.center
            
            /*
             pBox.components.set(InputTargetComponent())
             pBox.generateCollisionShapes(recursive: true, static: true)
             pBox.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: true, canRotate: true))
             */

            
            //            pBox.position = vb.center // pte.position // + vb.center
            //            pm.addChild(pBox)
            model.rootEntity.addChild(pBox)
             */
            
            
//          }
          
          
          //        } else {
          
          
          /* Single Protein
           
           if let p = await Molecule.protein(atoms: atoms, saveCloud: false) {
           //            print(p.name)
           await print(p.name, p.position)
           await p.components.set(HoverEffectComponent())
           await p.components.set(InputTargetComponent())
           await p.generateCollisionShapes(recursive: true, static: true)
           await p.components.set(GestureComponent(canDrag: false, pivotOnDrag: false, preserveOrientationOnPivotDrag: false, canScale: true, canRotate: true))
           await pe.addChild(p)
           
           //            pe.position = pte.position + firstPos // pte.position
           await pe.setPosition([0, 1, -0.5], relativeTo: nil)
           let pc = ProteinComponent()
           await pe.components.set(pc)
           
           Task { @MainActor in
           model.protein = pe
           }
           
           }
           */
          
          /*
           pe.setPosition([0, 1, -0.5], relativeTo: nil)
           let pc = ProteinComponent()
           pe.components.set(pc)
           
           Task { @MainActor in
           model.protein = pe
           }
           */
          
          /*
           Task { @MainActor in
           //              model.rootEntity.addChild(pe)
           model.rootEntity.addChild(pte)
           }
           */
          
          /*
           switch await openImmersiveSpace(id: "ImmersiveSpace") {
           case .opened:
           immersiveSpaceIsShown = true
           //            model.loading = false
           case .error, .userCancelled:
           fallthrough
           @unknown default:
           immersiveSpaceIsShown = false
           showImmersiveSpace = false
           }
           */
          
          /*
           } else if immersiveSpaceIsShown {
           await dismissImmersiveSpace()
           immersiveSpaceIsShown = false
           
           model.loading = false
           model.tagged.removeAll()
           model.protein?.removeFromParent()
           model.proteinTag?.removeFromParent()
           model.ligand?.removeFromParent()
           model.protein = nil
           model.proteinTag = nil
           model.ligand = nil
           
           }
           */
          //        */
          //        }
          
          /*
           } else {
           Task {
           if immersiveSpaceIsShown {
           model.loading = false
           model.tagged.removeAll()
           model.protein?.removeFromParent()
           model.proteinTag?.removeFromParent()
           model.ligand?.removeFromParent()
           model.protein = nil
           model.proteinTag = nil
           model.ligand = nil
           
           await dismissImmersiveSpace()
           immersiveSpaceIsShown = false
           
           }
           }
           }
           */
        
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
