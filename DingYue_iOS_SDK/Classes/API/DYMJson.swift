//
//  DYMJson.swift
//  DingYueMobileSDK
//
//  Created by YaoZiLiang on 2022/4/8.
//

import UIKit

protocol DYMJSONCodable {
    init?(json: DYMParams) throws
}

struct DYMJson: DYMJSONCodable {
    let json: DYMParams
    init?(json: DYMParams) throws {
        self.json = json
    }
}

struct DYMJsonAttributed: DYMJSONCodable {
    
    let json: DYMParams
    
    init?(json: DYMParams) throws {
        let attributes: DYMParams
        do {
            attributes = try json.attributes()
        } catch {
            throw error
        }
        self.json = attributes
    }
    
}

struct DYMResponseError: DYMJSONCodable {
    
    let detail: String
    let status: Int
    let source: DYMParams
    let code: String
    
    init?(json: DYMParams) throws {
        self.detail = json["detail"] as? String ?? ""
        if let statusString = json["status"] as? String, let status = Int(statusString) {
            self.status = status
        } else {
            self.status = 0
        }
        self.source = json["source"] as? DYMParams ?? DYMParams()
        self.code = json["code"] as? String ?? ""
        
        logMissingRequiredParams()
    }
    
    var description: String {
        return "Status: \(code). Details: \(detail)"
    }
    
    private func logMissingRequiredParams() {
        var missingParams: [String] = []
        if self.detail.isEmpty { missingParams.append("detail") }
        if self.status == 0 { missingParams.append("status") }
        if self.source.count == 0 { missingParams.append("source") }
        if self.code.isEmpty { missingParams.append("code") }
        if !missingParams.isEmpty {
            DYMLogManager.logError(DYMError.missingParam("ResponseErrorModel - \(missingParams.joined(separator: ", "))")) }
    }
    
}

struct DYMResponseErrors: DYMJSONCodable {
    
    var errors: [DYMResponseError] = []
    
    init?(json: DYMParams) throws {
        guard let errors = json["errors"] as? [DYMParams] else {
            return nil
        }
        
        do {
            try errors.forEach { (params) in
                if let error = try DYMResponseError(json: params) {
                    self.errors.append(error)
                }
            }
        } catch {
            throw DYMError.invalidProperty("ResponseErrors – errors", errors)
        }
    }
    
}

