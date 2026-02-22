// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SagebrushWeb",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(
            url: "https://github.com/hummingbird-project/hummingbird-lambda.git", from: "2.0.0"),
        .package(
            url: "https://github.com/apple/swift-openapi-generator.git", from: "1.6.0"),
        .package(
            url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.7.0"),
        .package(
            url: "https://github.com/swift-server/swift-openapi-hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "7.3.0"),
        .package(
            url: "https://github.com/neon-law-foundation/SagebrushStandards.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.13.0"),
        .package(
            url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.12.0"),
        .package(
            url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.8.1"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdLambda", package: "hummingbird-lambda"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "SotoSecretsManager", package: "soto"),
                .product(name: "SagebrushDAL", package: "SagebrushStandards"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "Configuration", package: "swift-configuration"),
            ],
            path: "Sources/App",
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .byName(name: "App"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
            path: "Tests/AppTests"
        ),
    ]
)
