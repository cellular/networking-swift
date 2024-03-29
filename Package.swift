// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v5),
        .macOS(.v10_12)
    ],
    products: [
        .library(name: "Networking", targets: ["Networking"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.5.0"),
        .package(url: "https://github.com/cellular/cellular-swift", from: "6.0.1"),
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: ["Alamofire", .product(name: "CELLULAR", package: "cellular-swift")]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            resources: [
                .process("Resources"),
            ]
        )
    ]
)
