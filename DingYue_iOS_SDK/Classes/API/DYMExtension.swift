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
        if let version31 = attribution["Version3.1"] as? Dictionary<String,Any> {
            self.iadAttribution = version31["iad-attribution"] as? String
            self.iadOrgName = version31["iad-org-name"] as? String
            self.iadOrgId = version31["iad-org-id"] as? String
            self.iadCampaignId = version31["iad-campaign-id"] as? String
            self.iadCampaignName = version31["iad-campaign-name"] as? String
            self.iadClickDate = version31["iad-click-date"] as? String
            self.iadPurchaseDate = version31["iad-purchase-date"] as? String
            
            if let iadConversationDate = version31["iad-conversation-date"] as? String {
                self.iadConversationDate = iadConversationDate
            } else {
               if let iadConversationDate = version31["iad-conversion-date"] as? String {
                   self.iadConversationDate = iadConversationDate
                }
            }
            
            if let iadConversationType = version31["iad-conversation-type"] as? String {
                self.iadConversationType = IadConversationType(rawValue: iadConversationType)
            } else {
                if let iadConversationType = version31["iad-conversion-type"] as? String {
                    if iadConversationType == "Download" {
                        self.iadConversationType = .newdownload
                    } else {
                        self.iadConversationType = .redownload
                    }
                }
            }
            self.iadAdgroupName = version31["iad-adgroup-name"] as? String
            self.iadAdgroupId = version31["iad-adgroup-id"] as? String
            self.iadCountryOrRegion = version31["iad-country-or-region"] as? String
            self.iadKeyword = version31["iad-keyword"] as? String
            self.iadKeywordId = version31["iad-keyword-id"] as? String
            if let iadKeywordMatchtype = version31["iad-keyword-matchtype"] as? String {
                self.iadKeywordMatchtype = IadKeywordMatchtype(rawValue: iadKeywordMatchtype)
            }
            self.iadCreativesetId = version31["iad-creativeset-id"] as? String
            self.iadCreativesetName = version31["iad-creativeset-name"] as? String
            
            self.iadAdId = version31["iad-Ad-id"] as? String
            self.iadClaimType = version31["iad-claim-type"] as? String
            
        } else {
            
            if let attribute = attribution["attribution"] as? Bool{
                self.iadAttribution = (attribute == true) ? "true" : "false"
            }
            if let iadOrgId = attribution["orgId"] {
                self.iadOrgId = "\(iadOrgId)"
            }
            if let iadCampaignId = attribution["campaignId"] {
                self.iadCampaignId = "\(iadCampaignId)"
            }
            if let conversion = attribution["conversionType"] {
                if "\(conversion)" == "Download" {
                    self.iadConversationType = .newdownload
                } else {
                    self.iadConversationType = .redownload
                }
            }
            if let iadAdgroupId = attribution["adGroupId"] {
                self.iadAdgroupId = "\(iadAdgroupId)"
            }
            if let iadCountryOrRegion = attribution["countryOrRegion"] {
                self.iadCountryOrRegion = "\(iadCountryOrRegion)"
            }
            if let iadKeywordId = attribution["keywordId"] {
                self.iadKeywordId = "\(iadKeywordId)"
            }
            
            if let iadClickDate = attribution["clickDate"] {
                self.iadClickDate = "\(iadClickDate)"
            }
            if let iadAdId = attribution["adId"] {
                self.iadAdId = "\(iadAdId)"
            }
            if let iadClaimType = attribution["claimType"] {
                self.iadClaimType = "\(iadClaimType)"
            }
            
        }
    }
}

private let noInternetNetworkErrors = [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost,
                                       NSURLErrorDNSLookupFailed, NSURLErrorResourceUnavailable,
                                       NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost]
extension NSError {
    
    var isNotConnection: Bool { noInternetNetworkErrors.contains(code) }
    
}
