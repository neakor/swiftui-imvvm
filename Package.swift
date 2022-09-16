// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "IMVVM",
  platforms: [
    .iOS(.v13),
  ],
  products: [
    .library(
      name: "IMVVM",
      targets: ["IMVVM"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.2"),
  ],
  targets: [
    .target(
      name: "IMVVM",
      dependencies: [
        .product(name: "OrderedCollections", package: "swift-collections"),
      ]
    ),
    .testTarget(
      name: "IMVVMTests",
      dependencies: [
        "IMVVM",
      ]
    ),
  ]
)
