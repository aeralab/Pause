// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "StopRules",
    products: [.library(name: "StopRules", targets: ["StopRules"])],
    targets: [
        .target(name: "StopRules", path: "Shared", exclude: ["ScreenTime.swift", "Repository.swift"], sources: ["Rules.swift"]),
        .testTarget(name: "StopRulesTests", dependencies: ["StopRules"], path: "PackageTests")
    ]
)
