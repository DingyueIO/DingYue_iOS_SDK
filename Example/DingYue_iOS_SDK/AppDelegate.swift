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

    var window: UIWindow?
    // 示例工程内置的本地 Web Guide 资源名，对应 Example/DingYue_iOS_SDK/DemoGuide.bundle。
    private let demoGuideBundleName = "DemoGuide"

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
         4. 动态 Web Guide 启动容器
         - showVisualGuide 会先把 DYMGuideController 放到 window 上，展示启动页/加载态。
         - activate 之后，SDK 会根据后台配置下载或选择 Guide 模板，并将 guideLoadingStatus 置为可加载。
         - 因此这里需要在 activate 前准备 Guide 容器和代理链路；它不是普通页面的提前弹出。
         - 如果请求失败且没有可用本地 Guide，会走 clickGuideCloseButton 的 NO_LOCAL_WEB_GUIDE_CLOSE 分支。
         */
        self.showWebGuideVC()

        /*
         5. 其他 SDK 配置示例
         - defaultConversionValueEnabled：是否使用 SDK 默认 SKAN CV 规则。
         - networkRequestConfig：网络重试次数和重试间隔示例。
         */
        DYMobileSDK.defaultConversionValueEnabled = true
        DYMConfiguration.shared.networkRequestConfig.maxRetryCount = 5
        DYMConfiguration.shared.networkRequestConfig.retryInterval = 2

        // 6. Apple Search Ads 归因示例。mode = .networkRequest 表示主动请求一次归因数据。
        DYMobileSDK.retrieveAppleSearchAdsAttribution(mode: .networkRequest) { attri, error in
            print(String(describing: attri))
        }

        // 7. 启动 DingYue 激活流程，拉取购买状态、开关、Paywall/Guide 配置等数据。
        self.activeSDK()

        // 8. Lua 扩展示例初始化；不使用 Lua 的接入方可以去掉。
        TestLuaOperation.sharedInstance().initLua()
        return true
    }

    // MARK: - DingYue activation

    func activeSDK() {
        /*
         activate 会向 DingYue 后台同步当前设备/用户状态，并拉取：
         - 已购产品 subscribedOjects
         - Paywall / Guide 页面配置
         - 远程开关和用户分群等信息
         Demo 在回调里演示如何根据 nativeGuidePageId 决定继续展示 Web Guide 或进入主页。
         */
        DYMobileSDK.activate { results, error in
            if error == nil {
                if let res = results {
                    if let hasPurchasedItems = res["subscribedOjects"] as? [[String:Any]] {
                        // 已购订阅对象示例：缓存后会传给 Paywall/Guide 的 extras，供 H5 页面展示或判断。
                        purchasedProducts = hasPurchasedItems
                        for sub in DYMobileSDK.getProductItems() ?? [] {
                            print("test ----, AppDelegate getProductItems = \(sub.platformProductId)")
                        }
                    }

                    // Demo 手动设置 Guide 的 VIP 状态。正式项目建议根据 activate 返回的购买状态统一维护会员态。
                    DYMConfiguration.shared.guidePageConfig.isVIP = true

                    /*
                     nativeGuidePageId 为空：当前后台未配置 Web Guide，Demo 直接进入主页；
                     nativeGuidePageId 有值：后台配置了 Web Guide，继续使用前面 showVisualGuide 创建的 Guide 容器。
                     */
                    if let nativeGuidePageId = res["nativeGuidePageId"] as? String , nativeGuidePageId.count <= 0 {
                        // 这里可替换成接入方自己的原生引导页或首页路由。
                        self.setRootVC()
                    }else {
                        // Demo 为了每次调试都能看到 Guide，会重置展示标记；正式项目按自己的业务规则控制。
                        UserDefaults.standard.set(false, forKey: HasDisplayedGuide)

                        self.setupLocalDemoGuideBundleIfNeeded()
                        if UserDefaults.standard.bool(forKey: HasDisplayedGuide) {
                            self.window?.backgroundColor = .white
                            self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())
                        }
                    }
                }
                
            }else {
                // 激活失败时不要让用户停在加载页；这里进入 Demo 主页，正式项目可接自己的失败兜底策略。
                self.setRootVC()
            }
            

        }
    }

    // MARK: - Dynamic Web Guide container

    func showWebGuideVC() {
        /*
         这个方法是动态 Web Guide 的启动容器配置：
         - 创建 window；
         - 设置 DYMGuideController 为 rootViewController；
         - 绑定 DYMWindowManaging / DYMGuideActionDelegate；
         - 传入示例产品和 extras。
         DYMGuideController 会等待 activate 后的 Guide 数据或本地 Guide 资源，再真正加载页面。
         */
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        DYMConfiguration.shared.guidePageConfig.indicatorColor = .orange

        // 自定义产品信息示例。正式项目请替换为自己的 App Store productId 和价格展示信息。
        let defaultProuct1 = Subscription(type: "SUBSCRIPTION", name: "Week", platformProductId: "testWeek", price: "7.99", currencyCode: "USD", countryCode: "US")
        let defaultProuct2 = Subscription(type: "SUBSCRIPTION", name: "Year", platformProductId: "testYear", appleSubscriptionGroupId: nil, description: "default product item", period: "Year", price: "49.99", currencyCode: "USD", countryCode: "US", priceTier: nil, gracePeriod: nil, icon: nil, renewPriceChange: nil)

        // extras 会透传给 H5 Guide，可用于页面个性化展示、调试或业务参数传递。
        let extra:[String:Any] = [
            "phoneNumber": "1999999999",
            "phoneCountry" : "国家",
            "purchasedProducts" : purchasedProducts,
            "mainColor": "white"
        ]

        // 展示动态 Guide 容器。Guide 内购买完成后会通过该 completion 返回订单校验结果。
        DYMobileSDK.showVisualGuide(products: [defaultProuct1,defaultProuct2],rootDelegate:self,extras: extra) { receipt, purchaseResult,purchasedProduct, error in
            
            if let res = purchaseResult,res.count > 0 {
                let expireTime = self.calculateNewExpiryTime(from: res)
                let now = self.getCurrentTimestamp()
                if expireTime > Int(now){
                    // Guide 内购买成功后的 Demo 路由。正式项目可在这里刷新会员态并进入主页。
                    self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())
                    
                }else {
                    // Guide 内购买失败，可在这里提示用户或保留当前 Guide 页面。
                }
            }else {
                // Guide 内购买失败，可在这里提示用户或保留当前 Guide 页面。
            }
        }
        
 
    }
 
    // MARK: - Local Web Guide resource

    // 配置 Demo 内置的本地 Web Guide。
    // showVisualGuide 会先显示 Guide 容器；当 activate 后 SDK 判断需要本地 Guide 时，
    // 这里再把 DemoGuide.bundle/index.html 提供给 SDK 加载。
    // DemoGuide.bundle 只是示例资源名，接入方可以替换成自己的 bundle 和 index.html。
    func setupLocalDemoGuideBundleIfNeeded() {
        guard DYMobileSDK.isUseLocalWebGuide else {
            return
        }

        guard let bundleResourceURL = Bundle.main.url(forResource: demoGuideBundleName, withExtension: "bundle"),
              let resourceBundle = Bundle(url: bundleResourceURL),
              let htmlFilePath = resourceBundle.path(forResource: "index", ofType: "html") else {
            print("DemoGuide.bundle/index.html not found.")
            return
        }

        let bundleBasePath = resourceBundle.bundlePath
        DYMobileSDK.loadNativeGuidePage(paywallFullPath: htmlFilePath, basePath: bundleBasePath)
    }
    
    // MARK: - Demo route helpers

    // Demo 主页路由。正式项目可以替换为自己的首页、TabBar 或业务 RootCoordinator。
    func setRootVC() {
       
        if UserDefaults.standard.bool(forKey: HasDisplayedGuide) {
            self.window?.rootViewController = UINavigationController(rootViewController: ViewController())
        }else{
            // 如果没有展示过 Guide，也可以在这里切到接入方自己的原生引导页。
            self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())

        }
        
    }
    // Guide 完成或业务需要直接进入主页时可调用的示例方法。
    func gotoMainVC() {
        UserDefaults.standard.set(true, forKey: HasDisplayedGuide)
        UserDefaults.standard.synchronize()
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        
    }
    
}

