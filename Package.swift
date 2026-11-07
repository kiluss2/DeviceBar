// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeviceBar",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(name: "DeviceBar", path: "Sources/DeviceBar")
    ]
)
