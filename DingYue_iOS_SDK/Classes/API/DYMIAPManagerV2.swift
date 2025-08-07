//
//  DYMIAPManagerV2.swift
//  DingYue_iOS_SDK
//
//  Created by 王勇 on 2025/8/6.
//

import StoreKit

// MARK: - Mock Classes for V1 Compatibility
/// Mock SKProduct for V1 compatibility
private class MockSKProduct: SKProduct, @unchecked Sendable {
    private let _productIdentifier: String
    private let _price: String
    private let _priceLocale: Locale
    private let _localizedTitle: String
    private let _localizedDescription: String
    
    init(productIdentifier: String, price: String, priceLocale: Locale, localizedTitle: String, localizedDescription: String) {
        self._productIdentifier = productIdentifier
        self._price = price
        self._priceLocale = priceLocale
        self._localizedTitle = localizedTitle
        self._localizedDescription = localizedDescription
        super.init()
    }
    
    override public var productIdentifier: String { _productIdentifier }
    override public var price: NSDecimalNumber { NSDecimalNumber(string: _price) }
    override public var priceLocale: Locale { _priceLocale }
    override public var localizedTitle: String { _localizedTitle }
    override public var localizedDescription: String { _localizedDescription }
}

/// Mock SKPaymentTransaction for V1 compatibility
private class MockSKPaymentTransaction: SKPaymentTransaction, @unchecked Sendable {
    private let _transactionIdentifier: String?
    private let _transactionDate: Date?
    private let _transactionState: SKPaymentTransactionState
    
    init(transactionIdentifier: String?, transactionDate: Date?, transactionState: SKPaymentTransactionState) {
        self._transactionIdentifier = transactionIdentifier
        self._transactionDate = transactionDate
        self._transactionState = transactionState
        super.init()
    }
    
    override public var transactionIdentifier: String? { _transactionIdentifier }
    override public var transactionDate: Date? { _transactionDate }
    override public var transactionState: SKPaymentTransactionState { _transactionState }
}

/// DYMIAPManagerV2 - StoreKit 2 版本的 IAP 管理器
/// 提供现代化的应用内购买功能，支持 iOS 15.0+
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
class DYMIAPManagerV2: NSObject, @unchecked Sendable {
    
    // MARK: - Type Aliases
    
    /// 产品请求完成回调
    public typealias PaywallCompletion = (_ products: [DYMProductModel]?,_ error: DYMError?) -> Void
    
    /// 购买完成回调
    public typealias PurchaseCompletion = (_ purchase: DYMPurchaseResult,_ receiptVerifyMobileResponse:[String:Any]?) -> Void
    
    /// 恢复购买完成回调
    public typealias RestoreCompletion = (_ receipt: String?,_ receiptVerifyMobileResponse:[String:Any]?,_ error: DYMError?) -> Void
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = DYMIAPManagerV2()
    
    // MARK: - Properties
    
    /// 购买商品数量，默认为 1
    public var productQuantity: Int = 1
    
    /// 恢复购买完成回调
    private var restoreCompletion: RestoreCompletion?
    
    /// 恢复购买次数计数
    private var restorePurchaseTimes: Int = 0
    
    /// 是否正在手动恢复购买
    private var isRestoringManually: Bool = false
    
