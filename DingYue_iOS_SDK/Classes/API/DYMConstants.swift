//
//  Constants.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/10.
//

import UIKit
import StoreKit

class DYMConstants: NSObject {

    ///API Key
    enum APIKeys {
        static var secretKey = ""
        static var appId = ""
    }
    ///网络链接
    enum URLs {
        static let host = "mobile.dingyueio.com"
    }
    
    ///请求头
    enum Headers {
        static let apiKey = "X-API-KEY"
        static let appId  = "X-APP-ID"
        static let userId = "X-USER-ID"
        static let agent  = "User-Agent"
    }

    enum Versions {
        static let SDKVersion = "0.1.6"
        static let SDKBuild = 1
    }
    enum BundleKeys {
        static let appDelegateProxyEnabled = "DYAppDelegateProxyEnabled"
        static let appleSearchAdsAttributionCollectionEnabled = "DYAppleSearchAdsAttributionCollectionEnabled"
    }
    enum NotificationPayload {
        static let source = "source"
        static let promoDeliveryId = "promo_delivery_id"
    }
    enum UserDefaults {
        static let profileId                 = "DYMSDK_Profile_Id"
        static let installation              = "DYMSDK_Installation"
        static let apnsTokenString           = "DYMSDK_APNS_Token_String"
        static let cachedEvents              = "DYMSDK_Cached_Events"
        static let cachedVariationsIds       = "DYMSDK_Cached_Variations_Ids"
        static let purchaserInfo             = "DYMSDK_Purchaser_Info"
        static let cachedPaywalls            = "DYMSDK_Cached_Purchase_Containers"
        static let cachedProducts            = "DYMSDK_Cached_Products"
        static let cachedSwitchItems         = "DYMSDK_Cached_SwitchItems"
        static let cachedSubscribedObjects   = "DYMSDK_Cached_SubscribedObjects"
        static let appleSearchAdsSyncDate    = "DYMSDK_Apple_Search_Ads_Sync_Date"
        static let externalAnalyticsDisabled = "DYMSDK_External_Analytics_Disabled"
        static let previousResponseHashes    = "DYMSDK_Previous_Response_Hashes"
        static let responseJSONCaches        = "DYMSDK_Response_JSON_Caches"
        static let postRequestParamsHashes   = "DYMSDK_Post_Request_Params_Hashes"
        static let cachedPayWallPageUrl      = "DYMSDK_Cached_PayWall_Page_Url"
    }
    ///App信息plist文件
    enum AppInfoName {
        static let plistName = "DingYue"
        static let plistType = "plist"
        static let appId  = "DINGYUE_APP_ID"
        static let apiKey = "DINGYUE_API_KEY"
    }
}

public enum DYMAttributionSource: UInt {
    case appsFlyer
    case adjust
    case amplitude

    var rawString: String {
        switch self {
            case .appsFlyer: return "APPSFLYER"
            case .adjust: return "ADJUST"
            case .amplitude: return "AMPLITUDE"
        }
    }
}
// MARK: - Purchase
/// Payment transaction
public protocol DYMPaymentTransaction {
    var transactionDate: Date? { get }
    var transactionState: SKPaymentTransactionState { get }
    var transactionIdentifier: String? { get }
    var downloads: [SKDownload] { get }
}

extension SKPaymentTransaction: DYMPaymentTransaction {}
///Purchase detail
public struct DYMPurchaseDetail {
    public let productId: String
    public let quantity: Int
    public let product: SKProduct
    public let receipt: String
    public let transaction: DYMPaymentTransaction
    
    public init(productId: String,quantity: Int, product: SKProduct, receipt: String, transaction: DYMPaymentTransaction) {
        self.productId = productId
        self.quantity = quantity
        self.product = product
        self.receipt = receipt
        self.transaction = transaction
    }
}

public enum DYMPurchaseResult {
    case succeed(_ purchase: DYMPurchaseDetail)
    case failure(_ error: DYMError)
}

// MARK: - Block
public typealias DYMPurchaseCompletion = (_ receipt: String?,_ purchaseResult: [[String:Any]]?,_ error: DYMError?) -> Void
public typealias DYMRestoreCompletion = (_ receipt: String?,_ purchaseResult: [[String:Any]]?,_ error: DYMError?) -> Void
