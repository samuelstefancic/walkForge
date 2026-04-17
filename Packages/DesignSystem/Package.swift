// swift-tools-version: 6.0
// WalkForge — DesignSystem
// Palette, typographie, composants SwiftUI réutilisables, haptic feedback.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableExperimentalFeature("StrictConcurrency"),
]

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    dependencies: [
        .package(path: "../DomainKit"),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "DomainKit", package: "DomainKit"),
            ],
            path: "Sources/DesignSystem",
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "Tests/DesignSystemTests",
            swiftSettings: swiftSettings,
        ),
    ],
    swiftLanguageModes: [.v6],
)
