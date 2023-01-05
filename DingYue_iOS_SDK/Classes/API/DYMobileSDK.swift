//
//  DingYueMobileSDK.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/10.
//

#if canImport(UIKit)
import UIKit
import FCUUID
import SSZipArchive
import AnyCodable
import StoreKit
import AppTrackingTransparency
#endif

@objc public class DYMobileSDK: NSObject {

    private static let shared = DYMobileSDK()
    
    ///判断是否需要IDFA
    @objc public static var idfaCollectionDisabled: Bool = false
    ///是否已完成配置
    private var isConfigured = false
    ///场景控制器
    private lazy var sessionsManager: SessionsManager = {
        return SessionsManager()
    }()
    ///行为控制器
    private lazy var eventManager: DYMEventManager = {
        return DYMEventManager.shared
    }()
    ///api控制器
    private lazy var apiManager:ApiManager = {
        return ApiManager()
    }()
    ///应用内支付
    private lazy var iapManager:DYMIAPManager = {
        return DYMIAPManager.shared
    }()
    ///推送地址
    @objc public static var apnsToken: Data? {
        didSet {
            shared.apnsTokenStr = apnsToken?.map { String(format: "%02.2hhx", $0) }.joined()
        }
    }

    @objc public static var apnsTokenString: String? {
        guard let token = DYMDefaultsManager.shared.apnsTokenString else {
            return nil
        }
        return token
    }

    private var apnsTokenStr: String? {
        set {
            DYMLogManager.logMessage("Setting APNS token.")
            DYMDefaultsManager.shared.apnsTokenString = newValue
        }
        get {
            return DYMDefaultsManager.shared.apnsTokenString
        }
    }
    // MARK: - Activate SDK
    ///Activate SDK
    @objc public class func activate(completion:@escaping sessionActivateCompletion) {
        //读取DingYue.plist信息
        let path = Bundle.main.path(forResource: DYMConstants.AppInfoName.plistName, ofType: DYMConstants.AppInfoName.plistType)
        guard let plistPath = path else {
            return
        }
        guard let appInfoDictionary = NSMutableDictionary(contentsOfFile: plistPath) else {
            return
        }
        guard let appId = appInfoDictionary.value(forKey: DYMConstants.AppInfoName.appId) as? String, let apiKey = appInfoDictionary.value(forKey: DYMConstants.AppInfoName.apiKey) as? String else{
            return
        }
        DYMConstants.APIKeys.appId = appId
        DYMConstants.APIKeys.secretKey = apiKey

        shared.configure(completion: completion)
    }
    ///Configure
    private func configure(completion:@escaping sessionActivateCompletion) {
        if isConfigured { return }
        isConfigured = true
        performInitialRequests(completion: completion)
        DYMAppDelegateSwizzler.startSwizzlingIfPossible(self)
    }
    ///Initial requests
    private func performInitialRequests(completion:@escaping sessionActivateCompletion) {
        apiManager.completion = completion
        apiManager.startSession()

        iapManager.startObserverPurchase()
        sendAppleSearchAdsAttribution()
    }
    
