//
// GlobalSwitch.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** globalSwitch */
@objcMembers public class GlobalSwitch: NSObject, Codable, JSONEncodable {

    public var showName: String
    public var varName: String
    public var value: Bool

    public init(showName: String, varName: String, value: Bool) {
        self.showName = showName
        self.varName = varName
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case showName
        case varName
        case value
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(showName, forKey: .showName)
        try container.encode(varName, forKey: .varName)
        try container.encode(value, forKey: .value)
    }
}

