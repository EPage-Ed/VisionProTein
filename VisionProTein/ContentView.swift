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
  @State private var loading = false
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

      HStack(spacing: 20) {
        Spacer()
        Toggle("\(showImmersiveSpace ? "Hide" : "Show") Immersive Space", isOn: $showImmersiveSpace)
          .toggleStyle(.button)
          .disabled(loading)
        Spacer()
        Toggle("Residues", isOn: $model.showResidues)
          .toggleStyle(.switch)
          .disabled(loading)
        Spacer()
      }
      .padding(.top, 50)

//      Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
//        .font(.title)
//        .frame(width: 360)
//        .padding(24)
//        .glassBackgroundEffect()
    }
    .padding()
    .onChange(of: showImmersiveSpace) { _, newValue in
      if newValue {
        loading = true
        
        let (atoms,residues) = PDB.parsePDB(named: "Biotin")  // 1hqq Biotin
        let pe = ModelEntity()
        pe.name = "Protein"
//        let pc = ProteinComponent()
//        pe.components.set(pc)

        if model.showResidues {
          var cnt : Double = 0
          let tot = Double(residues.count)
          for r in residues {
//          residues.forEach { r in
            if let me = Molecule.entity(residue: r) {
              let mc = MoleculeComponent(residue: r)
              
              let p = r.atoms.first!
              let pos : SIMD3<Float> = [Float(p.x/100), Float(p.y/100), Float(p.z/100)]
              me.transform.translation = pos
                          
              me.name = r.resName
              me.components.set(HoverEffectComponent())
              me.components.set(InputTargetComponent())
              me.generateCollisionShapes(recursive: true, static: true)
              me.components.set(mc)
              
  //            print(me.name, r.resName)
              
              pe.addChild(me)
            }
            
            cnt += 1
//            DispatchQueue.main.async {
              progress = cnt / tot
              print("Building",progress)
//            }
            
          }
          
          pe.components.set(InputTargetComponent())
          pe.generateCollisionShapes(recursive: true, static: true)
          pe.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: true, canRotate: true))

        } else {

          if let p = Molecule.protein(atoms: atoms, saveCloud: true) {
            pe.addChild(p)
            pe.components.set(InputTargetComponent())
            pe.generateCollisionShapes(recursive: true, static: true)
            pe.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: true, canRotate: true))
          }

        }
        
        pe.setPosition([0, 1, -0.5], relativeTo: nil)
        let pc = ProteinComponent()
        pe.components.set(pc)
        model.protein = pe
        model.rootEntity.addChild(pe)

      }

      Task {
        if newValue {
          switch await openImmersiveSpace(id: "ImmersiveSpace") {
          case .opened:
            immersiveSpaceIsShown = true
            loading = false
          case .error, .userCancelled:
            fallthrough
          @unknown default:
            immersiveSpaceIsShown = false
            showImmersiveSpace = false
          }
        } else if immersiveSpaceIsShown {
          await dismissImmersiveSpace()
          immersiveSpaceIsShown = false
        }
      }
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView(model: ARModel())
}
