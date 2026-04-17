// swift-tools-version: 6.0
// WalkForge — BLECore
// CoreBluetooth + FTMS protocol implementation. Depends on DomainKit.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("StrictConcurrency"),
    .enableExperimentalFeature("StrictConcurrency"),
]

let package = Package(
    name: "BLECore",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
        .watchOS(.v11),
    ],
    products: [
        .library(name: "BLECore", targets: ["BLECore"]),
    ],
    dependencies: [
        .package(path: "../DomainKit"),
    ],
    targets: [
        .target(
            name: "BLECore",
            dependencies: [
                .product(name: "DomainKit", package: "DomainKit"),
            ],
            path: "Sources/BLECore",
            swiftSettings: swiftSettings,
        ),
        .testTarget(
            name: "BLECoreTests",
            dependencies: ["BLECore"],
            path: "Tests/BLECoreTests",
            swiftSettings: swiftSettings,
        ),
    ],
    swiftLanguageModes: [.v6],
)
