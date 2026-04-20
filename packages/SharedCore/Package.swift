// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedCore",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SharedCore", targets: ["SharedCore"])
    ],
    targets: [
        .target(name: "SharedCore"),
        .testTarget(name: "SharedCoreTests", dependencies: ["SharedCore"])
    ],
    swiftLanguageModes: [.v6]
)
