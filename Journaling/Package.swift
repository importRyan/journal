// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Journaling",
    platforms: [.macOS(.v11)],
    products: [
        .library(
            name: "Journaling",
            targets: ["Journaling"]),
        .library(
            name: "JournalingPersistence",
            targets: ["JournalingPersistence"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Journaling",
            dependencies: []),
        .target(
            name: "JournalingPersistence",
            dependencies: ["Journaling"]),
        .testTarget(
            name: "JournalingTests",
            dependencies: ["Journaling"]),
        .testTarget(
            name: "JournalingPersistenceTests",
            dependencies: ["JournalingPersistence"]),
    ]
)
