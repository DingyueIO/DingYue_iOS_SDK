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
        self.idfa = UserProperties.idfa
        self.idfv = UserProperties.idfv
        self.deviceToken = UserProperties.deviceToken
        self.androidId = ""
        self.gpsAdid = ""
        self.fireAdid = ""
        self.oaid = ""
        self.imei = ""
        self.device = UserProperties.device
        self.connection = UserProperties.connection
        self.googleProfileId = ""
        self.googleProfileName = ""
        self.googleExternalAccountId = ""
        self.emailAddress = ""
        self.familyName = ""
        self.givenName = ""
        self.attribution = attribution
    }
}
