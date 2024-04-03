//
//  VisionProTeinApp.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import SwiftUI
import RealityKitContent

@main
struct VisionProTeinApp: App {
//  @StateObject var model = ARModel()
  var model = ARModel()

  init() {
    MoleculeComponent.registerComponent()
    ProteinComponent.registerComponent()
    GestureComponent.registerComponent()
    
//    NotificationCenter.default.post(name: .init("EntityScale"), object: nil, userInfo: ["scale":entity.scale])
    NotificationCenter.default.addObserver(forName: .init("EntityScale"), object: nil, queue: .main) { [self] note in
      if let scale = note.userInfo?["scale"] as? SIMD3<Float> {
        model.ligandScale(scale: scale)
//        model.ligand?.scale = scale
      }
    }

  }

  var body: some Scene {
    WindowGroup {
      ContentView(model: model)
    }
    
    ImmersiveSpace(id: "ImmersiveSpace") {
      ImmersiveView(model: model)
    }
  }
}
