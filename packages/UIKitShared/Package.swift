// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UIKitShared",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "UIKitShared", targets: ["UIKitShared"])
    ],
    dependencies: [
        .package(path: "../SharedCore"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "UIKitShared",
            dependencies: [
                .product(name: "SharedCore", package: "SharedCore"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ]
        ),
        .testTarget(name: "UIKitSharedTests", dependencies: ["UIKitShared"])
    ],
    swiftLanguageModes: [.v6]
)