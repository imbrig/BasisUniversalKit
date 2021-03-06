// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "BasisUniversalKit",
    platforms: [.macOS(.v10_10), .iOS(.v8)],
    products: [
        .library(
            name: "basisu",
            targets: ["basisu"]),
        .library(
            name: "BasisUniversalKit",
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
    cxxLanguageStandard: .gnucxx14
)
