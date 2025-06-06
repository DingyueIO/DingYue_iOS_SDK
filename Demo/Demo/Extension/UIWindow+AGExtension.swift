//
//  UIWindow+AGExtension.swift
//  AIGirl
//
//  Created by TJ on 2023/6/28.
//

import UIKit

extension UIWindow {
    static var ag_keyWindow: UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
//        print("所有场景数量: \(scenes.count)")
        
        // 首先尝试获取 foregroundActive 的场景
        if let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: \.isKeyWindow) {
            return keyWindow
        }
        
        // 如果没有找到，尝试获取任意 UIWindowScene
        if let windowScene = scenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: \.isKeyWindow) {
            return keyWindow
        }
        
        // 如果还是没有找到，尝试获取任意 UIWindowScene 的第一个窗口
        if let windowScene = scenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
           let firstWindow = windowScene.windows.first {
            return firstWindow
        }
        
        print("⚠️ 无法获取到keyWindow")
        return nil
    }
    
    static var ag_sceneDelegate: SceneDelegate? {
        return UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
    }
}
