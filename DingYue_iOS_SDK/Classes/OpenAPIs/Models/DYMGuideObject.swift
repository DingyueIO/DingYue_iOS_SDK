//
//  DYMGuideObject.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2024/9/2.
//

import UIKit
#if canImport(AnyCodable)
import AnyCodable
#endif

/** an object describing the purchase page configuration */
public struct DYMGuideObject: Codable, JSONEncodable, Hashable {

    /** name */
    public var name: String
    /** paywall version number */
    public var version: Double
    public var subscriptions: [DYMGudieSubscriptions]
    public var downloadUrl: String
    public var previewUrl: String?
    public var customize: Bool
    public var configurations: [DYMGuideConfiguration]?
    public var purchaseSwitch: Bool
    public var swiperSize: Int

    public init(name: String, version: Double, subscriptions: [DYMGudieSubscriptions], downloadUrl: String, previewUrl: String? = nil, customize: Bool, configurations: [DYMGuideConfiguration]? = nil, purchaseSwitch: Bool,swiperSize:Int) {
        self.name = name
        self.version = version
        self.subscriptions = subscriptions
        self.downloadUrl = downloadUrl
        self.previewUrl = previewUrl
        self.customize = customize
        self.configurations = configurations
        self.purchaseSwitch = purchaseSwitch
        self.swiperSize = swiperSize
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        case version
        case subscriptions
        case downloadUrl
        case previewUrl
        case customize
        case configurations
        case purchaseSwitch
        case swiperSize
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(version, forKey: .version)
        try container.encode(subscriptions, forKey: .subscriptions)
        try container.encode(downloadUrl, forKey: .downloadUrl)
        try container.encodeIfPresent(previewUrl, forKey: .previewUrl)
        try container.encode(customize, forKey: .customize)
        try container.encode(configurations, forKey: .configurations)
        try container.encode(purchaseSwitch, forKey: .purchaseSwitch)
        try container.encode(swiperSize, forKey: .swiperSize)
    }
}

public struct DYMGuideConfiguration:Codable, JSONEncodable, Hashable {
    public var key: String
    public var defaultValue: String
    public var localeValues: [String:String]
    
    public init(key: String, defaultValue: String, localeValues: [String:String]) {
        self.key = key
        self.defaultValue = defaultValue
        self.localeValues = localeValues
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case key
        case defaultValue
        case localeValues
    }

    // Encodable protocol methods
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(defaultValue, forKey: .defaultValue)
        try container.encode(localeValues, forKey: .localeValues)
    }
}

public struct DYMGudieSubscriptions: Codable, JSONEncodable, Hashable {

    public var subscriptionId: String?
    public var subscription: Subscription?

    public init(subscriptionId: String? = nil, subscription: Subscription? = nil) {
        self.subscriptionId = subscriptionId
        self.subscription = subscription
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case subscriptionId
        case subscription
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(subscriptionId, forKey: .subscriptionId)
        try container.encodeIfPresent(subscription, forKey: .subscription)
    }
}
