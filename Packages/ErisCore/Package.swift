// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ErisCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ErisCore",
            targets: ["ErisCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ErisCore",
            dependencies: [],
            path: "Sources/ErisCore",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ErisCoreTests",
            dependencies: ["ErisCore"],
            path: "Tests/ErisCoreTests"
        ),
    ]
)
