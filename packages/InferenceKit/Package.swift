// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "InferenceKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "InferenceKit", targets: ["InferenceKit"])
    ],
    dependencies: [
        .package(path: "../SharedCore")
    ],
    targets: [
        .target(
            name: "InferenceKit",
            dependencies: [
                .product(name: "SharedCore", package: "SharedCore")
            ]
        ),
        .testTarget(name: "InferenceKitTests", dependencies: ["InferenceKit"])
    ],
    swiftLanguageModes: [.v6]
)
