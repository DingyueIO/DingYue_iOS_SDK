//
//  IWDingYueManager.swift
//  AMDT
//
//  Created by TJ on 2024/9/26.
//

import DingYue_iOS_SDK
//import KakaJSON


enum IWDingYuePageHandleType {
    case purchase
    case restore
}

enum IWDingYuePageNameType:String {
    case createQrcode
    case sub0
    case sub1
    case sub2
}

enum IWDingYuePageActionType:String {
    case see_more
}

class IWDingYueManager:NSObject {
    
    static var shared = IWDingYueManager()
    
    var _dismissComplete: AG_BLANK_BLOCK?
    var _chatPremiumResultSuccess: AG_BLANK_BLOCK?
    var _auto_pay:Bool = false
    //是否准备push聊天页
    var _preparePushQRCodeVC:Bool = false
    var _subscribeSuccess:Bool = false
    var _handleType:IWDingYuePageHandleType = .purchase
    var _receipt: String?
    var _purchaseResult: [[String:Any]]?
    var _isPush:Bool = false
    var _switchs:[String:Bool]?
    
    static var toQRcodeVCing = false
    
    static var mainPage:UINavigationController?

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static func getUID() -> String {
        return UserProperties.requestUUID
    }
    
    static func getAppID() -> String {
        return UserProperties.requestAppId
    }
    
    static func config(success:AG_BLANK_BLOCK?, failed:AG_BLANK_BLOCK?) {
        DYMobileSDK.basePath = "https://mobile.aifire.info"
//        let uid = getUID()
//        AGLog("tj``:UID: \(uid) AppID: ")
        
        //1. 第一次激活
        DYMobileSDK.activate { results, error in
            print("DingYueSDK第一次激活日志：\(results ?? [:]), \nerror: \(error)")
            guard error == nil else {
                failed?()
                return
            }

            dealActiveResult(results)
            success?()
        }
    }
    
    static private func dealActiveResult(_ results:[String:Any]?) {
        if let result = results {
            //开关
            var dic = [String:Bool]()
            if let globalSwitchItems = result["globalSwitchItems"] as? [GlobalSwitch] {
                print("DYMobileSDK:activate:globalSwitchItems: \(globalSwitchItems)")
            }
            if let switchs = result["switchs"] as? [SwitchItem] {
                print("DYMobileSDK:activate:switchs: \(switchs)")
                dic = switchItemListToDic(switchs, dic: dic)
            }
//            switchItemDicToObject(dic: dic)
            
            if let configurations = result["configurations"] as? [[String:Any]] {
                
            }
            
            //购买过的有效产品
            if let subscribedOjects = result["subscribedOjects"] as? [[String:Any]] {
                print("DYMobileSDK:activate:subscribedOjects: \(subscribedOjects)")
                //subscribedOject["platformProductId"]
                //subscribedOject["originalTransactionId"]
                //subscribedOject["expiresAt"]
                if subscribedOjects.count > 0 {
                    
                    print("购买过有效产品")
                }else{
                    print("没有购买过有效产品")
                }
            }else{
                print("没有购买过有效产品")
            }
            
            //是否使用本地内购页
            if let isUseNativePaywall = result["isUseNativePaywall"] as? Bool {
                //本地内购页ID（须和内购页包名一致）
                if let nativePaywallId = result["nativePaywallId"] as? String {
                    //使用本地内购页的话，需要工程师提前通过‘loadNativePaywall(paywallFullPath: String,basePath:String)’方法设置本地内购页Path
                }
            }
        }
    }
    
//    static private func setCustomProperties(success:AG_BLANK_BLOCK?, failed:AG_BLANK_BLOCK?) {
//        DYMobileSDK.setCustomPropertiesWith(IWDingYueViewModel.shared.customProperties) { result, error in
//            if error == nil {
//                AGLog("DingYueSDK-设置自定义参数成功:\(result?.status))")
//                success?()
//            }else{
//                AGLog("DingYueSDK-设置自定义参数失败:\(error?.localizedDescription)")
//                failed?()
//            }
//        }
//    }
    
//    static func DingYueCreateSwitch() {
//        //远程开关：在开发阶段工程师利用'DYMobileSDK.createGlobalSwitch(globalSwitch: , completion:)' 方法创建的远程开关
//        let DingYuePayPageSwitch = GlobalSwitch(showName: "DingYuePayPageSwitch", varName: "DingYuePayPageSwitch", value: true)
//        let DingYueGuidePageSwitch = GlobalSwitch(showName: "DingYueGuidePageSwitch", varName: "DingYueGuidePageSwitch", value: true)
//        let DingYueVideoPageSwitch = GlobalSwitch(showName: "DingYueVideoPageSwitch", varName: "DingYueVideoPageSwitch", value: true)
//        DYMobileSDK.createGlobalSwitch(globalSwitch: DingYuePayPageSwitch) { result, error in
//            makeNurseLog("test_switch_01创建开关结果：\(result), 错误：\(error)")
//        }
//        DYMobileSDK.createGlobalSwitch(globalSwitch: DingYueGuidePageSwitch) { result, error in
//            makeNurseLog("test_switch_02创建开关结果：\(result), 错误：\(error)")
//        }
//        DYMobileSDK.createGlobalSwitch(globalSwitch: DingYueVideoPageSwitch) { result, error in
//            makeNurseLog("test_switch_02创建开关结果：\(result), 错误：\(error)")
//        }
//    }
    
