// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Kinako",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Kinako",
            path: "Sources/Kinako"
        )
    ],
    swiftLanguageModes: [.v5]
)
