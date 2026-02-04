// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ProteinRibbon",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "ProteinRibbon", targets: ["ProteinRibbon"])
    ],
    targets: [
        .target(name: "ProteinRibbon"),
        .testTarget(name: "ProteinRibbonTests", dependencies: ["ProteinRibbon"])
    ]
)
