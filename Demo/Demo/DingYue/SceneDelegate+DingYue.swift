//
//  SceneDelegate+DingYue.swift
//  QRScanner
//
//  Created by TJ on 2025/1/8.
//

import DingYue_iOS_SDK

extension SceneDelegate:DYMWindowManaging, DYMGuideActionDelegate {
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
//            UserDefaults.standard.set(true, forKey: HasDisplayedGuide)
//            UserDefaults.standard.synchronize()
        }
        IWDingYueManager.newGuideToNext()
    }
    public func clickGuideTermsAction(baseViewController: UIViewController) {
        print("clickGuideTermsAction")
//        AGWebVC.showProtocol(.terms)
    }
    public func clickGuidePrivacyAction(baseViewController: UIViewController) {
        print("clickGuidePrivacyAction")
//        AGWebVC.showProtocol(.policy)
    }
    public func clickGuideRestoreButton(baseViewController: UIViewController) {
        print("clickGuideRestoreButton")
        IWDingYueManager.shared._handleType = .restore
    }
    public func clickGuidePurchaseButton(baseViewController: UIViewController) {
        print("clickGuidePurchaseButton")
        IWDingYueManager.shared._handleType = .purchase
    }
    public func clickGudieContinueButton(baseViewController: UIViewController, currentIndex: Int, nextIndex: Int, swiperSize: Int) {
        print("clickGudieContinueButton--currentIndex:\(currentIndex) --- nextIndex:\(nextIndex)")
    }
    
}
