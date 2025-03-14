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

var purchasedProducts:[[String:Any]] = [] {
    didSet {
        print("test ----, purchasedProducts = \(purchasedProducts)")
    }
}
let HasDisplayedGuide = "HasDisplayedGuide"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //session report
      
        
         /*
          配置用户的UUID，包括内购时的applicationUsername 也是这个，如果不设置，则默认使用第三方库 FCUUID.uuidForDevice()获取的id
          */
//        DYMobileSDK.UUID = UUID().uuidString // uuid 的格式要符合Apple UUID 格式，用于内购时设置applicationUsername,以便于appstore 推送时返回token
        
        /*
         enableAutoDomain 动态切换域名，默认为关闭
         在下次启动的时候，会切换成从后台下发的域名（单独切换域名，只适合不通域名下，相同帐号的情况，如果是不通帐号的话，需要下发plistInfo）
         如果后台下发了plistInfo，则appid 和apikey 将使用后台下发的
         如果再需要手动设置basepath的话，需要将该属性设置为flase
        */
        DYMobileSDK.enableAutoDomain = false
        
        
        
        /*
          手动指定basePath后台地址。
         */
//        DYMobileSDK.basePath = "https://mobile.dingyueio.cn"

        /*
         连续请求15次失败之后 将会进入之前下载的默认引导页(如果没有默认下载的引导页，则需要在clickGuideCloseButton代理中，设置下一步操作，例如，进入主页，
         也可以 在sdk回调中进行设置。可根据 nativeGuidePageId 进行判断 （ 未返回，或者为空  代表未配置 web引导页） 可设置为 切换到原生引导页。
         如果不设置，则会在网络成功的情况下进入web 引导页
         */
     
        self.showWebGuideVC()
//        self.setLocalGuidePaths()
        DYMobileSDK.defaultConversionValueEnabled = true //use default cv rule
        DYMConfiguration.shared.networkRequestConfig.maxRetryCount = 5
        DYMConfiguration.shared.networkRequestConfig.retryInterval = 2

        DYMobileSDK.activate { results, error in
            if error == nil {
                if let res = results {
                    if let hasPurchasedItems = res["subscribedOjects"] as? [[String:Any]] {
                        purchasedProducts = hasPurchasedItems
                        for sub in DYMobileSDK.getProductItems() ?? [] {
                            print("test ----, AppDelegate getProductItems = \(sub.platformProductId)")
                        }
                    }
                    
                    DYMConfiguration.shared.guidePageConfig.isVIP = true
                    // 未返回 nativeGuidePageId 代表 未配置 web引导页
                    if let nativeGuidePageId = res["nativeGuidePageId"] as? String , nativeGuidePageId.count <= 0 {
                        // 原生 rootvc相关逻辑
                        self.setRootVC()
                    }else {
                      // 如果配置 则 自动加载 引导页 或者进入主页
                        if UserDefaults.standard.bool(forKey: HasDisplayedGuide) {
                            self.window?.backgroundColor = .white
                            self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())
                        }
                    }
                }
                
            }else {
                // 接口请求失败
                self.setRootVC()
            }
            

        }
        
        DYMobileSDK.retrieveAppleSearchAdsAttribution { attribution, error in
            print("🍌🍌🍌\(attribution)")
        }

        
        //lua 脚本相关
        TestLuaOperation.sharedInstance().initLua()
        return true
    }
    
    func showWebGuideVC() {
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        DYMConfiguration.shared.guidePageConfig.indicatorColor = .orange

        //显示引导页-可以传符合要求的内购项信息对象
        let defaultProuct1 = Subscription(type: "SUBSCRIPTION", name: "Week", platformProductId: "testWeek", price: "7.99", currencyCode: "USD", countryCode: "US")
        let defaultProuct2 = Subscription(type: "SUBSCRIPTION", name: "Year", platformProductId: "testYear", appleSubscriptionGroupId: nil, description: "default product item", period: "Year", price: "49.99", currencyCode: "USD", countryCode: "US", priceTier: nil, gracePeriod: nil, icon: nil, renewPriceChange: nil)
        //显示引导页
        
        let extra:[String:Any] = [
            "phoneNumber": "1999999999",
            "phoneCountry" : "国家",
            "purchasedProducts" : purchasedProducts,
            "mainColor": "white"
        ]
        DYMobileSDK.showVisualGuide(products: [defaultProuct1,defaultProuct2],rootDelegate:self,extras: extra) { receipt, purchaseResult,purchasedProduct, error in
            
            if let res = purchaseResult,res.count > 0 {
                let expireTime = self.calculateNewExpiryTime(from: res)
                let now = self.getCurrentTimestamp()
                if expireTime > Int(now){
                    //引导页购买成功
                    //自定义逻辑
                    self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())
                    
                }else {
                    //引导页购买失败
                }
            }else {
                //引导页购买失败
            }
        }
        
 
    }
 
    
    //加载本地web 路径
    func setLocalGuidePaths() {
          // 获取主 Bundle 的路径
        let bundlePath = Bundle.main.bundlePath
        // 拼接子文件夹路径
        let subfolderPath = (bundlePath as NSString).appendingPathComponent("7306588143563858788")
        // 拼接最终文件路径
        let filePath = (subfolderPath as NSString).appendingPathComponent("index.html")
        
        // 确保文件存在
        if FileManager.default.fileExists(atPath: filePath) {
            // 设置 DYMDefaultsManager 的路径属性
            DYMobileSDK.loadNativeGuidePage(paywallFullPath: filePath, basePath: subfolderPath)

        } else {
            print("index.html file not found at path: \(filePath)")
        }

      }
    
    func setRootVC() {
       
        if UserDefaults.standard.bool(forKey: HasDisplayedGuide) {
            self.window?.rootViewController = UINavigationController(rootViewController: ViewController())
        }else{
            // 原生引导页
            self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())

        }
        
    }
    
    func gotoMainVC() {
        UserDefaults.standard.set(true, forKey: HasDisplayedGuide)
        UserDefaults.standard.synchronize()
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        
    }
    
}

