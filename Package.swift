// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WinBucket",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "WinBucket",
            path: "Sources/WinBucket"
        )
    ]
)
