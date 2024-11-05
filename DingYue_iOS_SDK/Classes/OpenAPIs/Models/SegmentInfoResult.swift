//
//  SegmentInfoResult.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2024/11/5.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@objcMembers public class SegmentInfoResult: NSObject, Codable, JSONEncodable {
    
    public enum Status: String, Codable, CaseIterable {
        case ok = "ok"
        case fail = "fail"
    }
    
    /** the status of the operation */
    public var status: Status
    /** indicated why this operation fails */
    public var errmsg: String?
    /** list of segments */
    public var segmentList: [String] // String array for segment information, initialized as an empty array

    public init(status: Status, errmsg: String? = nil, segmentList: [String] = []) {
        self.status = status
        self.errmsg = errmsg
        self.segmentList = segmentList
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case status
        case errmsg
        case segmentList
    }

    // Encodable protocol methods
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(errmsg, forKey: .errmsg)
        // Use encodeIfPresent to ensure it can handle nil values
        try container.encodeIfPresent(segmentList.isEmpty ? nil : segmentList, forKey: .segmentList)
    }
    
    // Decodable protocol methods
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(Status.self, forKey: .status)
        errmsg = try container.decodeIfPresent(String.self, forKey: .errmsg)
        // Decode segmentList with a fallback to an empty array if nil
        segmentList = try container.decodeIfPresent([String].self, forKey: .segmentList) ?? []
    }
}