    func sendAppleSearchAdsAttribution() {
        //IDFA
        if #available(iOS 14.3, *) {
            let state = ATTrackingManager.trackingAuthorizationStatus
            if state == .notDetermined {
                var isSendRequest = false
                NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: .main) { notification in
                    if isSendRequest == false {
                        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                            isSendRequest = true
                            self.reportAppleSearchAdsAttribution()
                        })
                    }
                }
            } else{
                reportAppleSearchAdsAttribution()
            }
        } else {
            reportAppleSearchAdsAttribution()
        }

    }

    // MARK: - idfa
    @objc public class func reportIdfa(idfa:String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.reportIdfa(idfa: idfa) { result, error in
            if error != nil {
                print("(dingyue):report idfa fail, error = \(error!)")
            }

            if result != nil {
                if result?.status == .ok {
                    print("(dingyue):report idfa ok")
                } else {
                    print("(dingyue):report idfa fail, errmsg = \(result?.errmsg ?? "")")
                }
            }
        }
    }

    // MARK: - device token
    @objc public class func reportDeviceToken(token:String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.reportDeviceToken(token: token) { result, error in
            if error != nil {
                print("(dingyue):report DeviceToken fail, error = \(error!)")
            }

            if result != nil {
                if result?.status == .ok {
                    print("(dingyue):report DeviceToken ok")
                } else {
                    print("(dingyue):report DeviceToken fail, errmsg = \(result?.errmsg ?? "")")
                }
            }
        }
    }

    // MARK: - Attribution
    @objc public class func reportAttribution(adjustId:String? = nil,appsFlyerId:String? = nil,amplitudeId:String? = nil) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        let attributes = Attribution(adjustId: adjustId, appsFlyerId: appsFlyerId, amplitudeId: amplitudeId)
        shared.apiManager.reportAttribution(attribution: attributes) { result, error in
            if error != nil {
                print("(dingyue):report Attribution fail, error = \(error!)")
            }

            if result != nil {
                if result?.status == .ok {
                    print("(dingyue):report Attribution ok")
                } else {
                    print("(dingyue):report Attribution fail, errmsg = \(result?.errmsg ?? "")")
                }
            }
        }
    }
#if os(iOS)
    private func reportAppleSearchAdsAttribution() {
        UserProperties.appleSearchAdsAttribution { (attribution, error) in
            // check if this is an actual first sync
            guard let attribution = attribution, DYMDefaultsManager.shared.appleSearchAdsSyncDate == nil else { return }

            func update(attribution: Dictionary<String,Any>, asa: Bool) {
//                var attribution = attribution
//                attribution["asa-attribution"] = asa
                Self.reportSearchAds(attribution: attribution)
            }

            if let values = attribution.values.map({ $0 }).first as? Parameters,
               let iAdAttribution = values["iad-attribution"] as? NSString {
                // check if the user clicked an Apple Search Ads impression up to 30 days before app download
//                if iAdAttribution.boolValue == true {
//                    update(attribution: attribution, asa: false)
//                }
                update(attribution: attribution, asa: false)
            } else {
                update(attribution: attribution, asa: true)
            }
        }
    }
