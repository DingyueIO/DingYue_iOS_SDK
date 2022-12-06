//
//  ApiManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/25.
//

import Foundation
import AnyCodable
import SSZipArchive
import StoreKit

public typealias ErrorCompletion = (ErrorResponse?) -> Void
public typealias AdsCompletion = (SimpleStatusResult?,Error) -> Void
public typealias FirstReceiptCompletion = ([String:Any]?,Error?) -> Void
public typealias RecoverReceiptCompletion = ([String:Any]?,Error?) -> Void
//public typealias sessionActivateCompletion = ([SwitchItem]?,[[String:Any]]?,Bool?,String?,Error?) -> Void
public typealias sessionActivateCompletion = ([String:Any]?,Error?) -> Void

class ApiManager {
    var completion:sessionActivateCompletion?
    var paywallIdentifier = ""
    var paywallCustomize = false

    @objc func startSession(){
        SessionsAPI.reportSession(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportSession.ios, X_VERSION: UserProperties.sdkVersion, uniqueUserObject: UniqueUserObject(), apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            if (error != nil) {
                DYMLogManager.logError(error!)

                let time: TimeInterval = 1.0
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                    self.startSession()
                }

            }else{
                if data?.status == .ok {
                    if let paywall = data?.paywall {
                        DYMDefaultsManager.shared.cachedPaywalls = [paywall]
                        if paywall.downloadUrl != "" {
                            if paywall.downloadUrl == "local" {
                                if let nativePaywallId = data?.paywallId {
                                    let version = paywall.version
                                    self.paywallIdentifier = nativePaywallId
                                    DYMDefaultsManager.shared.cachedPaywallPageIdentifier = nativePaywallId + "/" + String(version)
                                    self.paywallCustomize = paywall.customize

                                    DYMDefaultsManager.shared.isUseNativePaywall = true
                                    DYMDefaultsManager.shared.isLoadingStatus = true
                                }

                            } else {
                                DYMDefaultsManager.shared.isUseNativePaywall = false
                                if let paywallId = data?.paywallId {
                                    let version = paywall.version
                                    self.paywallIdentifier = paywallId + "/" + String(version)
                                    self.paywallCustomize = paywall.customize
                                    if self.paywallIdentifier != DYMDefaultsManager.shared.cachedPaywallPageIdentifier {
                                        self.downloadWebTemplate(url: URL(string: paywall.downloadUrl)!) { res, err in
                                        }
                                    } else {
                                        DYMDefaultsManager.shared.isLoadingStatus = true
                                    }
                                }
                            }

                        }
                        //内购项信息
                        var subsArray:[Subscription] = []
                        for subscription in paywall.subscriptions {
                            let sub = subscription.subscription!
                            subsArray.append(sub)
                        }
                        DYMDefaultsManager.shared.cachedProducts = subsArray
                    } else {
                        DYMDefaultsManager.shared.isLoadingStatus = true
                        DYMDefaultsManager.shared.cachedPaywalls = nil
                        DYMDefaultsManager.shared.cachedProducts = nil
                    }

                    DYMDefaultsManager.shared.cachedSwitchItems = data?.switchItems
                    DYMDefaultsManager.shared.cachedSubscribedObjects = data?.subscribedProducts
                    DYMDefaultsManager.shared.cachedGlobalSwitch = data?.globalSwitchItems
                    print(data ?? "")

                    let subscribedOjects = DYMDefaultsManager.shared.subscribedObjects(subscribedObjectArray: DYMDefaultsManager.shared.cachedSubscribedObjects)

                    var results = [
                        "switchs": DYMDefaultsManager.shared.cachedSwitchItems as Any,
                        "subscribedOjects":subscribedOjects,
                        "isUseNativePaywall":DYMDefaultsManager.shared.isUseNativePaywall
                    ] as [String : Any]

                    if DYMDefaultsManager.shared.isUseNativePaywall {
                        results["nativePaywallId"] = self.paywallIdentifier
                    }

                    if let globalSwitchItems = DYMDefaultsManager.shared.cachedGlobalSwitch {
                        if globalSwitchItems.count > 0 {
                            results["globalSwitchItems"] = globalSwitchItems
                        }
                    }

                    self.completion?(results,nil)
                }else{
                    DYMLogManager.logError(data?.errmsg as Any)
                    DYMDefaultsManager.shared.isLoadingStatus = true
                    self.completion?(nil,DYMError.failed)
                }
            }
        }
    }

    func reportIdfa(idfa:String,completion:@escaping ((SimpleStatusResult?,Error?)->())) {
        SessionsAPI.reportType(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportType.ios, X_VERSION: UserProperties.sdkVersion, type: SessionsAPI.ModelType_reportType.idfa, body: idfa) { data, error in
            completion(data,error)
        }
    }

    func reportDeviceToken(token:String,completion:@escaping ((SimpleStatusResult?,Error?)->())) {
        SessionsAPI.reportType(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportType.ios, X_VERSION: UserProperties.sdkVersion, type: SessionsAPI.ModelType_reportType.deviceToken, body: token) { data, error in
            completion(data,error)
        }
    }
    
    func updateSearchAdsAttribution(attribution: AnyCodable? = nil, completion:@escaping (SimpleStatusResult?,Error?) -> Void) {
        guard let attribution = attribution?.value as? DYMParams else{
            DYMLogManager.logMessage("attrition is nil")
            completion(nil,nil)
            return
        }
        let searchAtt = AppleSearchAdsAttribution(attribution: attribution)
        let appleReportObjAtt = AppleSearchAdsAttributionReportObjectAttribution(version31:searchAtt)
        let appleReportObj = AppleSearchAdsAttributionReportObject(attribution: appleReportObjAtt)
        AttributionAPI.reportSearchAdsAttr(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: AttributionAPI.XPLATFORM_reportSearchAdsAttr.ios, X_VERSION: UserProperties.sdkVersion, appleSearchAdsAttributionReportObject: appleReportObj, apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            completion(data,error)
        }
    }

    func reportAttribution(attribution:Attribution,complete:@escaping ((SimpleStatusResult?,Error?)->())) {
        if attribution.adjustId == nil && attribution.appsFlyerId == nil && attribution.amplitudeId == nil {
            DYMLogManager.logMessage("attrition is nil")
            complete(nil,nil)
            return
        }
        AttributionAPI.attributionData(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: AttributionAPI.XPLATFORM_attributionData.ios, X_VERSION: UserProperties.sdkVersion, attribution: attribution, apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            complete(data,error)
        }
    }

    //下载内购页zip
    func downloadWebTemplate(url: URL, completion:@escaping (SimpleStatusResult?,Error?) -> Void) {
        let turl = url
        URLSession.shared.downloadTask(with: turl) { url, response, error in
            if response != nil {
                if (response as! HTTPURLResponse).statusCode == 200 {

                    if let zipFileUrl = url, let targetUnzipUrl = UserProperties.pallwallPath {
                        let success = SSZipArchive.unzipFile(atPath: zipFileUrl.path, toDestination: targetUnzipUrl)
                        if success {
                            var items: [String]
                              do {
                                  items = try FileManager.default.contentsOfDirectory(atPath: targetUnzipUrl)
                                  DYMDefaultsManager.shared.isLoadingStatus = true
                              } catch {
                               return
                              }

                            if self.paywallCustomize == false {
                                if items.contains("config.js") {
                                    DYMDefaultsManager.shared.cachedPaywallPageIdentifier = self.paywallIdentifier
                                }
                            } else {
                                DYMDefaultsManager.shared.cachedPaywallPageIdentifier = self.paywallIdentifier
                            }
                        } else {
                            DYMDefaultsManager.shared.isLoadingStatus = true
                        }
                        try? FileManager.default.removeItem(at: zipFileUrl)
                    } else {
                        DYMDefaultsManager.shared.isLoadingStatus = true
                    }
                }else {
                    DYMLogManager.logError(error as Any)
                    DYMDefaultsManager.shared.isLoadingStatus = true
                }
            } else {
                DYMDefaultsManager.shared.isLoadingStatus = true
            }
        }.resume()
    }

    func verifySubscriptionFirst(receipt: String,for product: SKProduct?,completion:@escaping FirstReceiptCompletion) {
        guard let product = product else {
            return
        }
        let platformProductId = product.productIdentifier
        let price = product.price.stringValue
        let currency = (product.priceLocale.currencyCode)!
        let countryCode = (product.priceLocale.regionCode)!
        let receiptObj = FirstReceiptVerifyPostObject(appleReceipt: receipt, platformProductId: platformProductId, price: price, currencyCode: currency,countryCode: countryCode)
        ReceiptAPI.verifyFirstReceipt(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: ReceiptAPI.XPLATFORM_verifyFirstReceipt.ios, X_VERSION: UserProperties.sdkVersion, firstReceiptVerifyPostObject: receiptObj, completion: completion)
    }

    func verifySubscriptionFirstWith(receipt: String,for product: Dictionary<String, String>?,completion:@escaping FirstReceiptCompletion) {
        guard let product = product else {
            return
        }
        let platformProductId = product["productId"]!
        let price = product["price"]!
        let currency = product["currencyCode"]!
        let countryCode = product["regionCode"]!

        let receiptObj = FirstReceiptVerifyPostObject(appleReceipt: receipt, platformProductId: platformProductId, price: price, currencyCode: currency,countryCode: countryCode)
        ReceiptAPI.verifyFirstReceipt(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: ReceiptAPI.XPLATFORM_verifyFirstReceipt.ios, X_VERSION: UserProperties.sdkVersion, firstReceiptVerifyPostObject: receiptObj, completion: completion)
    }

    func verifySubscriptionRecover(receipt: String,completion:@escaping RecoverReceiptCompletion) {
        let receiptObj = ReceiptVerifyPostObject(appleReceipt: receipt)
        ReceiptAPI.verifyReceipt(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: ReceiptAPI.XPLATFORM_verifyReceipt.ios, X_VERSION: UserProperties.sdkVersion, receiptVerifyPostObject: receiptObj, completion: completion)
    }
    
    func addGlobalSwitch(globalSwitch:GlobalSwitch,complete:@escaping ((SimpleStatusResult?,Error?)->())) {
        SessionsAPI.reportGlobalSwitch(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportGlobalSwitch.ios, X_VERSION: UserProperties.sdkVersion, globalSwitch: globalSwitch) { data, error in
            complete(data,error)
        }
    }
}
