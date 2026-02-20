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
//    MainView(model: model)
//      .frame(minWidth: 1024, minHeight: 600)
//      .transform3DEffect(AffineTransform3D(translation: .init(x: 0, y: 1, z: -5)))


    RealityView { content, attachments in
      // CRITICAL FIX: Only add rootEntity if it's not already in the scene
      // This prevents the "already parented" error when SwiftUI re-evaluates
      print("[ImmersiveView] RealityView make closure called")
      print("[ImmersiveView] rootEntity children: \(model.rootEntity.children.count), parent: \(String(describing: model.rootEntity.parent?.name))")
      
      // Add skybox - Create a simple lighting environment
      // For a basic skybox, we can use ImageBasedLightComponent or set lighting
      let skyboxEntity = Entity()
      skyboxEntity.name = "Skybox"
      
      // Create a large sphere to act as skybox
      let skyboxMesh = MeshResource.generateSphere(radius: 1000)
      var skyboxMaterial = UnlitMaterial()
      skyboxMaterial.color = .init(tint: .init(red: 0.05, green: 0.08, blue: 0.25, alpha: 1.0))
      
      let skyboxModel = ModelEntity(mesh: skyboxMesh, materials: [skyboxMaterial])
      skyboxModel.name = "SkyboxModel"
      skyboxModel.scale *= .init(x: -1, y: 1, z: 1) // Invert to render inside
      skyboxModel.components.set(OpacityComponent(opacity: model.skyboxOpacity))
      skyboxEntity.addChild(skyboxModel)
      content.add(skyboxEntity)
      
      print("[ImmersiveView] Skybox created")
      
      // Check if rootEntity is already in content by checking if it has a scene
      if model.rootEntity.scene == nil {
        print("[ImmersiveView] Adding rootEntity to content (first time)")
        content.add(model.rootEntity)
      } else {
        print("[ImmersiveView] WARNING: rootEntity already has a scene, skipping add")
      }
      /*
      if let entity = attachments.entity(for: "Panel") {
        entity.position = [-0.5,1,-0.75]
        content.add(entity)
      }
      model.loading = false
       */
      
      withAnimation {
        model.pName = model.protein == nil ? "Select a Protein" : model.pName
        model.immersiveSpaceReady = true
      }

    } update: { content, attachments in
    } attachments: {
      
      /*
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
//          .disabled(model.modelState != .tagging)
          .padding()
        }
        .glassBackgroundEffect()
      }
       */
    }
    
    /*
    .gesture(
      DragGesture(minimumDistance: 0, coordinateSpace: .immersiveSpace)
        .onChanged { value in
          print("TAP")
          // This captures the 3D position of the hand pinch
          let handPosition = value.location3D
          
          // Create entity at the pinch point
//          let dot = ModelEntity(mesh: .generateSphere(radius: 0.01))
          let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.01),
            materials: [SimpleMaterial(color: .systemBlue, isMetallic: true)]
          )
          sphere.position = SIMD3<Float>(handPosition)
          model.rootEntity.addChild(sphere)
//          content.add(dot)
        }
    )
     */

