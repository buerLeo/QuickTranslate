// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuickTranslate",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "QuickTranslate", targets: ["QuickTranslate"])
    ],
    targets: [
        .executableTarget(
            name: "QuickTranslate",
            path: "QuickTranslate",
            exclude: ["Info.plist"],
            resources: []
        )
    ],
    swiftLanguageModes: [.v5]
)
