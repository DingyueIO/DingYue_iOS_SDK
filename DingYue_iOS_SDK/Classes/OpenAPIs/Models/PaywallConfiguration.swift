//
//  PaywallConfiguration.swift
//  DingYue_iOS_SDK
//
//  Created by apple on 2024/1/16.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct PaywallConfiguration:Codable, JSONEncodable, Hashable {
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

