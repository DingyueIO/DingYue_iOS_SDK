//
//  DefaultsManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/24.
//

import Foundation

public enum DataState: Int, Codable {
    case cached
    case synced
}

class DYMDefaultsManager {

    static let shared = DYMDefaultsManager()
    private var defaults = UserDefaults.standard

    private init() {}
    init(with defaults: UserDefaults) {
        self.defaults = defaults
    }

    var profileId: String {
        get {
            if let profileId = defaults.string(forKey: DYMConstants.UserDefaults.profileId) {
                return profileId
            }

            // try to restore profileId from cached profile
            // basically, backward compatibility only
            if let profileId = purchaserInfo?.platformProductId {
                self.profileId = profileId
                return profileId
            }

            // generate new profileId
            let profileId = UserProperties.uuid
            self.profileId = profileId
            return profileId
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.profileId)
        }
    }

    var purchaserInfo: Subscription? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.purchaserInfo) as? Data, let purchaserInfo = try? JSONDecoder().decode(Subscription.self, from: data) {
                return purchaserInfo
            }

            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: DYMConstants.UserDefaults.purchaserInfo)
        }
    }

    var apnsTokenString: String? {
        get {
            return defaults.string(forKey: DYMConstants.UserDefaults.apnsTokenString)
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.apnsTokenString)
        }
    }

    var cachedVariationsIds: [String: String] {
        get {
            return defaults.dictionary(forKey: DYMConstants.UserDefaults.cachedVariationsIds) as? [String: String] ?? [:]
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.cachedVariationsIds)
        }
    }

    var cachedPaywalls: [Paywall]? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedPaywalls) as? Data, let paywalls = try? JSONDecoder().decode([Paywall].self, from: data) {
                return paywalls
            }
            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: DYMConstants.UserDefaults.cachedPaywalls)
        }
    }

    var cachedPaywallPageIdentifier: String? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedPayWallPageIdentifier) as? String {
                return data
            }
            return nil
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.cachedPayWallPageIdentifier)
        }
    }
    
    var cachedPaywallName: String? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedPaywallName) as? String {
                return data
            }
            return nil
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.cachedPaywallName)
        }
    }

    var cachedProducts: [Subscription]? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedProducts) as? Data, let products = try? JSONDecoder().decode([Subscription].self, from: data) {
                return products
            }

            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: DYMConstants.UserDefaults.cachedProducts)
        }
    }

    var cachedSwitchItems: [SwitchItem]? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedSwitchItems) as? Data, let products = try? JSONDecoder().decode([SwitchItem].self, from: data) {
                return products
            }

            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: DYMConstants.UserDefaults.cachedSwitchItems)
        }
    }

    var cachedGlobalSwitch: [GlobalSwitch]? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedGlobalSwitch) as? Data, let products = try? JSONDecoder().decode([GlobalSwitch].self, from: data) {
                return products
            }

            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: DYMConstants.UserDefaults.cachedGlobalSwitch)
        }
    }

    var cachedSubscribedObjects: [SubscribedObject]? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedSubscribedObjects) as? Data, let products = try? JSONDecoder().decode([SubscribedObject].self, from: data) {
                return products
            }

            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: DYMConstants.UserDefaults.cachedSubscribedObjects)
        }
    }

    var appleSearchAdsSyncDate: Date? {
        get {
            return defaults.object(forKey: DYMConstants.UserDefaults.appleSearchAdsSyncDate) as? Date
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.appleSearchAdsSyncDate)
        }
    }

    var externalAnalyticsDisabled: Bool {
        get {
            return defaults.bool(forKey: DYMConstants.UserDefaults.externalAnalyticsDisabled)
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.externalAnalyticsDisabled)
        }
    }

    var previousResponseHashes: [String: String] {
        get {
            return (defaults.dictionary(forKey: DYMConstants.UserDefaults.previousResponseHashes) as? [String: String]) ?? [:]
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.previousResponseHashes)
        }
    }

    var responseJSONCaches: [String: [String: Data]] {
        get {
            return (defaults.dictionary(forKey: DYMConstants.UserDefaults.responseJSONCaches) as? [String: [String: Data]]) ?? [:]
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.responseJSONCaches)
        }
    }

    var postRequestParamsHashes: [String: String] {
        get {
            return (defaults.dictionary(forKey: DYMConstants.UserDefaults.postRequestParamsHashes) as? [String: String]) ?? [:]
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.postRequestParamsHashes)
        }
    }
    var subscribedObject: [[String:Any]]? {
        var subsArray:[[String:Any]] = []
        if let cacheSubscribledObjects = self.cachedSubscribedObjects {
            for sub in cacheSubscribledObjects {
                var subDic:[String:Any] = [:]
                subDic["platformProductId"] = sub.platformProductId
                subDic["originalTransactionId"] = sub.originalTransactionId
                if let expiresAt = sub.expiresAt {
                    subDic["expiresAt"] = expiresAt
                }
                if let groupId = sub.appleSubscriptionGroupId {
                    subDic["appleSubscriptionGroupId"] = groupId
                }
                subsArray.append(subDic)
            }
        }
        return subsArray
    }
    
    var isMultipleLaunch: Bool {
        get {
            return (defaults.bool(forKey: DYMConstants.UserDefaults.multipleLaunch))
        }
        
        set {
            defaults.setValue(newValue, forKey: DYMConstants.UserDefaults.multipleLaunch)
        }
    }

    var isLoadingStatus: Bool = false
    var isUseNativePaywall: Bool = false
    var nativePaywallPath: String!
    var nativePaywallBasePath: String!
    var defaultPaywallPath:String?

    //guide相关 -began
    var guideLoadingStatus: Bool = false
    var isUseNativeGuide: Bool = false
    var nativeGuidePath: String!
    var nativeGuideBasePath: String!
    var defaultGuidePath:String?
    //guide相关 -end
    
    func subscribedObjects(subscribedObjectArray: [SubscribedObject?]?) -> [[String:Any]] {
        var subsArray:[[String:Any]] = []
        if let subscribledObjects = subscribedObjectArray {
            for sub in subscribledObjects {
                var subDic:[String:Any] = [:]
                subDic["platformProductId"] = sub?.platformProductId
                if let originalTransactionId = sub?.originalTransactionId {
                    subDic["originalTransactionId"] = originalTransactionId
                }
                if let expiresAt = sub?.expiresAt {
                    subDic["expiresAt"] = expiresAt
                }
                if let groupId = sub?.appleSubscriptionGroupId {
                    subDic["appleSubscriptionGroupId"] = groupId
                }
                subsArray.append(subDic)
            }
        }
        return subsArray
    }
    
    func paywallConfigurations(configurations: [PaywallConfiguration]) -> [[String:Any]] {
        var config:[[String:Any]] = []
        for con in configurations {
            var subCon:[String:Any] = [:]
            subCon["key"] = con.key
            subCon["defaultValue"] = con.defaultValue
            subCon["localeValues"] = con.localeValues
            config.append(subCon)
        }
        return config
    }

    func firstReceiptResponse(firstReceiptResponse: FirstReceiptVerifyMobileResponse?) -> [String:Any] {
        var response:[String:Any] = [:]
        if let firstResponse = firstReceiptResponse {
            response["status"] = firstResponse.status
            response["errmsg"] = firstResponse.errmsg
            response["subscribledObject"] = self.subscribedObjects(subscribedObjectArray:[firstResponse.receipt])
        }
        return response
    }
    func recoverReceiptResponse(recoverReceiptResponse: ReceiptVerifyMobileResponse?) -> [String:Any] {
        var response:[String:Any] = [:]
        if let recoverResponse = recoverReceiptResponse {
            response["status"] = recoverResponse.status
            response["errmsg"] = recoverResponse.errmsg
            response["subscribledObject"] = self.subscribedObjects(subscribedObjectArray:recoverResponse.receipts)
        }
        return response
    }

    func clean() {
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedVariationsIds)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedPaywalls)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedPayWallPageIdentifier)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedProducts)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedSwitchItems)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedSubscribedObjects)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.appleSearchAdsSyncDate)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.externalAnalyticsDisabled)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.previousResponseHashes)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.responseJSONCaches)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.postRequestParamsHashes)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedPaywallName)
        
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedGuides)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedGuideName)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedGuidePageIdentifier)
    }
}

