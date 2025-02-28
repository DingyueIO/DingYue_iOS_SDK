//
//  AGHelper.swift
//  DingYue_iOS_SDK
//
//  Created by TJ on 2025/2/27.
//

import Foundation

class AGHelper {
    
    static func ag_convertDicToJSONStr(dictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        } catch {
            print("Error converting dictionary to JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 将 UniqueUserObject 转换为字典的函数
    static func ag_convertToDictionary(_ object: UniqueUserObject) -> [String: Any]? {
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
    
}
