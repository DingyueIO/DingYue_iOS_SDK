//
//  UserProperties.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/10.
//
#if canImport(AdSupport)
import AdSupport
#endif

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

#if canImport(AdServices)
import AdServices
#endif

#if canImport(iAd)
import iAd
#endif

#if canImport(FCUUID)
import FCUUID
#endif

import Foundation
#if canImport(UIKit)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public typealias Parameters = [String: Any]

@objcMembers public class UserProperties:NSObject {
    public static var staticUuid = UUID().stringValue
    class func resetStaticUuid() {
        staticUuid = UUID().stringValue
    }
    public static var extraData: [String:String]?
    static var uuid: String {
        return UUID().stringValue//will have different value for every new instance
    }
    private static var _requestUUID: String = FCUUID.uuidForDevice() ?? ""
    public static var requestUUID: String {
        get {
            let appId = DYMConstants.APIKeys.appId
            if _sdk0312AppIds.contains(appId) {
                return FCUUID.uuidForDevice() ?? ""
            }
            // If _requestUUID is not in UUID format, use the original value and print a warning
            if _requestUUID.isEmpty || !isValidUUID(_requestUUID) {
                let validUUID = convertToAppleUUIDFormat(FCUUID.uuidForDevice() ?? UUID().uuidString)
                if !isValidUUID(validUUID) {
                    // If the converted UUID still does not meet the format, use the original UUID and print a warning
                    print("❌ The device UUID '\(_requestUUID)' is not in valid Apple UUID format. Using the original value.")
                    _requestUUID = FCUUID.uuidForDevice() ?? ""
                } else {
                    _requestUUID = validUUID
                }
            }
            return _requestUUID
        }
        set {
            // If the new UUID is valid, assign it directly
            if isValidUUID(newValue) {
                _requestUUID = newValue
            } else {
                // If the UUID cannot be converted to a valid Apple UUID format, keep the original value
                let validUUID = convertToAppleUUIDFormat(newValue)
                // If the converted UUID is still invalid, keep the original value and print a warning
                if !isValidUUID(validUUID) {
                    print("❌ The provided UUID '\(newValue)' is not valid. Using the original value.")
                }
                _requestUUID = validUUID
            }
        }
    } 
    
    private static let _sdk0312AppIds = ["74267848f2084ba9913080f8c6010abb", "832c0286e58a45e4829712d8b3515fd7"]
    private static var _requestAppId: String = DYMConstants.APIKeys.appId
    public static var requestAppId: String {
        get {
            return _requestAppId
        }
    }
    
    static var userAgent: String {
        return "user-agent"
    }
    static var userSubscriptionPurchasedSources: String {
        return "uniqueUser.extraData.userPurchasedSources"
    }
    static var userSubscriptionPurchasedSourcesType:DYMUserSubscriptionPurchasedSourceType? = nil
    static var appID: String = ""
    static var idfa: String? {
        // Get and return IDFA
//        if DYMobileSDK.idfaCollectionDisabled == false, #available(iOS 9.0, macOS 10.14, *) {
//            if #available(iOS 14, *) {
//                if ATTrackingManager.trackingAuthorizationStatus == .authorized {
//                    return ASIdentifierManager.shared().advertisingIdentifier.uuidString
//                } else {
//                    return nil
//                }
//            } else {
//                if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
//                    return ASIdentifierManager.shared().advertisingIdentifier.uuidString
//                }else{
//                    return nil
//                }
//            }
//        } else {
            return nil
//        }
    }
    static var idfv: String?  {
        guard let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString else {
            return nil
        }
        return identifierForVendor
    }

    static var connection: UniqueUserObject.Connection = .unknown

    static var sdkVersion: String {
        return DYMConstants.Versions.SDKVersion
    }

    static var sdkVersionBuild: Int {
        return DYMConstants.Versions.SDKBuild
    }

