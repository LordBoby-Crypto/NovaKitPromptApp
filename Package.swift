// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NovaKitPromptAppCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "NovaKitPromptAppCore", targets: ["NovaKitPromptAppCore"])
    ],
    targets: [
        .target(
            name: "NovaKitPromptAppCore",
            path: "NovaKitPromptApp",
            exclude: [
                "AppStore.swift",
                "ConversationListView.swift",
                "ConversationView.swift",
                "NovaKitPromptApp.swift",
                "Info.plist",
                "Assets.xcassets"
            ]
        ),
        .testTarget(
            name: "NovaKitPromptAppTests",
            dependencies: ["NovaKitPromptAppCore"],
            path: "Tests/NovaKitPromptAppTests"
        )
    ]
)
