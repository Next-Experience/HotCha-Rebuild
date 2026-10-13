// swift-tools-version: 6.0
import PackageDescription

// 화면·위치 권한·네트워크 없이 테스트할 수 있는 규칙만 둔다.
// 맥에서 `swift test` 로 초 단위에 돈다 — 시뮬레이터가 필요 없다.
let package = Package(
    name: "HotChaKit",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "HotChaKit", targets: ["HotChaKit"])
    ],
    targets: [
        .target(name: "HotChaKit"),
        .testTarget(name: "HotChaKitTests", dependencies: ["HotChaKit"]),
    ]
)