    static var appBuild: String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }

    static var appVersion: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    static var pallwallPath:String?{
        return createPaywallDir()
    }

    static var area: String? {
        if(DYMobileSDK.checkIsSb()){
           return "AS0"
        }else{
           return NSLocale.current.regionCode
        }
    }

    static var language: String? {
        return NSLocale.preferredLanguages[0]
    }
    class func createPaywallDir() -> String? {
        let DocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let filePath = DocumentPaths[0].appending("/PayWallWeb")
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) {
            if isDir.boolValue{
                DYMLogManager.logMessage("paywall directory already exists")
                return filePath
            }else{
                return nil
            }
        }else{
            do {
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: false, attributes: nil)
                return filePath
            } catch {
                DYMLogManager.logError(error)
                return nil
            }
        }
    }
    
    static var guidePath: String? {
        return createGuideDirPath()
    }
    class func createGuideDirPath() ->String?{
        let DocumentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let filePath = DocumentPaths[0].appending("/GuideWeb")
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) {
            if isDir.boolValue{
                DYMLogManager.logMessage("guide directory already exists")
                return filePath
            }else{
                return nil
            }
        }else{
            do {
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: false, attributes: nil)
                return filePath
            } catch {
                DYMLogManager.logError(error)
                return nil
            }
        }
    }
    
    
    static var device: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        let matchingDict = IOServiceMatching("IOPlatformExpertDevice")
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
        defer { IOObjectRelease(service) }

        if let modelData = IORegistryEntryCreateCFProperty(service,
                                                           "model" as CFString,
                                                           kCFAllocatorDefault, 0).takeRetainedValue() as? Data,
           let cString = modelData.withUnsafeBytes({ $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }) {
            return String(cString: cString)
        } else {
            return "unknown device"
        }
        #else
        return UIDevice.modelName
        #endif
    }

    static var locale: String {
        return Locale.preferredLanguages.first ?? Locale.current.identifier
    }

    static var OS: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        return "macOS \(ProcessInfo().operatingSystemVersionString)"
        #else
        return "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        #endif
    }

    static var platform: String {
        #if os(macOS) || targetEnvironment(macCatalyst)
        return "macOS"
        #else
        return UIDevice.current.systemName
        #endif
    }

    static var timezone: String {
        return TimeZone.current.identifier
    }

    static var deviceToken: String? {
        guard let token = DYMobileSDK.apnsTokenString else {
            return nil
        }
        return token
    }


    #if os(iOS)
    class func appleSearchAdsAttribution(completion: @escaping (Parameters, Error?) -> Void) {
        modernAppleSearchAdsAttribution(completion: completion)
    }

    private class func modernAppleSearchAdsAttribution(retry:Int? = 2, completion: @escaping (Parameters, Error?) -> Void) {
        if #available(iOS 14.3, *) {
            do {
                let attributionToken = try AAAttribution.attributionToken()
                let request = NSMutableURLRequest(url: URL(string:"https://api-adservices.apple.com/api/v1/")!)
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = Data(attributionToken.utf8)
                let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
                    
                    if let r = retry, r != 0, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        
                        DYMEventManager.shared.track(event: "ASA_FAIL", extra: "status code: \(httpResponse.statusCode), error: \(error?.localizedDescription ?? "no error")")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            modernAppleSearchAdsAttribution(retry: (r - 1), completion: completion)
                        }
                        return
                    }
                    
                    guard let data = data else {
                        if let r = retry, r != 0, let httpResponse = response as? HTTPURLResponse {
                            DYMEventManager.shared.track(event: "ASA_FAIL", extra: "status code: \(httpResponse.statusCode), error: \(error?.localizedDescription ?? "data is nil")")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                                modernAppleSearchAdsAttribution(retry: (r - 1), completion: completion)
                            }
                        } else {
                            completion(["":""], error)
                        }
                        return
                    }
                    do {
                        let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Parameters
                        if result != nil {
                            DYMEventManager.shared.track(event: "ASA_SUCCESS", extra: "status code: 200")
                        }
                        completion(result ?? ["":""], nil)
                    } catch {
                        completion(["":""], error)
                    }
                }
                task.resume()
            } catch  {
                completion(["":""], error)
            }
        } else {
            completion(["":""], nil)
        }
    }
    #endif
    
    public static var luaScriptDirectoryPath:String?{
        return createLuaScriptDirectory()
    }
    class func createLuaScriptDirectory() -> String? {
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0].appending("/LuaScriptDirectory")
        var isDir : ObjCBool = false
        
        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) {
            if isDir.boolValue{
                DYMLogManager.logMessage("ScriptLuas directory already exists")
                return filePath
            }else{
                return nil
            }
        } else{
            do {
                try FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: false, attributes: nil)
                return filePath
            } catch {
                DYMLogManager.logError(error)
                return nil
            }
        }
    }
}
//MARK: Private method
extension UserProperties {
    // 验证 UUID 格式是否符合标准
    // Verify if the UUID format conforms to the standard
    private static func isValidUUID(_ uuidString: String) -> Bool {
        let uuidRegex = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
        let uuidTest = NSPredicate(format: "SELF MATCHES %@", uuidRegex)
        return uuidTest.evaluate(with: uuidString)
    }

    private static func convertToAppleUUIDFormat(_ uuidString: String) -> String {
        // If the string length is not 32, return the original string
        if uuidString.count != 32 {
            print("⚠️ The UUID '\(uuidString)' length is not 32 characters. Keeping the original value.")
            return uuidString
        }

        // Use String.Index to slice the string
        let startIndex = uuidString.startIndex
        let part1 = uuidString.prefix(8)
        let part2 = uuidString[uuidString.index(startIndex, offsetBy: 8)..<uuidString.index(startIndex, offsetBy: 12)]
        let part3 = uuidString[uuidString.index(startIndex, offsetBy: 12)..<uuidString.index(startIndex, offsetBy: 16)]
        let part4 = uuidString[uuidString.index(startIndex, offsetBy: 16)..<uuidString.index(startIndex, offsetBy: 20)]
        let part5 = uuidString.suffix(12)
        
        // Concatenate parts into standard UUID format
        return part1 + "-" + part2 + "-" + part3 + "-" + part4 + "-" + part5
    }
}
