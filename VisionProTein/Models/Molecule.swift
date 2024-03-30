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
  
  static func genProtein(atoms : [Atom], saveCloud: Bool = false) -> URL? {
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
      let url = URL.documentsDirectory.appending(path: "residue.usdz")
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
  
  static func entity(residue: Residue) -> ModelEntity? {
    guard let url = genEntity(residue: residue)
    else { return nil }
//    let e = try? Entity.load(contentsOf: url)
    
    // Return residue
    return try? Entity.loadModel(contentsOf: url)

  }
  
  static func protein(atoms: [Atom], saveCloud: Bool = false) -> ModelEntity? {
    guard let url = genProtein(atoms: atoms, saveCloud: saveCloud) else { return nil }

//    let m = try? await ModelEntity(contentsOf: url)
//    return m

    return try? Entity.loadModel(contentsOf: url)
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

