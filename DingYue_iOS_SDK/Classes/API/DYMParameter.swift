//
//  DYMParameter.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/4/3.
//

import UIKit
#if canImport(AnyCodable)
import AnyCodable
#endif

public typealias DYMParams = [String:Any]

protocol DYMParamEncoder {
    func encode(_ urlRequest: URLRequest,with params: DYMParams)throws -> URLRequest
}

struct DYMJSONParamEncoder: DYMParamEncoder {

    func encode(_ urlRequest: URLRequest,with params: DYMParams)throws -> URLRequest {
        var request = urlRequest
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            throw NSError()
        }
        return request
    }

}

struct DYMURLParamEncoder: DYMParamEncoder {

    func encode(_ urlRequest: URLRequest, with params: DYMParams) throws -> URLRequest {
        var request = urlRequest
        guard let url = urlRequest.url else { throw DYMError.emptyRequest }
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),!params.isEmpty {
            urlComponents.queryItems = queryItems(params)
            request.url = urlComponents.url
        }
        return request
    }

    func queryItems(_ source: [String: Any?]) -> [URLQueryItem]? {
        let destination = source.filter { $0.value != nil }.reduce(into: [URLQueryItem]()) { result, item in
            if let collection = item.value as? [Any?] {
                collection.filter { $0 != nil }.map { "\($0!)" }.forEach { value in
                    result.append(URLQueryItem(name: item.key, value: value))
                }
            } else if let value = item.value {
                result.append(URLQueryItem(name: item.key, value: "\(value)"))
            }
        }

        if destination.isEmpty {
            return nil
        }
        return destination
    }

}

public struct DYMParamsWrapper: Codable, Hashable {
    public var data: [String: AnyCodable]?
    public init(params: [String: Any]?) {
        self.data = params?.mapValues { AnyCodable($0) }
    }
}
