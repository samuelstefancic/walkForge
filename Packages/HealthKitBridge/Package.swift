// swift-tools-version: 6.0
// WalkForge — HealthKitBridge
// Wrapper HealthKit. Implémente DomainKit.HealthKitServiceProtocol.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableExperimentalFeature("StrictConcurrency"),
]

let package = Package(
    name: "HealthKitBridge",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "HealthKitBridge", targets: ["HealthKitBridge"]),
    ],
    dependencies: [
        .package(path: "../DomainKit"),
    ],
    targets: [
        .target(
            name: "HealthKitBridge",
            dependencies: [
                .product(name: "DomainKit", package: "DomainKit"),
            ],
            path: "Sources/HealthKitBridge",
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "HealthKitBridgeTests",
            dependencies: ["HealthKitBridge"],
            path: "Tests/HealthKitBridgeTests",
            swiftSettings: swiftSettings,
        ),
    ],
    swiftLanguageModes: [.v6],
)
