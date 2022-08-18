//
//  ReportObject.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/24.
//

import UIKit
import StoreKit

class ReportObject: NSObject {
    var ReceiptVerifyPostObject:ReceiptVerifyPostObject?
}

extension UniqueUserObject{
    public init(attribution: UniqueUserObjectAttribution? = nil) {
        self.osVersion = UserProperties.OS
        self.appVersion = UserProperties.appVersion
        self.idfa = UserProperties.idfa
        self.idfv = UserProperties.idfv
        self.deviceToken = UserProperties.deviceToken
        self.device = UserProperties.device
        self.connection = UserProperties.connection
        self.attribution = attribution
        self.area = UserProperties.area
        self.language = UserProperties.language
    }
}
