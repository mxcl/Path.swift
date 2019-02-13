// swift-tools-version:4.2
import PackageDescription

let pkg = Package(
    name: "Path.swift",
    products: [
        .library(name: "Path", targets: ["Path"]),
    ],
    targets: [
        .target(name: "Path", path: "Sources"),
        .testTarget(name: "PathTests", dependencies: ["Path"]),
    ],
    swiftLanguageVersions: [.v4, .v4_2]
)
