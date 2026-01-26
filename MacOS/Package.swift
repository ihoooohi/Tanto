// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tanto",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Tanto", targets: ["App"])
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: ["Core", "UI", "Utils"]
        ),
        .target(
            name: "Core",
            dependencies: ["Utils"]
        ),
        .target(
            name: "UI",
            dependencies: ["Core", "Utils"]
        ),
        .target(
            name: "Utils"
        ),
        .testTarget(
            name: "TantoTests",
            dependencies: ["Core"]
        )
    ]
)