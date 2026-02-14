// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "FinanceCore",
            targets: ["FinanceCore"]
        ),
    ],
    targets: [
        .target(
            name: "FinanceCore",
            path: "Sources/FinanceCore"
        ),
        .testTarget(
            name: "FinanceCoreTests",
            dependencies: ["FinanceCore"],
            path: "Tests/FinanceCoreTests"
        ),
    ]
)
