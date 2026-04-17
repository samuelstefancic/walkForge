// swift-tools-version: 6.0
// WalkForge — NotificationKit
// Wrapper UserNotifications. Implémente DomainKit.NotificationServiceProtocol.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableExperimentalFeature("StrictConcurrency"),
]

let package = Package(
    name: "NotificationKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "NotificationKit", targets: ["NotificationKit"]),
    ],
    dependencies: [
        .package(path: "../DomainKit"),
    ],
    targets: [
        .target(
            name: "NotificationKit",
            dependencies: [
                .product(name: "DomainKit", package: "DomainKit"),
            ],
            path: "Sources/NotificationKit",
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "NotificationKitTests",
            dependencies: ["NotificationKit"],
            path: "Tests/NotificationKitTests",
            swiftSettings: swiftSettings,
        ),
    ],
    swiftLanguageModes: [.v6],
)
