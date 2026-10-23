// swift-tools-version:5.7
import PackageDescription
let package = Package(name: "DYMTransactionRecovery", defaultLocalization: "en", products: [.library(name: "DYMTransactionRecovery", targets: ["DYMTransactionRecovery"])], targets: [
    .target(name: "StoreKit", path: "RecoveryStubs/StoreKit"),
    .target(name: "UIKit", path: "RecoveryStubs/UIKit"),
    .target(name: "DYMTransactionRecovery", dependencies: ["StoreKit", "UIKit"], path: ".", sources: [
        "DingYue_iOS_SDK/Classes/API/DYMTransactionJournal.swift",
        "DingYue_iOS_SDK/Classes/API/DYMTransactionDelivery.swift",
        "DingYue_iOS_SDK/Classes/API/DYMIAPManager.swift", "RecoveryStubs/SDK/SDK.swift"]),
    .testTarget(name: "DYMTransactionRecoveryTests", dependencies: ["DYMTransactionRecovery"], path: "RecoveryTests"),
    .testTarget(name: "DYMAdapterTests", dependencies: ["DYMTransactionRecovery", "StoreKit"], path: "AdapterTests")
])
