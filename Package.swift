// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Path.swift",
    products: [
        .library(name: "Path", targets: ["Path"]),
    ],
    targets: [
        .target(name: "Path", path: "Sources"),
        .testTarget(name: "PathTests", dependencies: ["Path"]),
    ],
    swiftLanguageVersions: [.v4, .v4_2, .version("5")]
)
