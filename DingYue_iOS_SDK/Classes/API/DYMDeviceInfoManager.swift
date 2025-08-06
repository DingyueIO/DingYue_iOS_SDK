//
//  DYMDeviceInfoManager.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2025/8/4.
//

import UIKit
import CoreTelephony
import AnyCodable

public class DYMDeviceInfoManager {
    public static func getDeviceInfo() -> DYMDeviceInfo {
        // Device model identifier (e.g. "iPhone12,8")
        var systemInfo = utsname()
        uname(&systemInfo)
        let deviceCode = Mirror(reflecting: systemInfo.machine).children.reduce("") { id, element in
            guard let value = element.value as? Int8, value != 0 else { return id }
            return id + String(UnicodeScalar(UInt8(value)))
        }

        // Screen info
        let screen = UIScreen.main
        let screenResolution = "\(Int(screen.nativeBounds.width))x\(Int(screen.nativeBounds.height))"
        let screenScale = "\(screen.scale)"

        // RAM info (GB)
        let ramGB = String(format: "%.2f", Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024 / 1024)
        let usedRamGB = String(format: "%.2f", Double(usedMemoryInMB()) / 1024)

        // CPU core count
        let cpuCoreCount = "\(ProcessInfo.processInfo.processorCount)"

        // Storage info (GB)
        let fileManager = FileManager.default
        var totalStorageGB: Double = 0
        var freeStorageGB: Double = 0
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            if let totalSpace = attrs[.systemSize] as? NSNumber {
                totalStorageGB = totalSpace.doubleValue / (1024 * 1024 * 1024)
            }
            if let freeSpace = attrs[.systemFreeSize] as? NSNumber {
                freeStorageGB = freeSpace.doubleValue / (1024 * 1024 * 1024)
            }
        }
        let usedStorageGB = totalStorageGB - freeStorageGB
        let usedStorageRatio = totalStorageGB > 0 ? usedStorageGB / totalStorageGB : 0

        // Calculate storage capacity label
        let storageCapacity = storageCapacityLabel(for: totalStorageGB)

        // Simulator check
        let isSimulator: String = {
            #if targetEnvironment(simulator)
            return "true"
            #else
            return "false"
            #endif
        }()

        // Battery info
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = String(format: "%.2f", UIDevice.current.batteryLevel)
        let isCharging = (UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full) ? "true" : "false"

        // Carrier info
        var carriers: [DYMCarrierInfo] = []
        let networkInfo = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            if let providers = networkInfo.serviceSubscriberCellularProviders {
                for (_, carrier) in providers {
                    let name = carrier.carrierName ?? ""
                    let mcc = carrier.mobileCountryCode ?? ""
                    let mnc = carrier.mobileNetworkCode ?? ""
                    carriers.append(DYMCarrierInfo(carrierName: name, mcc: mcc, mnc: mnc))
                }
            }
        } else {
            if let carrier = networkInfo.subscriberCellularProvider {
                let name = carrier.carrierName ?? ""
                let mcc = carrier.mobileCountryCode ?? ""
                let mnc = carrier.mobileNetworkCode ?? ""
                carriers.append(DYMCarrierInfo(carrierName: name, mcc: mcc, mnc: mnc))
            }
        }

        return DYMDeviceInfo(
            deviceCode: deviceCode,
            systemName: UIDevice.current.systemName,
            systemVersion: UIDevice.current.systemVersion,
            screenResolution: screenResolution,
            screenScale: screenScale,
            cpuCoreCount: cpuCoreCount,
            ramGB: ramGB,
            usedRamGB: usedRamGB,
            totalStorageGB: String(format: "%.2f", totalStorageGB),
            freeStorageGB: String(format: "%.2f", freeStorageGB),
            usedStorageGB: String(format: "%.2f", usedStorageGB),
            usedStorageRatio: String(format: "%.2f", usedStorageRatio),
            storageCapacity: storageCapacity,
            isSimulator: isSimulator,
            batteryLevel: batteryLevel,
            isCharging: isCharging,
            carriers: carriers
        )
    }

    /// 计算存储容量对应标签，针对大于1TB区间做特殊处理
    private static func storageCapacityLabel(for totalStorageGB: Double) -> String {
        switch totalStorageGB {
        case 0..<16:
            return "16"
        case 16..<32:
            return "32"
        case 32..<64:
            return "64"
        case 64..<128:
            return "128"
        case 128..<256:
            return "256"
        case 256..<512:
            return "512"
        case 512..<1024:
            return "1024"
        case 1024..<2048:
            return "2048"
        case 2048..<4096:
            return "4096"
        case 4096..<8192:
            return "8192"
        default:
            return String(Int(totalStorageGB))
        }
    }

    /// 直接输出 [String: AnyCodable]，方便赋值给 UniqueUserObject.deviceInfo
    public static func getDeviceInfoAsAnyCodableDict() -> [String: AnyCodable] {
        let info = getDeviceInfo()

        // 手动转换为 [String: AnyCodable]，避免 JSONSerialization 可选问题
        var dict: [String: AnyCodable] = [
            "deviceCode": AnyCodable(info.deviceCode),
            "systemName": AnyCodable(info.systemName),
            "systemVersion": AnyCodable(info.systemVersion),
            "screenResolution": AnyCodable(info.screenResolution),
            "screenScale": AnyCodable(info.screenScale),
            "ramGB": AnyCodable(info.ramGB),
            "usedRamGB": AnyCodable(info.usedRamGB),
            "cpuCoreCount": AnyCodable(info.cpuCoreCount),
            "totalStorageGB": AnyCodable(info.totalStorageGB),
            "freeStorageGB": AnyCodable(info.freeStorageGB),
            "usedStorageGB": AnyCodable(info.usedStorageGB),
            "usedStorageRatio": AnyCodable(info.usedStorageRatio),
            "storageCapacity": AnyCodable(info.storageCapacity),
            "isSimulator": AnyCodable(info.isSimulator),
            "batteryLevel": AnyCodable(info.batteryLevel),
            "isCharging": AnyCodable(info.isCharging)
        ]

        // Carriers 转成 [[String: AnyCodable]]
        let carriersArray = info.carriers.map { carrier in
            [
                "carrierName": AnyCodable(carrier.carrierName),
                "mcc": AnyCodable(carrier.mcc),
                "mnc": AnyCodable(carrier.mnc)
            ]
        }
        dict["carriers"] = AnyCodable(carriersArray)

        return dict
    }

    private static func usedMemoryInMB() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: taskInfo) / MemoryLayout<Int32>.size)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return taskInfo.resident_size / 1024 / 1024
        } else {
            return 0
        }
    }
}

public struct DYMCarrierInfo: Codable {
    public let carrierName: String
    public let mcc: String
    public let mnc: String
}

public struct DYMDeviceInfo: Codable {
    public let deviceCode: String
    public let systemName: String
    public let systemVersion: String
    public let screenResolution: String
    public let screenScale: String

    public let cpuCoreCount: String
    public let ramGB: String
    public let usedRamGB: String

    public let totalStorageGB: String
    public let freeStorageGB: String

    public let usedStorageGB: String
    public let usedStorageRatio: String
    public let storageCapacity: String

    public let isSimulator: String
    public let batteryLevel: String
    public let isCharging: String
    public let carriers: [DYMCarrierInfo]
}
