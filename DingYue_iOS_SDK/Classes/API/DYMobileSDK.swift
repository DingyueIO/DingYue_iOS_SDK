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
import AdSupport
#endif

@objc public class DYMobileSDK: NSObject {
    
    private static let shared = DYMobileSDK()
    
    ///判断是否需要IDFA
    @objc public static var idfaCollectionDisabled: Bool = false
    ///判断是否使用默认CV规则
    @objc public static var defaultConversionValueEnabled: Bool = false
    ///是否使用通知(默认启用)
    @objc public static var enableRemoteNotifications: Bool = true
    /// 是否启用自动获取并使用域名 (默认关闭)。
    /// 注意：
    /// - 启用后，会从缓存中加载域名到 `basePath`，仅在当前 `basePath` 为空时生效。
    /// - 如果在开启后，再次手动设置 `basePath`，手动设置的值将优先使用。
    @objc public static var enableAutoDomain:Bool = false {
        didSet {
            if enableAutoDomain,basePath.isEmpty {
                if let path = DYMDefaultsManager.shared.cachedDomainName, !path.isEmpty {
                    basePath = path
                }
            }
        }
    }
    ///手动设置固定path
    @objc public static var basePath:String = "" {
        didSet {
            if !basePath.isEmpty {
                OpenAPIClientAPI.basePath = basePath
            }
        }
    }
    ///手动设置用户uuid
    @objc public static var UUID:String = "" {
        didSet {
            if !UUID.isEmpty {
                UserProperties.requestUUID = UUID
            }
        }
    }

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
        performInitialRequests(completion: completion)
        if DYMobileSDK.enableRemoteNotifications {
            DYMAppDelegateSwizzler.startSwizzlingIfPossible(self)
        }
    }
    ///Initial requests
    private func performInitialRequests(completion:@escaping sessionActivateCompletion) {
        apiManager.completion = completion
        apiManager.startSession()

        iapManager.startObserverPurchase()
        
        sendAppleSearchAdsAttribution()
    }

    // MARK: - idfa
    @objc public class func reportIdfa(idfa:String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.reportIdfa(idfa: idfa) { result, error in
        }
    }

    // MARK: - device token
    @objc public class func reportDeviceToken(token:String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.reportDeviceToken(token: token) { result, error in
        }
    }

    // MARK: - Attribution
    @objc public class func reportAttribution(adjustId:String? = nil,appsFlyerId:String? = nil,amplitudeId:String? = nil) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        let attributes = Attribution(adjustId: adjustId, appsFlyerId: appsFlyerId, amplitudeId: amplitudeId)
        shared.apiManager.reportAttribution(attribution: attributes) { result, error in
        }
    }
