// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "PDBKit",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1)],
    products: [
        .library(name: "PDBKit", targets: ["PDBKit"])
    ],
    targets: [
        .target(name: "PDBKit"),
        .testTarget(name: "PDBKitTests", dependencies: ["PDBKit"])
    ]
)
