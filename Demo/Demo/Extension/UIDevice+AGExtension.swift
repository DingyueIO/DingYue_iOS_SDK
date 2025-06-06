//
//  UIDevice+Extension.swift
//  TanchiShop_ios
//
//  Created by Steve on 2022/11/24.
//

import UIKit
import CoreTelephony
import SystemConfiguration
//import Alamofire

extension UIDevice {
    /// 顶部安全区高度
    static func ag_safeDistanceTop() -> CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let window = windowScene.windows.first else { return 0 }
            return window.safeAreaInsets.top
        } else if #available(iOS 11.0, *) {
            guard let window = UIApplication.shared.windows.first else { return 0 }
            return window.safeAreaInsets.top
        }
        return 0;
    }
    
    /// 底部安全区高度
    static func ag_safeDistanceBottom() -> CGFloat {
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let window = windowScene.windows.first else { return 0 }
            return window.safeAreaInsets.bottom
        } else if #available(iOS 11.0, *) {
            guard let window = UIApplication.shared.windows.first else { return 0 }
            return window.safeAreaInsets.bottom
        }
        return 0;
    }
    
    /// 顶部状态栏高度（包括安全区）
    static func ag_statusBarHeight() -> CGFloat {
        var statusBarHeight: CGFloat = 0
        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes.first
            guard let windowScene = scene as? UIWindowScene else { return 0 }
            guard let statusBarManager = windowScene.statusBarManager else { return 0 }
            statusBarHeight = statusBarManager.statusBarFrame.height
        } else {
            statusBarHeight = UIApplication.shared.statusBarFrame.height
        }
        return statusBarHeight
    }
    
    /// 导航栏高度
    static func ag_navigationBarHeight() -> CGFloat {
        return 44.0
    }
    
    /// 状态栏+导航栏的高度
    static func ag_navigationFullHeight() -> CGFloat {
        return UIDevice.ag_statusBarHeight() + UIDevice.ag_navigationBarHeight()
    }
    
    /// 底部导航栏高度
    static func ag_tabBarHeight() -> CGFloat {
        return 49.0
    }
    
    /// 底部导航栏高度（包括安全区）
    static func ag_tabBarFullHeight() -> CGFloat {
        return UIDevice.ag_tabBarHeight() + UIDevice.ag_safeDistanceBottom()
    }
}

