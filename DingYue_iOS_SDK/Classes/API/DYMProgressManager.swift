//
//  DYMProgressManager.swift
//  DingYueMobileSDK
//
//  Created by hua on 2022/6/24.
//

import Foundation

class ProgressView:NSObject {
    static let shared:ProgressView = ProgressView()
    lazy var progressView:UIView = {
        let baseView = UIView()
        baseView.frame.size = UIScreen.main.bounds.size
        baseView.backgroundColor = .lightGray
        baseView.alpha = 0.3
        baseView.addSubview(activity)
        activity.center = baseView.center
        return baseView
    }()

    lazy var activity:UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView(style: .large)
        activity.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        activity.backgroundColor = .clear
        return activity
    }()

    class func show(rootViewConroller:UIViewController){
        rootViewConroller.view.addSubview(shared.progressView)
        shared.activity.startAnimating()
    }
    class func stop(){
        shared.activity.stopAnimating()
        shared.progressView.removeFromSuperview()
    }
}
