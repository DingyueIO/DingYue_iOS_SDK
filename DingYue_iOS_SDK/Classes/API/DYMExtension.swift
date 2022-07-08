//
//  DYExtension.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/10.
//

#if canImport(UIKit)
extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("", { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        })
    }()

}
#endif
extension UUID {

    var stringValue: String {
        return self.uuidString.lowercased()
    }

}

extension Dictionary {
    
    func attributes() throws -> DYMParams  {
        guard let json = self as? DYMParams else {
            throw DYMError.invalidProperty("JSON response", self)
        }
        
        guard var attributes = json["attributes"] as? Parameters else {
            throw DYMError.missingParam("JSON response - attributes")
        }
        
        if let id = json["id"] as? String {
            attributes["id"] = id
        }
        
        return attributes
    }
    
    static func formatData(with id: Any, type: String, attributes: DYMParams) -> DYMParams {
        var data = ["id": id, "type": type]
        if attributes.count > 0 {
            data["attributes"] = attributes
        }
        return ["data": data]
    }
    
}

extension String {

    var dateValue: Date? {
        return DateFormatter.iso8601Formatter.date(from: self)
    }

}

extension DateFormatter {

    static var iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()

}
extension AppleSearchAdsAttribution {
    init(attribution:DYMParams) {
        self.iadAttribution = attribution["iad-attribution"] as? String ?? ""
        self.iadOrgName = attribution["iad-org-name"] as? String ?? ""
        self.iadOrgId = attribution["iad-org-id"] as? String ?? ""
        self.iadCampaignId = attribution["iad-campaign-id"] as? String ?? ""
        self.iadCampaignName = attribution["iad-campaign-name"] as? String ?? ""
        self.iadClickDate = attribution["iad-click-date"] as? String ?? ""
        self.iadPurchaseDate = attribution["iad-purchase-date"] as? String ?? ""
        self.iadConversationDate = attribution["iad-conversation-date"] as? String ?? ""
        self.iadConversationType = IadConversationType(rawValue: attribution["iad-conversation-type"] as? String ?? "newdownload") 
        self.iadAdgroupName = attribution["iad-adgroup-name"] as? String ?? ""
        self.iadAdgroupId = attribution["iad-adgroup-id"] as? String ?? ""
        self.iadCountryOrRegion = attribution["iad-country-or-region"] as? String ?? ""
        self.iadKeyword = attribution["iad-keyword"] as? String ?? ""
        self.iadKeywordId = attribution["iad-keyword-id"] as? String ?? ""
        self.iadKeywordMatchtype = IadKeywordMatchtype(rawValue: attribution["iad-keyword-matchtype"] as? String ?? "BOARD")
        self.iadCreativesetId = attribution["iad-creativeset-id"] as? String ?? ""
        self.iadCreativesetName = attribution["iad-creativeset-name"] as? String ?? ""
    }
}

private let noInternetNetworkErrors = [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost,
                                       NSURLErrorDNSLookupFailed, NSURLErrorResourceUnavailable,
                                       NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost]
extension NSError {
    
    var isNotConnection: Bool { noInternetNetworkErrors.contains(code) }
    
}
