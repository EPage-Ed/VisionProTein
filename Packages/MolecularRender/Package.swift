
 // swift-tools-version:5.9
 // The swift-tools-version declares the minimum version of Swift required to build this package.
 import PackageDescription

 let package = Package(
     name: "MolecularRender",
     platforms: [.iOS(.v17),.visionOS(.v1)],
     products: [.library(name:"MolecularRender", targets:["MolecularRender"])],
     targets: [
         .target(name:"MolecularRender"),
         .testTarget(name:"MolecularRenderTests", dependencies:["MolecularRender"])
     ]
 )
