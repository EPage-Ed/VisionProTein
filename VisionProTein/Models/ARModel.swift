//
//  ARModel.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/29/24.
//

import RealityKit
import ARKit
import Accelerate
import AVFoundation
import OrderedCollections
import PDBKit
import ProteinRibbon
import ProteinSpheresMesh

/*
extension simd_float4x4 {
  /// Extracts the 3D position from the transform matrix
  var translation: SIMD3<Float> {
    SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
  }
}

/// Standard Euclidean distance between two 3D points
func distance(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
  simd_distance(a, b)
}
*/

/*
enum ModelState : CaseIterable, Identifiable {
  case resizing
  case tagging
  case ribbon
  
  var id: Self { self } // Conforms to Identifiable
}
 */

// Simple spatial index for efficient nearest-atom queries
class AtomSpatialIndex {
  struct AtomEntry {
    let position: SIMD3<Float>
    let atomIndex: Int
    let residue: Residue
  }
  
  private var atoms: [AtomEntry] = []
  
  init(atoms: [AtomEntry]) {
    self.atoms = atoms
  }
  
  // Find the nearest atom to a given position
  func findNearest(to position: SIMD3<Float>) -> (atomIndex: Int, residue: Residue, distance: Float)? {
    guard !atoms.isEmpty else { return nil }
    
    var nearestIndex = 0
    var minDistance = distance(position, atoms[0].position)
    
    for i in 1..<atoms.count {
      let dist = distance(position, atoms[i].position)
      if dist < minDistance {
        minDistance = dist
        nearestIndex = i
      }
    }
    
    let nearest = atoms[nearestIndex]
    return (atomIndex: nearest.atomIndex, residue: nearest.residue, distance: minDistance)
  }
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
  var ligands = [ModelEntity]()
  var bindings : [ModelEntity] = []
  var chainLabels : [ModelEntity] = []  // Chain label text entities for unfolded spheres
  var proteinCenterOffset: SIMD3<Float> = .zero  // Offset applied to center the protein for rotation
  
  // Finger tip indicators for tag mode
  var leftThumbIndicator: ModelEntity?
  var leftMiddleFingerIndicator: ModelEntity?
  
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
  @Published var showImmersiveSpace = false
  @Published var immersiveSpaceIsShown = false

  
  var pName = "Building..." // 1hqq Biotin 3nir 1nc9 4HR9 1ERT
  var pDetails = ""
  let rootEntity = Entity()
  @Published var loading = false
  @Published var progress : Double = 0
  @Published var loadingStatus: String = ""
  @Published var showResidues = true
//  @Published var modelState : ModelState = .resizing
  @Published var tagMode = false
  @Published var tagExtendDistance = 0.0
  @Published var tagged = OrderedSet<Residue>()
  @Published var selectedResidue: Residue?
  @Published var showRibbon: Bool = false
  @Published var foldedState = true
  var foldedPositions = [SIMD3<Float>]()
  var proteinTransform : Transform = Transform()
//  var proteinTransform : SIMD3<Float> = [0,0,0]
  
  @Published var showSpheres: Bool = false
  @Published var showRibbons: Bool = false
  @Published var ribbonColorScheme: ColorScheme = .byStructure
  @Published var showBallAndStick: Bool = true
  @Published var showLigands: Bool = false
  @Published var showBindings: Bool = false
  @Published var skyboxOpacity: Float = 0.5


  var planes = [UUID: PlaneAnchor]()
  var entityMap: [UUID: Entity] = [:]
  var meshes = [UUID: MeshAnchor]()
  var meshMap: [UUID: ModelEntity] = [:]
  
  var protein : ModelEntity?
  var proteinTag : ModelEntity?
  var ribbon : ModelEntity?
  
  var pdbStructure : PDBStructure?
  
  var proteinCollision : CollisionComponent?
  
  // Track highlighted residue entities for removal (keyed by residue.id which is unique across chains)
  var highlightedResidueEntities: [Int: ModelEntity] = [:]
  
  var bindingResidues : [Residue] = []
  
