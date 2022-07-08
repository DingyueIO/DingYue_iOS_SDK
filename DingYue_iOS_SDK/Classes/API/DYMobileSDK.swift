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
            shared.apnsTokenString = apnsToken?.map { String(format: "%02.2hhx", $0) }.joined()
        }
    }

    @objc public static var apnsTokenString: String? {
        didSet {
            shared.apnsTokenString = apnsTokenString
        }
    }

    private var apnsTokenString: String? {
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
        //读取DingYueService-Info.plist信息
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
        #if os(iOS)
        // check if user enabled apple search ads attribution collection
        if let appleSearchAdsAttributionCollectionEnabled = Bundle.main.infoDictionary?[DYMConstants.BundleKeys.appleSearchAdsAttributionCollectionEnabled] as? Bool, appleSearchAdsAttributionCollectionEnabled {
            reportAppleSearchAdsAttribution()
        }
        #endif
    }

    // MARK: - Attribution
    @objc public class func reportAttribution(adjustId:String? = nil,appsFlyerId:String? = nil,amplitudeId:String? = nil) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        let attributes = Attribution(adjustId: adjustId, appsFlyerId: appsFlyerId, amplitudeId: amplitudeId)
        shared.apiManager.reportAttribution(attribution: attributes) { result, error in
            print("----attribution report response-----\(result)")
        }
    }
#if os(iOS)
    private func reportAppleSearchAdsAttribution() {
        UserProperties.appleSearchAdsAttribution { (attribution, error) in
            print("apple search ads attribution : ",attribution as Any)
            // check if this is an actual first sync
            guard let attribution = attribution, DYMDefaultsManager.shared.appleSearchAdsSyncDate == nil else { return }

            func update(attribution: Dictionary<String,Any>, asa: Bool) {
                var attribution = attribution
                attribution["asa-attribution"] = asa
                Self.reportSearchAds(attribution: attribution)
            }

            if let values = attribution.values.map({ $0 }).first as? Parameters,
               let iAdAttribution = values["iad-attribution"] as? NSString {
                // check if the user clicked an Apple Search Ads impression up to 30 days before app download
                if iAdAttribution.boolValue == true {
                    update(attribution: attribution, asa: false)
                }
            } else {
                update(attribution: attribution, asa: true)
            }
        }
    }
#endif

    private class func reportSearchAds(attribution: DYMParams) {
        let data = AnyCodable(attribution)
        shared.apiManager.updateSearchAdsAttribution(attribution: data) { result, error in
            
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
    @objc public class func purchase(product: SKProduct,completion:@escaping DYMPurchaseCompletion) {
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
    @objc public class func showVisualPaywall(for products:[Subscription]? = nil,in rootController: UIViewController, completion:@escaping DYMRestoreCompletion){
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
    ///验证订单-first-swift
    @objc public class func validateReceiptFirst(_ receipt: String,for product:SKProduct?,completion:@escaping FirstReceiptCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.verifySubscriptionFirst(receipt: receipt, for: product, completion: completion)
    }
    ///验证订单-recover-swift
    @objc public class func validateReceiptRecover(_ receipt: String,completion:@escaping RecoverReceiptCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.verifySubscriptionRecover(receipt: receipt, completion: completion)
    }
    /// MARK: - Events
    @objc public class func track(event: Int, extra: String = "", user: String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.eventManager.track(event: DYMEventType(rawValue: event)!, extra: extra, user: user)
    }
    /// MARK: - User Attributes
    @objc public class func customUser(attributes:[String],completion:((Bool,DYMError?)-> Void)? = nil) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.updateUser(attributes: attributes, completion: completion)
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
}

extension DYMobileSDK: DYMAppDelegateSwizzlerDelegate {

    func didReceiveAPNSToken(_ deviceToken: Data) {
        Self.apnsToken = deviceToken
    }

}
