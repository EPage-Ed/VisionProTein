//
//  Molecule.swift
//  VisionProTein
//
//  Created by Edward Arenberg on 3/30/24.
//

import SceneKit
import RealityKit

extension SCNVector3 {
  static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
  }
}

class Molecule {
  
  static func genMolecule(residue: Residue) -> ModelEntity? {
    let basePos = residue.atoms.first.map { a in
      SIMD3(x: Float(a.x)/100, y: Float(a.y)/100, z: Float(a.z)/100)
    }
    let baseSize = residue.atoms.first.map { a in
      Float(a.radius)
    }
    guard let basePos, let baseSize else { return nil }
    let me = ModelEntity()
    me.name = residue.resName
    me.position = basePos
    
    //    s.model = ModelComponent(mesh: .generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .red, isMetallic: false)])
    
    
    /*
     s.position = basePos
     s.generateCollisionShapes(recursive: true)
     s.components.set(HoverEffectComponent())
     s.components.set(InputTargetComponent())
     s.components.set(GestureComponent(canDrag: true, pivotOnDrag: true, preserveOrientationOnPivotDrag: true, canScale: false, canRotate: true))
     me.addChild(s)
     */
    
    /*
     var instancesComponent = MeshInstancesComponent()
     guard let instanceData = try? LowLevelInstanceData.init(instanceCount: residue.atoms.count) else { return nil }
     let part = MeshInstancesComponent.Part(mesh: mesh, instanceData: instanceData)
     instancesComponent[partIndex: 0] = part
     s.components[MeshInstancesComponent.self] = instancesComponent
     */
    
    func buildAtom(atom: Atom) -> ModelEntity {
      let a = ModelEntity()
      a.name = atom.name // "Sphere"
      let mesh = MeshResource.generateSphere(radius: Float(atom.radius))
      let material = SimpleMaterial(color: atom.color, isMetallic: false)
      let modelComponent = ModelComponent(mesh: mesh, materials: [material])
      a.model = modelComponent
      return a
    }
    
    let atomDict = Dictionary(grouping: residue.atoms, by: { $0.element })
    for k in atomDict.keys {
      let a = atomDict[k]!.first!
      let s = buildAtom(atom: a)
      //      let baseSize = Float(a.radius)
      //      let aPos = SIMD3(x: Float(a.x)/100, y: Float(a.y)/100, z: Float(a.z)/100)
      
      //      let m = atomDict[k]! // .dropFirst()
      let count = atomDict[k]?.count ?? 0
      //      print("\(k) : \(a.name) : \(count)")
      guard let mesh = s.components[ModelComponent.self]?.mesh else { continue }
      guard let instanceData = try? LowLevelInstanceData.init(instanceCount: count) else { continue }
      instanceData.withMutableTransforms { transforms in
        for i in 0..<count {
          let a = atomDict[k]![i]
          //          let s = Float(a.radius) // baseSize > 0 ? Float(a.radius) / baseSize : 1
          //            print(s)
          //          let scale = SIMD3<Float>(repeating: s)
          //        let instanceAngle = 2 * .pi * Float(i) / Float(count)
          //        let radialTranslation: SIMD3<Float> = [-sin(instanceAngle), cos(instanceAngle), 0] * 0.02
          let translation = SIMD3<Float>(x: Float(a.x)/100, y: Float(a.y)/100, z: Float(a.z)/100) - basePos
          //          print(i,translation)
          
          // Position each robot around a circle.
          let transform = Transform(
            scale: .one, // scale / 10, // .one / 2, // / 10,
            rotation: simd_quatf(angle: 0, axis: [0,0,1]), // .init(), // simd_quatf(angle: instanceAngle, axis: [0, 0, 1]),
            translation: translation // radialTranslation
          )
          transforms[i] = transform.matrix
        }
      }
      // Instance only the first model.
      let modelID = mesh.contents.models.first?.id
      
      // Create the component using the convenience initializer.
      if let instancesComponent = try? MeshInstancesComponent(
        mesh: mesh,
        modelID: modelID,
        instances: instanceData
      ) {
        s.components.set(instancesComponent)
      }
      
      me.addChild(s)
      
    }
    
    /*
     guard let mesh = s.components[ModelComponent.self]?.mesh else { return nil }
     
     let count = residue.atoms.count
     guard let instanceData = try? LowLevelInstanceData.init(instanceCount: count) else { return nil }
     
     instanceData.withMutableTransforms { transforms in
     for i in 0..<count {
     let s = baseSize > 0 ? Float(residue.atoms[i].radius) / baseSize : 1
     print(s)
     let scale = SIMD3<Float>(repeating: s)
     //        let instanceAngle = 2 * .pi * Float(i) / Float(count)
     //        let radialTranslation: SIMD3<Float> = [-sin(instanceAngle), cos(instanceAngle), 0] * 0.02
     let translation = SIMD3<Float>(x: Float(residue.atoms[i].x)/100, y: Float(residue.atoms[i].y)/100, z: Float(residue.atoms[i].z)/100) - basePos
     print(translation)
     
     // Position each robot around a circle.
     let transform = Transform(
     scale: scale, // scale / 10, // .one / 2, // / 10,
     rotation: simd_quatf(angle: 0, axis: [0,0,1]), // .init(), // simd_quatf(angle: instanceAngle, axis: [0, 0, 1]),
     translation: translation // radialTranslation
     )
     transforms[i] = transform.matrix
     }
     }
     
     // Instance only the first model.
     let modelID = mesh.contents.models.first?.id
     
     // Create the component using the convenience initializer.
     if let instancesComponent = try? MeshInstancesComponent(
     mesh: mesh,
     modelID: modelID,
     instances: instanceData
     ) {
     s.components.set(instancesComponent)
     }
     
     
     /*
      if let p = try? MeshInstancesComponent(mesh: mesh, instances: instanceData) {
      //    let part = MeshInstancesComponent.Part(mesh: mesh, instanceData: instanceData)
      //      instancesComponent[partIndex: 0] = p.part(at: 0)
      s.components[MeshInstancesComponent.self] = p
      }
      */
     
     //    instances.withMutableTransforms { transforms in
     /*
      instanceData.withMutableTransforms { transforms in
      for i in 0..<residue.atoms.count {
      let radius = Float(residue.atoms[i].radius)
      let position = basePos // SIMD3<Float>(x: Float(residue.atoms[i].x)/100, y: Float(residue.atoms[i].y)/100, z: Float(residue.atoms[i].z)/100)
      //        let transform = Transform(scale: SIMD3<Float>(x: 0.01, y: 0.01, z: 0.01), rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(x: 0, y: 1, z: 0)), translation: position)
      let transform = Transform(scale: SIMD3<Float>(repeating: 1), rotation: .init(), translation: position)
      transforms[i] = transform.matrix
      
      /*
       // Scale each robot down to a reasonable size
       var scale = SIMD4<Float>(x: 0.5, y: 0.5, z: 0.5, w: 1.0)
       
       var matrix = float4x4(diagonal: scale)
       matrix.columns.3 = .init(x: -1 + Float(i) * 0.1, y: 0, z: 0, w: 1)
       */
      }
      }
      
      guard let meshComponent = s.components[ModelComponent.self] else { return me }
      let meshResource = meshComponent.mesh
      
      //    s.components.set(try! MeshInstancesComponent(mesh: meshResource, instances: instanceData))
      //    s.components.set(EnvironmentBlendingComponent(preferredBlendingMode: .occluded(by: .surroundings)))
      */
     
     
     me.addChild(s)
     */
    return me
    
  }
  
  static func genEntity(residue : Residue) -> URL? {
    let basePos = residue.atoms.first.map { a in
      SCNVector3(x: Float(a.x)/100, y: Float(a.y)/100, z: Float(a.z)/100)
    }
    guard let basePos else { return nil }
    let scene = SCNScene()
    scene.rootNode.position = basePos
    for atom in residue.atoms {
      let sphere = SCNSphere(radius: atom.radius)
      sphere.segmentCount = 12
      //      let box = SCNBox(width: atom.radius*2, height: atom.radius*2, length: atom.radius*2, chamferRadius: 0)
      
      let mat = SCNMaterial()
      mat.diffuse.contents = atom.color // UIColor.red
      mat.specular.contents = UIColor(white: 0.6, alpha: 1.0)
      mat.shininess = 0.3
      
      sphere.materials = [mat]
      //      box.materials = [mat]
      
      let node = SCNNode(geometry: sphere)
      //      let node = SCNNode(geometry: box)
      let aPos = SCNVector3(x: Float(atom.x)/100, y: Float(atom.y)/100, z: Float(atom.z)/100)
      node.position = aPos - basePos
      scene.rootNode.addChildNode(node)
    }
    let url = URL.documentsDirectory.appending(path: "residue.usdz")
    scene.write(to: url, delegate: nil)
    //    docURL[residue.resName] = url
    return url
    //    Task {
    //      try? await Task.sleep(nanoseconds: UInt64(1E8))
    //      entity = try? await Entity(contentsOf: docURL)
    ////      entity = try? await Entity.load(contentsOf: docURL)
    //    }
  }
  
  static func genProtein(named name: String, atoms : [Atom], saveCloud: Bool = false) -> URL? {
    let basePos = atoms.first.map { a in
      SCNVector3(x: Float(a.x)/100, y: Float(a.y)/100, z: Float(a.z)/100)
    }
    guard let basePos else { return nil }
    let scene = SCNScene()
    scene.rootNode.position = basePos
    
    //      var cnt : Double = 0
    //      let tot : Double = Double(atoms.count)
    for atom in atoms {
      let sphere = SCNSphere(radius: atom.radius)
      sphere.segmentCount = 12
      //      let box = SCNBox(width: atom.radius*2, height: atom.radius*2, length: atom.radius*2, chamferRadius: 0)
      
      
      let mat = SCNMaterial()
      mat.diffuse.contents = atom.color // UIColor.red
      mat.specular.contents = UIColor(white: 0.6, alpha: 1.0)
      mat.shininess = 0.3
      
      sphere.materials = [mat]
      //      box.materials = [mat]
      
      let node = SCNNode(geometry: sphere)
      //      let node = SCNNode(geometry: box)
      let aPos = SCNVector3(x: Float(atom.x)/100, y: Float(atom.y)/100, z: Float(atom.z)/100)
      node.position = aPos - basePos
      scene.rootNode.addChildNode(node)
      
    }
    let url = URL.documentsDirectory.appending(path: "\(name).usdz")
    scene.write(to: url, delegate: nil)
    
    /*
     if saveCloud {
     // CloudKit Container ID
     let containerIdentifier = "iCloud.com.epage.Life3D"
     if let url = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) {
     print(url)
     let fileURL = url.appendingPathComponent("Documents").appendingPathComponent("protein.usdz")
     let saved = scene.write(to: fileURL, delegate: nil)
     print(saved)
     //      try! "hello world".write(to: fileURL, atomically: true, encoding: .utf8)
     } else {
     print("Can't get UbiquityContainer url")
     }
     }
     */
    
    //    docURL[residue.resName] = url
    return url
  }
  
  @MainActor
  static func entity(residue: Residue) -> ModelEntity? {
    guard let url = genEntity(residue: residue)
    else { return nil }
    //    let e = try? Entity.load(contentsOf: url)
    
    // Return residue
    return try? Entity.loadModel(contentsOf: url)
    
  }
  
  @MainActor
  static func protein(atoms: [Atom], saveCloud: Bool = false) -> ModelEntity? {
    
    guard let url = genProtein(named: "protein", atoms: atoms, saveCloud: saveCloud) else { return nil }
    
    //    let m = try? await ModelEntity(contentsOf: url)
    //    return m
    
    return try? Entity.loadModel(contentsOf: url)
  }
  
  static func protein(named name: String) async -> ModelEntity? {
    await ModelCache.shared.getModel(named: name)
  }
  
  /*
   func gen(pos: SIMD3<Float>) -> Entity? {
   guard let entity else {
   entity = try? Entity.load(contentsOf: docURL)
   entity?.transform.translation = pos
   return entity
   }
   let e = entity.clone(recursive: true)
   e.transform.translation = pos
   return e
   
   //    let asset = MDLAsset(url: objPath)
   //    let scene = SCNScene(mdlAsset: asset)
   //    scene.write(to: path, delegate: nil)
   }
   */
}

