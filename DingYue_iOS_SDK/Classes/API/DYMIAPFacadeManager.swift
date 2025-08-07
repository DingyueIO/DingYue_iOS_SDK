//
//  DYMIAPFacadeManager.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2025/8/6.
//

import UIKit
import StoreKit

class DYMIAPFacadeManager: NSObject {
    
    // MARK: - Type Aliases (与 V1 保持一致)
    public typealias PaywallCompletion = (_ products: [DYMProductModel]?,_ error: DYMError?) -> Void
    public typealias PurchaseCompletion = (_ purchase: DYMPurchaseResult,_ receiptVerifyMobileResponse:[String:Any]?) -> Void
    public typealias RestoreCompletion = (_ receipt: String?,_ receiptVerifyMobileResponse:[String:Any]?,_ error: DYMError?) -> Void
    
    // MARK: - Singleton
    static let shared = DYMIAPFacadeManager()
    override private init() { super.init() }
    
    // MARK: - Version Detection
    private var shouldUseStoreKit2: Bool {
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Product Request
    public func requestProducts(identifiers: Set<String>?, completion: @escaping PaywallCompletion) {
        if shouldUseStoreKit2 {
            // 使用 StoreKit 2
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                DYMIAPManagerV2.shared.requestProducts(identifiers: identifiers, completion: completion)
            } else {
                DYMIAPManager.shared.requestProducts(identifiers: identifiers, completion: completion)
            }
        } else {
            // 使用 StoreKit 1
            DYMIAPManager.shared.requestProducts(identifiers: identifiers, completion: completion)
        }
    }
    
    // MARK: - Purchase
    public func buy(productId: String, completion: PurchaseCompletion? = nil) {
        if shouldUseStoreKit2 {
            // 使用 StoreKit 2
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                if let completion = completion {
                    DYMIAPManagerV2.shared.buy(productId: productId, completion: completion)
                }
            } else {
                DYMIAPManager.shared.buy(productId: productId, completion: completion)
            }
        } else {
            // 使用 StoreKit 1
            DYMIAPManager.shared.buy(productId: productId, completion: completion)
        }
    }
    
    public func buy(product: SKProduct?, completion: PurchaseCompletion? = nil) {
        if shouldUseStoreKit2 {
            // 使用 StoreKit 2 - 需要将 SKProduct 转换为 Product
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                guard let skProduct = product, let completion = completion else { return }
                
                // 通过产品 ID 获取 StoreKit 2 的 Product
                Task {
                    do {
                        let products = try await Product.products(for: [skProduct.productIdentifier])
                        if let storeKit2Product = products.first {
                            DYMIAPManagerV2.shared.buy(product: storeKit2Product, completion: completion)
                        } else {
                            let error = DYMError(code: 404, message: "Product not found")
                            completion(.failure(error), nil)
                        }
                    } catch {
                        let dymError = DYMError(code: 500, message: error.localizedDescription)
                        completion(.failure(dymError), nil)
                    }
                }
            } else {
                DYMIAPManager.shared.buy(product: product, completion: completion)
            }
        } else {
            // 使用 StoreKit 1
            DYMIAPManager.shared.buy(product: product, completion: completion)
        }
    }
    
    // MARK: - Restore
    public func restrePurchase(completion: RestoreCompletion? = nil) {
        if shouldUseStoreKit2 {
            // 使用 StoreKit 2
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                if let completion = completion {
                    DYMIAPManagerV2.shared.restrePurchase(completion: completion)
                }
            } else {
                DYMIAPManager.shared.restrePurchase(completion: completion)
            }
        } else {
            // 使用 StoreKit 1
            DYMIAPManager.shared.restrePurchase(completion: completion)
        }
    }
    
    // MARK: - Code Redemption
    public func presentCodeRedemptionSheet() {
        if shouldUseStoreKit2 {
            // 使用 StoreKit 2
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                DYMIAPManagerV2.shared.presentCodeRedemptionSheet()
            } else {
                DYMIAPManager.shared.presentCodeRedemptionSheet()
            }
        } else {
            // 使用 StoreKit 1
            DYMIAPManager.shared.presentCodeRedemptionSheet()
        }
    }
    
    // MARK: - Properties
    public var productQuantity: Int {
        get {
            if shouldUseStoreKit2 {
                if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                    return DYMIAPManagerV2.shared.productQuantity
                } else {
                    return DYMIAPManager.shared.productQuantity
                }
            } else {
                return DYMIAPManager.shared.productQuantity
            }
        }
        set {
            if shouldUseStoreKit2 {
                if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                    DYMIAPManagerV2.shared.productQuantity = newValue
                } else {
                    DYMIAPManager.shared.productQuantity = newValue
                }
            } else {
                DYMIAPManager.shared.productQuantity = newValue
            }
        }
    }
}
