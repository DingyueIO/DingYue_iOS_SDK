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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //session report
        DYMobileSDK.activate { results, error in
            if error == nil {
                if let result = results {
                    if let isUseNativePaywall = result["isUseNativePaywall"] as? Bool, let nativePaywallId = result["nativePaywallId"] as? String {
                        if isUseNativePaywall == true {
                            let filePath1 = Bundle.main.path(forResource: "index", ofType: ".html", inDirectory: nativePaywallId)
//                            DYMobileSDK.loadNativePaywall(paywallFullPath: filePath1!, basePath: Bundle.main.bundlePath + nativePaywallId)
                        }
                    }
                }
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日HH时mm分ss秒"
        formatter.timeZone = TimeZone(abbreviation: "UTC+8")

        let nowDate = NSDate(timeIntervalSinceNow: 0) as Date
        print("时间戳转日期 = \(formatter.string(from: nowDate))")
        let name = "Dingyue-Launch@" + "\(formatter.string(from: nowDate))"
        DYMobileSDK.track(event: name)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
