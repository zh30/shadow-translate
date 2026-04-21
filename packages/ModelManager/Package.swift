// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModelManager",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ModelManager", targets: ["ModelManager"])
    ],
    dependencies: [
        .package(path: "../SharedCore"),
        .package(url: "https://github.com/huggingface/swift-huggingface", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "ModelManager",
            dependencies: [
                .product(name: "SharedCore", package: "SharedCore"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
            ]
        ),
        .testTarget(name: "ModelManagerTests", dependencies: ["ModelManager"])
    ],
    swiftLanguageModes: [.v6]
)