
 // swift-tools-version:5.9
 import PackageDescription

 let package = Package(
     name: "MolecularRibbonKit",
     platforms: [.iOS(.v17)],
     products: [.library(name:"MolecularRibbonKit", targets:["MolecularRibbonKit"])],
     targets: [
         .target(name:"MolecularRibbonKit"),
         .testTarget(name:"MolecularRibbonKitTests", dependencies:["MolecularRibbonKit"])
     ]
 )
