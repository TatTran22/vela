// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceData",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
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
            path: "Sources/FinanceData",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "FinanceDataTests",
            dependencies: ["FinanceData"],
            path: "Tests/FinanceDataTests"
        ),
    ]
)
