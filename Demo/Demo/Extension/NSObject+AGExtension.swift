//
//  NSObject+AGExtension.swift
//  QRScanner
//
//  Created by TJ on 2024/12/25.
//

import Foundation

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    static var className: String {
        return String(describing: self)
    }
}
