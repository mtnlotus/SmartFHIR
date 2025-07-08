// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmartFHIR",
	platforms: [
		.macOS(.v14),
		.iOS(.v15),
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SmartFHIR",
            targets: ["SmartFHIR"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/FHIRModels.git", "0.7.0"..<"1.0.0"),
		.package(url: "https://github.com/p2/OAuth2", "5.2.0"..<"6.0.0"),
//		.package(url: "https://github.com/clinical-cloud/OAuth2.git", branch: "master")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "SmartFHIR",
			dependencies: [
				.product(name: "ModelsR4", package: "FHIRModels"),
				.product(name: "OAuth2", package: "OAuth2"),
			]),
		.testTarget(
			name: "SmartFHIRTests",
			dependencies: ["SmartFHIR"],
			resources: [.copy("TestResources"), .copy("metadata")]
		),
	]
)
