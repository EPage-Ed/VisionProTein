
// Minimal usage example

import SwiftUI
import RealityKit
import MolecularRibbonKitRealityKit

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        RealityView { content in
            let pdbString = """
ATOM      1  CA  ALA A   1      11.104  13.207  10.551
ATOM      2  CA  ALA A   2      12.220  14.101  11.234
ATOM      3  CA  ALA A   3      13.343  14.900  12.002
"""
            let parser = PDBParser()
            let atoms = parser.parse(pdbString)
            let builder = RibbonEntityBuilder()
            let entity = builder.buildProteinEntity(from: atoms)
            content.add(entity)
        }
    }
}
