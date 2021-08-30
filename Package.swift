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
    targets: [
        .binaryTarget(
            name: "OpenConnectAdapter",
            path: "Frameworks/OpenConnectAdapter.xcframework"
        )
    ]
)
