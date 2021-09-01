// swift-tools-version:5.3
 
import PackageDescription
 
let package = Package(
    name: "OpenConnect",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "OpenConnectAdapter",
            targets: ["OpenConnectAdapter"]
        ),
    ],
    dependencies: [
        .package(name: "OpenSSL", url: "https://github.com/dm-zharov/OpenSSL.git", .branch("legacy1.0.2"))
    ],
    targets: [
        .binaryTarget(
            name: "OpenConnectAdapter",
            path: "Frameworks/OpenConnectAdapter.xcframework"
        )
    ]
)
