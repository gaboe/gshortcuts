// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "gshortcuts",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "gshortcuts", path: "Sources/gshortcuts")
    ]
)
