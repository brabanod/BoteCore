// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BoteCore",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BoteCore",
            targets: ["BoteCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/eonil/FSEvents.git", from: "0.1.6"),
        .package(url: "https://github.com/jakeheis/Shout.git", from: "0.5.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "BoteCore",
            dependencies: ["EonilFSEvents", "Shout"]),
        .testTarget(
            name: "BoteCoreTests",
            dependencies: ["BoteCore"]),
    ]
)
