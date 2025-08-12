//
//  DYMConfiguration.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2024/9/3.
//

import UIKit
import NVActivityIndicatorView

@objc public class DYMConfiguration:NSObject {
    // 单例实例
    @objc public static let shared = DYMConfiguration()
    
    // 引导页配置
    @objc public var guidePageConfig: GuidePageConfig
    // 网络请求配置
    @objc public var networkRequestConfig: NetworkRequestConfig
    // 支付页面配置
    @objc public var paywallConfig: DYMPaywallConfig
    
    
    // 私有初始化以确保单例
    @objc private override init() {
        // 设置默认配置值
        self.guidePageConfig = GuidePageConfig(
            isVip: false,
            isVisible: true,
            indicatorType: 1,
            indicatorColor: .red,
            indicatorSize: CGSize(width: 64, height: 34),
            bottomSpacing: 80
        )
        self.networkRequestConfig = NetworkRequestConfig(maxRetryCount: 15, retryInterval: 1)
        self.paywallConfig = DYMPaywallConfig(
            presentationStyle: .bottomSheetFullScreen,
            enableSwipeToDismiss: true,
            enableSwipeToDismissFromEdge: true
        )
    }
}
// MARK: web引导页配置
@objc public class GuidePageConfig: NSObject {
    @objc public var isVisible: Bool
    @objc public var indicatorType: Int
    @objc public var indicatorColor: UIColor
    @objc public var indicatorSize: CGSize
    @objc public var bottomSpacing: CGFloat
    @objc public var isVIP: Bool
    
    @objc public init(isVip:Bool, isVisible: Bool, indicatorType: Int, indicatorColor: UIColor, indicatorSize: CGSize, bottomSpacing: CGFloat) {
        self.isVIP = isVip
        self.isVisible = isVisible
        self.indicatorType = indicatorType
        self.indicatorColor = indicatorColor
        self.indicatorSize = indicatorSize
        self.bottomSpacing = bottomSpacing
    }
    public static func type(from intValue: Int) -> NVActivityIndicatorType {
        switch intValue {
        case 0: return .blank
        case 1: return .ballPulse
        case 2: return .ballGridPulse
        case 3: return .ballClipRotate
        case 4: return .squareSpin
        case 5: return .ballClipRotatePulse
        case 6: return .ballClipRotateMultiple
        case 7: return .ballPulseRise
        case 8: return .ballRotate
        case 9: return .cubeTransition
        case 10: return .ballZigZag
        case 11: return .ballZigZagDeflect
        case 12: return .ballTrianglePath
        case 13: return .ballScale
        case 14: return .lineScale
        case 15: return .lineScaleParty
        case 16: return .ballScaleMultiple
        case 17: return .ballPulseSync
        case 18: return .ballBeat
        case 19: return .ballDoubleBounce
        case 20: return .lineScalePulseOut
        case 21: return .lineScalePulseOutRapid
        case 22: return .ballScaleRipple
        case 23: return .ballScaleRippleMultiple
        case 24: return .ballSpinFadeLoader
        case 25: return .lineSpinFadeLoader
        case 26: return .triangleSkewSpin
        case 27: return .pacman
        case 28: return .ballGridBeat
        case 29: return .semiCircleSpin
        case 30: return .ballRotateChase
        case 31: return .orbit
        case 32: return .audioEqualizer
        case 33: return .circleStrokeSpin
        default: return .ballPulse
        }
    }
}

// MARK: - 网络请求配置
@objc public class NetworkRequestConfig: NSObject {
    @objc public var maxRetryCount: Int  // 最大重试次数
    @objc public var retryInterval: TimeInterval  // 请求间隔时间（秒）
    
    @objc public init(maxRetryCount: Int, retryInterval: TimeInterval) {
        self.maxRetryCount = maxRetryCount
        self.retryInterval = retryInterval
    }
}

// MARK: - 支付页面配置
@objc public class DYMPaywallConfig: NSObject {
    @objc public enum PresentationStyle: Int {
        case bottomSheet = 0    // 从底部弹出（非全屏）
        case bottomSheetFullScreen = 1  // 从底部弹出（全屏，默认）
        case push = 2           // 类似导航栏 push
        case modal = 3          // 模态居中
        case circleSpread = 4   // 圆形扩散动画
        
    }
    
    @objc public var presentationStyle: PresentationStyle
    @objc public var enableSwipeToDismiss: Bool
    @objc public var enableSwipeToDismissFromEdge: Bool
    
    @objc public init(presentationStyle: PresentationStyle, enableSwipeToDismiss: Bool, enableSwipeToDismissFromEdge: Bool) {
        self.presentationStyle = presentationStyle
        self.enableSwipeToDismiss = enableSwipeToDismiss
        self.enableSwipeToDismissFromEdge = enableSwipeToDismissFromEdge
    }
}