//    .installGestures()
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
//    .gesture(
//      SpatialTapGesture()
//        .targetedToAnyEntity()
//        .onEnded { value in
//          // Check if we tapped on the ball and stick entity
//          guard let ballAndStick = model.ballAndStick,
//                ballAndStick.isEnabled,
//                let tappedEntity = value.entity as? ModelEntity else {
//            return
//          }
//          
//          // First check if we tapped on a highlighted residue entity
//          var current: Entity? = tappedEntity
//          var highlightedEntity: ModelEntity?
//          
//          while let entity = current {
//            // Check if this entity is one of our highlighted residues
//            if entity.name.hasPrefix("Selected_") {
//              highlightedEntity = entity as? ModelEntity
//              break
//            }
//            current = entity.parent
//          }
//          
//          // If we tapped a highlighted residue, remove it
//          if let highlighted = highlightedEntity {
//            // Extract residue ID from name format: "Selected_<resName>_<chainID><serNum>"
//            let nameParts = highlighted.name.split(separator: "_")
//            if nameParts.count >= 3 {
//              // Parse the chain and sequence number from the last part
//              let chainAndSeq = String(nameParts[2])
//              if let serNum = Int(chainAndSeq.dropFirst()) {
//                // Remove from tracking dictionary
//                model.highlightedResidueEntities.removeValue(forKey: serNum)
//                
//                // Find and remove from tagged set
//                if let residue = model.tagged.first(where: { $0.serNum == serNum }) {
//                  model.tagged.remove(residue)
//                  print("Removed highlighted residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
//                }
//                
//                // Remove entity from scene
//                highlighted.removeFromParent()
//              }
//            }
//            return  // Don't process as a new selection
//          }
//          
//          // Check if the tapped entity is part of the ball and stick hierarchy
//          current = tappedEntity
//          var isPartOfBallAndStick = false
//          while let entity = current {
//            if entity === ballAndStick {
//              isPartOfBallAndStick = true
//              break
//            }
//            current = entity.parent
//          }
//          
//          if isPartOfBallAndStick {
//            // Use cached protein data instead of parsing PDB on every tap
//            guard !model.atomPositions.isEmpty, !model.atomRadii.isEmpty else {
//              print("No cached atom positions available")
//              return
//            }
//            
//            // FINAL APPROACH: Simple distance-based selection
//            // Convert the 2D screen tap to a 3D point using scene conversion
//            // Even if not perfectly accurate, find the closest atom to that point
//            
//            let tapScenePoint = value.convert(value.location3D, from: .local, to: .scene)
//            let tapWorldPos = SIMD3<Float>(
//              Float(tapScenePoint.x),
//              Float(tapScenePoint.y),
//              Float(tapScenePoint.z)
//            )
//            let tapLocalPos = ballAndStick.convert(position: tapWorldPos, from: nil)
//            
//            print("========== TAP DEBUG ==========")
//            print("Tapped entity: \(tappedEntity.name)")
//            print("Tap in ball-and-stick local: \(tapLocalPos)")
//            print("Searching through \(model.atomPositions.count) atoms...")
//            
//            // Find the closest atom, period - no radius restrictions
//            var closestAtomIndex: Int = -1
//            var minDistance: Float = .infinity
//            
//            for (index, atomPos) in model.atomPositions.enumerated() {
//              let dist = distance(tapLocalPos, atomPos)
//              if dist < minDistance {
//                minDistance = dist
//                closestAtomIndex = index
//              }
//            }
//            
//            print("Closest atom: index \(closestAtomIndex) at distance \(minDistance)m")
//            print("===============================")
//            
//            let selectionMultiplier: Float = 5.0 // For visualization
//            
//            // Clean up old debug markers
//            ballAndStick.children.filter { $0.name.hasPrefix("DEBUG_") }.forEach { $0.removeFromParent() }
//            model.rootEntity.children.filter { $0.name.hasPrefix("DEBUG_") }.forEach { $0.removeFromParent() }
//            
//            // If we found a closest atom
//            if closestAtomIndex >= 0 {
//              // Get the residue for the closest atom
//              guard let closestResidue = model.atomToResidueMap[closestAtomIndex] else {
//                print("Could not find residue for atom index \(closestAtomIndex)")
//                return
//              }
//              
//              print("Selected atom index: \(closestAtomIndex) in \(closestResidue.resName)\(closestResidue.serNum)")
//              let residue = closestResidue
//              // Check if this residue is already highlighted - if so, remove it
//              if let existingEntity = model.highlightedResidueEntities[residue.serNum] {
//                print("Removing highlighted residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
//                
//                // Remove from tracking dictionary
//                model.highlightedResidueEntities.removeValue(forKey: residue.serNum)
//                
//                // Remove from tagged set
//                model.tagged.remove(residue)
//                
//                // Remove entity from scene
//                existingEntity.removeFromParent()
//                return
//              }
//              
//              print("Selected residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
//              
//              // Create a separate entity for this residue with larger atom radius
//              if let residueEntity = Molecule.genBallAndStickResidue(residue: residue, atomScale: 1.5) {
//                residueEntity.name = "Selected_\(residue.resName)_\(residue.chainID)\(residue.serNum)"
//                
//                // Add emissive material for highlight with 50% opacity
//                var material = PhysicallyBasedMaterial()
//                material.emissiveColor.color = .yellow
//                material.emissiveIntensity = 0.3
//                material.blending = .transparent(opacity: 0.3)
//                
//                // Apply material to all children
//                residueEntity.children.forEach { child in
//                  if var modelEntity = child as? ModelEntity,
//                     let model = modelEntity.model {
//                    modelEntity.model?.materials = model.materials.map { _ in material }
//                  }
//                }
//                
//                // Add collision shapes and input target to make it tappable
//                residueEntity.components.set(InputTargetComponent())
//                residueEntity.generateCollisionShapes(recursive: true, static: true)
//                
//                // Add it to the same parent as the ball and stick entity
//                // This ensures it uses the same coordinate space
//                if let parent = ballAndStick.parent {
//                  parent.addChild(residueEntity)
//                } else {
//                  model.rootEntity.addChild(residueEntity)
//                }
//                
//                // Track this highlighted entity
//                model.highlightedResidueEntities[residue.serNum] = residueEntity
//                
//                // Add to tagged residues
//                model.tagged.insert(residue)
//              }
//            }
//            return
//          }
//        }
//    )
    
    
//    .gesture(
//      TapGesture(count: 1)
////        .targetedToAnyEntity()
//        .targetedToEntity(where: .has(MoleculeComponent.self))
//        .onEnded { value in
////          print("Tap !!!")
//          guard let atom = value.entity as? ModelEntity,
//                let mc = atom.components[MoleculeComponent.self],
//                let res = atom.parent
//          else { return }
//          
//          let residue = mc.residue
//          print(residue.resName)
//
////          return;
//          
//          if mc.outline {
//            
//            let mcs = res.children.compactMap({ $0.components[MoleculeComponent.self]})
//            for ac in mcs {
//              ac.outline = false
//            }
//
//            res.children.filter { $0.name == "Text" }.forEach { $0.removeFromParent() }
////          if residue.atoms.count == 0 {
////            res.removeFromParent()
//            
//            /*
//            let ents = protein.children.compactMap({ $0.components[MoleculeComponent.self]?.residue.id == residue.id ? $0 : nil })
//            for e in ents {
//              if e.name == "Text" { e.removeFromParent() }
//            }
//
//            
//            let mcs = protein.children.compactMap({ $0.components[MoleculeComponent.self]})
//            for mc in mcs.filter({ $0.residue.id == residue.id}) {
//              mc.outline = false
//            }
//             */
//            model.tagged.remove(residue)
//          } else {
//            let mcs = res.children.compactMap({ $0.components[MoleculeComponent.self]})
//            for ac in mcs {
//              ac.outline = true
//            }
//            
//            /*
//            for mc in mcs.filter({ $0.residue.id == residue.id}) {
//              mc.outline = true
//              
//              let lmc = MoleculeComponent(residue: Residue(id: residue.id, serNum: -1, chainID: "", resName: res.name, atoms: []))
//              let outline = res.clone(recursive: true) // as! ModelEntity
//              outline.scale *= 1.03
//              outline.name = "Outline"
//              outline.components[MoleculeComponent.self] = lmc
//              
//              var material = PhysicallyBasedMaterial()
//              material.emissiveColor.color = .white
//              material.emissiveIntensity = 0.5
//              
//              // an outer surface doesn't contribute to the final image
//              material.faceCulling = .front
//              
//              outline.model?.materials = outline.model!.materials.map { _ in material }
//              //              outline.transform = res.transform
//              protein.addChild(outline)
//
//            }
//             */
////            mc.outline = true
//            Task {
////            print(res.name, res.parent?.parent)
////              if let protein = res.parent {
////              print(res.name)
//
//              model.tagged.insert(residue)
//              
//              /*
//              let lmc = MoleculeComponent(residue: Residue(id: residue.id, serNum: -1, chainID: "", resName: res.name, atoms: []))
//              let outline = res.clone(recursive: true) // as! ModelEntity
//              outline.scale *= 1.03
//              outline.name = "Outline"
//              outline.components[MoleculeComponent.self] = lmc
//              
//              var material = PhysicallyBasedMaterial()
//              material.emissiveColor.color = .white
//              material.emissiveIntensity = 0.5
//              
//              // an outer surface doesn't contribute to the final image
//              material.faceCulling = .front
//              
//              outline.model?.materials = outline.model!.materials.map { _ in material }
//              //              outline.transform = res.transform
//              protein.addChild(outline)
//               */
//              
////              let textEntity = ModelEntity(mesh: .generateText(res.name, extrusionDepth: 0.4, font: .boldSystemFont(ofSize: 24), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping))
//
////              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.4, font: .boldSystemFont(ofSize: 2), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
////              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.01, font: .boldSystemFont(ofSize: 0.1), containerFrame: CGRect(x: 0, y: 0, width: 0.25, height: 0.1), alignment: .center)
//              let tm = MeshResource.generateText(res.name, extrusionDepth: 0.002, font: .boldSystemFont(ofSize: 0.015), containerFrame: .zero, alignment: .center)
//              let textEntity = ModelEntity(mesh: tm, materials: [SimpleMaterial(color: .red, isMetallic: false)])
//              textEntity.name = "Text"
//              textEntity.components[MoleculeComponent.self] = mc
//              let vb = res.visualBounds(relativeTo: res)
//              let bc = vb.center
//              let br = vb.boundingRadius
//              let bt = vb.max.y
//              let bb = vb.min.y
//              textEntity.position = bc + [0, (bt - bb)/2, 0]
////              textEntity.position = outline.position + [-0.02,0.01,0]
//              res.addChild(textEntity)
//
//              
////              } else {
////                protein.findEntity(named: "Outline")?.removeFromParent()
//
////              }
//              
////              res.components[MoleculeComponent.self]?.outline.toggle()
//              
//              
//              /*
//              let box = m.visualBounds(recursive: true, relativeTo: m.parent!)
//              let bm = MeshResource.generateBox(width: box.max.x - box.min.x, height: box.max.y - box.min.y, depth: box.max.z - box.min.z)
//              let be = ModelEntity(mesh: bm)
//              be.transform = m.transform
//
//              be.name = "Box"
//              be.isEnabled = true
//              m.parent?.addChild(be)
//               */
//              
////              m.findEntity(named: "Box")?.isEnabled = true
//            }
//          }
//        }
//    )

    .task {
      await model.run()
    }
    
    /*
    // Free-space tap gesture with raycast
    .gesture(
      SpatialTapGesture(coordinateSpace: .global)
        .onEnded { value in
          print("========== SPATIAL TAP (FREE SPACE) ==========")
          print("Location3D: \(value.location3D)")
          
          // Convert to world position - location3D is in global space
          let tapWorldPos = SIMD3<Float>(
            Float(value.location3D.x),
            Float(value.location3D.y),
            Float(value.location3D.z)
          )
          
          print("Tap world position: \(tapWorldPos)")
          
          // Create a bright cyan sphere at tap location
          var markerMaterial = PhysicallyBasedMaterial()
          markerMaterial.baseColor = .init(tint: .cyan)
          markerMaterial.emissiveColor = .init(color: .cyan)
          markerMaterial.emissiveIntensity = 10.0
          
          let marker = ModelEntity(
            mesh: .generateSphere(radius: 0.08),
            materials: [markerMaterial]
          )
          marker.name = "FreeSpaceTapMarker"
          marker.position = tapWorldPos
          
          // Remove old markers
          model.rootEntity.children.filter { $0.name == "FreeSpaceTapMarker" }.forEach { $0.removeFromParent() }
          
          model.rootEntity.addChild(marker)
          print("Marker placed at: \(tapWorldPos)")
          print("==============================================")
        }
    )
     */

  }

}

#Preview {
  ImmersiveView(model: ARModel())
//    .environment(Loading())
    .previewLayout(.sizeThatFits)
}
