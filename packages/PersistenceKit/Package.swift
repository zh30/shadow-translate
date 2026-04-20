// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PersistenceKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "PersistenceKit", targets: ["PersistenceKit"])
    ],
    dependencies: [
        .package(path: "../SharedCore")
    ],
    targets: [
        .target(
            name: "PersistenceKit",
            dependencies: [
                .product(name: "SharedCore", package: "SharedCore")
            ]
        ),
        .testTarget(name: "PersistenceKitTests", dependencies: ["PersistenceKit"])
    ],
    swiftLanguageModes: [.v6]
)
