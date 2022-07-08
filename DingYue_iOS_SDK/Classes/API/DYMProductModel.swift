//
//  DYMProductModel.swift
//  DingYueMobileSDK
//
//  Created by YaoZiLiang on 2022/4/11.
//

import UIKit
import StoreKit

@objc public class DYMProductModel: NSObject, DYMJSONCodable, Codable {
    
    enum CodingKeys: String, CodingKey {
    case vendorIdentifier
    }
    
    @objc public enum PeriodUnit : UInt, Codable {
        case day
        case week
        case month
        case year
        case unknown
    }
    
    @objc public var vendorIdentifier:String = ""
    @objc public var skproduct: SKProduct? {
        didSet {
            guard let product = skproduct else { return }
            print(product)
        }
    }
    
    required init?(json: DYMParams) throws {
        
    }
    
    init(productId: String) {
        super.init()
        self.vendorIdentifier = productId
    }
}
