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
            path: "Sources/MouseTrails",
            linkerSettings: [
                // Embed Info.plist in the binary so macOS reads LSUIElement and
                // other keys when running outside of an .app bundle (e.g. swift run).
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Resources/Info.plist",
                ])
            ]
        )
    ]
)
