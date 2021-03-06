// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Packages",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ApiClient",
            targets: ["ApiClient"]),
        .library(
            name: "PersistenceService",
            targets: ["PersistenceService"]),
        .library(
            name: "SynchronizationService",
            targets: ["SynchronizationService"]),
        .library(
            name: "DataImporterService",
            targets: ["DataImporterService"]),
        .library(
            name: "Models",
            targets: ["Models"]),
        .library(
            name: "TodosFeature",
            targets: ["TodosFeature"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ApiClient",
            dependencies: ["Models"]),
        .testTarget(
            name: "ApiClientTests",
            dependencies: ["ApiClient"]),
        .target(
            name: "PersistenceService",
            dependencies: ["Models"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "PersistenceServiceTests",
            dependencies: ["PersistenceService"]),
        .target(
            name: "SynchronizationService",
            dependencies: [
                "Models",
                "DataImporterService",
                "PersistenceService",
                "ApiClient"
            ]
        ),
        .testTarget(
            name: "SynchronizationServiceTests",
            dependencies: ["SynchronizationService"]),
        .target(
            name: "DataImporterService",
            dependencies: [
                "Models",
                "PersistenceService",
                "ApiClient"
            ]
        ),
        .testTarget(
            name: "DataImporterServiceTests",
            dependencies: ["DataImporterService"]),
        .target(
            name: "Models",
            dependencies: []
        ),
        .target(
            name: "TodosFeature",
            dependencies: ["Models", "PersistenceService", "DataImporterService"]
        )
    ]
)
