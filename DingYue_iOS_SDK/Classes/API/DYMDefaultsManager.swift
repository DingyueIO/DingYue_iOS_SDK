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

    ///是否有存在内购页
    public var isExistPayWall = false

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

    var cachedEvents: [[String: String]] {
        get {
            return defaults.array(forKey: DYMConstants.UserDefaults.cachedEvents) as? [[String: String]] ?? []
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.cachedEvents)
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

    // [%requestType: %hash]
    var previousResponseHashes: [String: String] {
        get {
            return (defaults.dictionary(forKey: DYMConstants.UserDefaults.previousResponseHashes) as? [String: String]) ?? [:]
        }
        set {
            defaults.set(newValue, forKey: DYMConstants.UserDefaults.previousResponseHashes)
        }
    }

    // [%requestType: [%hash: data]]
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
                if let originalTransactionId = sub.originalTransactionId {
                    subDic["originalTransactionId"] = originalTransactionId
                }
                if let expiresAt = sub.expiresAt {
                    subDic["expiresAt"] = expiresAt
                }
                subsArray.append(subDic)
            }
        }
        return subsArray
    }

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
                subsArray.append(subDic)
            }
        }
        return subsArray
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
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedEvents)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedVariationsIds)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedPaywalls)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedProducts)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedSwitchItems)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.cachedSubscribedObjects)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.appleSearchAdsSyncDate)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.externalAnalyticsDisabled)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.previousResponseHashes)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.responseJSONCaches)
        defaults.removeObject(forKey: DYMConstants.UserDefaults.postRequestParamsHashes)
    }
}
