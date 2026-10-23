//
//  AppDelegate.swift
//  DingYue_iOS_SDK
//
//  Created by DingYueIO on 07/07/2022.
//  Copyright (c) 2022 DingYueIO. All rights reserved.
//

import UIKit
import AdSupport
import DingYue_iOS_SDK

// Demo 中缓存 activate 或购买回调返回的已购产品，传给 Paywall/Guide 的 extras 做展示示例。
var purchasedProducts:[[String:Any]] = [] {
    didSet {
        print("test ----, purchasedProducts = \(purchasedProducts)")
    }
}
// Demo 的引导页展示标记。正式项目可替换成自己的 onboarding/guide 完成状态。
let HasDisplayedGuide = "HasDisplayedGuide"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /*
         1. 用户 UUID（可选）
         - 不设置时，SDK 默认使用 FCUUID.uuidForDevice()。
         - 如果设置，该值也会用于内购的 applicationUsername，方便 App Store Server Notifications 回传后匹配用户。
         - 格式需符合 Apple UUID 字符串格式。
         */
//        DYMobileSDK.UUID = UUID().uuidString
        
        /*
         2. 后台域名配置（可选）
         - 如果业务需要固定后台地址，先设置 basePath，再设置 enableAutoDomain。
         - enableAutoDomain = false：使用手动配置或 SDK 默认后台地址。
         - enableAutoDomain = true：优先使用缓存/后台下发域名；basePath 可作为兜底默认域名。
         */
//        DYMobileSDK.basePath = "https://mobile.dingyueio.cn"

        /*
         3. 动态域名开关
         - 默认为关闭。
         - 开启后，下次启动会优先使用后台下发或缓存的域名。
         - 如果后台同时下发 plistInfo，SDK 会使用下发的 appId 和 apiKey。
         - 如果仍希望强制使用手动 basePath，请保持 enableAutoDomain = false。
         */
        DYMobileSDK.enableAutoDomain = false

        /*
         4. 其他 SDK 配置示例
         - defaultConversionValueEnabled：是否使用 SDK 默认 SKAN CV 规则。
         - networkRequestConfig：网络重试次数和重试间隔示例。
         */
        DYMobileSDK.defaultConversionValueEnabled = true
        DYMConfiguration.shared.networkRequestConfig.maxRetryCount = 5
        DYMConfiguration.shared.networkRequestConfig.retryInterval = 2

        // 5. Apple Search Ads 归因示例。mode = .networkRequest 表示主动请求一次归因数据。
        DYMobileSDK.retrieveAppleSearchAdsAttribution(mode: .networkRequest) { attri, error in
            print(String(describing: attri))
        }

        // 场景窗口与 Guide 启动流程在 SceneDelegate 中准备。
        return true
    }

}
