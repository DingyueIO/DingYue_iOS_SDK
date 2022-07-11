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

public typealias sessionActivateCompletion = ([SwitchItem]?,[[String:Any]]?,Error?) -> Void

class ApiManager {
    var completion:sessionActivateCompletion?
    func startSession(){
        SessionsAPI.reportSession(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportSession.ios, uniqueUserObject: UniqueUserObject(), apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            if (error != nil) {
                DYMLogManager.logError(error!)
            }else{
                if data?.status == .ok {
                    if let paywall = data?.paywall {
                        DYMDefaultsManager.shared.cachedPaywalls = [paywall]
                        if paywall.downloadUrl != "" {
                            self.downloadWebTemplate(url: URL(string: paywall.downloadUrl)!) { res, err in
                            }
                        }
                        //内购项信息
                        var subsArray:[Subscription] = []
                        for subscription in paywall.subscriptions {
                            let sub = subscription.subscription!
                            subsArray.append(sub)
                        }
                        DYMDefaultsManager.shared.cachedProducts = subsArray
                    }

                    if let switchItems = data?.switchItems {
                        DYMDefaultsManager.shared.cachedSwitchItems = switchItems
                    }

                    if let subscribedProducts = data?.subscribedProducts {
                        DYMDefaultsManager.shared.cachedSubscribedObjects = subscribedProducts
                    }
                    print(data ?? "")
                }else{
                    DYMLogManager.logError(data?.errmsg as Any)
                }
            }
            //session report 返回开关状态数据和购买的产品信息
            let subscribedOjects = DYMDefaultsManager.shared.subscribedObjects(subscribedObjectArray: DYMDefaultsManager.shared.cachedSubscribedObjects)
            self.completion?(DYMDefaultsManager.shared.cachedSwitchItems,subscribedOjects,error)
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
        AttributionAPI.reportSearchAdsAttr(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: AttributionAPI.XPLATFORM_reportSearchAdsAttr.ios, appleSearchAdsAttributionReportObject: appleReportObj, apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            completion(data,error)
        }
    }

    func reportAttribution(attribution:Attribution,complete:@escaping ((SimpleStatusResult?,Error?)->())) {
        if attribution.adjustId == nil && attribution.appsFlyerId == nil && attribution.amplitudeId == nil {
            DYMLogManager.logMessage("attrition is nil")
            complete(nil,nil)
            return
        }
        AttributionAPI.attributionData(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: AttributionAPI.XPLATFORM_attributionData.ios, attribution: attribution, apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            complete(data,error)
        }
    }

    //下载内购页zip
    func downloadWebTemplate(url: URL, completion:@escaping (SimpleStatusResult?,Error?) -> Void) {
        let turl = url
        URLSession.shared.downloadTask(with: turl) { url, response, error in
            if (response as! HTTPURLResponse).statusCode == 200 {
                let dstPath = UserProperties.pallwallPath
                let success = SSZipArchive.unzipFile(atPath: url!.path, toDestination: dstPath!)
                if success {
                    var items: [String]
                      do {
                          items = try FileManager.default.contentsOfDirectory(atPath: dstPath!)
                      } catch {
                       return
                      }
                    print("purchase zip download successfully!---\(items)")
                    DYMDefaultsManager.shared.isExistPayWall = true
                }
                try? FileManager.default.removeItem(at: url!)
            }else {
                DYMLogManager.logError(error as Any)
            }
        }.resume()
    }

    func verifySubscriptionFirst(receipt: String,for product: SKProduct?,completion:@escaping FirstReceiptCompletion) {
        let platformProductId = (product?.productIdentifier)!
        let price = (product?.price.stringValue)!
        let currency = (product?.priceLocale.currencyCode)!
        let countryCode = (product?.priceLocale.regionCode)!
        let receiptObj = FirstReceiptVerifyPostObject(appleReceipt: receipt, platformProductId: platformProductId, price: price, currencyCode: currency,countryCode: countryCode)
        ReceiptAPI.verifyFirstReceipt(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: ReceiptAPI.XPLATFORM_verifyFirstReceipt.ios, firstReceiptVerifyPostObject: receiptObj, completion: completion)
    }

    func verifySubscriptionRecover(receipt: String,completion:@escaping RecoverReceiptCompletion) {
        let receiptObj = ReceiptVerifyPostObject(appleReceipt: receipt)
        ReceiptAPI.verifyReceipt(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: ReceiptAPI.XPLATFORM_verifyReceipt.ios, receiptVerifyPostObject: receiptObj, completion: completion)
    }
    
    func updateUser(attributes:[String],completion:((Bool,DYMError?) -> Void)? = nil) {
//        UserAttributeAPI.updateUserAttributes(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_APP_Key: DYMConstants.APIKeys.secretKey, attributes: attributes) { data, error in
//            if error != nil {
//                completion?(false,DYMError(error!))
//                return
//            }
//            if let result = data {
//                if result.status == .ok {
//                    completion?(true,nil)
//                }else {
//                    completion?(false,DYMError(code: .failed, message: result.errmsg ?? ""))
//                }
//                return
//            }
//            completion?(false,.failed)
//        }

//
//        SessionsAPI.updateUserAttribute(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_updateUserAttribute.ios, editOneOf: <#T##[EditOneOf]#>) { data, error in
//            if error != nil {
//                completion?(false,DYMError(error!))
//                return
//            }
//            if let result = data {
//                if result.status == .ok {
//                    completion?(true,nil)
//                }else {
//                    completion?(false,DYMError(code: .failed, message: result.errmsg ?? ""))
//                }
//                return
//            }
//            completion?(false,.failed)
//        }

    }
}