  // Cached protein data for tap selection
  var proteinResidues: [Residue] = []
  var atomPositions: [SIMD3<Float>] = []  // Scaled positions matching ball and stick (in ball&stick local space)
  var atomRadii: [Float] = []  // Visual radii (scaled by 0.3)
  var atomToResidueMap: [Int: Residue] = [:]  // Maps atom index to its residue
  var atomSpatialIndex: AtomSpatialIndex?  // Spatial index for efficient nearest atom search
  
  // Chain data for unfolded spheres animation
  var residuesByChain: [String: [Residue]] = [:]
  var unfoldedResidueCenters: [Int: SIMD3<Float>] = [:]

  var initialHandRotation : simd_quatf = .init(vector: [0,0,0,0])
  var initialHandTranslation : SIMD3<Float> = .zero
  var initialProteinTranslation : SIMD3<Float> = .zero
  var initialRHandTranslation : SIMD3<Float> = .zero
  var initialLigandTranslation : SIMD3<Float> = .zero
  
  // Audio player for tap feedback
  private var tapSoundPlayer: AVAudioPlayer?

  init() {
    setupTapSound()
  }
  
  // Setup tap sound using system sound
  private func setupTapSound() {
    // Use a system tap sound (ID 1104 is a gentle tap sound)
    // Alternatively, we can use AVAudioPlayer with a custom sound file
    // For now, we'll prepare to use system sounds via AudioServicesPlaySystemSound
  }
  
  // Play tap sound feedback
  func playTapSound() {
    // Use system sound for tap feedback (1104 is a gentle tap)
    AudioServicesPlaySystemSound(1105)
  }
  func playDeselectSound() {
    // Use system sound for deselect feedback
    AudioServicesPlaySystemSound(1103)
  }
  func playMissSound() {
    AudioServicesPlaySystemSound(1104)
  }
  
  // Clear cached protein data
  func clearProteinData() {
    proteinResidues.removeAll()
    atomPositions.removeAll()
    atomRadii.removeAll()
    atomToResidueMap.removeAll()
    atomSpatialIndex = nil
    highlightedResidueEntities.values.forEach { $0.removeFromParent() }
    highlightedResidueEntities.removeAll()
    tagged.removeAll()
    chainLabels.forEach { $0.removeFromParent() }
    chainLabels.removeAll()
    residuesByChain.removeAll()
    unfoldedResidueCenters.removeAll()
    proteinCenterOffset = .zero
    
    
    protein?.removeFromParent()
//    proteinTag?.removeFromParent()
    ligands.forEach { $0.removeFromParent() }
    ligands.removeAll()
    bindings.forEach { $0.removeFromParent() }
    bindings.removeAll()
    bindingResidues.removeAll()
    protein = nil
//    proteinTag = nil
    showSpheres = false
    showRibbons = false
    showBallAndStick = true
    showLigands = false
    showBindings = false
    selectedResidue = nil

  }
  
  // Clear all selected residues and remove highlights
  func clearAllSelections() {
    highlightedResidueEntities.values.forEach { $0.removeFromParent() }
    highlightedResidueEntities.removeAll()
    tagged.removeAll()
    selectedResidue = nil
  }

  @MainActor
  func changeRibbonColorScheme(to newScheme: ColorScheme) {
    guard let pdbStructure else { return }
    print("New scheme: \(newScheme)")
    let entity = ProteinRibbon.ribbonEntity(from: pdbStructure, options: ProteinRibbon.Options(colorScheme: newScheme))
    Task { @MainActor in
      progress = 0.5
      loadingStatus = "Created ribbon..."
    }
    entity.name = "Ribbon2"
    entity.transform = ribbons?.transform ?? .identity
    entity.isEnabled = showRibbons
    protein?.addChild(entity)
    ribbons?.removeFromParent()
    ribbons = entity

    ManipulationComponent.configureEntity(protein!)
    protein!.components[ManipulationComponent.self]!.releaseBehavior = .stay
    protein!.components[ManipulationComponent.self]!.dynamics.translationBehavior = .unconstrained

  }
  
