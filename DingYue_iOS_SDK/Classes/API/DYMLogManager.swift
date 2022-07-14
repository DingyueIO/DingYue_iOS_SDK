//
//  LoggerManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/10.
//

import UIKit

public enum DYMLogLevel: Int {
    case none
    case errors
    case verbose
    case all
}

class DYMLogManager: NSObject {
    static var logLevel: DYMLogLevel = .none

    class func logError(_ error: Any) {
        guard isAllowedToLog(.errors) else {
            return
        }

        print("\(prefix) - ERROR.\n\(error)")
    }

    class func logMessage(_  message: String) {
        guard isAllowedToLog(.verbose) else {
            return
        }

        print("\(prefix) - INFO.\n\(message)")
    }

    class func logGlobalMessage(_  message: String) {
        guard isAllowedToLog(.all) else {
            return
        }

        print("\(prefix) - INFO.\n\(message)")
    }

    private class func isAllowedToLog(_ level: DYMLogLevel) -> Bool {
        return logLevel.rawValue >= level.rawValue
    }

    private class var prefix: String {
        return "\(dateTime) [DingYue v\(UserProperties.sdkVersion )(\(UserProperties.sdkVersionBuild))]"
    }

    private static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        return formatter
    }()
    private class var dateTime: String {
        return formatter.string(from: Date())
    }
}
