// swift-tools-version: 6.0
// WalkForge — DomainKit
// Pure Swift module: entities, protocols, errors. No framework dependency.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableExperimentalFeature("StrictConcurrency"),
]

let package = Package(
    name: "DomainKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
        .watchOS(.v11),
    ],
    products: [
        .library(name: "DomainKit", targets: ["DomainKit"]),
    ],
    targets: [
        .target(
            name: "DomainKit",
            path: "Sources/DomainKit",
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "DomainKitTests",
            dependencies: ["DomainKit"],
            path: "Tests/DomainKitTests",
            swiftSettings: swiftSettings,
        ),
    ],
    swiftLanguageModes: [.v6],
)