  // Find residues within a specified distance (in angstroms) from a given residue
  // Returns residues not already in the tagged set
  func findNearbyResidues(from selectedResidue: Residue, withinDistance distanceAngstroms: Double) -> [Residue] {
    guard distanceAngstroms > 0, !proteinResidues.isEmpty else { return [] }
    
    // Convert angstroms to meters (PDB uses angstroms, scaled by 0.01 for display)
    let distanceMeters = Float(distanceAngstroms * 0.01)
    let distanceSquared = distanceMeters * distanceMeters
    
    var nearbyResidues: [Residue] = []
    
    // Calculate the center position of the selected residue (average of all atom positions)
    let selectedAtoms = selectedResidue.atoms
    guard !selectedAtoms.isEmpty else { return [] }
    
    var selectedCenter = SIMD3<Float>.zero
    for atom in selectedAtoms {
      selectedCenter += SIMD3<Float>(
        Float(atom.x) * 0.01,
        Float(atom.y) * 0.01,
        Float(atom.z) * 0.01
      )
    }
    selectedCenter /= Float(selectedAtoms.count)
    
    // Check each residue for proximity
    for residue in proteinResidues {
      // Skip if already tagged or if it's the selected residue itself
      if tagged.contains(residue) || residue == selectedResidue {
        continue
      }
      
      // Calculate center of this residue
      guard !residue.atoms.isEmpty else { continue }
      var residueCenter = SIMD3<Float>.zero
      for atom in residue.atoms {
        residueCenter += SIMD3<Float>(
          Float(atom.x) * 0.01,
          Float(atom.y) * 0.01,
          Float(atom.z) * 0.01
        )
      }
      residueCenter /= Float(residue.atoms.count)
      
      // Check if within distance using squared distance (more efficient)
      let delta = residueCenter - selectedCenter
      let distSq = dot(delta, delta)
      
      if distSq <= distanceSquared {
        nearbyResidues.append(residue)
      }
    }
    
    print("Found \(nearbyResidues.count) residues within \(distanceAngstroms)Å of \(selectedResidue.resName)\(selectedResidue.serNum)")
    return nearbyResidues
  }
  
