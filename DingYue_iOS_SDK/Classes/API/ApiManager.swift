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
public typealias sessionActivateCompletion = ([String:Any]?,Error?) -> Void

class ApiManager {
    var completion:sessionActivateCompletion?
    var paywallIdentifier = ""
    var paywallName = ""
    var paywallCustomize = false
    
    var guidePageIdentifier = ""
    var guidePageName = ""
    var guideCustomize = false
    var retryCount = 0
    var maxRetries = 15

    @objc func startSession(){
        
        //tj``:埋点-SessionsAPI.reportSession 请求前
        let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                              "uniqueUserObject":AGHelper.ag_convertToDictionary(UniqueUserObject()) ?? "",
                              "X_USER_ID":UserProperties.requestUUID,
                              "userAgent":UserProperties.userAgent,
                              "X_APP_ID":DYMConstants.APIKeys.appId,
                              "X_PLATFORM":SessionsAPI.XPLATFORM_reportSession.ios,
                              "X_VERSION":UserProperties.sdkVersion]
        DYMobileSDK.track(event: "SDK.Session.report", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
        
        let ag_startTime = Int64(Date().timeIntervalSince1970 * 1000)
        SessionsAPI.reportSession(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportSession.ios, X_VERSION: UserProperties.sdkVersion, uniqueUserObject: UniqueUserObject(), apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            
            //tj``:埋点-SessionsAPI.reportSession 请求响应时
            let ag_endTime = Int64(Date().timeIntervalSince1970 * 1000)
            let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                 "responseTime":(ag_endTime - ag_startTime),
                                                 "statusCode":data?.status ?? "error"]
            DYMobileSDK.track(event: "SDK.Session.Response", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
            
            if (error != nil) {
                DYMLogManager.logError(error!)
               
                //引导页暂定重新请求10次
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    let time: TimeInterval = 1.0
                    
                    //tj``:埋点-SessionsAPI.reportSession 重试开始前
                    let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                         "retryTimes":self.retryCount,
                                                         "lastError":error.debugDescription]
                    DYMobileSDK.track(event: "SDK.Session.Retry", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                        self.startSession()
                    }
                }else {
                    
                    //tj``:埋点-Completion Session请求失败
                    let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                         "category":"session"]
                    DYMobileSDK.track(event: "SDK.Session.Failed", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                    
                    DYMDefaultsManager.shared.guideLoadingStatus = true
                    DYMDefaultsManager.shared.isLoadingStatus = true
                    self.completion?(nil,DYMError.failed)
                }
            }else{
                
                //tj``:埋点-Session.report 响应体获取成功
                let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                     "size":0]
                DYMobileSDK.track(event: "SDK.Session.Success", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                
                if data?.status == .ok {
                    var configurations:[[String:Any]]?
                    if let paywall = data?.paywall {
                        DYMDefaultsManager.shared.cachedPaywalls = [paywall]
                        if paywall.downloadUrl != "" {
                            if paywall.downloadUrl == "local" {//使用项目中带的内购页
                                
                                //tj``:埋点-Paywall 判断download url类型
                                let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                     "urlCategory":"local"]
                                DYMobileSDK.track(event: "SDK.Paywall.DownloadURL", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                
                                if let nativePaywallId = data?.paywallId {
                                    let version = paywall.version
                                    self.paywallIdentifier = nativePaywallId
                                    DYMDefaultsManager.shared.cachedPaywallPageIdentifier = nativePaywallId + "/" + String(version)
                                    DYMDefaultsManager.shared.cachedPaywallName = paywall.name
                                    self.paywallCustomize = paywall.customize

                                    DYMDefaultsManager.shared.isUseNativePaywall = true
                                    DYMDefaultsManager.shared.isLoadingStatus = true
                                }

                            } else {//订阅下发的内购页信息
                                
                                //tj``:埋点-Paywall 判断download url类型
                                let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                     "urlCategory":"server"]
                                DYMobileSDK.track(event: "SDK.Paywall.DownloadURL", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                
                                DYMDefaultsManager.shared.isUseNativePaywall = false
                                if let paywallId = data?.paywallId {
                                    let version = paywall.version
                                    self.paywallIdentifier = paywallId + "/" + String(version)
                                    self.paywallName = paywall.name
                                    self.paywallCustomize = paywall.customize
                                    if self.paywallIdentifier != DYMDefaultsManager.shared.cachedPaywallPageIdentifier {
                                        
                                        //tj``:埋点-Paywall 下载zip文件开始
                                        let ag_startTime = Int64(Date().timeIntervalSince1970 * 1000)
                                        let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                   "url":paywall.downloadUrl]
                                        DYMobileSDK.track(event: "SDK.Paywall.DownloadStart", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                        
                                        self.downloadWebTemplate(url: URL(string: paywall.downloadUrl)!) { res, err in
                                            let ag_endTime = Int64(Date().timeIntervalSince1970 * 1000)
                                            
                                            if err == nil {
                                                //tj``:埋点-Paywall 下载zip文件成功
                                                let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                                     "url":paywall.downloadUrl,
                                                                                     "costTime": (ag_endTime - ag_startTime),
                                                                                     "size":paywall.customize]
                                                DYMobileSDK.track(event: "SDK.Paywall.DownloadFinish", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                            }else{
                                                //tj``:埋点-Paywall 下载zip文件失败
                                                let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                                     "url":paywall.downloadUrl,
                                                                                     "costTime": (ag_endTime - ag_startTime),
                                                                                     "size":paywall.customize]
                                                DYMobileSDK.track(event: "SDK.Paywall.DownloadFailed", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                            }
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
                        
                        //热更新配置信息
                        if let config = paywall.configurations {
                            configurations = DYMDefaultsManager.shared.paywallConfigurations(configurations: config)
                        }
                    } else {
                        DYMDefaultsManager.shared.isLoadingStatus = true
                        DYMDefaultsManager.shared.cachedPaywalls = nil
                        DYMDefaultsManager.shared.cachedProducts = nil
                    }
                    
                    if let guide = data?.guidePage {
                        DYMDefaultsManager.shared.cachedGuides = [guide]
                        if guide.downloadUrl ==  "local" {
                            
                            //tj``:埋点-Guide 判断download url类型
                            let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                 "urlCategory":"local"]
                            DYMobileSDK.track(event: "SDK.Guide.DownloadURL", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                            
                            if let nativeGuidePageId = data?.guidePageId {
                                let guideVersion = guide.version
                                self.guidePageIdentifier = nativeGuidePageId
                                DYMDefaultsManager.shared.cachedGuidePageIdentifier = nativeGuidePageId + "/" + String(guideVersion)
                                DYMDefaultsManager.shared.cachedGuideName = guide.name
                                self.guideCustomize = guide.customize
                                DYMDefaultsManager.shared.isUseNativeGuide = true
                                DYMDefaultsManager.shared.guideLoadingStatus = true
                            }
                        }else {
                            
                            //tj``:埋点-Guide 判断download url类型
                            let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                 "urlCategory":"server"]
                            DYMobileSDK.track(event: "SDK.Guide.DownloadURL", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                            
                            DYMDefaultsManager.shared.isUseNativeGuide = false
                            if let guidePageId = data?.guidePageId {
                                let guideVersion = guide.version
                                self.guidePageIdentifier = guidePageId + "/" + String(guideVersion)
                                self.guidePageName = guide.name
                                self.guideCustomize = guide.customize
                                if self.guidePageIdentifier != DYMDefaultsManager.shared.cachedGuidePageIdentifier {
                                    
                                    //tj``:埋点-Guide 下载zip文件开始
                                    let ag_startTime = Int64(Date().timeIntervalSince1970 * 1000)
                                    let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                         "url":URL(string: guide.downloadUrl)!]
                                    DYMobileSDK.track(event: "SDK.Guide.DownloadStart", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                    
                                    self.downloadGuideWebTemplate(url: URL(string: guide.downloadUrl)!) { res, error in
                                        let ag_endTime = Int64(Date().timeIntervalSince1970 * 1000)
                                        
                                        if error == nil {
                                            //tj``:埋点-Guide 下载zip文件成功
                                            let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                                 "url":guide.downloadUrl,
                                                                                 "costTime": (ag_endTime - ag_startTime),
                                                                                 "size":guide.customize]
                                            DYMobileSDK.track(event: "SDK.Guide.DownloadFinish", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                        }else{
                                            //tj``:埋点-Guide 下载zip文件失败
                                            let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                                                 "url":guide.downloadUrl,
                                                                                 "costTime": (ag_endTime - ag_startTime),
                                                                                 "size":guide.customize]
                                            DYMobileSDK.track(event: "SDK.Guide.DownloadFailed", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                                        }
                                    }
                                }else {
                                    DYMDefaultsManager.shared.guideLoadingStatus = true
                                }
                            }
                        }                                                                        
                    }else {
                        DYMDefaultsManager.shared.guideLoadingStatus = true
                        DYMDefaultsManager.shared.cachedGuides = nil
                    }
                    
                    DYMDefaultsManager.shared.cachedSwitchItems = data?.switchItems
                    DYMDefaultsManager.shared.cachedSubscribedObjects = data?.subscribedProducts
                    DYMDefaultsManager.shared.cachedGlobalSwitch = data?.globalSwitchItems

                    let subscribedOjects = DYMDefaultsManager.shared.subscribedObjects(subscribedObjectArray: DYMDefaultsManager.shared.cachedSubscribedObjects)
                    var results = [
                        "switchs": DYMDefaultsManager.shared.cachedSwitchItems as Any,
                        "subscribedOjects":subscribedOjects,
                        "isUseNativePaywall":DYMDefaultsManager.shared.isUseNativePaywall,
                        "isUseNativeGuide":DYMDefaultsManager.shared.isUseNativeGuide,
                        "nativeGuidePageId":self.guidePageIdentifier
                    ] as [String : Any]

                    if DYMDefaultsManager.shared.isUseNativePaywall {
                        results["nativePaywallId"] = self.paywallIdentifier
                    }                

                    if let globalSwitchItems = DYMDefaultsManager.shared.cachedGlobalSwitch {
                        if globalSwitchItems.count > 0 {
                            results["globalSwitchItems"] = globalSwitchItems
                        }
                    }
                    if let config = configurations, !config.isEmpty {
                        results["configurations"] = config
                    }
                    
                    //tj``:埋点-Result 拼接result对象完成
                    let ag_param_extra:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                         "result":results,
                                                          "category":"session"]
                    DYMobileSDK.track(event: "SDK.Session.Result", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra))
                    
                    //tj``:埋点-Completion 调用completion回调前
                    let ag_param_extra1:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                         "category":"session"]
                    DYMobileSDK.track(event: "SDK.Session.Callback", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra1))
                    
                    self.completion?(results,nil)
                }else{
                    DYMLogManager.logError(data?.errmsg as Any)
                    DYMDefaultsManager.shared.isLoadingStatus = true
                    DYMDefaultsManager.shared.guideLoadingStatus = true
                    
                    //tj``:埋点-Completion 调用completion回调前
                    let ag_param_extra1:[String : Any] = ["timestamp":Int64(Date().timeIntervalSince1970 * 1000),
                                                         "category":"session"]
                    DYMobileSDK.track(event: "SDK.Session.Callback", extra: AGHelper.ag_convertDicToJSONStr(dictionary:ag_param_extra1))
                    
                    self.completion?(nil,DYMError.failed)
                }
                
                if let domainName = data?.domainName, !domainName.isEmpty{
                    DYMDefaultsManager.shared.cachedDomainName = domainName
                }
                
                if let plistInfo = data?.plistInfo,
                   let appId = plistInfo.appId, !appId.isEmpty,
                   let apiKey = plistInfo.apiKey, !apiKey.isEmpty {
                    DYMDefaultsManager.shared.cachedAppId = appId
                    DYMDefaultsManager.shared.cachedApiKey = apiKey
                }
                
                if DYMobileSDK.defaultConversionValueEnabled && !DYMDefaultsManager.shared.isMultipleLaunch {
                    DYMobileSDK().updateConversionValueWithDefaultRule(value: 1)
                    DYMDefaultsManager.shared.isMultipleLaunch = true
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
    
    func setCustomProperties(customProperties:[String:Any?]?,completion:@escaping ((SimpleStatusResult?,Error?)->())) {
        guard let properties = customProperties else {
            DYMLogManager.logMessage("properties is nil")
            completion(nil,nil)
            return
        }
        
        AttributionAPI.setCustomProperties(X_USER_ID: UserProperties.requestUUID, userAgent:  UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: AttributionAPI.XPLATFORM_attributionData.ios, X_VERSION: UserProperties.sdkVersion, customProperties: properties, apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            completion(data,error)
        }
        
    }
    

    //MARK: 下载内购页zip
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
                                    DYMDefaultsManager.shared.cachedPaywallName = self.paywallName
                                }
                            } else {
                                DYMDefaultsManager.shared.cachedPaywallPageIdentifier = self.paywallIdentifier
                                DYMDefaultsManager.shared.cachedPaywallName = self.paywallName
                            }
                        } else {
                            DYMDefaultsManager.shared.isLoadingStatus = true
                        }
                        try? FileManager.default.removeItem(at: zipFileUrl)
                    } else {
                        DYMDefaultsManager.shared.isLoadingStatus = true
                    }
                    completion(SimpleStatusResult(status: .ok), nil)
                }else {
                    DYMLogManager.logError(error as Any)
                    DYMDefaultsManager.shared.isLoadingStatus = true
                    completion(nil, error)
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
    
    func reportConversionValue(cv:Int, coarseValue:ConversionRequest.CoarseValue? = nil) {
        let cvObject = ConversionRequest(conversionValue: cv, coarseValue: coarseValue)
        SessionsAPI.reportConversion(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportConversion.ios, X_VERSION: UserProperties.sdkVersion, conversionRequest: cvObject) { data, error in
        }
    }
    
    func updateUserProperties() {
        var source = DYMUserSubscriptionPurchasedSourceType.DYAPICall.rawString//默认是api调用
        if let type = UserProperties.userSubscriptionPurchasedSourcesType, type == .DYPaywall {
            source = DYMUserSubscriptionPurchasedSourceType.DYPaywall.rawString
            if let paywallname = DYMDefaultsManager.shared.cachedPaywallName {
                source.append(":\(paywallname)")
            }
            if let paywallId = DYMDefaultsManager.shared.cachedPaywallPageIdentifier {
                source.append("/\(paywallId)")
            }
        } else {
            source = DYMUserSubscriptionPurchasedSourceType.DYAPICall.rawString
        }
        
        let editStringUnit = EditStringUnit(key: UserProperties.userSubscriptionPurchasedSources, value: source, type: .string)
        let editOneOf = EditOneOf.typeEditStringUnit(editStringUnit)
        
        SessionsAPI.updateUserAttribute(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_updateUserAttribute.ios, X_VERSION: UserProperties.sdkVersion, editOneOf: [editOneOf]) { data, error in
            UserProperties.userSubscriptionPurchasedSourcesType = nil
        }
    }
}

