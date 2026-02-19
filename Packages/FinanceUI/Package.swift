// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceUI",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "FinanceUI",
            targets: ["FinanceUI"]
        ),
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
    ],
    targets: [
        .target(
            name: "FinanceUI",
            dependencies: ["FinanceCore"],
            path: "Sources/FinanceUI"
        ),
        .testTarget(
            name: "FinanceUITests",
            dependencies: ["FinanceUI"],
            path: "Tests/FinanceUITests"
        ),
    ]
)