#if os(iOS)
    private func reportAppleSearchAdsAttribution() {
        UserProperties.appleSearchAdsAttribution { (attribution, error) in
            print(attribution)
            Self.reportSearchAds(attribution: attribution)
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
    @objc public class func purchase(productId: String, productPrice:String? = nil, completion:@escaping DYMPurchaseCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.iapManager.productQuantity = 1
        shared.iapManager.buy(productId: productId) { purchase, receiptVerifyMobileResponse in
            switch purchase {
            case .succeed(let purchase):
                if self.defaultConversionValueEnabled && productPrice != nil  {
                    self.updateCVWithTargetProductPrice(price: productPrice!)
                }
                
                if let subs = receiptVerifyMobileResponse {
                    //更新用户属性 --- 以甄别购买来源是通过内购页还是直接调用API
                    shared.apiManager.updateUserProperties()
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
    @objc public class func showVisualPaywall(products:[Subscription]? = nil,rootController: UIViewController, extras:[String:Any]? = nil, completion:@escaping DYMRestoreCompletion){
        let controller = getVisualPaywall(for: products, extras: extras, completion: completion)
        rootController.present(controller, animated: true)
        controller.delegate = (rootController as? DYMPayWallActionDelegate)
    }

    public class func getVisualPaywall(for products:[Subscription]? = nil, extras:[String:Any]? = nil, completion: @escaping DYMRestoreCompletion) -> DYMPayWallController {
        let paywallViewController = DYMPayWallController()
        paywallViewController.custemedProducts = products ?? []
        paywallViewController.extras = extras
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
    // MARK: - Events
    @objc public class func track(event: String, extra: String? = nil, user: String? = nil) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        if event != "" {
            if DYMConstants.APIKeys.appId == "" || DYMConstants.APIKeys.secretKey == "" {
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
            }
            shared.eventManager.track(event: event, extra: extra, user: user)
        }
    }
    // MARK: - Load native paywall
    @objc public class func loadNativePaywall(paywallFullPath: String,basePath:String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        DYMDefaultsManager.shared.nativePaywallBasePath = basePath
        DYMDefaultsManager.shared.nativePaywallPath = paywallFullPath
    }
    // MARK: - Default paywall
    @objc public class func setDefaultPaywall(paywallFullPath: String,basePath:String) {
        DYMDefaultsManager.shared.defaultPaywallPath = paywallFullPath
    }
    //MARK: - Handle remote notification
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

    // MARK: - Switchs
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
    
    ///Golbal Switch
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
    
    //MARK: - private method
    private func sendAppleSearchAdsAttribution() {
        //IDFA
        if #available(iOS 14, *) {
            let state = ATTrackingManager.trackingAuthorizationStatus
            if state == .notDetermined {
                self.reportAppleSearchAdsAttribution()
                NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: .main) { notification in
                    ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                        self.reportAppleSearchAdsAttribution()
                        
                        if status == .authorized {
                            Self.reportIdfa(idfa: ASIdentifierManager.shared().advertisingIdentifier.uuidString)
                        }
                    })
                }
            } else {
                reportAppleSearchAdsAttribution()
                if state == .authorized {
                    Self.reportIdfa(idfa: ASIdentifierManager.shared().advertisingIdentifier.uuidString)
                }
            }
        } else {
            reportAppleSearchAdsAttribution()
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                Self.reportIdfa(idfa: ASIdentifierManager.shared().advertisingIdentifier.uuidString)
            }
        }
    }
    
    private class func updateCVWithTargetProductPrice(price:String) {
        let sdkBundle = Bundle(for: DYMobileSDK.self)
        guard let resourceBundleURL = sdkBundle.url(forResource: "DingYue_iOS_SDK", withExtension: "bundle")else { fatalError("DingYue_iOS_SDK.bundle not found, do not get conversion value data.") }
        guard let resourceBundle = Bundle(url: resourceBundleURL)else { fatalError("Cannot access DingYue_iOS_SDK.bundle,do not do not get conversion value data.") }
        if let path = resourceBundle.path(forResource: "DingYueConversionValueMap", ofType: "plist") {
            if let appInfoDictionary = NSMutableDictionary(contentsOfFile: path) {
                if let valueArray = appInfoDictionary.allKeys as? [String] {
                    if valueArray.contains(price) {
                        let value = appInfoDictionary[price] as? Int ?? 0
                        DYMobileSDK.shared.updateConversionValueWithDefaultRule(value: value)
                    }
                }
            }
        }
    }
    
    
    func updateConversionValueWithDefaultRule(value: Int) {
        //update conversion value
        if #available(iOS 16.1, *) {
            
        #if compiler(>=5.7)
            var coarse = SKAdNetwork.CoarseConversionValue.low
            var coarseDY = ConversionRequest.CoarseValue.low
            if value <= 21 {
                coarse = SKAdNetwork.CoarseConversionValue.low
                coarseDY = ConversionRequest.CoarseValue.low
            } else if value > 21 && value <= 42 {
                coarse = SKAdNetwork.CoarseConversionValue.medium
                coarseDY = ConversionRequest.CoarseValue.medium
            } else { //>42
                coarse = SKAdNetwork.CoarseConversionValue.high
                coarseDY = ConversionRequest.CoarseValue.high
            }
            SKAdNetwork.updatePostbackConversionValue(value, coarseValue: coarse, lockWindow: false) { error in
                print("dingyue cv iOS 16.1 * compiler high value is \(value)")
                
                DYMobileSDK.shared.apiManager.reportConversionValue(cv: value, coarseValue: coarseDY)
            }
        #else
            SKAdNetwork.updatePostbackConversionValue(value) { error in
                print("dingyue cv iOS 16.1 * compiler low value is \(value)")
                DYMobileSDK.shared.apiManager.reportConversionValue(cv: value)
            }
        #endif
            
        } else {
            // Fallback on earlier versions
            if #available(iOS 15.4, *) {
                SKAdNetwork.updatePostbackConversionValue(value) { error in
                    print("dingyue cv iOS 15.4 * value is \(value)")
                    DYMobileSDK.shared.apiManager.reportConversionValue(cv: value)
                }
 
            } else {
                // Fallback on earlier versions
                if #available(iOS 14.0, *) {
                    SKAdNetwork.updateConversionValue(value)
                    DYMobileSDK.shared.apiManager.reportConversionValue(cv: value)
                    print("dingyue cv iOS 14.0 * value is \(value)")
                } else {
                    // Fallback on earlier versions
                    if #available(iOS 11.3, *) {
                        SKAdNetwork.registerAppForAdNetworkAttribution()
                        DYMobileSDK.shared.apiManager.reportConversionValue(cv: 0)
                    }
                }
            }
        }
    }
    
    @objc public class func getProductItems() -> [Subscription]? {
        return DYMDefaultsManager.shared.cachedProducts
    }
}

