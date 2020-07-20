// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BasisUniversalKit",
    platforms: [.macOS(.v10_10), .iOS(.v8)],
    products: [
        .library(
            name: "BasisUniversalKit",
            targets: ["BasisUniversalKit"]),
        .library(
            name: "basisu",
            targets: ["basisu"]),
    ],
    targets: [
        .target(
            name: "BasisUniversalKit",
            dependencies: [
                "basisu",
            ],
            path: "BasisUniversalKit",
            exclude: ["basis_universal"]
        ),
        .target(
            name: "basisu",
            path: "BasisUniversalKit/basis_universal/transcoder/"),
    ],
    swiftLanguageVersions: [.v4_2]
)