extension UIDevice {
    static func modelName() -> String {
      var systemInfo = utsname()
      uname(&systemInfo)
      let machineMirror = Mirror(reflecting: systemInfo.machine)
      let identifier = machineMirror.children.reduce("") { identifier, element in
         guard let value = element.value as? Int8, value != 0 else { return identifier }
         return identifier + String(UnicodeScalar(UInt8(value)))
      }
      switch identifier {
         //TODO:iPod touch
         case "iPod1,1":                                       return "iPod touch"
         case "iPod2,1":                                       return "iPod touch (2nd generation)"
         case "iPod3,1":                                       return "iPod touch (3rd generation)"
         case "iPod4,1":                                       return "iPod touch (4th generation)"
         case "iPod5,1":                                       return "iPod touch (5th generation)"
         case "iPod7,1":                                       return "iPod touch (6th generation)"
         case "iPod9,1":                                       return "iPod touch (7th generation)"

         //TODO:iPad
         case "iPad1,1":                                       return "iPad"
         case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":      return "iPad 2"
         case "iPad3,1", "iPad3,2", "iPad3,3":                 return "iPad (3rd generation)"
         case "iPad3,4", "iPad3,5", "iPad3,6":                 return "iPad (4th generation)"
         case "iPad6,11", "iPad6,12":                          return "iPad (5th generation)"
         case "iPad7,5", "iPad7,6":                            return "iPad (6th generation)"
         case "iPad7,11", "iPad7,12":                          return "iPad (7th generation)"
         case "iPad11,6", "iPad11,7":                          return "iPad (8th generation)"
         case "iPad12,1", "iPad12,2":                          return "iPad (9th generation)"

         //TODO:iPad Air
         case "iPad4,1", "iPad4,2", "iPad4,3":                 return "iPad Air"
         case "iPad5,3", "iPad5,4":                            return "iPad Air 2"
         case "iPad11,3", "iPad11,4":                          return "iPad Air (3rd generation)"
         case "iPad13,1", "iPad13,2":                          return "iPad Air (4rd generation)"

         //TODO:iPad Pro
         case "iPad6,3", "iPad6,4":                            return "iPad Pro (9.7-inch)"
         case "iPad7,3", "iPad7,4":                            return "iPad Pro (10.5-inch)"
         case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":      return "iPad Pro (11-inch)"
         case "iPad8,9", "iPad8,10":                           return "iPad Pro (11-inch) (2nd generation)"
         case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":  return "iPad Pro (11-inch) (3rd generation)"
         case "iPad6,7", "iPad6,8":                            return "iPad Pro (12.9-inch)"
         case "iPad7,1", "iPad7,2":                            return "iPad Pro (12.9-inch) (2nd generation)"
         case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":      return "iPad Pro (12.9-inch) (3rd generation)"
         case "iPad8,11", "iPad8,12":                          return "iPad Pro (12.9-inch) (4th generation)"
         case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11":return "iPad Pro (12.9-inch) (5th generation)"

         //TODO:iPad mini
         case "iPad2,5", "iPad2,6", "iPad2,7":                 return "iPad mini"
         case "iPad4,4", "iPad4,5", "iPad4,6":                 return "iPad Mini 2"
         case "iPad4,7", "iPad4,8", "iPad4,9":                 return "iPad Mini 3"
         case "iPad5,1", "iPad5,2":                            return "iPad Mini 4"
         case "iPad11,1", "iPad11,2":                          return "iPad mini (5th generation)"
         case "iPad14,1", "iPad14,2":                          return "iPad mini (6th generation)"

         //TODO:iPhone
         case "iPhone1,1":                               return "iPhone"
         case "iPhone1,2":                               return "iPhone 3G"
         case "iPhone2,1":                               return "iPhone 3GS"
         case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
         case "iPhone4,1":                               return "iPhone 4s"
         case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
         case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
         case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
         case "iPhone7,2":                               return "iPhone 6"
         case "iPhone7,1":                               return "iPhone 6 Plus"
         case "iPhone8,1":                               return "iPhone 6s"
         case "iPhone8,2":                               return "iPhone 6s Plus"
         case "iPhone8,4":                               return "iPhone SE (1st generation)"
         case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
         case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
         case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
         case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
         case "iPhone10,3", "iPhone10,6":                return "iPhone X"
         case "iPhone11,8":                              return "iPhone XR"
         case "iPhone11,2":                              return "iPhone XS"
         case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
         case "iPhone12,1":                              return "iPhone 11"
         case "iPhone12,3":                              return "iPhone 11 Pro"
         case "iPhone12,5":                              return "iPhone 11 Pro Max"
         case "iPhone12,8":                              return "iPhone SE (2nd generation)"
         case "iPhone13,1":                              return "iPhone 12 mini"
         case "iPhone13,2":                              return "iPhone 12"
         case "iPhone13,3":                              return "iPhone 12 Pro"
         case "iPhone13,4":                              return "iPhone 12 Pro Max"
         case "iPhone14,4":                              return "iPhone 13 mini"
         case "iPhone14,5":                              return "iPhone 13"
         case "iPhone14,2":                              return "iPhone 13 Pro"
         case "iPhone14,3":                              return "iPhone 13 Pro Max"
         case "iPhone14,6":                              return "iPhone SE (3rd generation)"
         case "iPhone14,7":                              return "iPhone 14"
         case "iPhone14,8":                              return "iPhone 14 Plus"
         case "iPhone15,2":                              return "iPhone 14 Pro"
         case "iPhone15,3":                              return "iPhone 14 Pro Max"
         case "iPhone15,4":                              return "iPhone 15"
         case "iPhone15,5":                              return "iPhone 15 Plus"
         case "iPhone16,1":                              return "iPhone 15 Pro"
         case "iPhone16,2":                              return "iPhone 15 Pro Max"
         case "iPhone17,3":                              return "iPhone 16"
         case "iPhone17,4":                              return "iPhone 16 Plus"
         case "iPhone17,1":                              return "iPhone 16 Pro"
         case "iPhone17,2":                              return "iPhone 16 Pro Max"

         case "AppleTV5,3":                              return "Apple TV"
         case "i386", "x86_64":                          return "iPhone Simulator"
         default:                                        return identifier
      }
   }
    
