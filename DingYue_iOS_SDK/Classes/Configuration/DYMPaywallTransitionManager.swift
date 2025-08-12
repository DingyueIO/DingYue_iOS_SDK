//
//  DYMPaywallTransitionManager.swift
//  DingYue_iOS_SDK
//
//  Created by Assistant on 2025/1/27.
//

import UIKit

// MARK: - 支付页面转场动画管理
@objc public class DYMPaywallTransitionManager: NSObject {
    
    // MARK: - 单例
    @objc public static let shared = DYMPaywallTransitionManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - 获取转场代理
    @objc public func getTransitionDelegate(for style: DYMPaywallConfig.PresentationStyle) -> UIViewControllerTransitioningDelegate? {
        switch style {
        case .push:
            return DYMPushTransitionDelegate.shared
        case .bottomSheetFullScreen:
            return DYMBottomSheetFullScreenTransitionDelegate.shared
        case .circleSpread:
            return DYMCircleSpreadTransitionDelegate.shared
        case .bottomSheet, .modal:
            return nil // 使用系统默认转场
        }
    }
}

// MARK: - Push 转场动画代理
class DYMPushTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = DYMPushTransitionDelegate()
    
    private override init() {
        super.init()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DYMPushPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DYMPushDismissAnimator()
    }
}

