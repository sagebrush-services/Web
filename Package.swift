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
      url: "https://github.com/neon-law-foundation/Harness.git",
      branch: "feature/dry-and-rename-flow-alignment"),
    .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0"),
    .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.0.0"),
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
        .product(name: "SotoSES", package: "soto"),
        .product(name: "HarnessDAL", package: "Harness"),
        .product(name: "HarnessOIDCMiddleware", package: "Harness"),
        .product(name: "HarnessDatabaseService", package: "Harness"),
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
        .product(name: "Hummingbird", package: "hummingbird"),
        .product(name: "HummingbirdTesting", package: "hummingbird"),
        .product(name: "HarnessDAL", package: "Harness"),
        .product(name: "HarnessOIDCMiddleware", package: "Harness"),
        .product(name: "JWTKit", package: "jwt-kit"),
      ],
      path: "Tests/AppTests"
    ),
  ]
)
