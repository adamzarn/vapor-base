// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "vapor-base",
    platforms: [
        .macOS(.v10_15),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.51.1"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.4.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.2.1"),
        .package(url: "https://github.com/vapor-community/mailgun.git", from: "5.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.1.3"),
        .package(url: "https://github.com/soto-project/soto.git", from: "5.10.0")
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Fluent", package: "fluent"),
            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Mailgun", package: "mailgun"),
            .product(name: "Leaf", package: "leaf"),
            .product(name: "SotoS3", package: "soto")
        ]),
        .target(name: "Run", dependencies: [
            .target(name: "App"),
        ]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor")
        ])
    ]
)

