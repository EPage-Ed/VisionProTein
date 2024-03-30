//
//  VisionProTeinApp.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import SwiftUI

@main
struct VisionProTeinApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
