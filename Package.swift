// swift-tools-version:5.3
 
import PackageDescription
 
let package = Package(
    name: "OpenConnect",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "OpenConnect",
            targets: ["OpenConnect"]
        ),
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
            name: "OpenConnect",
            path: "Frameworks/OpenConnect.xcframework"
        ),
        .binaryTarget(
            name: "OpenConnectAdapter",
            path: "Frameworks/OpenConnectAdapter.xcframework"
        )
    ]
)