    static func showAndPreparePushQRCodeVC() {
        
        shared._preparePushQRCodeVC = true
        shared._subscribeSuccess = false
        
        showDingYuePayPage()
    }
    
    static func showDingYuePayPage(chatPremiumResultSuccess:AG_BLANK_BLOCK? = nil, dismissComplete: AG_BLANK_BLOCK? = nil) {
        guard let fromVC = UIViewController.ag_current, fromVC.classForCoder != DYMPayWallController.self else {return}
        
        shared._chatPremiumResultSuccess = chatPremiumResultSuccess
        shared._dismissComplete = dismissComplete
        
        DispatchQueue.main.async {
            
            DYMobileSDK.showVisualPaywall(products: [], rootController: fromVC, extras: nil) { receipt, purchasedResult, error in
//                if error == nil { //购买成功
//                    subscribeSuccess(purchaseResult:purchasedResult)
//                }else{
//                    subscribeFailed()
//                }
            }
        }
    }
    
    static func showDingYueGuidePage(fromVC: UIViewController? = nil) {
            DispatchQueue.main.async {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard let sceneDelegate = UIWindow.ag_sceneDelegate else {
                        print("场景代理为空")
                        return
                    }
                    
                    // 使用传入的控制器或者尝试获取当前控制器
                    let currentVC = fromVC ?? UIViewController.ag_current
                    guard let currentVC = currentVC else {
                        print("当前控制器为空")
                        return
                    }
                    
                    guard let navController = currentVC.navigationController else {
                        print("导航控制器为空")
                        return
                    }
                    
                    print("准备显示引导页")
                    print("当前控制器: \(currentVC)")
                    print("导航控制器: \(navController)")
                    
                    mainPage = navController
                    DYMobileSDK.showVisualGuide(rootDelegate: sceneDelegate, extras: nil) { receipt, purchaseResult, error in
//                        if error == nil {
//                            subscribeSuccess(purchaseResult:purchaseResult)
//                        }else{
//                            subscribeFailed()
//                        }
                    }
                }
            }
        }
    
    static func restorePurchase(chatPremiumResultSuccess:AG_BLANK_BLOCK? = nil) {
        
        shared._chatPremiumResultSuccess = chatPremiumResultSuccess
        shared._handleType = .restore
        
        DYMobileSDK.restorePurchase(completion: { receipt, result, error in
//            if error == nil {
//                subscribeSuccess(purchaseResult: result)
//                return
//            }
//            subscribeFailed()
        })
    }
    
    static private func switchItemListToDic(_ list:[SwitchItem], dic:[String:Bool]) -> [String:Bool] {
//        var list = dealGuideSwitchOnlyOne(list)
        var dic = dic
        
        list.forEach { item in
            dic[item.variableName] = item.variableValue
        }
        return dic
    }
    
    
}


extension IWDingYueManager {
    
    static func dingYuePageDismissComplete() {
        if shared._subscribeSuccess {
            shared._subscribeSuccess = false
            shared._chatPremiumResultSuccess?()
        }else{
            shared._dismissComplete?()
        }
        shared._chatPremiumResultSuccess = nil
        shared._dismissComplete = nil
    }
    
    static func toMainPage() {
        if toQRcodeVCing {return}
        toQRcodeVCing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            toQRcodeVCing = false
        }
        DispatchQueue.main.async {
            let vc = HomeVC()
            let nav = VRNavigationController(rootViewController: vc)
            UIWindow.ag_keyWindow?.rootViewController = nav
        }
    }
    
    static func newGuideToNext() {
//        if IWDingYueViewModel.shared.switchObject.open_dingyue {
//            showAndPreparePushQRCodeVC()
//        }else{
            toMainPage()
//        }
    }
    
    static func dismissMainPage() {
        if let mainPage = IWDingYueManager.mainPage {
            print("mainPage存在: \(mainPage)")
            // 因为引导页是设置为rootViewController，所以我们需要把mainPage设置回去
            if let window = UIWindow.ag_keyWindow {
                print("获取到keyWindow: \(window)")
                window.rootViewController = mainPage
                window.makeKeyAndVisible()
            } else {
                print("⚠️ 未能获取到keyWindow")
            }
        } else {
            print("⚠️ mainPage为空")
        }
    }
    
}