    /// 当前购买回调，用于交易监听器回调
    private var currentPurchaseCompletion: PurchaseCompletion?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        startTransactionListener()
    }
    
    deinit {
        stopTransactionListener()
    }
    
    // MARK: - Product Management
    
    /// 请求产品信息（StoreKit 2 原生）
    /// - Parameters:
    ///   - productIdentifiers: 产品标识符集合
    ///   - completion: 完成回调，返回 Product 数组或错误
    func requestProducts(productIdentifiers: Set<String>, completion: @escaping ([Product]?, Error?) -> Void) {
        Task {
            do {
                let products = try await Product.products(for: Array(productIdentifiers))
                completion(products, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    /// 请求产品信息（V1 兼容接口）
    /// - Parameters:
    ///   - identifiers: 产品标识符集合（可选）
    ///   - completion: 完成回调，返回 DYMProductModel 数组或错误
    func requestProducts(identifiers: Set<String>?, completion: @escaping PaywallCompletion) {
        let productIdentifiers = identifiers ?? Set<String>()
        
        Task {
            do {
                let products = try await Product.products(for: Array(productIdentifiers))
                
                // 将 StoreKit 2 的 Product 转换为 DYMProductModel
                let dymProducts = products.map { product in
                    let dymProduct = DYMProductModel(productId: product.id)
                    // 创建 Mock SKProduct 用于兼容 V1 接口
                    let mockSKProduct = MockSKProduct(
                        productIdentifier: product.id,
                        price: product.price.description,
                        priceLocale: product.priceFormatStyle.locale,
                        localizedTitle: product.displayName,
                        localizedDescription: product.description
                    )
                    dymProduct.skproduct = mockSKProduct
                    return dymProduct
                }
                
                DispatchQueue.main.async {
                    completion(dymProducts, nil)
                }
                
            } catch {
                let dymError = DYMError(code: 500, message: error.localizedDescription)
                DispatchQueue.main.async {
                    completion(nil, dymError)
                }
            }
        }
    }
    
    // MARK: - Purchase Operations
    
    /// 通过产品 ID 购买商品
    /// - Parameters:
    ///   - productId: 产品标识符
    ///   - completion: 完成回调
    func buy(productId: String, completion: @escaping PurchaseCompletion) {
        Task {
            do {
                let products = try await Product.products(for: [productId])
                guard let product = products.first else {
                    let error = DYMError(code: 404, message: "Product not found")
                    completion(.failure(error), nil)
                    return
                }
                
                // 保存当前购买回调，让交易监听器处理结果
                currentPurchaseCompletion = completion
                
                let result = try await product.purchase()
                
                // 只处理非成功的情况（pending, cancelled, error）
                switch result {
                case .success(_):
                    // 成功情况由交易监听器处理
                    break
                case .pending:
                    let error = DYMError(code: 102, message: "Purchase is pending")
                    completion(.failure(error), nil)
                    currentPurchaseCompletion = nil
                case .userCancelled:
                    let error = DYMError(code: 101, message: "User cancelled the purchase")
                    completion(.failure(error), nil)
                    currentPurchaseCompletion = nil
                @unknown default:
                    let error = DYMError(code: 500, message: "Unknown error occurred")
                    completion(.failure(error), nil)
                    currentPurchaseCompletion = nil
                }
                
            } catch {
                let dymError = DYMError(code: 500, message: error.localizedDescription)
                completion(.failure(dymError), nil)
                currentPurchaseCompletion = nil
            }
        }
    }
    
    /// 通过 Product 对象购买商品
    /// - Parameters:
    ///   - product: StoreKit 2 Product 对象
    ///   - completion: 完成回调
    func buy(product: Product, completion: @escaping PurchaseCompletion) {
        Task {
            do {
                // 保存当前购买回调，让交易监听器处理结果
                currentPurchaseCompletion = completion
                
                let result = try await product.purchase()
                
                // 只处理非成功的情况（pending, cancelled, error）
                switch result {
                case .success(_):
                    // 成功情况由交易监听器处理
                    break
                case .pending:
                    let error = DYMError(code: 102, message: "Purchase is pending")
                    completion(.failure(error), nil)
                    currentPurchaseCompletion = nil
                case .userCancelled:
                    let error = DYMError(code: 101, message: "User cancelled the purchase")
                    completion(.failure(error), nil)
                    currentPurchaseCompletion = nil
                @unknown default:
                    let error = DYMError(code: 500, message: "Unknown error occurred")
                    completion(.failure(error), nil)
                    currentPurchaseCompletion = nil
                }
                
            } catch {
                let dymError = DYMError(code: 500, message: error.localizedDescription)
                completion(.failure(dymError), nil)
                currentPurchaseCompletion = nil
            }
        }
    }
    
    // MARK: - Restore Operations
    
    /// 恢复购买
    /// - Parameter completion: 完成回调
    func restrePurchase(completion: RestoreCompletion? = nil) {
        isRestoringManually = true
        restoreCompletion = completion
        restorePurchaseTimes = 0
        
        Task {
            await performRestore()
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
            DYMLogManager.logError("Presenting code redemption sheet is available only for iOS 14 and higher.")
        }
        #endif
    }
}

// MARK: - Private Methods

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension DYMIAPManagerV2 {
    

    
    /// 执行恢复购买
    func performRestore() async {
        do {
            try await AppStore.sync()
            
            var hasValidTransactions = false
            var verificationErrors: [Error] = []
            
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    hasValidTransactions = true
                    restorePurchaseTimes += 1
                    print("Restored transaction: \(transaction.productID)")
                    
                case .unverified(_, let verificationError):
                    print("Unverified transaction: \(verificationError)")
                    verificationErrors.append(verificationError)
                }
            }
            
            // 处理验证错误
            if !verificationErrors.isEmpty {
                callBackRestoreCompletion(.failure(DYMError(verificationErrors.first!)))
                return
            }
            
            // 处理无有效交易的情况
            if !hasValidTransactions {
                callBackRestoreCompletion(.failure(.noPurchased))
                return
            }
            
            // 获取收据并验证
            guard let receipt = await getReceipt() else {
                callBackRestoreCompletion(.failure(.noReceipt))
                return
            }
            
            DYMobileSDK.validateReceiptRecover(receipt) { recoverResponse, error in
                if error != nil {
                    self.callBackRestoreCompletion(.failure(DYMError(error!)))
                } else {
                    self.callBackRestoreCompletion(.success(receipt), recoverResponse)
                }
            }
            
        } catch {
            callBackRestoreCompletion(.failure(DYMError(error)))
        }
    }
    
    /// 恢复购买结果回调
    /// - Parameters:
    ///   - result: 结果
    ///   - receiptVerifyMobileResponse: 收据验证响应
    func callBackRestoreCompletion(_ result: Result<String,DYMError>,_ receiptVerifyMobileResponse:[String:Any]? = nil) {
        DispatchQueue.main.async {
            switch result {
            case .success(let receipt):
                if let response = receiptVerifyMobileResponse {
                    self.restoreCompletion?(receipt, response, nil)
                } else {
                    self.restoreCompletion?(receipt, nil, nil)
                }
                
            case .failure(let error):
                self.restoreCompletion?(nil, nil, error)
            }
            
            self.restoreCompletion = nil
        }
    }
    
    /// 验证交易
    /// - Parameter result: 验证结果
    /// - Returns: 验证后的交易
    /// - Throws: 验证失败时抛出错误
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw DYMError(code: 401, message: "Transaction verification failed")
        case .verified(let safe):
            return safe
        }
    }
    
    /// 启动交易监听器
    func startTransactionListener() {
        Task {
            for await result in Transaction.updates {
                await handleTransactionUpdate(result)
            }
        }
    }
    
    /// 停止交易监听器
    func stopTransactionListener() {
        // 在 StoreKit 2 中，Task 会自动管理生命周期
        // 这里可以添加额外的清理逻辑
    }
    
    /// 处理交易状态更新
    /// - Parameter result: 交易验证结果
    func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            
            // Transaction.updates 已经过滤了状态，这里直接处理有效交易
            await handleValidTransaction(transaction)
            
        } catch {
            print("Transaction verification failed: \(error)")
            // 验证失败，回调错误
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let dymError = DYMError(code: 401, message: "Transaction verification failed")
                self.currentPurchaseCompletion?(.failure(dymError), nil)
                self.currentPurchaseCompletion = nil
            }
        }
    }
    
    /// 处理有效交易
    /// - Parameter transaction: 交易对象
    func handleValidTransaction(_ transaction: Transaction) async {
        print("Valid transaction: \(transaction.productID)")
        
        // 获取收据并验证
        guard let receipt = await getReceipt() else {
            print("Failed to get receipt for transaction: \(transaction.productID)")
            // 收据获取失败，回调失败
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let error = DYMError(code: 103, message: "Failed to get receipt")
                self.currentPurchaseCompletion?(.failure(error), nil)
                self.currentPurchaseCompletion = nil
            }
            return
        }
        
        // 验证收据（统一在这里处理所有购买完成）
        DYMobileSDK.validateReceiptFirst(receipt, for: nil) { [weak self] firstReceiptVerifyMobileResponse, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let err = error {
                    print("Receipt validation failed for \(transaction.productID): \(err)")
                    // 收据验证失败，回调失败
                    let dymError = DYMError(code: 104, message: err.localizedDescription)
                    self.currentPurchaseCompletion?(.failure(dymError), nil)
                } else {
                    print("Receipt validation successful for \(transaction.productID)")
                    // 收据验证成功，创建 DYMPurchaseDetail 并回调成功
                    let purchaseDetail = self.createPurchaseDetail(from: transaction, receipt: receipt)
                    self.currentPurchaseCompletion?(.succeed(purchaseDetail), firstReceiptVerifyMobileResponse)
                }
                self.currentPurchaseCompletion = nil
            }
        }
    }

    
    /// 创建 DYMPurchaseDetail 对象
    /// - Parameters:
    ///   - transaction: StoreKit 2 交易对象
    ///   - receipt: 收据字符串
    /// - Returns: DYMPurchaseDetail 对象
    func createPurchaseDetail(from transaction: Transaction, receipt: String) -> DYMPurchaseDetail {
        // 创建 Mock SKProduct 用于兼容 V1 接口
        let mockProduct = MockSKProduct(
            productIdentifier: transaction.productID,
            price: transaction.price?.description ?? "0.00",
            priceLocale: Locale.current,
            localizedTitle: transaction.productID,
            localizedDescription: transaction.productID
        )
        
        // 创建 Mock SKPaymentTransaction 用于兼容 V1 接口
        let mockTransaction = MockSKPaymentTransaction(
            transactionIdentifier: transaction.id.description,
            transactionDate: transaction.purchaseDate,
            transactionState: .purchased
        )
        
        return DYMPurchaseDetail(
            productId: transaction.productID,
            quantity: 1, // StoreKit 2 默认数量为 1
            product: mockProduct,
            receipt: receipt,
            transaction: mockTransaction
        )
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
            DYMLogManager.logError("Couldn't read receipt data.\n\(error)")
            return nil
        }

        guard let receipt = receiptData?.base64EncodedString() else {
            DYMLogManager.logError(DYMError.noReceipt)
            return nil
        }
        
        return receipt
    }
}
    



