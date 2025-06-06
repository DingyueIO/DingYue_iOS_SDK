//
//  FBNetworkMonitor.swift
//  Firebee VPN
//
//  Created by TJ on 2023/3/27.
//

import Foundation
import Network

enum AGNetworkMonitorStatus {
    case connected
    case disConnected
    case none
}

class AGNetworkMonitor {
    static let shared = AGNetworkMonitor()
    
    private let queue = DispatchQueue.global()
    private var monitor:NWPathMonitor?
    var connectStatus:AGNetworkMonitorStatus = .none
    
    private init() {
        monitor = NWPathMonitor()
    }
    
    func startMonitoring() {
        monitor?.pathUpdateHandler = {[weak self] path in
            if path.status == .satisfied {
                print("We're connected!")
                if self?.connectStatus == .connected {return}
                self?.connectStatus = .connected
                NotificationCenter.default.post(name: AGNotificationNetworkMonitorStatus, object: AGNetworkMonitorStatus.connected)
            } else {
                print("No connection.")
                if self?.connectStatus == .disConnected {return}
                self?.connectStatus = .disConnected
                NotificationCenter.default.post(name: AGNotificationNetworkMonitorStatus, object: AGNetworkMonitorStatus.disConnected)
            }
        }
        monitor?.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor?.cancel()
    }
    
}
