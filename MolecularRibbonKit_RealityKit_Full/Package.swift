// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MolecularRibbonKitRealityKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MolecularRibbonKitRealityKit", targets: ["MolecularRibbonKitRealityKit"])
    ],
    targets: [
        .target(name: "MolecularRibbonKitRealityKit", path: "Sources"),
        .testTarget(name: "MolecularRibbonKitRealityKitTests", dependencies: ["MolecularRibbonKitRealityKit"])
    ]
)
