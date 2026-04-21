// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "InferenceKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "InferenceKit", targets: ["InferenceKit"])
    ],
    dependencies: [
        .package(path: "../SharedCore"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "3.31.3"),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.31.3"),
        .package(url: "https://github.com/huggingface/swift-huggingface", from: "0.9.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "InferenceKit",
            dependencies: [
                .product(name: "SharedCore", package: "SharedCore"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "HuggingFace", package: "swift-huggingface"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ]
        ),
        .testTarget(name: "InferenceKitTests", dependencies: ["InferenceKit"])
    ],
    swiftLanguageModes: [.v6]
)