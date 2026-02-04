//
//  ARModel.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import RealityKit
import ARKit
import Accelerate

enum ModelState : CaseIterable, Identifiable {
  case resizing
  case tagging
  case ribbon
  
  var id: Self { self } // Conforms to Identifiable
}

final class ARModel : ObservableObject {
  private let arSession = ARKitSession()
  
  private let sceneReconstruction = SceneReconstructionProvider(modes: [.classification])
  private let planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
  private let handTracker = HandTrackingProvider()
  private let worldTracker = WorldTrackingProvider()
  
  private var rightHandOpen = true
  private var leftHandOpen = true
  private var grabState = false
  private var rgrabState = false
  private var popState = false
  
  var spheres : ModelEntity?
  var ribbons : ModelEntity?
  var ballAndStick : ModelEntity?
  
  var proteinItem: ProteinItem? {
    didSet {
      if proteinItem != nil {
        loading = true
        Task { @MainActor in
          
          
          self.loading = false
        }
      }
    }
  }

  /*
  @MainActor
  private func buildProtein() async {
    let (latoms,lresidues) = PDB.parsePDB(named: "1nc9", maxChains: 99, atom: false, hexatm: true)
    if latoms.count > 0 {
      let le = ModelEntity()
      le.name = "Ligand"
      
      if let l = Molecule.protein(atoms: latoms, saveCloud: false) {
//            print(p.name)
        l.components.set(HoverEffectComponent())
        l.components.set(InputTargetComponent())
        l.generateCollisionShapes(recursive: true, static: true)
        l.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: false, canRotate: true))
        le.addChild(l)
        
//            pe.position = pte.position + firstPos // pte.position
        le.setPosition([0.5, 1, -0.5], relativeTo: nil)
//            let pc = ProteinComponent()
//            pe.components.set(pc)
        ligand = le

        rootEntity.addChild(le)

      }
      
    }
    
    let (atoms,residues) = PDB.parsePDB(named: "1nc9", maxChains: 2)  // 1hqq Biotin 3nir 1nc9
    let pe = ModelEntity()
    let pte = ModelEntity()
    pe.name = "Protein"
    pte.name = "ProteinTag"
//        let pc = ProteinComponent()
//        pe.components.set(pc)
    var firstPos : SIMD3<Float> = .zero

//        if model.showResidues {
    var cnt : Double = 0
    let tot = Double(residues.count)
    for r in residues {
      //          residues.forEach { r in
      if let me = Molecule.entity(residue: r) {
        let mc = MoleculeComponent(residue: r)
        
        
        let p = r.atoms.first!
        let pos : SIMD3<Float> = [Float(p.x/100), Float(p.y/100), Float(p.z/100)]
        if cnt == 0 {
          firstPos = pos
        }
        me.transform.translation = pos - firstPos
        
        me.name = r.resName
        me.components.set(HoverEffectComponent())
        //              me.components.set(InputTargetComponent())
        //              me.generateCollisionShapes(recursive: true, static: true)
        me.components.set(mc)
        //              me.components.remove(CollisionComponent.self)
        //              me.components.remove(InputTargetComponent.self)
        
        //            print(me.name, r.resName)
        
        pte.addChild(me)
        
        if cnt == 0 {
          print(me.name, me.position)
        }
        
      }
      
      cnt += 1

      progress = cnt / tot
      print("Building",progress)
      
    }
      
    pte.components.set(InputTargetComponent())
    pte.generateCollisionShapes(recursive: true, static: true)
    pte.components.set(GestureComponent(canDrag: false, pivotOnDrag: false, preserveOrientationOnPivotDrag: false, canScale: true, canRotate: true))

    pte.position = [0, 1, -0.5]
//        pte.setPosition([0, 1, -0.5], relativeTo: nil)
    let ptc = ProteinComponent()
    pte.components.set(ptc)
    pte.isEnabled = false
    proteinTag = pte

//        } else {

    if let p = Molecule.protein(atoms: atoms, saveCloud: false) {
      //            print(p.name)
      print(p.name, p.position)
      p.components.set(HoverEffectComponent())
      p.components.set(InputTargetComponent())
      p.generateCollisionShapes(recursive: true, static: true)
      p.components.set(GestureComponent(canDrag: false, pivotOnDrag: false, preserveOrientationOnPivotDrag: false, canScale: true, canRotate: true))
      pe.addChild(p)
      
      //            pe.position = pte.position + firstPos // pte.position
      pe.setPosition([0, 1, -0.5], relativeTo: nil)
      let pc = ProteinComponent()
      pe.components.set(pc)
      protein = pe
      
    }

//        }
    
    rootEntity.addChild(pe)
    rootEntity.addChild(pte)

  }
   */
  
  let rootEntity = Entity()
  @Published var loading = false
  @Published var progress : Double = 0
  @Published var showResidues = true
  @Published var modelState : ModelState = .resizing
  @Published var tagged = Set<Residue>()
  @Published var selectedResidue: Residue?
  @Published var showRibbon: Bool = false
  @Published var foldedState = true
  var foldedPositions = [SIMD3<Float>]()
  var proteinTransform : Transform = Transform()
//  var proteinTransform : SIMD3<Float> = [0,0,0]
  
