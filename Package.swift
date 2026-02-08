// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BreakTime",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "BreakTime",
            path: "BreakTime",
            exclude: ["Info.plist", "Resources"]
        )
    ]
)
