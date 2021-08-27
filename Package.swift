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
            name: "OpenConnect",
            targets: ["OpenConnect"]
        ),
        .library(
            name: "OpenConnectAdapter",
            targets: ["OpenConnectAdapter"]
        ),
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