    /// 获取网络类型
    static func getNetworkType() -> String {
        let notReachable = "notReachable"
        var zeroAddress = sockaddr_storage()
        bzero(&zeroAddress, MemoryLayout<sockaddr_storage>.size)
        zeroAddress.ss_len = __uint8_t(MemoryLayout<sockaddr_storage>.size)
        zeroAddress.ss_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
                SCNetworkReachabilityCreateWithAddress(nil, address)
            }
        }
        guard let defaultRouteReachability = defaultRouteReachability else {
            return notReachable
        }
        var flags = SCNetworkReachabilityFlags()
        let didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags)
        
        guard didRetrieveFlags == true,
              (flags.contains(.reachable) && !flags.contains(.connectionRequired)) == true
        else {
            return notReachable
        }
        if flags.contains(.connectionRequired) {
            return notReachable
        } else if flags.contains(.isWWAN) {
            return self.cellularType()
        } else {
            return "WiFi"
        }
    }
        
    /// 获取蜂窝数据类型
    static func cellularType() -> String {
        let notReachable = "notReachable"
        let info = CTTelephonyNetworkInfo()
        var status: String
        
        if #available(iOS 12.0, *) {
            guard let dict = info.serviceCurrentRadioAccessTechnology,
                  let firstKey = dict.keys.first,
                  let statusTemp = dict[firstKey] else {
                return notReachable
            }
            status = statusTemp
        } else {
            guard let statusTemp = info.currentRadioAccessTechnology else {
                return notReachable
            }
            status = statusTemp
        }
        
        if #available(iOS 14.1, *) {
            if status == CTRadioAccessTechnologyNR || status == CTRadioAccessTechnologyNRNSA {
                return "5G"
            }
        }
        
        switch status {
        case CTRadioAccessTechnologyGPRS,
            CTRadioAccessTechnologyEdge,
        CTRadioAccessTechnologyCDMA1x:
            return "2G"
        case CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyeHRPD,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
        CTRadioAccessTechnologyCDMAEVDORevB:
            return "3G"
        case CTRadioAccessTechnologyLTE:
            return "4G"
        default:
            return notReachable
        }
    }
    
}


extension UIDevice {
    static func authenticationNetWork(_ showAlert:Bool = false, success:(() -> Void)? = nil, failed:((CTCellularDataRestrictedState) -> Void)? = nil) {
        let cellularData = CTCellularData()
        cellularData.cellularDataRestrictionDidUpdateNotifier = { state in
            switch state {
            case .restricted:  //拒绝
                failed?(state)
                break
            case .notRestricted: //允许
                success?()
                break
            case .restrictedStateUnknown: //未知
                failed?(state)
                break
            default:
                failed?(state)
                break
            }
        }
    }
    
//    static var isNetworkConnect: Bool {
//        let network = NetworkReachabilityManager()
//        return network?.isReachable ?? true // 无返回就默认网络已连接
//    }
    
//    static func noNetworkConnect() -> Bool {
//        return !UIDevice.isNetworkConnect
//    }
    
    //判断是否有插SIM卡
    static func ag_haveSIMCard() -> Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrierProviders = networkInfo.serviceSubscriberCellularProviders {
            for item in carrierProviders.values {
                if item.mobileNetworkCode != nil {
                    return true
                }
            }
        }
//        AGLog("可能没有插SIM卡，或者无法读取运营商信息")
        return false
    }
    
//    //判断是否有插SIM卡
//    static func ag_haveSIMCard() -> Bool {
//        let networkInfo = CTTelephonyNetworkInfo()
//        if let carrier = networkInfo.subscriberCellularProvider {
//            if let carrierName = carrier.carrierName {
//                AGLog("Carrier Name: \(carrierName)")
//                return true
//            } else {
//                AGLog("可能没有插SIM卡，或者无法读取运营商信息")
//                return false
//            }
//        } else {
//            AGLog("可能没有插SIM卡，或者无法读取运营商信息")
//            return false
//        }
//    }
    
    static func ag_isVPNConnected() -> Bool {
        if let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as NSDictionary?,
           let scoped = settings["__SCOPED__"] as? [String: AnyObject] {
            for key in scoped.keys {
                if key.contains("tap") || key.contains("tun") || key.contains("ppp") {
                    return true
                }
            }
        }
        return false
    }
}
