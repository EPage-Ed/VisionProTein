
import SwiftUI
import RealityKit
import MolecularRibbonKit

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State var entity:Entity?

    var body: some View {
        RealityView { content in
            if let e = entity { content.add(e) }
        }
        .onAppear {
            let pdb = """
ATOM      1  CA  ALA A   1       1.0 1.0 1.0
ATOM      2  CA  ALA A   2       2.0 2.0 2.0
ATOM      3  CA  ALA A   3       3.0 3.0 2.0
ATOM      4  CA  ALA A   4       4.0 4.0 2.0
ATOM      5  CA  ALA A   5       5.0 4.0 2.0
"""
            entity = MolecularRibbonKit.entity(from: pdb)
        }
    }
}
