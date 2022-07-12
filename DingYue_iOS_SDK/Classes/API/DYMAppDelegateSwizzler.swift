//
//  AppDelegateSwizzler.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/11.
//

import Foundation
#if os(macOS)
import AppKit
#endif


protocol DYMAppDelegateSwizzlerDelegate: class {
    func didReceiveAPNSToken(_ deviceToken: Data)
}

private typealias RegisterForNotificationsClosureType = @convention(c) (AnyObject, Selector, Application, Data) -> Void

class DYMAppDelegateSwizzler {

    private static let shared = DYMAppDelegateSwizzler()
    private weak var delegate: DYMAppDelegateSwizzlerDelegate?
    private static var registerForNotificationsOriginalImp: RegisterForNotificationsClosureType?

    class func startSwizzlingIfPossible(_ delegate: DYMAppDelegateSwizzlerDelegate) {
        // check if user disabled swizzling
        if let appDelegateProxyEnabled = Bundle.main.infoDictionary?[DYMConstants.BundleKeys.appDelegateProxyEnabled] as? Bool, !appDelegateProxyEnabled {
            return
        }

        shared.delegate = delegate
    }

    private init() {
        DispatchQueue.main.async {
            if #available(iOS 9.0, macOS 10.14, *) {
                let center = UNUserNotificationCenter.current()
                center.getNotificationSettings { settings in
                    if settings.authorizationStatus == .notDetermined {
                        center.requestAuthorization(options: [.alert,.sound,.badge]) { grand, error in
                        }
                        DispatchQueue.main.async {
                            Application.shared.registerForRemoteNotifications()
                        }
                    }else if settings.authorizationStatus == .authorized {
                        DispatchQueue.main.async {
                            Application.shared.registerForRemoteNotifications()
                        }
                    }
                }
            } else {
                #if os(macOS)
                NSApp.registerForRemoteNotifications(matching: [.alert, .badge, .sound])
                #endif
            }

            guard
                let originalClass = object_getClass(Application.shared.delegate),
                let swizzledClass = object_getClass(self)
            else { return }

            let originalSelector = #selector(ApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
            let swizzledSelector = #selector(self.swizzled_application(_:didRegisterForRemoteNotificationsWithDeviceToken:))

            self.swizzle(originalClass, swizzledClass, originalSelector, swizzledSelector)
        }
    }

    private func swizzle(_ originalClass: AnyClass, _ swizzledClass: AnyClass, _ originalSelector: Selector, _ swizzledSelector: Selector) {
        guard let swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector) else {
            return
        }

        if let originalMethod = class_getInstanceMethod(originalClass, originalSelector) {
            let imp = method_getImplementation(originalMethod)
            DYMAppDelegateSwizzler.registerForNotificationsOriginalImp = unsafeBitCast(imp, to: RegisterForNotificationsClosureType.self)

            // exchange implementation
            method_exchangeImplementations(originalMethod, swizzledMethod)
        } else {
           // add implementation
           class_addMethod(originalClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        }
    }

    @objc private func swizzled_application(_ application: Application, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // call parent method
        DYMAppDelegateSwizzler.registerForNotificationsOriginalImp?(Application.shared.delegate!, #selector(ApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)), application, deviceToken)

        // sync token to Adapty
        Self.shared.delegate?.didReceiveAPNSToken(deviceToken)
    }

}
