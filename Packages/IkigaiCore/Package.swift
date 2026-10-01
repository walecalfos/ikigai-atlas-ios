// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "IkigaiCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "IkigaiCore", targets: ["IkigaiCore"])
    ],
    targets: [
        .target(name: "IkigaiCore"),
        .testTarget(name: "IkigaiCoreTests", dependencies: ["IkigaiCore"])
    ]
)
