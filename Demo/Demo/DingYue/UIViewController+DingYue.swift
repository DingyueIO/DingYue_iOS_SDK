//
//  UIViewController+DingYue.swift
//  QRScanner
//
//  Created by TJ on 2025/1/8.
//

import UIKit
import DingYue_iOS_SDK

extension UIViewController:DYMPayWallActionDelegate {

    //点击内购页上的关闭按钮
    public func clickCloseButton(baseViewController: UIViewController) {
        
    }
    
    //内购页显示
    public func payWallDidAppear(baseViewController: UIViewController) {

    }
    //内购页消失
    public func payWallDidDisappear(baseViewController: UIViewController) {
        if IWDingYueManager.shared._isPush == true {
            IWDingYueManager.shared._isPush = false
            return
        }
        if IWDingYueManager.shared._preparePushQRCodeVC {
            IWDingYueManager.shared._preparePushQRCodeVC = false
            IWDingYueManager.toMainPage()
        }
        IWDingYueManager.dingYuePageDismissComplete()
    }
    //购买
    public func clickPurchaseButton(baseViewController:UIViewController) {
        IWDingYueManager.shared._handleType = .purchase
    }
    //恢复
    public func clickRestoreButton(baseViewController:UIViewController) {
        IWDingYueManager.shared._handleType = .restore
    }
    //服务条款
    public func clickTermsAction(baseViewController: UIViewController) {
        IWDingYueManager.shared._isPush = true
//        AGWebVC.showProtocol(.terms)
    }
    //隐私政策
    public func clickPrivacyAction(baseViewController: UIViewController) {
        IWDingYueManager.shared._isPush = true
//        AGWebVC.showProtocol(.policy)
    }
}

