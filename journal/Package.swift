// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "journal",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(name: "swift-argument-parser", path: "../../../SwiftArgumentParser"),
        .package(name: "Journaling", path: "../Journaling")
    ],
    targets: [
        .executableTarget(
            name: "journal",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Journaling", package: "Journaling"),
            ]),
        .testTarget(
            name: "journalTests",
            dependencies: [
                "journal"
            ]),
    ]
)
