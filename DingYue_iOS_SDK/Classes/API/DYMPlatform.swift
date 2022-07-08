//
//  Platform.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/2/11.
//

#if canImport(UIKit)
import UIKit

typealias Application = UIApplication
typealias ApplicationDelegate = UIApplicationDelegate
#elseif os(macOS)
import AppKit

typealias Application = NSApplication
typealias ApplicationDelegate = NSApplicationDelegate
#endif
