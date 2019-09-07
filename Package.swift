// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SODAKit",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
        .watchOS(.v4),
        .tvOS(.v12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SODAKit",
            targets: ["SODAKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SODAKit",
            dependencies: [],
            path: "SODAKit"
        ),
        .testTarget(
            name: "SODAKitTests",
            dependencies: ["SODAKit"],
            path: "SODATests"
        ),
    ]
)

