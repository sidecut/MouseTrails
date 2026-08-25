// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MouseTrails",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "MouseTrails",
            path: "Sources/MouseTrails"
        ),
        .testTarget(
            name: "MouseTrailsTests",
            dependencies: ["MouseTrails"],
            path: "Tests/MouseTrailsTests"
        ),
    ]
)