  // Highlight a residue by creating its visual entity
  @MainActor
  @discardableResult
  func highlightResidue(_ residue: Residue) -> ModelEntity? {
    // Skip if already highlighted
    guard highlightedResidueEntities[residue.id] == nil else { return nil }
    
    // Create highlighted residue entity
    guard let residueEntity = Molecule.genBallAndStickResidue(residue: residue, atomScale: 1.5) else {
      print("Failed to create entity for residue \(residue.resName)\(residue.serNum)")
      return nil
    }
    
    residueEntity.name = "Selected_\(residue.resName)_\(residue.chainID)\(residue.serNum)"
    
    // Apply the same center offset that was applied to ball and stick
    residueEntity.position = residueEntity.position + proteinCenterOffset
    
    // Add emissive material for highlight
    var material = PhysicallyBasedMaterial()
    material.emissiveColor.color = .yellow
    material.emissiveIntensity = 0.3
    material.blending = .transparent(opacity: 0.3)
    
    // Apply material to all children
    residueEntity.children.forEach { child in
      if let modelEntity = child as? ModelEntity,
         let model = modelEntity.model {
        modelEntity.model?.materials = model.materials.map { _ in material }
      }
    }
    
    // Add collision shapes and input target
    residueEntity.components.set(InputTargetComponent())
    residueEntity.generateCollisionShapes(recursive: true, static: true)
    
    // Add to same parent as ball and stick
    if let ballAndStick = ballAndStick, let parent = ballAndStick.parent {
      parent.addChild(residueEntity)
    } else {
      rootEntity.addChild(residueEntity)
    }
    
    // Track this highlighted entity
    highlightedResidueEntities[residue.id] = residueEntity
    if showBindings {
      tagged.append(residue)
      tagged.sort()
    }
    
    print("Highlighted residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
    return residueEntity
  }
  
  // Update the highlight color of a residue entity
  @MainActor
  func updateResidueHighlightColor(_ residue: Residue, isSelected: Bool) {
    guard let residueEntity = highlightedResidueEntities[residue.id] else { return }
    
    // Create material with appropriate color
    var material = PhysicallyBasedMaterial()
    material.emissiveColor.color = isSelected ? .orange : .yellow
    material.emissiveIntensity = isSelected ? 0.8 : 0.3
    material.blending = .transparent(opacity: isSelected ? 0.5 : 0.3)
    
    // Apply material to all children
    residueEntity.children.forEach { child in
      if let modelEntity = child as? ModelEntity,
         let model = modelEntity.model {
        modelEntity.model?.materials = model.materials.map { _ in material }
      }
    }
    
    print("Updated highlight color for \(residue.resName) \(residue.chainID)\(residue.serNum) to \(isSelected ? "orange" : "yellow")")
  }
  
  // Create chain label entities for the unfolded spheres view
  @MainActor
  func createChainLabels(residuesByChain: [String: [Residue]], unfoldedResidueCenters: [Int: SIMD3<Float>]) {
    // Remove any existing chain labels
    chainLabels.forEach { $0.removeFromParent() }
    chainLabels.removeAll()
    
    // Create a label for each chain
    for (chainID, chainResidues) in residuesByChain {
      guard !chainResidues.isEmpty else { continue }
      
      // Calculate the center position of the chain in the unfolded state
      var chainCenter = SIMD3<Float>.zero
      var count = 0
      for residue in chainResidues {
        if let center = unfoldedResidueCenters[residue.id] {
          chainCenter += center
          count += 1
        }
      }
      
      if count > 0 {
        chainCenter /= Float(count)
        
        // Position label above the chain center
        let labelPosition = chainCenter + SIMD3<Float>(0, 0.15, 0)
        
        // Create 3D text mesh
        let textMesh = MeshResource.generateText(
          chainID,
          extrusionDepth: 0.02,
          font: .systemFont(ofSize: 0.08),
          containerFrame: .zero,
          alignment: .center,
          lineBreakMode: .byWordWrapping
        )
        
        // Create red material
        var material = PhysicallyBasedMaterial()
        material.baseColor.tint = .red
        material.emissiveColor.color = .red
        material.emissiveIntensity = 0.5
        
        // Create the text entity
        let textEntity = ModelEntity(mesh: textMesh, materials: [material])
        textEntity.name = "ChainLabel_\(chainID)"
        textEntity.position = labelPosition
        
        // Add billboard component so it always faces the user
        textEntity.components.set(BillboardComponent())
        
        // Add to spheres entity
        if let spheres = spheres {
          spheres.addChild(textEntity)
          chainLabels.append(textEntity)
          print("Created chain label '\(chainID)' at position \(labelPosition)")
        }
      }
    }
  }
  
  // Remove all chain labels
  @MainActor
  func removeChainLabels() {
    chainLabels.forEach { $0.removeFromParent() }
    chainLabels.removeAll()
    print("Removed all chain labels")
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
  
  /*
  func ligandScale(scale: SIMD3<Float>) {
//    ligand?.scale = scale
  }
   */
  
//  var tapAnchor : AnchorEntity?
//  var tapEntity : Entity?
  var tapActive = false
  
  @MainActor
  func processHandAnchorUpdate(_ update: AnchorUpdate<HandAnchor>) async {
    //            print(update.description)
    if !tagMode { return }
    if let leftHand = handTracker.latestAnchors.leftHand,
       let indexTip = leftHand.handSkeleton?.joint(.middleFingerTip),
       let thumbTip = leftHand.handSkeleton?.joint(.thumbTip),
       indexTip.isTracked && thumbTip.isTracked {
      
      let distance = distance(indexTip.anchorFromJointTransform.columns.3, thumbTip.anchorFromJointTransform.columns.3)
      
      // Update finger tip indicators based on tagMode
      if tagMode {
        // Create indicators if they don't exist
        if leftThumbIndicator == nil {
          let thumbSphere = ModelEntity(
            mesh: .generateSphere(radius: 0.01),
            materials: [SimpleMaterial(color: .red, isMetallic: true)]
          )
          thumbSphere.name = "LeftThumbIndicator"
          rootEntity.addChild(thumbSphere)
          leftThumbIndicator = thumbSphere
        }
        
        if leftMiddleFingerIndicator == nil {
          let fingerSphere = ModelEntity(
            mesh: .generateSphere(radius: 0.01),
            materials: [SimpleMaterial(color: .red, isMetallic: true)]
          )
          fingerSphere.name = "LeftMiddleFingerIndicator"
          rootEntity.addChild(fingerSphere)
          leftMiddleFingerIndicator = fingerSphere
        }
        
        // Update positions - convert to world space
        let thumbWorldMatrix = leftHand.originFromAnchorTransform * thumbTip.anchorFromJointTransform
        let thumbWorldPos = SIMD3<Float>(thumbWorldMatrix.columns.3.x, thumbWorldMatrix.columns.3.y, thumbWorldMatrix.columns.3.z)
        leftThumbIndicator?.position = thumbWorldPos
        
        let fingerWorldMatrix = leftHand.originFromAnchorTransform * indexTip.anchorFromJointTransform
        let fingerWorldPos = SIMD3<Float>(fingerWorldMatrix.columns.3.x, fingerWorldMatrix.columns.3.y, fingerWorldMatrix.columns.3.z)
        leftMiddleFingerIndicator?.position = fingerWorldPos
        
        // Make sure they're visible
        leftThumbIndicator?.isEnabled = true
        leftMiddleFingerIndicator?.isEnabled = true
      } else {
        // Hide indicators when tagMode is false
        leftThumbIndicator?.isEnabled = false
        leftMiddleFingerIndicator?.isEnabled = false
      }

      if !tapActive {
        // 3. Calculate distance to detect pinch
      
        if distance < 0.005 {
          print("Pinch detected")
          tapActive = true
//          tapEntity?.removeFromParent()
//          tapEntity = nil
//          tapAnchor = nil
          
          // Multiply hand anchor by joint transform to get World Space
          let worldMatrix = leftHand.originFromAnchorTransform * indexTip.anchorFromJointTransform
          let pinchWorldPos = SIMD3<Float>(worldMatrix.columns.3.x, worldMatrix.columns.3.y, worldMatrix.columns.3.z)
          
          /*
          // Debug sphere at pinch location
          let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.01),
            materials: [SimpleMaterial(color: .red, isMetallic: true)]
          )
          sphere.position = pinchWorldPos
          rootEntity.addChild(sphere)
          tapEntity = sphere
           */
          
          // Find nearest atom using spatial index
          guard let ballAndStick = ballAndStick,
                ballAndStick.isEnabled,
                let spatialIndex = atomSpatialIndex else {
            print("Ball and stick not enabled or spatial index not available")
            return
          }
          
          // Convert world position to ball and stick local coordinates
          let localPos = ballAndStick.convert(position: pinchWorldPos, from: nil)
          
          print("========== PINCH GESTURE ==========")
          print("Pinch world position: \(pinchWorldPos)")
          print("Pinch local position: \(localPos)")
          
          // Find nearest atom
          if let result = spatialIndex.findNearest(to: localPos) {
            let residue = result.residue
            print("Nearest atom at distance: \(result.distance)m")
            print("Residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
            
            // Only select if within reasonable distance (5cm)
            if result.distance < 0.05 {
              // Check if this residue is already highlighted
              if let existingEntity = highlightedResidueEntities[residue.id] {
                print("Removing highlight from residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
                
                playDeselectSound()
                // Remove from tracking
                highlightedResidueEntities.removeValue(forKey: residue.id)
                tagged.remove(residue)
                
                // Remove entity from scene
                existingEntity.removeFromParent()
              } else {
                print("Highlighting residue: \(residue.resName) \(residue.chainID)\(residue.serNum)")
                
                // Play tap sound feedback
                playTapSound()
                
                // Highlight the selected residue
                highlightResidue(residue)
                tagged.append(residue)
                
                // Find and highlight nearby residues if tagExtendDistance > 0
                if tagExtendDistance > 0 {
                  let nearbyResidues = findNearbyResidues(from: residue, withinDistance: tagExtendDistance)
                  for nearbyResidue in nearbyResidues {
                    highlightResidue(nearbyResidue)
                    tagged.append(nearbyResidue)
                  }
                }
              }
            } else {
              print("Atom too far away (\(result.distance)m), not selecting")
              playMissSound()
            }
          } else {
            print("No atoms found in spatial index")
          }
          print("===================================")
        }
      } else {
        if distance > 0.01 {
          print("Pinch released")
          tapActive = false
        }
      }
    }


    /*
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
     */

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
  
  func buildImmersive() {
    loading = true
    progress = 0.0
    loadingStatus = "Initializing..."
    
    Task { @MainActor in
      
      let rbs = ModelEntity()
      rbs.name = "RibbonAndStick"
      protein = rbs
      
      await MainActor.run {
        progress = 0.1
        loadingStatus = "Loading PDB..."
      }
      if let u = Bundle.main.url(forResource: pName, withExtension: "pdb") { //, // 3aid 6uml (Thilidomide) 1a3n (Hemoglobin) 3nir 4HR9 6a5j 1ERT
//         let s = try? String(contentsOf: u, encoding: .utf8) {
//        var s = ""
        let (bytes, response) = try await URLSession.shared.bytes(for: URLRequest(url: u))
//        guard let httpResponse = response as? URLResponse, httpResponse.statusCode == 200 else {
//          Logger.main.error("Network response error")
//          return
//        }
        let length = Int(response.expectedContentLength)
        var data = Data(capacity: length)

        var bytesAccumulator = 0
        let bytesForUpdate = length / 100
        
        for try await byte in bytes {
          data.append(byte)
          bytesAccumulator += 1
          
          if bytesAccumulator > bytesForUpdate {
            let progress = Double(data.count) / Double(length)
//            print(progress)
            await MainActor.run {
              self.progress = progress * 0.35 + 0.1
            }
            bytesAccumulator = 0
          }
        }
        guard let s = try? String(contentsOf: u, encoding: .utf8) else { return }

        
        
//        let task = URLSession.shared.dataTask(with: u) { data, response, error in
//          if let data = data, let content = String(data: data, encoding: .utf8) {
//            print(content)
//            s = content
//          }
//        }
//        task.resume() // Start the task
        
        // PARSE ONCE - Get all data needed for all renderers
        await MainActor.run {
          progress = 0.45
          loadingStatus = "Parsing PDB file..."
        }
        let parseResult = PDB.parseComplete(pdbString: s) { progress in
          self.progress = progress
        }
        //            let atoms = parseResult.atoms
        let allResidues = parseResult.residues
        pdbStructure = parseResult.pdbStructure
        
        
        //        let entity = ProteinRibbon.structureColoredEntity(from: pdbStructure)  // Red helix, blue sheet, green coil
        let entity = ProteinRibbon.ribbonEntity(from: pdbStructure!, options: ProteinRibbon.Options(colorScheme: .byStructure))
        entity.name = "Ribbon2"
        entity.isEnabled = false
        rbs.addChild(entity)
        ribbons = entity
        print(entity.position)
        
        await MainActor.run {
          progress = 0.7
          loadingStatus = "Creating ball-and-stick model..."
        }
        
        let bse = ProteinRibbon.ballAndStickCPK(from: pdbStructure!)
        bse.name = "BallAndStick"
        //            bse.position = [0, 3, -2]
        rbs.addChild(bse)
        ballAndStick = bse
        print(bse.position)
        
        // Build spatial index for efficient atom lookup
        await MainActor.run {
          progress = 0.8
          loadingStatus = "Building spatial index..."
        }
        
        // Filter to only include standard amino acid residues (excludes HETATM ligands, water, etc.)
        let residues = allResidues.filter { $0.aminoAcid != nil }
        print("Filtered residues: \\(allResidues.count) total -> \\(residues.count) amino acids")
        
        proteinResidues = residues
        
        // Build spatial index entries
        var indexEntries: [AtomSpatialIndex.AtomEntry] = []
        var atomIndex = 0
        for residue in residues {
          for atom in residue.atoms {
            // Use 0.01 scale to match ball and stick representation
            let atomPos = SIMD3<Float>(
              Float(atom.x) * 0.01,
              Float(atom.y) * 0.01,
              Float(atom.z) * 0.01
            )
            atomPositions.append(atomPos)
            atomRadii.append(Float(atom.radius))
            atomToResidueMap[atomIndex] = residue
            
            indexEntries.append(AtomSpatialIndex.AtomEntry(
              position: atomPos,
              atomIndex: atomIndex,
              residue: residue
            ))
            atomIndex += 1
          }
        }
        atomSpatialIndex = AtomSpatialIndex(atoms: indexEntries)
        print("Built spatial index with \(indexEntries.count) atoms for \(residues.count) residues")
        
        
        await MainActor.run {
          progress = 0.9
          loadingStatus = "Finding binding residues..."
        }
        // Get ligands from consolidated parse result
        let ligands = parseResult.ligands
        print("Ligands found: \(ligands.count):\n\(ligands.map(\.resName).joined(separator: "\n"))")
        
        for ligand in ligands {
          // Generate glowing sphere entity for each ligand
          let ligandEntity = ligand.generateSphereEntity(
            atomScale: 1.0,
            glowColor: .cyan,
            glowIntensity: 0.5,
            opacity: 0.8,
            useElementColors: true
          )
          
          // Add to scene
          ballAndStick?.addChild(ligandEntity)
          ligandEntity.isEnabled = false
          self.ligands.append(ligandEntity)
          
          // Also highlight binding residues
          let bindingResidues = ligand.findBindingResidues(in: proteinResidues)
          self.bindingResidues.append(contentsOf: bindingResidues)
          
          print("Ligand: \(ligand.resName), Binding residues: \(bindingResidues.map(\.resName).joined(separator: ", "))")
          
          
          // Highlight the binding pocket in yellow
          bindingResidues.forEach { residue in
            // Highlight the selected residue
            if let entity = highlightResidue(residue) {
              bindings.append(entity)
              entity.isEnabled = false
            }
          }
          
          print("\(ligand.resName): \(bindingResidues.count) binding residues")
          
        }
        
        
        await MainActor.run {
          progress = 0.95
          loadingStatus = "Creating sphere representation..."
        }
        
        
        let se = ProteinSpheresMesh.spheresCPK(from: pdbStructure!, scale: 0.5)
        se.name = "Spheres"
        se.isEnabled = false
        rbs.addChild(se)
        spheres = se
        print(se.position)
        
        
        // Build position-to-residue map for fast lookup
        var posToResidue: [SIMD3<Float>: Residue] = [:]
        for residue in residues {
          for atom in residue.atoms {
            let pos = SIMD3<Float>(
              Float(atom.x) * 0.01,
              Float(atom.y) * 0.01,
              Float(atom.z) * 0.01
            )
            posToResidue[pos] = residue
          }
        }
        
        // Calculate residue centers for structure-preserving animation
        var residueCenters: [Int: SIMD3<Float>] = [:]  // id -> center
        for residue in residues {
          var center = SIMD3<Float>.zero
          for atom in residue.atoms {
            center += SIMD3<Float>(
              Float(atom.x) * 0.01,
              Float(atom.y) * 0.01,
              Float(atom.z) * 0.01
            )
          }
          center /= Float(residue.atoms.count)
          residueCenters[residue.id] = center
        }
        
        // Calculate unfolded residue centers (organize chains in parallel)
        var unfoldedResidueCenters: [Int: SIMD3<Float>] = [:]
        
        // Group residues by chain
        var residuesByChain: [String: [Residue]] = [:]
        for residue in residues {
          let chainID = residue.chainID ?? "A"  // Default to chain A if no chainID
          if residuesByChain[chainID] == nil {
            residuesByChain[chainID] = []
          }
          residuesByChain[chainID]?.append(residue)
        }
        
        // Store for chain label creation
        self.residuesByChain = residuesByChain
        
        // Sort chains for consistent ordering
        let sortedChains = residuesByChain.keys.sorted()
        let chainCount = Float(sortedChains.count)
        let chainSpacing: Float = 0.3  // Z-spacing between parallel chains
        
        // Position each chain in parallel
        for (chainIndex, chainID) in sortedChains.enumerated() {
          guard let chainResidues = residuesByChain[chainID] else { continue }
          
          let chainResidueCount = Float(chainResidues.count)
          let zOffset = (Float(chainIndex) - chainCount / 2) * chainSpacing
          
          for (residueIndex, residue) in chainResidues.enumerated() {
            let unfoldedCenter = SIMD3<Float>(
              (Float(residueIndex) - chainResidueCount / 2) * 0.1,  // X: spread along chain
              0.5,                                                     // Y: constant height
              -0.5 + zOffset                                          // Z: offset per chain
            )
            unfoldedResidueCenters[residue.id] = unfoldedCenter
          }
        }
        
        // Store for chain label creation
        self.unfoldedResidueCenters = unfoldedResidueCenters
        
        // Setup animation on each child sphere entity (one per element type)
        for child in se.children {
          if var meshInstances = child.components[MeshInstancesComponent.self],
             var part = meshInstances[partIndex: 0] {
            
            var startTranslations: [SIMD3<Float>] = []
            var endTranslations: [SIMD3<Float>] = []
            
            part.data.withMutableTransforms { transforms in
              for i in 0..<transforms.count {
                // Get current atom position
                let atomPos = SIMD3<Float>(
                  transforms[i].columns.3.x,
                  transforms[i].columns.3.y,
                  transforms[i].columns.3.z
                )
                startTranslations.append(atomPos)
                
                // Find which residue this atom belongs to via position lookup
                if let residue = posToResidue[atomPos],
                   let foldedCenter = residueCenters[residue.id],
                   let unfoldedCenter = unfoldedResidueCenters[residue.id] {
                  // Calculate unfolded position: offset from unfolded residue center
                  let offsetFromCenter = atomPos - foldedCenter
                  let unfoldedPos = unfoldedCenter + offsetFromCenter
                  endTranslations.append(unfoldedPos)
                } else {
                  // Fallback: keep same position
                  endTranslations.append(atomPos)
                }
              }
            }
            
            let animation = InstanceAnimationComponent(
              startTranslations: startTranslations,
              endTranslations: endTranslations,
              duration: 8.0,
              easing: .easeInOut
            )
            child.components.set(animation)
            
            // Optional: Add completion callback
            child.setInstanceAnimationCompletion {
              print("\(child.name) unfold complete!")
            }
          }
        }
        print("Setup structure-preserving animations for \(se.children.count) sphere child entities with \(residues.count) residues")
        
        await MainActor.run {
          progress = 0.99
          loadingStatus = "Finalizing..."
        }
        
      }
      
      
      rootEntity.addChild(rbs)
      rbs.position = [0, 1, -1.85]
      
      let rvb = rbs.visualBounds(recursive: true, relativeTo: rbs, excludeInactive: false)
      print(rvb.extents, rvb.center)
      
      
      // Offset all children so the visual center becomes the pivot point
      let centerOffset = -rvb.center
      proteinCenterOffset = centerOffset
      for child in rbs.children {
        child.position = child.position + centerOffset
      }
      
      
      ManipulationComponent.configureEntity(rbs)
      rbs.components[ManipulationComponent.self]!.releaseBehavior = .stay
      rbs.components[ManipulationComponent.self]!.dynamics.translationBehavior = .unconstrained
      
      await MainActor.run {
        progress = 1.0
        loadingStatus = "Complete!"
      }
      try? await Task.sleep(for: .milliseconds(200))
      await MainActor.run {
        loading = false
        progress = 0.0
        loadingStatus = ""
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
