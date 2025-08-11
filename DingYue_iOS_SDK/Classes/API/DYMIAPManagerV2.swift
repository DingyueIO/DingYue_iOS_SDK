//
//  DYMIAPManagerV2.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2025/8/6.
//

import StoreKit

/// DYMIAPManagerV2 - StoreKit 2 版本的 IAP 管理器
/// 提供现代化的应用内购买功能，支持 iOS 15.0+
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
class DYMIAPManagerV2: NSObject, @unchecked Sendable {
    
    // MARK: - Type Aliases
    
    /// 产品请求完成回调（StoreKit 2 原生）
    public typealias ProductRequestCompletion = (_ products: [Product]?,_ error: Error?) -> Void
    
    /// 购买完成回调（StoreKit 2 原生）
    public typealias PurchaseCompletion = (_ result: Product.PurchaseResult?, _ product: Product?, _ error: Error?) -> Void
    
    /// 恢复购买完成回调（StoreKit 2 原生）
    public typealias RestoreCompletion = (_ hasValidTransactions: Bool, _ verificationErrors: [Error]) -> Void
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = DYMIAPManagerV2()
    
    // MARK: - Properties
    
    /// 是否已启动交易监听器
    private var isTransactionListenerStarted = false
    
    /// 购买数量（与 V1 保持一致）
    public var productQuantity: Int = 1
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    deinit {
        stopTransactionListener()
    }
    
    // MARK: - Product Management
    
    /// 请求产品信息
    /// - Parameters:
    ///   - productIdentifiers: 产品标识符集合
    ///   - completion: 完成回调，返回 Product 数组或错误
    func requestProducts(productIdentifiers: Set<String>, completion: @escaping ProductRequestCompletion) {
        DYMLogManager.logMessage("DYMIAPManagerV2: Requesting products for \(productIdentifiers.count) identifiers")
        Task {
            do {
                let products = try await Product.products(for: Array(productIdentifiers))
                DYMLogManager.logMessage("DYMIAPManagerV2: Successfully loaded \(products.count) products")
                completion(products, nil)
            } catch {
                DYMLogManager.logError("DYMIAPManagerV2: Failed to load products - \(error.localizedDescription)")
                completion(nil, error)
            }
        }
    }
    
    // MARK: - Purchase Operations
    
    /// 通过产品 ID 购买商品
    /// - Parameters:
    ///   - productId: 产品标识符
    ///   - completion: 完成回调
    func buy(productId: String, completion: @escaping PurchaseCompletion) {
        DYMLogManager.logMessage("DYMIAPManagerV2: Starting purchase for productId: \(productId), quantity: \(productQuantity)")
        Task {
            do {
                let products = try await Product.products(for: [productId])
                guard let product = products.first else {
                    let error = DYMError.noProducts
                    DYMLogManager.logError("DYMIAPManagerV2: Product not found: \(productId)")
                    completion(nil, nil, error)
                    return
                }
                
                // 处理购买数量
                if productQuantity > 1 {
                    // 多次购买来实现数量
                    DYMLogManager.logMessage("DYMIAPManagerV2: Performing \(productQuantity) purchases for quantity")
                    var lastResult: Product.PurchaseResult?
                    for i in 0..<productQuantity {
                        lastResult = try await product.purchase()
                        DYMLogManager.logMessage("DYMIAPManagerV2: Purchase \(i + 1)/\(productQuantity) completed")
                    }
                    DYMLogManager.logMessage("DYMIAPManagerV2: All \(productQuantity) purchases completed successfully")
                    completion(lastResult, product, nil)
                } else {
                    // 单次购买
                    DYMLogManager.logMessage("DYMIAPManagerV2: Performing single purchase")
                    let result = try await product.purchase()
                    DYMLogManager.logMessage("DYMIAPManagerV2: Purchase completed successfully")
                    completion(result, product, nil)
                }
                
            } catch {
                DYMLogManager.logError("DYMIAPManagerV2: Purchase failed - \(error.localizedDescription)")
                let dymError = DYMError(error)
                completion(nil, nil, dymError)
            }
        }
    }
    
