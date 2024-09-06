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
     }
}

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



