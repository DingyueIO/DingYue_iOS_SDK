//
//  IWDingYueLog.swift
//  QRScanner
//
//  Created by TJ on 2025/1/10.
//

import Foundation
import DingYue_iOS_SDK

class IWDingYueLog {
    
    static func logEvent(_ event: String, extra: String? = nil, user: String? = nil) {
        DYMobileSDK.track(event: event, extra: extra, user: user)
    }
    
}