#endif

    private class func reportSearchAds(attribution: DYMParams) {
        let data = AnyCodable(attribution)
        shared.apiManager.updateSearchAdsAttribution(attribution: data) { result, error in
            if error != nil {
                print("(dingyue):report SearchAdsAttribution fail, error = \(error!)")
            }

            if result != nil {
                if result?.status == .ok {
                    print("(dingyue):report SearchAdsAttribution ok")
                } else {
                    print("(dingyue):report SearchAdsAttribution fail, errmsg = \(result?.errmsg ?? "")")
                }
            }
        }
    }

    // MARK: - Subscription
    ///通过产品ID 购买
    @objc public class func purchase(productId: String,completion:@escaping DYMPurchaseCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.iapManager.buy(productId: productId) { purchase, receiptVerifyMobileResponse in
            switch purchase {
            case .succeed(let purchase):
                    if let subs = receiptVerifyMobileResponse {
                        completion(purchase.receipt,subs["subscribledObject"] as? [[String : Any]],nil)
                    } else {
                        completion(purchase.receipt,nil,nil)
                    }
            case .failure(let error):
                completion(nil,nil,error)
            }
        }
    }
    ///通过产品信息购买
    public class func purchase(product: SKProduct,completion:@escaping DYMPurchaseCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.iapManager.buy(product: product) { purchase, receiptVerifyMobileResponse in
            switch purchase {
            case .succeed(let purchase):
                    if let subs = receiptVerifyMobileResponse {
                        completion(purchase.receipt,subs["subscribledObject"] as? [[String : Any]],nil)
                    } else {
                        completion(purchase.receipt,nil,nil)
                    }
            case .failure(let error):
                completion(nil,nil,error)
            }
        }
    }
    ///恢复购买
    @objc public class func restorePurchase(completion: DYMRestoreCompletion? = nil) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.iapManager.restrePurchase { receipt, receiptVerifyMobileResponse, error in
            if let subs = receiptVerifyMobileResponse {
                completion?(receipt,subs["subscribledObject"] as? [[String : Any]],error)
            } else {
                completion?(receipt,nil,error)
            }
        }
    }
    
    #if os(iOS)
    ///展示支付页面
    @objc public class func showVisualPaywall(products:[Subscription]? = nil,rootController: UIViewController, completion:@escaping DYMRestoreCompletion){
        let controller = getVisualPaywall(for: products, completion: completion)
        rootController.present(controller, animated: true)
        controller.delegate = (rootController as? DYMPayWallActionDelegate)
    }

    public class func getVisualPaywall(for products:[Subscription]? = nil,completion: @escaping DYMRestoreCompletion) -> DYMPayWallController {
        let paywallViewController = DYMPayWallController()
        paywallViewController.custemedProducts = products ?? []
        paywallViewController.completion = completion
        paywallViewController.modalPresentationStyle = .fullScreen
        return paywallViewController
    }
    #endif
    ///验证订单-first
    @objc public class func validateReceiptFirst(_ receipt: String,for product:SKProduct?,completion:@escaping FirstReceiptCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.verifySubscriptionFirst(receipt: receipt, for: product, completion: completion)
    }
    ///验证订单-first
    @objc public class func validateReceiptFirstWith(_ receipt: String,for product:Dictionary<String, String>?,completion:@escaping FirstReceiptCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.verifySubscriptionFirstWith(receipt: receipt, for: product, completion: completion)
    }
    ///验证订单-recover
    @objc public class func validateReceiptRecover(_ receipt: String,completion:@escaping RecoverReceiptCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.verifySubscriptionRecover(receipt: receipt, completion: completion)
    }
    /// MARK: - Events
    @objc public class func track(event: String, extra: String? = nil, user: String? = nil) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        if event != "" {
            shared.eventManager.track(event: event, extra: extra, user: user)
        }
    }
    /// MARK: - load native paywall
    @objc public class func loadNativePaywall(paywallFullPath: String,basePath:String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        DYMDefaultsManager.shared.nativePaywallBasePath = basePath
        DYMDefaultsManager.shared.nativePaywallPath = paywallFullPath
    }

    @objc public class func handlePushNotification(_ userInfo: [AnyHashable : Any], completion: Error?) {
        DYMLogManager.logMessage("Calling now: \(#function)")

        guard let source = userInfo[DYMConstants.NotificationPayload.source] as? String, source == "adapty" else {
            DispatchQueue.main.async {
            }
            return
        }

        var params = [String: String]()
        if let promoDeliveryId = userInfo[DYMConstants.NotificationPayload.promoDeliveryId] as? String {
            params[DYMConstants.NotificationPayload.promoDeliveryId] = promoDeliveryId
        }
    }

    //request switch status with switch name
    @objc public class func getSwitchStatus(switchName: String)->Bool {
        guard let switchItems = DYMDefaultsManager.shared.cachedSwitchItems else {
            return false
        }
        for dic in switchItems {
            if dic.variableName == switchName {
                return dic.variableValue
            }
        }
        return false
    }
    
    /// MARK: - Switchs info
    @objc public class func createGlobalSwitch(globalSwitch: GlobalSwitch,completion:@escaping ((SimpleStatusResult?,Error?)->())) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        #if DEBUG
        shared.apiManager.addGlobalSwitch(globalSwitch: globalSwitch, complete: completion)
        #else
        completion(nil,nil)
        #endif
    }

    ///MARK: - request device unique uuid
    @objc public class func requestDeviceUUID() -> String {
        DYMLogManager.logMessage("Calling now: \(#function)")
        return UserProperties.requestUUID
    }
}

extension DYMobileSDK: DYMAppDelegateSwizzlerDelegate {

    func didReceiveAPNSToken(_ deviceToken: Data) {
        Self.apnsToken = deviceToken
        if let token = self.apnsTokenStr {
            Self.reportDeviceToken(token: token)
        }
    }
}
