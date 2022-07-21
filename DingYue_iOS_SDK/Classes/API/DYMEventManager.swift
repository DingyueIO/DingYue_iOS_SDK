//
//  EventReportManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/25.
//

import UIKit
import CommonCrypto

@objc public enum DYMEventType: Int {
    ///进入内购页
    case ENTER_PURCHASE
    ///退出订阅页
    case EXIT_PURCHASE
    ///点击关闭按钮
    case CLOSE_BUTTON
    ///点击关于我们
    case ABOUT_US
    ///点击隐私协议
    case ABOUT_PRIVACYPOLICY
    ///点击服务条款
    case ABOUT_TERMSOFSERVICE
    ///点击分享
    case ABOUT_SHARE
    ///点击购买按钮
    case PURCHASE_START
    ///订阅成功
    case PURCHASE_SUCCESS
    ///取消订阅
    case PURCHASE_CANCLED
    ///点击恢复购买
    case PURCHASE_RESTORE
    ///点击周付
    case PURCHASE_WEEK
    ///点击月付
    case PURCHASE_MONTH
    ///点击季付
    case PURCHASE_3MONTH
    ///点击半年付
    case PURCHASE_6MONTH
    ///点击年付
    case PURCHASE_YEAR
    ///点击消耗型
    case PURCHASE_CONSUME
    ///点击一次性消费
    case PURCHASE_ONCE
}

class DYMEventManager {

    static let shared = DYMEventManager()

    private init() {

    }

    private var cachedEvents: [[String: String]] {
        get {
            return DYMDefaultsManager.shared.cachedEvents
        }
        set {
            DYMDefaultsManager.shared.cachedEvents = newValue
        }
    }
    private func getEventTypeString(type:DYMEventType)->String{
        var typeStr:String = ""
        switch type {
            case .ENTER_PURCHASE:
                typeStr = "ENTER_PURCHASE"
                break
            case .EXIT_PURCHASE:
                typeStr = "EXIT_PURCHASE"
                break
            case .ABOUT_US:
                typeStr = "ABOUT_US"
                break
            case .ABOUT_PRIVACYPOLICY:
                typeStr = "ABOUT_PRIVACYPOLICY"
                break
            case .ABOUT_TERMSOFSERVICE:
                typeStr = "ABOUT_TERMSOFSERVICE"
                break
            case .ABOUT_SHARE:
                typeStr = "ABOUT_SHARE"
                break
            case .PURCHASE_START:
                typeStr = "PURCHASE_START"
                break
            case .PURCHASE_SUCCESS:
                typeStr = "PURCHASE_SUCCESS"
                break
            case .PURCHASE_CANCLED:
                typeStr = "PURCHASE_CANCLED"
                break
            case .PURCHASE_RESTORE:
                typeStr = "PURCHASE_RESTORE"
                break
            case .PURCHASE_WEEK:
                typeStr = "PURCHASE_WEEK"
                break
            case .PURCHASE_MONTH:
                typeStr = "PURCHASE_MONTH"
                break
            case .PURCHASE_3MONTH:
                typeStr = "PURCHASE_3MONTH"
                break
            case .PURCHASE_6MONTH:
                typeStr = "PURCHASE_6MONTH"
                break
            case .PURCHASE_YEAR:
                typeStr = "PURCHASE_YEAR"
                break
            case .PURCHASE_CONSUME:
                typeStr = "PURCHASE_CONSUME"
                break
            case .PURCHASE_ONCE:
                typeStr = "PURCHASE_ONCE"
                break
            default:
                break
        }
        return typeStr
    }

    func track(event type: DYMEventType, extra: String = "", user: String) {
        var eventParams = [String:String]()
        eventParams["name"] = getEventTypeString(type: type)
        eventParams["extra"] = extra
        eventParams["user"] = user
        eventParams["event_id"] = UserProperties.requestUUID
        cachedEvents.append(eventParams)
        DispatchQueue.global(qos: .background).async {
            self.syncEvents()
        }
    }
    
    private func syncEvents() {
        let currentEvents = cachedEvents
        let events = currentEvents.map { Event(name: $0["name"]!, extra: $0["extra"], user: $0["user"]!)}
        SessionsAPI.reportEvents(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportEvents.ios, X_VERSION: UserProperties.sdkVersion, eventReportObject: EventReportObject(events: events)) { data, error in
            if error == nil {
                let leftEvents = Set(self.cachedEvents).subtracting(Set(currentEvents))
                self.cachedEvents = Array(leftEvents)
            }
        }
    }
}
