// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DieCalcCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "DieCalcCore", targets: ["DieCalcCore"]),
    ],
    targets: [
        .target(
            name: "DieCalcCore",
            path: "Sources"
        ),
        .testTarget(
            name: "DieCalcCoreTests",
            dependencies: ["DieCalcCore"],
            path: "Tests"
        ),
    ]
)
