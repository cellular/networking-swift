// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11),
        .watchOS(.v5)
    ],
    products: [
        .library(name: "Networking", type: .dynamic, targets: ["Networking"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "4.8.2"),
        .package(url: "https://github.com/cellular/cellular-swift", .branch("feature/xcode_11.4")),
    ],
    targets: [
        .target(name: "Networking", dependencies: ["CELLULAR", "Alamofire"]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"])
    ]
)