    /// 通过 Product 对象购买商品
    /// - Parameters:
    ///   - product: StoreKit 2 Product 对象
    ///   - completion: 完成回调
    func buy(product: Product, completion: @escaping PurchaseCompletion) {
        DYMLogManager.logMessage("DYMIAPManagerV2: Starting purchase for product: \(product.id)")
        Task {
            do {
                let result = try await product.purchase()
                DYMLogManager.logMessage("DYMIAPManagerV2: Purchase completed successfully for product: \(product.id)")
                completion(result, product, nil)
            } catch {
                DYMLogManager.logError("DYMIAPManagerV2: Purchase failed for product \(product.id) - \(error.localizedDescription)")
                let dymError = DYMError(error)
                completion(nil, nil, dymError)
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    /// 恢复购买
    /// - Parameter completion: 完成回调
    func restorePurchases(completion: @escaping RestoreCompletion) {
        DYMLogManager.logMessage("DYMIAPManagerV2: Starting restore purchases")
        Task {
            do {
                // 同步 App Store
                try await AppStore.sync()
                DYMLogManager.logMessage("DYMIAPManagerV2: App Store sync completed")
                
                // 获取当前有效的交易
                var hasValidTransactions = false
                var verificationErrors: [Error] = []
                
                for await result in Transaction.currentEntitlements {
                    do {
                        let transaction = try checkVerified(result)
                        hasValidTransactions = true
                        DYMLogManager.logMessage("DYMIAPManagerV2: Valid transaction found: \(transaction.productID)")
                    } catch {
                        verificationErrors.append(error)
                        DYMLogManager.logError("DYMIAPManagerV2: Transaction verification failed - \(error.localizedDescription)")
                    }
                }
                
                DYMLogManager.logMessage("DYMIAPManagerV2: Restore completed - hasValidTransactions: \(hasValidTransactions), errors: \(verificationErrors.count)")
                DispatchQueue.main.async {
                    completion(hasValidTransactions, verificationErrors)
                }
                
            } catch {
                DYMLogManager.logError("DYMIAPManagerV2: Restore failed - \(error.localizedDescription)")
                let dymError = DYMError(error)
                DispatchQueue.main.async {
                    completion(false, [dymError])
                }
            }
        }
    }
    
    // MARK: - Code Redemption
    
    /// 展示兑换码页面
    func presentCodeRedemptionSheet() {
        #if swift(>=5.3) && os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *) {
            // StoreKit 2 中，兑换码页面通过 SKPaymentQueue 展示
            SKPaymentQueue.default().presentCodeRedemptionSheet()
        } else {
            print("Presenting code redemption sheet is available only for iOS 14 and higher.")
        }
        #endif
    }
    
    // MARK: - Transaction Listener Management
    
    /// 启动交易监听器
    func startTransactionListener() {
        // 避免重复启动
        guard !isTransactionListenerStarted else { 
            DYMLogManager.logMessage("DYMIAPManagerV2: Transaction listener already started")
            return 
        }
        isTransactionListenerStarted = true
        DYMLogManager.logMessage("DYMIAPManagerV2: Starting transaction listener")
        
        Task {
            for await result in Transaction.updates {
                await handleTransactionUpdate(result)
            }
        }
    }
    
    /// 停止交易监听器
    func stopTransactionListener() {
        isTransactionListenerStarted = false
        DYMLogManager.logMessage("DYMIAPManagerV2: Transaction listener stopped")
        // 在 StoreKit 2 中，Task 会自动管理生命周期
        // 这里可以添加额外的清理逻辑
    }
}

// MARK: - Private Methods

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension DYMIAPManagerV2 {
    
    /// 验证交易
    /// - Parameter result: 验证结果
    /// - Returns: 验证后的交易
    /// - Throws: 验证失败时抛出错误
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw DYMError(code: .failed, message: "Transaction verification failed")
        case .verified(let safe):
            return safe
        }
    }
    

    
    /// 处理交易状态更新
    /// - Parameter result: 交易验证结果
    func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            DYMLogManager.logMessage("DYMIAPManagerV2: Transaction update received for product: \(transaction.productID)")
            // 这里可以添加交易处理逻辑
        } catch {
            DYMLogManager.logError("DYMIAPManagerV2: Transaction verification failed - \(error.localizedDescription)")
        }
    }
    
    /// 获取收据
    /// - Returns: 收据字符串
    func getReceipt() async -> String? {
        // StoreKit 2 中，我们需要从 Bundle 中获取真实的收据
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else { 
            return nil 
        }
        
        guard FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else { 
            return nil 
        }

        var receiptData: Data?
        do { 
            receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped) 
        } catch {
            print("Couldn't read receipt data: \(error)")
            return nil
        }

        guard let receipt = receiptData?.base64EncodedString() else {
            print("Failed to encode receipt data")
            return nil
        }
        
        return receipt
    }
}
    