// MARK: - Push 出现动画
class DYMPushPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { 
            return 
        }
        
        let containerView = transitionContext.containerView
        
        // 确保背景视图保持可见
        if let fromView = transitionContext.view(forKey: .from) {
            containerView.insertSubview(toView, aboveSubview: fromView)
        } else {
            containerView.addSubview(toView)
        }
        
        // 设置初始位置（从右侧进入）
        toView.frame = CGRect(x: containerView.bounds.width, y: 0, width: containerView.bounds.width, height: containerView.bounds.height)
        
        // 执行动画
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: {
            toView.frame = containerView.bounds
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - Push 消失动画
class DYMPushDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        
        // 执行动画（向右侧退出）
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: {
            fromView.frame = CGRect(x: fromView.bounds.width, y: 0, width: fromView.bounds.width, height: fromView.bounds.height)
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - 全屏底部弹出转场动画代理
class DYMBottomSheetFullScreenTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = DYMBottomSheetFullScreenTransitionDelegate()
    
    private override init() {
        super.init()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DYMBottomSheetFullScreenPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DYMBottomSheetFullScreenDismissAnimator()
    }
}

// MARK: - 全屏底部弹出出现动画
class DYMBottomSheetFullScreenPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        // 确保背景视图保持可见
        if let fromView = transitionContext.view(forKey: .from) {
            containerView.insertSubview(toView, aboveSubview: fromView)
        } else {
            containerView.addSubview(toView)
        }
        
        // 设置初始位置（从底部进入）
        toView.frame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
        
        // 执行动画
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: {
            toView.frame = containerView.bounds
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - 全屏底部弹出消失动画
class DYMBottomSheetFullScreenDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        
        // 执行动画（向底部退出）
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseIn, animations: {
            fromView.frame = CGRect(x: 0, y: fromView.bounds.height, width: fromView.bounds.width, height: fromView.bounds.height)
        }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - 圆形扩散转场动画代理
class DYMCircleSpreadTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = DYMCircleSpreadTransitionDelegate()
    
    private override init() {
        super.init()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DYMCircleSpreadPresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DYMCircleSpreadDismissAnimator()
    }
}

// MARK: - 圆形扩散出现动画
class DYMCircleSpreadPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        // 设置视图的基本位置
        toView.frame = containerView.bounds
        
        // 添加视图到容器
        containerView.addSubview(toView)
        
        // 计算扩散的起始点（屏幕中心）
        let startPoint = CGPoint(x: containerView.bounds.width / 2, y: containerView.bounds.height / 2)
        
        // 计算最大半径（从中心到屏幕角落的距离）
        let maxX = max(startPoint.x, containerView.bounds.width - startPoint.x)
        let maxY = max(startPoint.y, containerView.bounds.height - startPoint.y)
        let maxRadius = sqrt(pow(maxX, 2) + pow(maxY, 2))
        
        // 创建起始圆形路径（很小的圆）
        let startRadius: CGFloat = 10.0
        let startPath = UIBezierPath(arcCenter: startPoint, radius: startRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        // 创建结束圆形路径（覆盖整个屏幕）
        let endPath = UIBezierPath(arcCenter: startPoint, radius: maxRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        // 创建遮罩层
        let maskLayer = CAShapeLayer()
        maskLayer.path = endPath.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        toView.layer.mask = maskLayer
        
        // 创建路径动画
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = startPath.cgPath
        pathAnimation.toValue = endPath.cgPath
        pathAnimation.duration = transitionDuration(using: transitionContext)
        pathAnimation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        pathAnimation.fillMode = "forwards"
        pathAnimation.isRemovedOnCompletion = false
        pathAnimation.delegate = self
        
        // 保存 transitionContext 和 maskLayer 用于动画完成回调
        pathAnimation.setValue(transitionContext, forKey: "transitionContext")
        pathAnimation.setValue(maskLayer, forKey: "maskLayer")
        
        // 添加动画到遮罩层
        maskLayer.add(pathAnimation, forKey: "path")
    }
}

// MARK: - 圆形收缩消失动画
class DYMCircleSpreadDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        
        let containerView = transitionContext.containerView
        
        // 计算收缩的结束点（屏幕中心）
        let endPoint = CGPoint(x: containerView.bounds.width / 2, y: containerView.bounds.height / 2)
        
        // 计算最大半径（从中心到屏幕角落的距离）
        let maxX = max(endPoint.x, containerView.bounds.width - endPoint.x)
        let maxY = max(endPoint.y, containerView.bounds.height - endPoint.y)
        let maxRadius = sqrt(pow(maxX, 2) + pow(maxY, 2))
        
        // 创建起始圆形路径（覆盖整个屏幕）
        let startPath = UIBezierPath(arcCenter: endPoint, radius: maxRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        // 创建结束圆形路径（很小的圆）
        let endRadius: CGFloat = 10.0
        let endPath = UIBezierPath(arcCenter: endPoint, radius: endRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        
        // 创建遮罩层
        let maskLayer = CAShapeLayer()
        maskLayer.path = startPath.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        fromView.layer.mask = maskLayer
        
        // 创建路径动画
        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.fromValue = startPath.cgPath
        pathAnimation.toValue = endPath.cgPath
        pathAnimation.duration = transitionDuration(using: transitionContext)
        pathAnimation.timingFunction = CAMediaTimingFunction(name: "easeInEaseOut")
        pathAnimation.fillMode = "forwards"
        pathAnimation.isRemovedOnCompletion = false
        pathAnimation.delegate = self
        
        // 保存 transitionContext 和 maskLayer 用于动画完成回调
        pathAnimation.setValue(transitionContext, forKey: "transitionContext")
        pathAnimation.setValue(maskLayer, forKey: "maskLayer")
        
        // 添加动画到遮罩层
        maskLayer.add(pathAnimation, forKey: "path")
    }
}

// MARK: - CAAnimationDelegate 扩展
extension DYMCircleSpreadPresentAnimator: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let transitionContext = anim.value(forKey: "transitionContext") as? UIViewControllerContextTransitioning,
           let maskLayer = anim.value(forKey: "maskLayer") as? CAShapeLayer {
            // 立即移除遮罩层，确保动画完成后视图正常显示
            maskLayer.removeFromSuperlayer()
            if let toView = transitionContext.view(forKey: .to) {
                toView.layer.mask = nil
            }
            
            // 延迟一帧完成转场，确保遮罩层完全移除
            DispatchQueue.main.async {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}

extension DYMCircleSpreadDismissAnimator: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let transitionContext = anim.value(forKey: "transitionContext") as? UIViewControllerContextTransitioning,
           let maskLayer = anim.value(forKey: "maskLayer") as? CAShapeLayer {
            // 立即移除遮罩层，避免闪烁
            maskLayer.removeFromSuperlayer()
            if let fromView = transitionContext.view(forKey: .from) {
                fromView.layer.mask = nil
            }
            
            // 延迟一帧完成转场，确保遮罩层完全移除
            DispatchQueue.main.async {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
