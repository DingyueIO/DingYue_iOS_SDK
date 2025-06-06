//
//  LaunchVC.swift
//  FindDevice
//
//  Created by TJ on 2025/1/7.
//

import UIKit

import AppTrackingTransparency
//import APNGKit

class VRLaunchVC: UIViewController {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        NotificationCenter.default.addObserver(self, selector: #selector(networkMonitorStatus(noti:)), name: AGNotificationNetworkMonitorStatus, object: nil)
        AGNetworkMonitor.shared.startMonitoring()
    }

    @objc func networkMonitorStatus(noti:Notification) {
        if let status:AGNetworkMonitorStatus = noti.object as? AGNetworkMonitorStatus {
            switch status {
            case .connected:
                initDingYueSDK()
                break
            default:
                break
            }
        }
    }
    
    func initDingYueSDK() {
        IWDingYueManager.config(success: {[weak self] in
            self?.toGuidePage()
        }, failed: {[weak self] in
            self?.toGuidePage()
        })
    }
    func toGuidePage() {
        DispatchQueue.main.async {
            IWDingYueManager.showDingYueGuidePage(fromVC: self)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 记录页面进入事件
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 只在页面真正退出时触发 leave 事件

    }
}