//MARK:  Guide 引导页相关
extension DYMDefaultsManager {
    var cachedGuides: [DYMGuideObject]? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedGuides) as? Data, let paywalls = try? JSONDecoder().decode([DYMGuideObject].self, from: data) {
                return paywalls
            }

            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: DYMConstants.UserDefaults.cachedGuides)
        }
    }

    var cachedGuidePageIdentifier: String? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedGuidePageIdentifier) as? String {
                return data
            }
            return nil
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.cachedGuidePageIdentifier)
        }
    }
    
    var cachedGuideName: String? {
        get {
            if let data = defaults.object(forKey: DYMConstants.UserDefaults.cachedGuideName) as? String {
                return data
            }
            return nil
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.cachedGuideName)
        }
    }
    func guideConfigurations(configurations: [DYMGuideConfiguration]) -> [[String:Any]] {
        var config:[[String:Any]] = []
        for con in configurations {
            var subCon:[String:Any] = [:]
            subCon["key"] = con.key
            subCon["defaultValue"] = con.defaultValue
            subCon["localeValues"] = con.localeValues
            config.append(subCon)
        }
        return config
    }
}
//MARK: cached domainName
extension DYMDefaultsManager {
    
    var cachedDomainName: String? {
        get {
            if let cachedDomain = defaults.object(forKey: DYMConstants.UserDefaults.cachedDomainName) as? String {
                return cachedDomain
            }else {
                return nil
            }
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.cachedDomainName)
        }
    }    
}
