//
//  ImmersiveView.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
  @ObservedObject var model : ARModel
  
  var body: some View {
    /*
    RealityView(make: { content, attachments in
      content.add(model.rootEntity)
    }, update: { content, attachments in
      
    }, attachments: {
      Attachment(id: "Panel") {
        
      }
    })
    */

    RealityView { content, attachments in
      // Add the initial RealityKit content
      content.add(model.rootEntity)
      if let entity = attachments.entity(for: "Panel") {
        entity.position = [-0.5,1,-0.75]
        content.add(entity)
      }
      model.loading = false

    } update: { content, attachments in
    } attachments: {
      Attachment(id: "Panel") {
        VStack {
          HStack {
            Spacer()
            Text("Protein Panel")
              .font(.title)
            Spacer()
          }
          .padding(.top)
          HStack {
            Spacer()
            /*
            Button("Deselect All") {
              
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.tagState)
            .padding()
             */
            
            Button("Select Binding Sites") {
              for i in 0..<model.proteinTag!.children.count {
                let r = model.proteinTag!.children[i] as! ModelEntity
                guard
                  let mc = r.components[MoleculeComponent.self],
                  let protein = r.parent else { continue }

                let res = mc.residue
                if res.serNum == 37 || res.serNum == 96 {

                  mc.outline = true
                  model.tagged.insert(mc.residue)
                  
                  let lmc = MoleculeComponent(residue: Residue(id: res.id, serNum: -1, chainID: "", resName: r.name, atoms: []))
                  let outline = r.clone(recursive: true) // as! ModelEntity
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
                  protein.addChild(outline)
                  
                  let tm = MeshResource.generateText(r.name, extrusionDepth: 0.002, font: .boldSystemFont(ofSize: 0.015), containerFrame: .zero, alignment: .center)
                  let textEntity = ModelEntity(mesh: tm, materials: [SimpleMaterial(color: .red, isMetallic: false)])
                  textEntity.name = "Text"
                  textEntity.components[MoleculeComponent.self] = lmc
                  let vb = outline.visualBounds(relativeTo: protein)
                  let bc = vb.center
                  let br = vb.boundingRadius
                  let bt = vb.max.y
                  let bb = vb.min.y
                  textEntity.position = bc + [0, (bt - bb)/2, 0]
    //              textEntity.position = outline.position + [-0.02,0.01,0]
                  protein.addChild(textEntity)

                  
                }

              }
              
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.tagState)
            .padding()
            
            HStack {
              Spacer()
              Text("Tag Residues")
              Toggle("", isOn: $model.tagState).labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing)
//              .toggleStyle(.automatic)
          }
          .padding()
          ZStack {
            VStack {
              Text("Selected Residues")
              ScrollView {
                VStack(spacing: 0) {
                  let a = Array(model.tagged)
                  ForEach(0..<a.count, id: \.self) { idx in
                    let r = a[idx]
                    HStack(spacing: 30) {
                      Text(r.resName)
                      Text("# \(r.serNum)")
                      Text("Chain \(r.chainID)")
                      Text("Atom Count \(r.atoms.count)")
                      Spacer()
                    }
                    .font(.title)
                    .padding()
                  }
                }
              }
              .background {
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color.clear)
                  .strokeBorder(style: .init(lineWidth: 2))
              }
            }
            .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 80)
          }
          Button("Regenerate", role: .destructive) {
            let children = model.proteinTag?.children.filter { res in
              if let mc = res.components[MoleculeComponent.self], mc.outline || mc.residue.atoms.count == 0 {
                return true
              }
              return false
            }
            children?.forEach { $0.removeFromParent() }
            model.tagged.removeAll()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
              children?.forEach {
                if $0.name == "Outline" || $0.name == "Text" { return }
                model.proteinTag?.addChild($0)
              }
            }
            
            
          }
          .buttonStyle(.borderedProminent)
          .disabled(!model.tagState)
          .padding()
        }
        .glassBackgroundEffect()
      }
    }

    .installGestures()
//    .onChange(of: model.protein?.scale) { old, new in
//      if let new {
//        model.ligand?.scale = new
//      }
//    }

    .gesture(
      TapGesture(count: 1)
//        .targetedToAnyEntity()
        .targetedToEntity(where: .has(MoleculeComponent.self))
        .onEnded { value in
          print("Tap !!!")
          guard let res = value.entity as? ModelEntity,
                let mc = res.components[MoleculeComponent.self],
                let protein = res.parent
          else { return }
          
          let r = mc.residue
          if r.atoms.count == 0 {
            res.removeFromParent()
            
            let ents = protein.children.compactMap({ $0.components[MoleculeComponent.self]?.residue.id == r.id ? $0 : nil })
            for e in ents {
              if e.name == "Text" { e.removeFromParent() }
            }

            
            let mcs = protein.children.compactMap({ $0.components[MoleculeComponent.self]})
            for mc in mcs.filter({ $0.residue.id == r.id}) {
              mc.outline = false
              model.tagged.remove(mc.residue)
            }
          } else {
            mc.outline = true
            Task {
//            print(res.name, res.parent?.parent)
//              if let protein = res.parent {
              print(res.name)
              model.tagged.insert(mc.residue)
              
              let lmc = MoleculeComponent(residue: Residue(id: r.id, serNum: -1, chainID: "", resName: res.name, atoms: []))
              let outline = res.clone(recursive: true) // as! ModelEntity
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
              protein.addChild(outline)
              
//              let textEntity = ModelEntity(mesh: .generateText(res.name, extrusionDepth: 0.4, font: .boldSystemFont(ofSize: 24), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping))

//              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.4, font: .boldSystemFont(ofSize: 2), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
//              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.01, font: .boldSystemFont(ofSize: 0.1), containerFrame: CGRect(x: 0, y: 0, width: 0.25, height: 0.1), alignment: .center)
              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.002, font: .boldSystemFont(ofSize: 0.015), containerFrame: .zero, alignment: .center)
              let textEntity = ModelEntity(mesh: tm, materials: [SimpleMaterial(color: .red, isMetallic: false)])
              textEntity.name = "Text"
              textEntity.components[MoleculeComponent.self] = lmc
              let vb = outline.visualBounds(relativeTo: protein)
              let bc = vb.center
              let br = vb.boundingRadius
              let bt = vb.max.y
              let bb = vb.min.y
              textEntity.position = bc + [0, (bt - bb)/2, 0]
//              textEntity.position = outline.position + [-0.02,0.01,0]
              protein.addChild(textEntity)

              
//              } else {
//                protein.findEntity(named: "Outline")?.removeFromParent()

//              }
              
//              res.components[MoleculeComponent.self]?.outline.toggle()
              
              
              /*
              let box = m.visualBounds(recursive: true, relativeTo: m.parent!)
              let bm = MeshResource.generateBox(width: box.max.x - box.min.x, height: box.max.y - box.min.y, depth: box.max.z - box.min.z)
              let be = ModelEntity(mesh: bm)
              be.transform = m.transform

              be.name = "Box"
              be.isEnabled = true
              m.parent?.addChild(be)
               */
              
//              m.findEntity(named: "Box")?.isEnabled = true
            }
          }
        }
    )

    .task {
      await model.run()
    }

  }

}

#Preview {
  ImmersiveView(model: ARModel())
//    .environment(Loading())
    .previewLayout(.sizeThatFits)
}
