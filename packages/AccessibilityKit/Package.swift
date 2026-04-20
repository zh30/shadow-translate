// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AccessibilityKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AccessibilityKit", targets: ["AccessibilityKit"])
    ],
    dependencies: [
        .package(path: "../SharedCore")
    ],
    targets: [
        .target(
            name: "AccessibilityKit",
            dependencies: [
                .product(name: "SharedCore", package: "SharedCore")
            ]
        ),
        .testTarget(name: "AccessibilityKitTests", dependencies: ["AccessibilityKit"])
    ],
    swiftLanguageModes: [.v6]
)
