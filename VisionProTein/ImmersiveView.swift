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
      /*
      if let entity = attachments.entity(for: "Panel") {
        entity.position = [-0.5,1,-0.75]
        content.add(entity)
      }
      model.loading = false
       */

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
            
            /*
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
            .disabled(model.modelState != .tag)
            .padding()
            
            HStack {
              Spacer()
              Text("Folded")
              Toggle("", isOn: $model.foldedState).labelsHidden()
                .disabled(model.modelState != .tag)

              Spacer()
              Text("Tag Residues")
              Toggle("", isOn: $model.modelState).labelsHidden()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing)
//              .toggleStyle(.automatic)
             */
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
          .disabled(model.modelState != .tagging)
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

    /*
    .gesture(
      TapGesture(count: 2)
        .targetedToAnyEntity()
        .onEnded { _ in
          print("Tap 1 !!!")
        }
    )
     */
    

    // Tap gesture for ball and stick representation  
    .gesture(
      SpatialTapGesture()
        .targetedToAnyEntity()
        .onEnded { value in
          // Check if we tapped on the ball and stick entity
          guard let ballAndStick = model.ballAndStick,
                ballAndStick.isEnabled,
                let tappedEntity = value.entity as? ModelEntity else {
            return
          }
          
          // First check if we tapped on a highlighted residue entity
          var current: Entity? = tappedEntity
          var highlightedEntity: ModelEntity?
          
          while let entity = current {
            // Check if this entity is one of our highlighted residues
            if entity.name.hasPrefix("Selected_") {
              highlightedEntity = entity as? ModelEntity
              break
            }
            current = entity.parent
          }
          
          // If we tapped a highlighted residue, remove it
          if let highlighted = highlightedEntity {
            // Extract residue ID from name format: "Selected_<resName>_<chainID><serNum>"
            let nameParts = highlighted.name.split(separator: "_")
            if nameParts.count >= 3 {
              // Parse the chain and sequence number from the last part
              let chainAndSeq = String(nameParts[2])
              if let serNum = Int(chainAndSeq.dropFirst()) {
                // Remove from tracking dictionary
                model.highlightedResidueEntities.removeValue(forKey: serNum)
                
                // Find and remove from tagged set
                if let residue = model.tagged.first(where: { $0.serNum == serNum }) {
                  model.tagged.remove(residue)
                  print("Removed highlighted residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
                }
                
                // Remove entity from scene
                highlighted.removeFromParent()
              }
            }
            return  // Don't process as a new selection
          }
          
          // Check if the tapped entity is part of the ball and stick hierarchy
          current = tappedEntity
          var isPartOfBallAndStick = false
          while let entity = current {
            if entity === ballAndStick {
              isPartOfBallAndStick = true
              break
            }
            current = entity.parent
          }
          
          if isPartOfBallAndStick {
            // Get all residues from the PDB
            let pName = "1ERT"
            let (atoms, residues, helices, sheets, seqres) = PDB.parsePDB(named: pName, maxChains: 2)
            
            // Simplest reliable approach: find the closest atom to the tap point
            // Convert tap location to ball and stick local space
            let tapWorldPos = value.convert(value.location3D, from: .local, to: .scene)
            let tapLocalPos = ballAndStick.convert(position: tapWorldPos, from: nil)
            
            print("Tap position (local): \(tapLocalPos)")
            
            // Find the closest atom
            var closestAtom: Atom?
            var closestResidue: Residue?
            var minDistance: Float = .infinity
            
            for residue in residues {
              for atom in residue.atoms {
                let atomPos = SIMD3<Float>(
                  Float(atom.x) * 0.01,
                  Float(atom.y) * 0.01,
                  Float(atom.z) * 0.01
                )
                
                let dist = distance(tapLocalPos, atomPos)
                
                if dist < minDistance {
                  minDistance = dist
                  closestAtom = atom
                  closestResidue = residue
                }
              }
            }
            
            print("Closest atom: \(closestAtom?.name ?? "none") in \(closestResidue?.resName ?? "")\(closestResidue?.serNum ?? -1), distance: \(minDistance)")
            
            // Debug: show what we found
            if let atom = closestAtom, let residue = closestResidue {
              let atomPos = SIMD3<Float>(
                Float(atom.x) * 0.01,
                Float(atom.y) * 0.01,
                Float(atom.z) * 0.01
              )
              print("Closest atom: \(atom.name) in residue \(residue.resName)\(residue.serNum)")
              print("Atom position: \(atomPos), distance: \(minDistance)")
            }
            
            // Accept matches within 0.1 units (10 cm in scene scale)
            // This is generous enough to account for tap location inaccuracy with instanced meshes
            if let residue = closestResidue, minDistance < 0.1 {
              // Check if this residue is already highlighted - if so, remove it
              if let existingEntity = model.highlightedResidueEntities[residue.serNum] {
                print("Removing highlighted residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
                
                // Remove from tracking dictionary
                model.highlightedResidueEntities.removeValue(forKey: residue.serNum)
                
                // Remove from tagged set
                model.tagged.remove(residue)
                
                // Remove entity from scene
                existingEntity.removeFromParent()
                return
              }
              
              print("Selected residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
              
              // Create a separate entity for this residue with larger atom radius
              if let residueEntity = Molecule.genBallAndStickResidue(residue: residue, atomScale: 1.5) {
                residueEntity.name = "Selected_\(residue.resName)_\(residue.chainID)\(residue.serNum)"
                
                // Add emissive material for highlight with 50% opacity
                var material = PhysicallyBasedMaterial()
                material.emissiveColor.color = .yellow
                material.emissiveIntensity = 0.3
                material.blending = .transparent(opacity: 0.3)
                
                // Apply material to all children
                residueEntity.children.forEach { child in
                  if var modelEntity = child as? ModelEntity,
                     let model = modelEntity.model {
                    modelEntity.model?.materials = model.materials.map { _ in material }
                  }
                }
                
                // Add collision shapes and input target to make it tappable
                residueEntity.components.set(InputTargetComponent())
                residueEntity.generateCollisionShapes(recursive: true, static: true)
                
                // Add it to the same parent as the ball and stick entity
                // This ensures it uses the same coordinate space
                if let parent = ballAndStick.parent {
                  parent.addChild(residueEntity)
                } else {
                  model.rootEntity.addChild(residueEntity)
                }
                
                // Track this highlighted entity
                model.highlightedResidueEntities[residue.serNum] = residueEntity
                
                // Add to tagged residues
                model.tagged.insert(residue)
              }
            }
            return
          }
        }
    )
    
    .gesture(
      TapGesture(count: 1)
//        .targetedToAnyEntity()
        .targetedToEntity(where: .has(MoleculeComponent.self))
        .onEnded { value in
//          print("Tap !!!")
          guard let atom = value.entity as? ModelEntity,
                let mc = atom.components[MoleculeComponent.self],
                let res = atom.parent
          else { return }
          
          let residue = mc.residue
          print(residue.resName)

//          return;
          
          if mc.outline {
            
            let mcs = res.children.compactMap({ $0.components[MoleculeComponent.self]})
            for ac in mcs {
              ac.outline = false
            }

            res.children.filter { $0.name == "Text" }.forEach { $0.removeFromParent() }
//          if residue.atoms.count == 0 {
//            res.removeFromParent()
            
            /*
            let ents = protein.children.compactMap({ $0.components[MoleculeComponent.self]?.residue.id == residue.id ? $0 : nil })
            for e in ents {
              if e.name == "Text" { e.removeFromParent() }
            }

            
            let mcs = protein.children.compactMap({ $0.components[MoleculeComponent.self]})
            for mc in mcs.filter({ $0.residue.id == residue.id}) {
              mc.outline = false
            }
             */
            model.tagged.remove(residue)
          } else {
            let mcs = res.children.compactMap({ $0.components[MoleculeComponent.self]})
            for ac in mcs {
              ac.outline = true
            }
            
            /*
            for mc in mcs.filter({ $0.residue.id == residue.id}) {
              mc.outline = true
              
              let lmc = MoleculeComponent(residue: Residue(id: residue.id, serNum: -1, chainID: "", resName: res.name, atoms: []))
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

            }
             */
//            mc.outline = true
            Task {
//            print(res.name, res.parent?.parent)
//              if let protein = res.parent {
//              print(res.name)

              model.tagged.insert(residue)
              
              /*
              let lmc = MoleculeComponent(residue: Residue(id: residue.id, serNum: -1, chainID: "", resName: res.name, atoms: []))
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
               */
              
//              let textEntity = ModelEntity(mesh: .generateText(res.name, extrusionDepth: 0.4, font: .boldSystemFont(ofSize: 24), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping))

//              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.4, font: .boldSystemFont(ofSize: 2), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
//              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.01, font: .boldSystemFont(ofSize: 0.1), containerFrame: CGRect(x: 0, y: 0, width: 0.25, height: 0.1), alignment: .center)
              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.002, font: .boldSystemFont(ofSize: 0.015), containerFrame: .zero, alignment: .center)
              let textEntity = ModelEntity(mesh: tm, materials: [SimpleMaterial(color: .red, isMetallic: false)])
              textEntity.name = "Text"
              textEntity.components[MoleculeComponent.self] = mc
              let vb = res.visualBounds(relativeTo: res)
              let bc = vb.center
              let br = vb.boundingRadius
              let bt = vb.max.y
              let bb = vb.min.y
              textEntity.position = bc + [0, (bt - bb)/2, 0]
//              textEntity.position = outline.position + [-0.02,0.01,0]
              res.addChild(textEntity)

              
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
