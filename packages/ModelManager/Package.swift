// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModelManager",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ModelManager", targets: ["ModelManager"])
    ],
    dependencies: [
        .package(path: "../SharedCore")
    ],
    targets: [
        .target(
            name: "ModelManager",
            dependencies: [
                .product(name: "SharedCore", package: "SharedCore")
            ]
        ),
        .testTarget(name: "ModelManagerTests", dependencies: ["ModelManager"])
    ],
    swiftLanguageModes: [.v6]
)
