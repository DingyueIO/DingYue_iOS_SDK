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
        let thisEvent = Event(name: name, extra: extra, user: user, sessionId: sessionId)
        DispatchQueue.global(qos: .background).async {
            self.syncEvents(event: thisEvent)
        }
    }

    private func syncEvents(event:Event) {
        SessionsAPI.reportEvents(X_USER_ID: UserProperties.requestUUID, userAgent: UserProperties.userAgent, X_APP_ID: DYMConstants.APIKeys.appId, X_PLATFORM: SessionsAPI.XPLATFORM_reportEvents.ios, X_VERSION: UserProperties.sdkVersion, eventReportObject: EventReportObject(events: [event])) { data, error in
        }
    }
}