//MARK: 引导页相关
extension ApiManager {
    //MARK: 下载引导页
    func downloadGuideWebTemplate(url: URL, completion:@escaping (SimpleStatusResult?,Error?) -> Void) {
        let turl = url
        URLSession.shared.downloadTask(with: turl) { url, response, error in
            if response != nil {
                if (response as! HTTPURLResponse).statusCode == 200 {

                    if let zipFileUrl = url, let targetUnzipUrl = UserProperties.guidePath {
                        let success = SSZipArchive.unzipFile(atPath: zipFileUrl.path, toDestination: targetUnzipUrl)
                        if success {
                            var items: [String]
                              do {
                                  items = try FileManager.default.contentsOfDirectory(atPath: targetUnzipUrl)
                                  DYMDefaultsManager.shared.guideLoadingStatus = true
                              } catch {
                               return
                              }
                            DYMDefaultsManager.shared.cachedGuidePageIdentifier = self.guidePageIdentifier
                            DYMDefaultsManager.shared.cachedGuideName = self.guidePageName
                        } else {
                            DYMDefaultsManager.shared.guideLoadingStatus = true
                        }
                        try? FileManager.default.removeItem(at: zipFileUrl)
                    } else {
                        DYMDefaultsManager.shared.guideLoadingStatus = true
                    }
                    completion(SimpleStatusResult(status: .ok), nil)
                }else {
                    DYMLogManager.logError(error as Any)
                    DYMDefaultsManager.shared.guideLoadingStatus = true
                    completion(nil,error)
                }
            } else {
                DYMDefaultsManager.shared.guideLoadingStatus = true
            }
        }.resume()
    }
}
//MARK: GetAppSegmentInfo
extension ApiManager {
    func getSegmentInfo(completion:@escaping((SegmentInfoResult?,Error?)->())) {
       
        AttributionAPI.getUserGroupInfo(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: AttributionAPI.XPLATFORM_GroupInfoData.ios, X_VERSION: UserProperties.sdkVersion,apiResponseQueue: OpenAPIClientAPI.apiResponseQueue) { data, error in
            completion(data,error)
        }
       
    }
    
}
