// swift-tools-version:5.0
import PackageDescription

let pkg = Package(
    name: "Path.swift",
    products: [
        .library(name: "Path", targets: ["Path"]),
    ],
    targets: [
        .target(name: "Path", path: "Sources"),
        .testTarget(name: "PathTests", dependencies: ["Path"]),
    ]
)

pkg.swiftLanguageVersions = [
    .v4_2, .v5
]
