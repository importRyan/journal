// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "journal",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.1")
    ],
    targets: [
        .executableTarget(
            name: "journal",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
                          ]),
        .testTarget(
            name: "journalTests",
            dependencies: ["journal"]),
    ]
)
