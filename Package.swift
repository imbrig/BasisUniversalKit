// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BasisUniversalKit",
    platforms: [.macOS(.v10_10), .iOS(.v8)],
    products: [
        .library(
            name: "basisu",
            type: .dynamic,
            targets: ["basisu"]),
        .library(
            name: "BasisUniversalKit",
            type: .dynamic,
            targets: ["BasisUniversalKit"])
    ],
    targets: [
        .target(
            name: "basisu",
            dependencies: [],
            path: "BasisUniversalKit/basis_universal/transcoder/"),
        .target(
            name: "BasisUniversalKit",
            dependencies: ["basisu"],
            path: "BasisUniversalKit",
            exclude: ["basis_universal"]
        )
    ],
    swiftLanguageVersions: [.v4_2],
    cxxLanguageStandard: .gnucxx14
)
