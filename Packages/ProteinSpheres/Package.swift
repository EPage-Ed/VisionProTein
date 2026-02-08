// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProteinSpheres",
    platforms: [
        .iOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "ProteinSpheres",
            targets: ["ProteinSpheres"]
        )
    ],
    targets: [
        .target(
            name: "ProteinSpheres"
        )
    ]
)
