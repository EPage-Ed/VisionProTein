// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ProteinSpheresMesh",
    platforms: [.iOS(.v18), .visionOS(.v26)],
    products: [.library(name: "ProteinSpheresMesh", targets: ["ProteinSpheresMesh"])],
    dependencies: [
        .package(path: "../PDBKit")
    ],
    targets: [
        .target(
            name: "ProteinSpheresMesh",
            dependencies: ["PDBKit"]
        ),
        .testTarget(name: "ProteinSpheresMeshTests", dependencies: ["ProteinSpheresMesh"])
    ]
)
