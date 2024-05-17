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
        DYMobileSDK.activate(encryptionKey: dingyueKeyStr) { results, error in
            if error == nil {
                if let res = results {
                    if let hasPurchasedItems = res["subscribedOjects"] as? [[String:Any]] {
                        purchasedProducts = hasPurchasedItems
                                                
                        for sub in DYMobileSDK.getProductItems() ?? [] {
                            print("test ----, AppDelegate getProductItems = \(sub.platformProductId)")
                        }
                    }
                }
            }
        }
        return true
    }
}
