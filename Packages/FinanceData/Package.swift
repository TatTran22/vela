// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceData",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "FinanceData",
            targets: ["FinanceData"]
        ),
    ],
    dependencies: [
        .package(path: "../FinanceCore"),
    ],
    targets: [
        .target(
            name: "FinanceData",
            dependencies: ["FinanceCore"],
            path: "Sources/FinanceData"
        ),
        .testTarget(
            name: "FinanceDataTests",
            dependencies: ["FinanceData"],
            path: "Tests/FinanceDataTests"
        ),
    ]
)