// MARK: - Consume
extension DYMobileSDK {
    @objc public class func purchaseConsumption(productId:String, count:Int,productPrice:String? = nil, completion:@escaping DYMPurchaseCompletion) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.iapManager.productQuantity = count
        shared.iapManager.buy(productId: productId) { purchase, receiptVerifyMobileResponse in
            switch purchase {
            case .succeed(let purchase):
                if self.defaultConversionValueEnabled && productPrice != nil  {
                    self.updateCVWithTargetProductPrice(price: productPrice!)
                }

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
}

extension DYMobileSDK: DYMAppDelegateSwizzlerDelegate {

    func didReceiveAPNSToken(_ deviceToken: Data) {
        Self.apnsToken = deviceToken
        if let token = self.apnsTokenStr {
            Self.reportDeviceToken(token: token)
            print("token - \(token)")
        }
    }
}
//MARK: Guide 引导页相关
extension DYMobileSDK {
    // MARK: - Load native guide
    @objc public class func loadNativeGuidePage(paywallFullPath: String,basePath:String) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        DYMDefaultsManager.shared.isUseNativeGuide = true
        DYMDefaultsManager.shared.guideLoadingStatus = true
        DYMDefaultsManager.shared.nativeGuideBasePath = basePath
        DYMDefaultsManager.shared.nativeGuidePath = paywallFullPath
    }
    // MARK: - Default guide
    @objc public class func setDefaultGuidePage(paywallFullPath: String,basePath:String) {
        DYMDefaultsManager.shared.defaultGuidePath = paywallFullPath
    }
    // MARK:
    #if os(iOS)
    /// 显示引导页
//    @objc public class func showVisualGuide(products: [Subscription]? = nil, rootAppdelegate: UIApplicationDelegate, extras: [String: Any]? = nil, completion: @escaping DYMRestoreCompletion) {
//        guard let appDelegate = UIApplication.shared.delegate  else {
//            fatalError("UIApplication.shared.delegate is not of type AppDelegate")
//        }
//
//        let guideController = getVisualGuide(for: products, extras: extras, completion: completion)
//        guideController.delegate = rootAppdelegate as? DYMGuideActionDelegate
//        
//        appDelegate.window??.rootViewController = guideController
//        appDelegate.window??.makeKeyAndVisible()
//
//    }
    @objc public class func showVisualGuide(products: [Subscription]? = nil, rootDelegate: DYMWindowManaging, extras: [String: Any]? = nil, completion: @escaping DYMRestoreCompletion) {
        let guideController = getVisualGuide(for: products, extras: extras, completion: completion)
        guideController.delegate = rootDelegate as? DYMGuideActionDelegate

        guard let window = rootDelegate.window else {
            // 如果没有找到窗口，创建一个新的 UIWindow
           print("No key window found. Creating a new UIWindow.")
           let newWindow = UIWindow(frame: UIScreen.main.bounds)
           newWindow.rootViewController = guideController
           newWindow.backgroundColor = .white
           newWindow.makeKeyAndVisible()
           // 你可以在这里添加额外的处理，比如通知或者日志记录
           print("A new UIWindow has been created and set.")
           return
        }

        window.rootViewController = guideController
        window.makeKeyAndVisible()
    }
    public class func getVisualGuide(for products: [Subscription]? = nil, extras: [String: Any]? = nil, completion: @escaping DYMRestoreCompletion) -> DYMGuideController {
        let guideController = DYMGuideController()
        guideController.custemedProducts = products ?? []
        guideController.extras = extras
        guideController.completion = completion
        guideController.modalPresentationStyle = .fullScreen
        return guideController
    }
    #endif
}

//MARK: SetCustomProperties
extension DYMobileSDK {
    @objc public class func setCustomPropertiesWith(_ customProperties:NSDictionary,completion:@escaping ((SimpleStatusResult?,Error?)->())) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        let propertiesDict = customProperties as? [String: Any?] ?? [:]        
        shared.apiManager.setCustomProperties(customProperties: propertiesDict) { result, error in
            completion(result,error)
        }
    }
}
//MARK: GetAppSegmentInfo
extension DYMobileSDK {
    @objc public class func getSegmentInfo(completion:@escaping((SegmentInfoResult?,Error?)->())) {
        DYMLogManager.logMessage("Calling now: \(#function)")
        shared.apiManager.getSegmentInfo { result, error in
            completion(result,error)
        }
    }
}
