// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "ProteinRibbon",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
        .visionOS(.v26)
    ],
    products: [
        .library(name: "ProteinRibbon", targets: ["ProteinRibbon"])
    ],
    targets: [
        .target(name: "ProteinRibbon"),
        .testTarget(name: "ProteinRibbonTests", dependencies: ["ProteinRibbon"])
    ]
)
