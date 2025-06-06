//
//  UIViewController.swift
//  Firebee VPN
//
//  Created by TJ on 2023/2/28.
//

import UIKit

extension UIViewController {
    
    static var ag_current:UIViewController? {
        var current = UIWindow.ag_keyWindow?.rootViewController
        
        while (current?.presentedViewController != nil)  {
            current = current?.presentedViewController
        }
        
        if let tabbar = current as? UITabBarController , tabbar.selectedViewController != nil {
            current = tabbar.selectedViewController
        }
        
        while let navi = current as? UINavigationController , navi.topViewController != nil  {
            current = navi.topViewController
        }
        return current
    }
    
    func ag_destroySelf() {
        if let navigationController = self.navigationController {
            var viewControllers = navigationController.viewControllers
            viewControllers.removeAll(where: { $0.classForCoder == self.classForCoder })
            navigationController.setViewControllers(viewControllers, animated: true)
        }
    }
    
    //是否能被模态
    func ag_canBePresented() -> Bool {
        guard UIViewController.ag_current?.presentedViewController == nil else {return false}
        guard presentingViewController == nil else {return false}
        if isBeingPresented == true {return false}
        return true
    }
    
    static func ag_destroyVC(_ type:UIViewController.Type) {
        if let navigationController = UIViewController.ag_current?.navigationController {
            var viewControllers = navigationController.viewControllers
            viewControllers.removeAll(where: { $0.classForCoder == type })
            navigationController.setViewControllers(viewControllers, animated: true)
        }
    }
    
    func ag_popToVC(_ type:UIViewController.Type) {
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else {return}
            if let typeVC = strongSelf.navigationController?.viewControllers.filter({ $0.classForCoder == type }).first {
                strongSelf.navigationController?.popToViewController(typeVC, animated: true)
            }else{
                strongSelf.navigationController?.popViewController(animated: true)
            }
        }
    }
    
}
