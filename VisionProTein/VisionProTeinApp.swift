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
  @StateObject var model = ARModel()

  init() {
    MoleculeComponent.registerComponent()
    ProteinComponent.registerComponent()
    RealityKitContent.GestureComponent.registerComponent()
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
