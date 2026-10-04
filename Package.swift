// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "TapUpdater",
  platforms: [.macOS(.v15)],
  products: [.executable(name: "tap-updater", targets: ["TapUpdater"])],
  dependencies: [
    .package(url: "https://github.com/swift-library/swift-semver", .upToNextMinor(from: "0.1.0"))
  ],
  targets: [
    .executableTarget(
      name: "TapUpdater", dependencies: [.product(name: "SemVer", package: "swift-semver")]),
    .testTarget(name: "TapUpdaterTests", dependencies: ["TapUpdater"]),
  ]
)
