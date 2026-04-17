// swift-tools-version: 6.0
// WalkForge — DataKit
// Persistance SwiftData + implémentations des repositories DomainKit.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableExperimentalFeature("StrictConcurrency"),
]

let package = Package(
    name: "DataKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "DataKit", targets: ["DataKit"]),
    ],
    dependencies: [
        .package(path: "../DomainKit"),
    ],
    targets: [
        .target(
            name: "DataKit",
            dependencies: [
                .product(name: "DomainKit", package: "DomainKit"),
            ],
            path: "Sources/DataKit",
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "DataKitTests",
            dependencies: ["DataKit"],
            path: "Tests/DataKitTests",
            swiftSettings: swiftSettings,
        ),
    ],
    swiftLanguageModes: [.v6],
)
