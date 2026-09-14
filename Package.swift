// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AG-SpatialPrivacy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "AG-SpatialPrivacy",
            targets: ["AG-SpatialPrivacy"]
        )
    ],
    targets: [
        .executableTarget(
            name: "AG-SpatialPrivacy",
            path: "Sources/AG-SpatialPrivacy"
        )
    ]
)