/*遵循协议
 DYMWindowManaging: window 的获取
 DYMGuideActionDelegate: web引导页 具体函数执行方法
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
        // “NO_LOCAL_WEB_GUIDE_CLOSE” 代表无本地web 引导页，有可能是接口请求失败或其他原因
        if closeType != "NO_LOCAL_WEB_GUIDE_CLOSE" {
         // 可以设置 是否还会再显示引导页
            UserDefaults.standard.set(true, forKey: HasDisplayedGuide)
            UserDefaults.standard.synchronize()
        }
        self.window?.rootViewController =  UINavigationController(rootViewController: ViewController())
        self.window?.backgroundColor = .white
        self.window?.makeKeyAndVisible()
    }
    public func clickGuideTermsAction(baseViewController: UIViewController) {
        print("clickGuideTermsAction")
        
        let vc = LBWebViewController.init()
        vc.url = "url"
        vc.title = NSLocalizedString("Terms_of_Service", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }
    public func clickGuidePrivacyAction(baseViewController: UIViewController) {
        print("clickGuidePrivacyAction")
        
        let vc = LBWebViewController.init()
        vc.url = "url"
        vc.title = NSLocalizedString("Privacy_Policy", comment: "")
        let nav = UINavigationController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        baseViewController.present(nav, animated: true)
    }
    public func clickGuideRestoreButton(baseViewController: UIViewController) {
        print("clickGuideRestoreButton")
    }
    public func clickGuidePurchaseButton(baseViewController: UIViewController) {
        print("clickGuidePurchaseButton")
    }
    public func clickGudieContinueButton(baseViewController: UIViewController, currentIndex: Int, nextIndex: Int, swiperSize: Int) {
        print("clickGudieContinueButton--currentIndex:\(currentIndex) --- nextIndex:\(nextIndex)")
    }
}

//MARK: private method
extension AppDelegate {
    func calculateNewExpiryTime(from products: [[String: Any]]) -> Int {
        var latestExpiry = ""
        for product in products {
            if let expiryDate = product["expiresAt"] as? String {
                latestExpiry = expiryDate > latestExpiry ? expiryDate : latestExpiry
            } else {
                // 非订阅产品，自定义逻辑
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
