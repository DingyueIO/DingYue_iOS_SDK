//
//  AGHelper.swift
//  DingYue_iOS_SDK
//
//  Created by TJ on 2025/2/27.
//

import Foundation

class AGHelper {
    
    static func ag_convertDicToJSONStr(dictionary: [String: Any]) -> String? {
        let result = AGValues.JSONString(dictionary)
        return result
    }
    
    // 将 UniqueUserObject 转换为字典的函数
    static func ag_convertToDic<T: Encodable>(_ object: T) -> [String: Any]? {
        do {
            // 将结构体编码为 JSON 数据
            let jsonData = try JSONEncoder().encode(object)
            
            // 将 JSON 数据转换为字典
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                return jsonObject
            }
        } catch {
            print("Error encoding JSON: \(error)")
        }
        return nil
    }
    
    static func ag_convertToDicArr<T: Encodable>(_ objects: [T]) -> [[String: Any]] {
        var result: [[String: Any]] = []
        
        for object in objects {
            if let dictionary = ag_convertToDic(object) {
                result.append(dictionary)
            }
        }
        
        return result
    }
    
}