final class ModelCache {
  static var shared = ModelCache()
  private var entities = [ModelEntity]()
  
  func getModel(named name: String) async -> ModelEntity? {
    let u = URL.documentsDirectory.appending(path: "\(name).usdz")
    do {
      if FileManager().fileExists(atPath: u.path()) {
        let me = try await ModelEntity(contentsOf: u)
        return me
      } else {
        // https://files.rcsb.org/download/1NC9.pdb
        let u = URL(string:"https://files.rcsb.org/download/\(name).pdb")!
        let (pdb,response) = try await URLSession.shared.data(from: u)
        guard let s = String(data: pdb, encoding: .utf8) else { return nil }
        let (atoms,residues,helices,sheets,seqres) = PDB.parsePDB(pdb: s, maxChains: 2)  // 1hqq Biotin 3nir 1nc9
        if let usdz = Molecule.genProtein(named: name, atoms: atoms) {
          return try? await ModelEntity(contentsOf: usdz)
        }
      }
    } catch {
      print(error.localizedDescription)
    }
    return nil
  }
  
  /*
   func buildEntity(atoms: [Atom]) {
   let le = ModelEntity()
   le.name = "Protein"
   
   if let l = Molecule.protein(atoms: atoms, saveCloud: false) {
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
   model.ligand = le
   
   model.rootEntity.addChild(le)
   
   }
   
   }
   */
}



class MoleculeComponent: Component {
  var residue: Residue
  var outline = false
  
  //  init(player: Player, state: State = .new) {
  init(residue: Residue) {
    self.residue = residue
  }
  
  func update(entity: Entity, with deltaTime: TimeInterval) {
    //    if popEntity?.parent == nil {
    //      entity.addChild(popEntity!)
    //    }
  }
}

