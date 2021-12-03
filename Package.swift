// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "arm64-to-sim",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "arm64-to-sim", targets: ["arm64-to-sim"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/ShellOut", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "arm64-to-sim", dependencies: [
            .product(name: "ShellOut", package: "ShellOut"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
