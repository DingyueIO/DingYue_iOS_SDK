//
//  DYMRouter.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/4/3.
//

import UIKit

enum DYMRouter {
    ///归因
    case attribution(params:DYMParams)
    ///广告归因
    case searchAds(params:DYMParams)
    ///场景
    case session(params:DYMParams)
    ///订单验证-首次购买
    case receiptFirst(params:DYMParams)
    ///订单验证-恢复购买
    case receiptRecover(params:DYMParams)
    ///事件跟踪
    case trackEvent(params:DYMParams)
    ///用户属性
    case userAttribute(params:DYMParams)
    ///商品信息
    case subscription(params:DYMParams)

    ///网络协议
    var scheme: String { return "https" }

    ///主链接
    var host: String { return DYMConstants.URLs.host }

    ///请求方法
    var method: HTTPMethod {
        switch self {
            case .attribution,.searchAds,.session,.receiptFirst,.receiptRecover, .trackEvent:
                return .post
            case .userAttribute:
                return .put
            case .subscription:
                return .get
        }
    }

    ///请求路径
    var path: String {
        switch self {
            case .attribution:
                return "/attribution/report"
            case .searchAds:
                return "/searchads/report"
            case .session:
                return "/sessions/report"
            case .receiptFirst:
                return "/receipt/verify/first"
            case .receiptRecover:
                return "/receipt/verify/recover"
            case .trackEvent:
                return "/users/report/events"
            case .userAttribute:
                return "/users/attribute/update"
            case .subscription:
                return "/product/subscriptions"
        }
    }

    ///配置网络请求
    func configURLRequest()throws -> URLRequest {
        let urlString = scheme + "://" + host + path
        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue(DYMConstants.APIKeys.appId, forHTTPHeaderField: DYMConstants.Headers.appId)
        request.setValue(DYMConstants.APIKeys.secretKey, forHTTPHeaderField: DYMConstants.Headers.apiKey)
        request.setValue(UserProperties.userAgent, forHTTPHeaderField: DYMConstants.Headers.agent)
        request.setValue(UserProperties.requestUUID, forHTTPHeaderField: DYMConstants.Headers.userId)
        request.httpMethod = method.rawValue
        var parameters: DYMParams = [:]
        switch self {
            case .attribution(let params),
                    .searchAds(let params),
                    .session(let params),
                    .receiptFirst(let params),
                    .receiptRecover(let params),
                    .trackEvent(let params),
                    .subscription(let params):
                parameters = params
            case .userAttribute:break
        }
        if method == .get {
            request = try DYMURLParamEncoder().encode(request, with: parameters)
        }else {
            request = try DYMJSONParamEncoder().encode(request, with: parameters)
        }
        return request
    }

}
