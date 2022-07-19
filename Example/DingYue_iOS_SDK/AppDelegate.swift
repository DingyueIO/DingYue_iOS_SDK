//
//  AppDelegate.swift
//  DingYue_iOS_SDK
//
//  Created by DingYueIO on 07/07/2022.
//  Copyright (c) 2022 DingYueIO. All rights reserved.
//

import UIKit
import AdSupport
import AppTrackingTransparency
import DingYue_iOS_SDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //session report
        DYMobileSDK.activate { switchItems, subscribedOjects, error in
            if error == nil {
                //激活成功
                print("DingYue_iOS_SDK 激活成功")
            } else {
                print("DingYue_iOS_SDK 激活失败 ---- \(error!)")
            }
        }
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
        requestIDFA()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

extension AppDelegate {
    func requestIDFA() {
        //IDFA权限
        if #available(iOS 14, *) {
            let state = ATTrackingManager.trackingAuthorizationStatus
            if state == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                    var idfa = ""
                    if status == .authorized {
                        idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                    }
                    DYMobileSDK.reportIdfa(idfa: idfa)
                })
            }else if state == .authorized {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                DYMobileSDK.reportIdfa(idfa: idfa)
            }else{
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                DYMobileSDK.reportIdfa(idfa: idfa)
            }
        } else {
            DYMobileSDK.reportIdfa(idfa: ASIdentifierManager.shared().advertisingIdentifier.uuidString)
        }
    }
}
