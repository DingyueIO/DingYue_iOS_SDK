//
//  EventReportManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/25.
//

import UIKit
import CommonCrypto

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

    func track(event name: String, extra: String? = nil, user: String? = nil) {
        var eventParams = [String:String]()
        eventParams["name"] = name
        eventParams["extra"] = extra
        eventParams["user"] = user
        cachedEvents.append(eventParams)
        DispatchQueue.global(qos: .background).async {
            self.syncEvents()
        }
    }
    
    private func syncEvents() {
        let currentEvents = cachedEvents
        let events = currentEvents.map { Event(name: $0["name"]!, extra: $0["extra"], user: $0["user"])}
        SessionsAPI.reportEvents(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportEvents.ios, X_VERSION: UserProperties.sdkVersion, eventReportObject: EventReportObject(events: events)) { data, error in
            if error == nil {
                let leftEvents = Set(self.cachedEvents).subtracting(Set(currentEvents))
                self.cachedEvents = Array(leftEvents)
            }
        }
    }
}
