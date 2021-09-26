// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Journaling",
    platforms: [.macOS(.v11)],
    products: [
        .library(
            name: "Journaling",
            targets: ["Journaling"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Journaling",
            dependencies: []),
        .testTarget(
            name: "JournalingTests",
            dependencies: ["Journaling"]),
    ]
)
