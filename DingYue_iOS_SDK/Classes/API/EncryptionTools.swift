//
//  EncryptionTools.swift
//  DingYue_iOS_SDK
//
//  Created by apple on 2024/5/17.
//

import UIKit
open class EncryptionTools {
    
    class func encrypt(data: Data, with keys: String) -> Data {
        var enResult = Data()
        let keyLength = keys.count
        let keysUnicodeView = keys.utf8

        for (idx, byte) in data.enumerated() {
            let idxInKeys = idx % keyLength
            let keyByte = keysUnicodeView[keysUnicodeView.index(keysUnicodeView.startIndex, offsetBy: idxInKeys)]
            
            let enByte = byte ^ keyByte
            enResult.append(enByte)
        }
        return enResult
    }
    
    class func decrypt(data: Data, with keys: String) -> Data {
        var deResult = Data()
        let keyLength = keys.count
        let keysUnicodeView = keys.utf8

        for (idx, byte) in data.enumerated() {
            let idxInKeys = idx % keyLength
            let keyByte = keysUnicodeView[keysUnicodeView.index(keysUnicodeView.startIndex, offsetBy: idxInKeys)]
            
            let enByte = byte ^ keyByte
            deResult.append(enByte)
        }
        return deResult
    }
}

