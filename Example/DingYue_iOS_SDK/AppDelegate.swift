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
        DYMobileSDK.defaultConversionValueEnabled = true //use default cv rule
        //进行配置
     
       
        DYMConfiguration.shared.guidePageConfig.indicatorColor = .orange
        /*
         连续请求10次失败之后 将会进入之前下载的默认引导页(如果没有默认下载的引导页，则需要在clickGuideCloseButton代理中，设置下一步操作，例如，进入主页，
         也可以 在sdk回调中进行设置。可根据 nativeGuidePageId 进行判断 （ 未返回，或者为空  代表未配置 web引导页） 可设置为 切换到原生引导页。
         如果不设置，则会在网络成功的情况下进入web 引导页
         */
        self.showWebGuideVC()
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
                        // 手动指定本地h5路径
                        // 或者 原生 引导页面
                        self.setRootVC()
                        // 本地web guide
                        // self.setLocalGuidePaths()
  
                    }else {
                      // 如果配置 则 自动加载 引导页 或者进入主页
                        if UserDefaults.standard.bool(forKey: HasDisplayedGuide) {
                            self.window?.backgroundColor = .white
                            self.window?.rootViewController = ViewController()
                        }
                    }
                }
                
            }else {
                // 接口请求失败的话，会自动调用 clickGuideCloseButton 代理。 closetype 是 “NO_LOCAL_WEB_GUIDE_CLOSE”
                self.setRootVC()
            }
            

        }
        //lua 脚本相关
//        TestLuaOperation.sharedInstance().initLua()
        return true
    }
    
    func showWebGuideVC() {
      
        
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
        DYMobileSDK.showVisualGuide(products: [defaultProuct1,defaultProuct2],rootAppdelegate:self,extras: extra) { receipt, purchaseResult, error in
            print("进入主页")
            self.window?.rootViewController = ViewController()
            self.window?.backgroundColor = .white
            self.window?.makeKeyAndVisible()
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
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        if UserDefaults.standard.bool(forKey: HasDisplayedGuide) {
            self.window?.rootViewController = ViewController()
        }else{
            // 原生引导页
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

extension AppDelegate:DYMGuideActionDelegate {
   
    public func guideDidAppear(baseViewController: UIViewController) {
        print("guideDidAppear")
    }
    public func guideDidDisappear(baseViewController: UIViewController) {
        print("guideDidDisappear")
    }
 
    public func clickGuideCloseButton(baseViewController: UIViewController, closeType: String) {
        print("clickGuideCloseButton---closeType--\(closeType)")
        if closeType != "NO_LOCAL_WEB_GUIDE_CLOSE" {
         // 可以设置 是否还会再显示引导页
            UserDefaults.standard.set(true, forKey: HasDisplayedGuide)
            UserDefaults.standard.synchronize()
        }
        self.window?.rootViewController = ViewController()
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

