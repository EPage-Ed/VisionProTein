//
//  ARModel.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import RealityKit
import ARKit
import Accelerate

final class ARModel : ObservableObject {
  private let arSession = ARKitSession()
  
  private let sceneReconstruction = SceneReconstructionProvider(modes: [.classification])
  private let planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
  private let handTracker = HandTrackingProvider()
  private let worldTracker = WorldTrackingProvider()
  
  private var rightHandOpen = true
  private var leftHandOpen = true
  private var grabState = true
  private var popState = false

  let rootEntity = Entity()
  @Published var showResidues = true

  var planes = [UUID: PlaneAnchor]()
  var entityMap: [UUID: Entity] = [:]
  var meshes = [UUID: MeshAnchor]()
  var meshMap: [UUID: ModelEntity] = [:]
  
  var protein : ModelEntity?
  var initialHandRotation : simd_quatf = .init(vector: [0,0,0,0])
  var initialHandTranslation : SIMD3<Float> = .zero
  var initialProteinTranslation : SIMD3<Float> = .zero
  
  init() {
  }
  
  func run() async {
    do {
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
      let a = hand.originFromAnchorTransform * fingerTip.anchorFromJointTransform
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
        
      }
    }
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
