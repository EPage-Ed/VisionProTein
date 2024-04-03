//
//  ContentView.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
  @ObservedObject var model : ARModel

  @State private var showImmersiveSpace = false
  @State private var immersiveSpaceIsShown = false
//  @State private var loading = false
  @State private var progress : Double = 0
  @State private var rotate : Angle = .zero

  @Environment(\.openImmersiveSpace) var openImmersiveSpace
  @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
  
  var body: some View {
    VStack {
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

      Group {
        Text("Vision ") +
        Text("ProTein")
          .foregroundStyle(Color.green)
      }
        .font(.largeTitle)

      ProgressView()
        .opacity(model.loading ? 1 : 0)
      
      ProteinListView(model: model, showImmersiveSpace: $showImmersiveSpace)
      
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
    .onChange(of: model.tagState) { _, newValue in
      if model.protein == nil || model.proteinTag == nil { return }
      if newValue {
        model.proteinTag?.isEnabled = true
        model.protein?.isEnabled = false
        model.proteinTag!.transform.scale = model.protein!.children[0].transform.scale
        model.proteinTag!.transform.rotation = model.protein!.children[0].transform.rotation
//        model.rootEntity.addChild(model.proteinTag!)
//        model.rootEntity.removeChild(model.protein!)
      } else {
        model.proteinTag?.isEnabled = false
        model.protein?.isEnabled = true
//        model.rootEntity.addChild(model.protein!)
//        model.rootEntity.removeChild(model.proteinTag!)
      }
    }
    .onChange(of: showImmersiveSpace) { _, newValue in
      if newValue {
        model.loading = true
        

//        model.rootEntity.components.set(HoverEffectComponent()) 
//        model.rootEntity.components.set(InputTargetComponent())
//        model.rootEntity.generateCollisionShapes(recursive: true, static: true)
//        model.rootEntity.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: true, canRotate: true))

      }
      

      Task {
        if newValue {
          
          // Get the Ligand
          let (latoms,lresidues) = PDB.parsePDB(named: "1nc9", maxChains: 99, atom: false, hexatm: true)
          if latoms.count > 0 {
            let le = ModelEntity()
            le.name = "Ligand"
            
            if let l = Molecule.protein(atoms: latoms, saveCloud: false) {
  //            print(p.name)
              l.components.set(HoverEffectComponent())
              l.components.set(InputTargetComponent())
              l.generateCollisionShapes(recursive: true, static: true)
              l.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: false, canRotate: true))
              le.addChild(l)
              
  //            pe.position = pte.position + firstPos // pte.position
              le.setPosition([0.5, 1, -0.5], relativeTo: nil)
  //            let pc = ProteinComponent()
  //            pe.components.set(pc)
              model.ligand = le

              model.rootEntity.addChild(le)

            }
            
          }
          
          let (atoms,residues) = PDB.parsePDB(named: "1nc9", maxChains: 2)  // 1hqq Biotin 3nir 1nc9
          let pe = ModelEntity()
          let pte = ModelEntity()
          pe.name = "Protein"
          pte.name = "ProteinTag"
  //        let pc = ProteinComponent()
  //        pe.components.set(pc)
          var firstPos : SIMD3<Float> = .zero

  //        if model.showResidues {
            var cnt : Double = 0
            let tot = Double(residues.count)
            for r in residues {
  //          residues.forEach { r in
              if let me = Molecule.entity(residue: r) {
                let mc = MoleculeComponent(residue: r)
                
                
                let p = r.atoms.first!
                let pos : SIMD3<Float> = [Float(p.x/100), Float(p.y/100), Float(p.z/100)]
                if cnt == 0 {
                  firstPos = pos
                }
                me.transform.translation = pos - firstPos
                            
                me.name = r.resName
                me.components.set(HoverEffectComponent())
  //              me.components.set(InputTargetComponent())
  //              me.generateCollisionShapes(recursive: true, static: true)
                me.components.set(mc)
  //              me.components.remove(CollisionComponent.self)
  //              me.components.remove(InputTargetComponent.self)
                
    //            print(me.name, r.resName)
                
                pte.addChild(me)
                
                if cnt == 0 {
                  print(me.name, me.position)
                }

/*
                if r.serNum == 37 || r.serNum == 96 {

                  mc.outline = true
                  model.tagged.insert(mc.residue)
                  
                  let lmc = MoleculeComponent(residue: Residue(id: r.id, serNum: -1, chainID: "", resName: me.name, atoms: []))
                  let outline = me.clone(recursive: true) // as! ModelEntity
                  outline.scale *= 1.03
                  outline.name = "Outline"
                  outline.components[MoleculeComponent.self] = lmc
                  
                  var material = PhysicallyBasedMaterial()
                  material.emissiveColor.color = .white
                  material.emissiveIntensity = 0.5
                  
                  // an outer surface doesn't contribute to the final image
                  material.faceCulling = .front
                  
                  outline.model?.materials = outline.model!.materials.map { _ in material }
                  //              outline.transform = res.transform
                  pte.addChild(outline)

                  
                  let tm = MeshResource.generateText(me.name, extrusionDepth: 0.002, font: .boldSystemFont(ofSize: 0.015), containerFrame: .zero, alignment: .center)
                  let textEntity = ModelEntity(mesh: tm, materials: [SimpleMaterial(color: .red, isMetallic: false)])
                  textEntity.name = "Text"
                  textEntity.components[MoleculeComponent.self] = lmc
                  let vb = outline.visualBounds(relativeTo: pte)
                  let bc = vb.center
                  let br = vb.boundingRadius
                  let bt = vb.max.y
                  let bb = vb.min.y
                  textEntity.position = bc + [0, (bt - bb)/2, 0]
    //              textEntity.position = outline.position + [-0.02,0.01,0]
                  pte.addChild(textEntity)

                  
                }
  */
                
              }
              
              
              cnt += 1
  //            DispatchQueue.main.async {
                progress = cnt / tot
                print("Building",progress)
  //            }
              
            }
            
            pte.components.set(InputTargetComponent())
            pte.generateCollisionShapes(recursive: true, static: true)
            pte.components.set(GestureComponent(canDrag: false, pivotOnDrag: false, preserveOrientationOnPivotDrag: false, canScale: true, canRotate: true))

          pte.position = [0, 1, -0.5]
  //        pte.setPosition([0, 1, -0.5], relativeTo: nil)
          let ptc = ProteinComponent()
          pte.components.set(ptc)
          pte.isEnabled = false
          model.proteinTag = pte

  //        } else {

            if let p = Molecule.protein(atoms: atoms, saveCloud: false) {
  //            print(p.name)
              print(p.name, p.position)
              p.components.set(HoverEffectComponent())
              p.components.set(InputTargetComponent())
              p.generateCollisionShapes(recursive: true, static: true)
              p.components.set(GestureComponent(canDrag: false, pivotOnDrag: false, preserveOrientationOnPivotDrag: false, canScale: true, canRotate: true))
              pe.addChild(p)
              
  //            pe.position = pte.position + firstPos // pte.position
              pe.setPosition([0, 1, -0.5], relativeTo: nil)
              let pc = ProteinComponent()
              pe.components.set(pc)
              model.protein = pe

            }

  //        }
          
          model.rootEntity.addChild(pe)
          model.rootEntity.addChild(pte)

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
      }
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView(model: ARModel())
}
