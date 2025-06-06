//
//  VRNavigationController.swift
//  VoiceRecorder
//
//  Created by TJ on 2025/3/28.
//

import UIKit

class VRNavigationController: UINavigationController {
    
    fileprivate var isEnableEdegePan = true
    fileprivate let needHiddenVCNames :[String] = [VRLaunchVC.className]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interactivePopGestureRecognizer?.delegate = self
        self.delegate = self
    }
    
    func getScreenEdgePanGestureRecognizer() -> UIScreenEdgePanGestureRecognizer? {
        
        var edgePan: UIScreenEdgePanGestureRecognizer?
        if let recognizers = view.gestureRecognizers, recognizers.count > 0 {
            for recognizer in recognizers {
                if recognizer is UIScreenEdgePanGestureRecognizer {
                    edgePan = recognizer as? UIScreenEdgePanGestureRecognizer
                    break
                }
            }
        }
        return edgePan
    }
    
    func enableScreenEdgePanGestureRecognizer(_ isEnable: Bool) {
        isEnableEdegePan = isEnable
    }
    
    
}

extension VRNavigationController: UINavigationControllerDelegate,UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !isEnableEdegePan { // 禁用边缘侧滑手势
            return false
        }
        return children.count > 1
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {

    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if viewControllers.count > 0 {
            // 隐藏tabBar底部
            viewController.hidesBottomBarWhenPushed = true
        }
        
        super.pushViewController(viewController, animated: animated)
    }
    
    //导航控制器将要显示控制器时调用，名单中控制器隐藏导航栏，其他的控制器显示导航栏
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
//        print(type(of: viewController))
        let name: AnyClass! = object_getClass(viewController)
        let vcName = NSStringFromClass(name)
        let vc = vcName.split(separator: ".").last
        if needHiddenVCNames.contains(String(vc ?? "")){
            self.setNavigationBarHidden(true, animated: true)
        }else {
            self.setNavigationBarHidden(false, animated: true)
        }
    }
}