  @Published var showSpheres: Bool = false
  @Published var showRibbons: Bool = false
  @Published var showBallAndStick: Bool = true


  var planes = [UUID: PlaneAnchor]()
  var entityMap: [UUID: Entity] = [:]
  var meshes = [UUID: MeshAnchor]()
  var meshMap: [UUID: ModelEntity] = [:]
  
  var protein : ModelEntity?
  var proteinTag : ModelEntity?
  var ribbon : ModelEntity?
  var ligand : ModelEntity?
  
  var proteinCollision : CollisionComponent?

  var initialHandRotation : simd_quatf = .init(vector: [0,0,0,0])
  var initialHandTranslation : SIMD3<Float> = .zero
  var initialProteinTranslation : SIMD3<Float> = .zero
  var initialRHandTranslation : SIMD3<Float> = .zero
  var initialLigandTranslation : SIMD3<Float> = .zero

  init() {
  }
  
  func run() async {
    do {
//      try await arSession.run([worldTracker])
      try await arSession.run([worldTracker, handTracker])
    } catch {
      print("ARKit session error \(error)")
    }
        
    Task {
      for await update in handTracker.anchorUpdates {
        await processHandAnchorUpdate(update)
      }
    }
  }
  
  func ligandScale(scale: SIMD3<Float>) {
    ligand?.scale = scale
  }
  
  @MainActor
  func processHandAnchorUpdate(_ update: AnchorUpdate<HandAnchor>) async {
    //            print(update.description)
    if let hand = handTracker.latestAnchors.leftHand,
       let fingerTip = hand.handSkeleton?.joint(.middleFingerTip)
//       let fingerBase = hand.handSkeleton?.joint(.middleFingerKnuckle)
    {
      //              print("Left",lh.description)
//      let jt = fingerTip.anchorFromJointTransform
      //              let t = Transform(matrix: jt)
//      let a = hand.originFromAnchorTransform * fingerTip.anchorFromJointTransform
//      let a = hand.originFromAnchorTransform

      let originFromLeftHandFingerTipTransform = matrix_multiply(
          hand.originFromAnchorTransform, fingerTip.anchorFromJointTransform
      ).columns.3.xyz
      let handTransform = hand.originFromAnchorTransform.columns.3.xyz

      let fingersDistance = distance(originFromLeftHandFingerTipTransform, handTransform)
      let handWasOpen = !grabState
      let handClosed = fingersDistance < 0.07
      grabState = handClosed
      if handWasOpen && handClosed {
        let t = Transform(matrix: hand.originFromAnchorTransform)
//        initialHandRotation = t.rotation
        initialHandTranslation = t.translation
        initialProteinTranslation = protein?.transform.translation ?? .zero
      }
      

      if grabState {
        
        let wt = Transform(matrix: hand.originFromAnchorTransform) // a
        let trans = wt.translation
        let move = trans - initialHandTranslation
        let newTrans = initialProteinTranslation + move
        
        protein?.transform.translation = newTrans
//        proteinTag?.transform.translation = newTrans
      }
    }

    /*
    if let hand = handTracker.latestAnchors.rightHand,
       let fingerTip = hand.handSkeleton?.joint(.middleFingerTip)
//       let fingerBase = hand.handSkeleton?.joint(.middleFingerKnuckle)
    {
      //              print("Left",lh.description)
//      let jt = fingerTip.anchorFromJointTransform
      //              let t = Transform(matrix: jt)
//      let a = hand.originFromAnchorTransform * fingerTip.anchorFromJointTransform
//      let a = hand.originFromAnchorTransform

      let originFromRightHandFingerTipTransform = matrix_multiply(
          hand.originFromAnchorTransform, fingerTip.anchorFromJointTransform
      ).columns.3.xyz
      let handTransform = hand.originFromAnchorTransform.columns.3.xyz

      let fingersDistance = distance(originFromRightHandFingerTipTransform, handTransform)
      let handWasOpen = !rgrabState
      let handClosed = fingersDistance < 0.07
      rgrabState = handClosed
      if handWasOpen && handClosed {
        let t = Transform(matrix: hand.originFromAnchorTransform)
//        initialHandRotation = t.rotation
        initialRHandTranslation = t.translation
        initialLigandTranslation = ligand?.transform.translation ?? .zero
      }
      

      if rgrabState {
        
        let wt = Transform(matrix: hand.originFromAnchorTransform) // a
        let trans = wt.translation
        let move = trans - initialRHandTranslation
        let newTrans = initialLigandTranslation + move
        
        ligand?.transform.translation = newTrans

      }
    }
     */
  }
  
}

extension SIMD4 {
  var xyz: SIMD3<Scalar> {
    self[SIMD3(0, 1, 2)]
  }
}


extension GeometrySource {
  @MainActor func asArray<T>(ofType: T.Type) -> [T] {
    assert(MemoryLayout<T>.stride == stride, "Invalid stride \(MemoryLayout<T>.stride); expected \(stride)")
    return (0..<self.count).map {
      buffer.contents().advanced(by: offset + stride * Int($0)).assumingMemoryBound(to: T.self).pointee
    }
  }
  
  // SIMD3 has the same storage as SIMD4.
  @MainActor  func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
    return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
  }
}
