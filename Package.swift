// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "p90sd-music-db",
    dependencies: [
        .package(url: "https://github.com/novi/ID3TagEditor.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "p90sd-music-db",
            dependencies: ["EDBDatabse", "ID3TagEditor"]),
        .target(
            name: "EDBDatabse"),
        .testTarget(
            name: "p90sd-music-dbTests",
            dependencies: ["p90sd-music-db"]),
    ]
)
