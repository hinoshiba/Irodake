// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Irodake",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Irodake", targets: ["Irodake"]),
    ],
    targets: [
        .executableTarget(
            name: "Irodake",
            path: "Sources/Irodake"
        ),
        .testTarget(
            name: "IrodakeTests",
            dependencies: ["Irodake"],
            path: "Tests/IrodakeTests"
        ),
    ]
)
