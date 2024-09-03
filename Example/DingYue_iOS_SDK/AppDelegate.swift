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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //session report
        DYMobileSDK.defaultConversionValueEnabled = true //use default cv rule
        self.setUpRootVC()

        DYMobileSDK.activate { results, error in
            if error == nil {
                if let res = results {
                    if let hasPurchasedItems = res["subscribedOjects"] as? [[String:Any]] {
                        purchasedProducts = hasPurchasedItems
                                                
                        for sub in DYMobileSDK.getProductItems() ?? [] {
                            print("test ----, AppDelegate getProductItems = \(sub.platformProductId)")
                        }
                    }
                }
            }else {
               
                
                
            }
        }
        //lua 脚本相关
//        TestLuaOperation.sharedInstance().initLua()
        return true
    }
    
    func setUpRootVC() {
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
            print("7666666")
        }
        
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

