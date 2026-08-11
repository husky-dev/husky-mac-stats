// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HuskyMacStats",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HuskyMacStats",
            path: "Sources/HuskyMacStats"
        )
    ]
)
