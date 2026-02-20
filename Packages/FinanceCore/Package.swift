// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FinanceCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
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
            path: "Sources/FinanceCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "FinanceCoreTests",
            dependencies: ["FinanceCore"],
            path: "Tests/FinanceCoreTests"
        ),
    ]
)
