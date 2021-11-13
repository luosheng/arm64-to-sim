// swift-tools-version:5.3
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
        .package(url: "https://github.com/JohnSundell/ShellOut", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "arm64-to-sim",
            dependencies: [
                .product(name: "ShellOut", package: "ShellOut")
            ]),
    ]
)
