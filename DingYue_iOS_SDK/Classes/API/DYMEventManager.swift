//
//  EventReportManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/25.
//

import CommonCrypto
class DYMEventManager {
    static let shared = DYMEventManager()
    private init() {}
    
    func track(event name: String, extra: String? = nil, user: String? = nil) {
        let sessionId = UserProperties.staticUuid
        debugPrint("www sessionId ->>> \(sessionId)")
        let thisEvent = Event(name: name, extra: extra, user: user, sessionId: sessionId)
        DispatchQueue.global(qos: .background).async {
            self.syncEvents(event: thisEvent)
        }
    }

    func track(event name: String, entrance: String = "", value: String = "", parameters: [String: Any]? = nil) {
        let eventName = name
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 基础参数
        var baseParams: [String: Any] = [
            "event.name": name,
            "event.timestamp": timestamp,
            "event.entrance": entrance,
            "event.value": value,
            "event.extra": [:]
        ]
        
        // 将parameters合并到event.extra中
        var extraDict: [String: Any] = [:]
        if let parameters = parameters {
            extraDict = parameters
        }
        
        baseParams["event.extra"] = extraDict
        
        // 将所有基础参数转为 JSON 字符串
        var extraString = ""
        if let jsonData = try? JSONSerialization.data(withJSONObject: baseParams, options: []),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            extraString = jsonString
        }
        DYMobileSDK.track(event: eventName, extra: extraString)
    }
    
    private func syncEvents(event:Event) {
        SessionsAPI.reportEvents(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportEvents.ios, X_VERSION: UserProperties.sdkVersion, eventReportObject: EventReportObject(events: [event])) { data, error in
        }
    }
}
