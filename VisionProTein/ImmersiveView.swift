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
    RealityView { content in
      // Add the initial RealityKit content

      content.add(model.rootEntity)

    } update: { content in
    }
    .installGestures()
    .gesture(
      TapGesture(count: 1)
        .targetedToEntity(where: .has(MoleculeComponent.self))
        .onEnded { value in
          guard let res = value.entity as? ModelEntity else { return }
          Task {
//            print(res.name, res.parent?.parent)
            if let protein = res.parent {
              
              protein.findEntity(named: "Outline")?.removeFromParent()
              
              print(res.name)
//              res.components[MoleculeComponent.self]?.outline.toggle()
              
              let outline = res.clone(recursive: true) // as! ModelEntity
              outline.scale *= 1.05
              outline.name = "Outline"
              outline.components[MoleculeComponent.self] = nil
              
              var material = PhysicallyBasedMaterial()
              material.emissiveColor.color = .white
              material.emissiveIntensity = 0.5

              // an outer surface doesn't contribute to the final image
              material.faceCulling = .front

              outline.model?.materials = outline.model!.materials.map { _ in material }
//              outline.transform = res.transform
              protein.addChild(outline)
              
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