/*
 DYMWindowManaging:
 - 提供 window 给 showVisualGuide 设置 DYMGuideController。
 - UIKit AppDelegate 接入时通常直接由 AppDelegate 实现。

 DYMGuideActionDelegate:
 - 接收 Web Guide 的 H5 事件，包括显示、消失、关闭、购买、恢复、继续、服务条款和隐私政策点击。
 - 代理对象需要在 Guide 生命周期内保持存活，避免 H5 回调丢失。
 */
extension AppDelegate: DYMWindowManaging,DYMGuideActionDelegate {
   
    public func guideDidAppear(baseViewController: UIViewController) {
        print("guideDidAppear")
    }
    public func guideDidDisappear(baseViewController: UIViewController) {
        print("guideDidDisappear")
    }
 
    public func clickGuideCloseButton(baseViewController: UIViewController, closeType: String) {
        print("clickGuideCloseButton---closeType--\(closeType)")

        /*
         closeType == "NO_LOCAL_WEB_GUIDE_CLOSE":
         - SDK 需要加载本地 Web Guide，但当前没有可用本地资源；
         - 常见于接口失败、模板未下载、或 DemoGuide.bundle 未配置。
         Demo 在这种情况下不写 HasDisplayedGuide，方便下次启动继续尝试。
         */
        if closeType != "NO_LOCAL_WEB_GUIDE_CLOSE" {
            // 正常关闭或完成 Guide 后，写入展示标记。正式项目可替换成自己的 onboarding 完成状态。
            UserDefaults.standard.set(true, forKey: HasDisplayedGuide)
            UserDefaults.standard.synchronize()
        }

        // Guide 关闭后进入 Demo 主页。正式项目可替换成自己的首页路由。
        self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())
        self.window?.backgroundColor = .white
        self.window?.makeKeyAndVisible()
    }
    public func clickGuideTermsAction(baseViewController: UIViewController) {
        print("clickGuideTermsAction")

        // 服务条款点击回调。Demo 使用占位 URL，正式项目请替换为真实服务条款地址。
        let vc = LBWebViewController.init()
        vc.url = "url"
        vc.title = NSLocalizedString("Terms_of_Service", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }
    public func clickGuidePrivacyAction(baseViewController: UIViewController) {
        print("clickGuidePrivacyAction")

        // 隐私政策点击回调。Demo 使用占位 URL，正式项目请替换为真实隐私政策地址。
        let vc = LBWebViewController.init()
        vc.url = "url"
        vc.title = NSLocalizedString("Privacy_Policy", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }
    public func clickGuideRestoreButton(baseViewController: UIViewController) {
        // Guide H5 点击恢复购买时的事件回调，可在这里补充埋点或统一恢复购买提示。
        print("clickGuideRestoreButton")
    }
    public func clickGuidePurchaseButton(baseViewController: UIViewController) {
        // Guide H5 点击购买按钮时的事件回调，可在这里补充埋点或 UI 状态记录。
        print("clickGuidePurchaseButton")
    }
    public func clickGudieContinueButton(baseViewController: UIViewController, currentIndex: Int, nextIndex: Int, swiperSize: Int) {
        // Guide H5 点击继续按钮时的事件回调，适合记录页码、完成状态或自定义跳转规则。
        print("clickGudieContinueButton--currentIndex:\(currentIndex) --- nextIndex:\(nextIndex)")
    }
}

// MARK: - Demo helpers
extension AppDelegate {
    // 根据购买校验返回的 expiresAt 计算最新订阅有效期。
    // 对非订阅产品，Demo 按一周有效期演示；正式项目请按自己的权益规则处理。
    func calculateNewExpiryTime(from products: [[String: Any]]) -> Int {
        var latestExpiry = ""
        for product in products {
            if let expiryDate = product["expiresAt"] as? String {
                latestExpiry = expiryDate > latestExpiry ? expiryDate : latestExpiry
            } else {
                let currentTimestamp = getCurrentTimestamp()
                let oneWeekInMilliseconds = 7 * 24 * 3600 * 1000
                return currentTimestamp + oneWeekInMilliseconds
            }
        }
        return Int(latestExpiry) ?? 0
    }
    
    func getCurrentTimestamp() -> Int {
       let currentTimeInterval = Date().timeIntervalSince1970
       let timestampInMilliseconds = Int(currentTimeInterval * 1000)
       return timestampInMilliseconds
   }
}
