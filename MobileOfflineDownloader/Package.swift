// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileOfflineDownloader",
    platforms: [.iOS("13.0")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MobileOfflineDownloader",
            targets: ["MobileOfflineDownloader"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            url: "https://github.com/realm/realm-swift.git",
            .upToNextMajor(from: "10.37.0")
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MobileOfflineDownloader",
            dependencies: [
                .product(name: "Realm", package: "realm-swift"),
                .product(name: "RealmSwift", package: "realm-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "MobileOfflineDownloaderTests",
            dependencies: ["MobileOfflineDownloader"]
        ),
    ]
)
