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
    
    // MARK: - Version Detection
    private var _shouldUseStoreKit2: Bool = false
    
    /// 更新 StoreKit 版本配置
    /// - Parameter useStoreKit2: 是否使用 StoreKit 2
    public func updateStoreKitVersion(_ useStoreKit2: Bool) {
        _shouldUseStoreKit2 = useStoreKit2
        DYMLogManager.logMessage("DYMIAPFacadeManager: StoreKit version updated to \(useStoreKit2 ? "StoreKit 2" : "StoreKit 1")")
    }
    
    private var shouldUseStoreKit2: Bool {
        return _shouldUseStoreKit2
    }
    
    // MARK: - Singleton
    static let shared = DYMIAPFacadeManager()
    
    override private init() { 
        super.init() 
        // 初始化时同步 productQuantity 到 V1 和 V2
        DYMIAPManager.shared.productQuantity = productQuantity
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
            DYMIAPManagerV2.shared.productQuantity = productQuantity
        }
    }
    
 
    
    // MARK: - Observer Management
    /// 启动购买监听器（与 V1 保持一致）
    public func startObserverPurchase() {
        DYMLogManager.logMessage("DYMIAPFacadeManager: startObserverPurchase called")
        
        // 根据版本选择启动相应的监听器
        if shouldUseStoreKit2 {
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                // 启动 V2 的监听器
                DYMIAPManagerV2.shared.startTransactionListener()
            }
        } else {
            // 启动 V1 的监听器
            DYMIAPManager.shared.startObserverPurchase()
        }
    }
    
    
    
    // MARK: - Product Request
    public func requestProducts(identifiers: Set<String>?, completion: @escaping PaywallCompletion) {
        if shouldUseStoreKit2 {
            // 使用 StoreKit 2
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                let productIdentifiers = identifiers ?? Set<String>()
                DYMIAPManagerV2.shared.requestProducts(productIdentifiers: productIdentifiers) { products, error in
                    if let products = products {
                        // 将 StoreKit 2 的 Product 转换为 DYMProductModel
                        let dymProducts = products.map { self.convertToDYMProductModel(from: $0) }
                        completion(dymProducts, nil)
                    } else {
                        let dymError = DYMError(code: 500, message: error?.localizedDescription ?? "Unknown error")
                        completion(nil, dymError)
                    }
                }
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
                    // productQuantity 已经通过 didSet 自动同步到 V2
                    DYMIAPManagerV2.shared.buy(productId: productId) { result, product, error in
                        if let error = error {
                            // 处理错误 - 确保在主线程执行
                            let dymError = self.convertToDYMError(error)
                            DispatchQueue.main.async {
                                completion(.failure(dymError), nil)
                            }
                        } else if let result = result {
                            // 将 StoreKit 2 的购买结果转换为 V1 兼容的结果
                            if let product = product {
                                self.handleStoreKit2PurchaseResult(result, product: product, completion: completion)
                            } else {
                                // 如果没有 Product 信息，使用默认处理
                                self.handleStoreKit2PurchaseResult(result, completion: completion)
                            }
                        }
                    }
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
                            DYMIAPManagerV2.shared.buy(product: storeKit2Product) { result, product, error in
                                if let error = error {
                                    // 处理错误 - 确保在主线程执行
                                    let dymError = self.convertToDYMError(error)
                                    DispatchQueue.main.async {
                                        completion(.failure(dymError), nil)
                                    }
                                } else if let result = result {
                                    // 将 StoreKit 2 的购买结果转换为 V1 兼容的结果
                                    if let product = product {
                                        self.handleStoreKit2PurchaseResult(result, product: product, completion: completion)
                                    } else {
                                        // 如果没有 Product 信息，使用默认处理
                                        self.handleStoreKit2PurchaseResult(result, completion: completion)
                                    }
                                }
                            }
                        } else {
                            let error = DYMError.noProducts
                            DispatchQueue.main.async {
                                completion(.failure(error), nil)
                            }
                        }
                    } catch {
                        let dymError = self.convertToDYMError(error)
                        DispatchQueue.main.async {
                            completion(.failure(dymError), nil)
                        }
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
                    DYMIAPManagerV2.shared.restorePurchases { hasValidTransactions, verificationErrors in
                        // 将 StoreKit 2 的恢复结果转换为 V1 兼容的结果
                        self.handleStoreKit2RestoreResult(hasValidTransactions: hasValidTransactions, verificationErrors: verificationErrors, completion: completion)
                    }
                }
            } else {
                DYMIAPManager.shared.restrePurchase(completion: completion)
            }
        } else {
            // 使用 StoreKit 1
            DYMIAPManager.shared.restrePurchase(completion: completion)
        }
    }
    
    // MARK: - Product Quantity
    
    /// 购买数量（与 V1 保持一致）
    public var productQuantity: Int = 1 {
        didSet {
            // 同步设置到 V1 和 V2
            DYMIAPManager.shared.productQuantity = productQuantity
            if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                DYMIAPManagerV2.shared.productQuantity = productQuantity
            }
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
    
    // MARK: - Error Conversion
    
    /// 将任意错误转换为 DYMError
    /// - Parameter error: 原始错误
    /// - Returns: DYMError
    private func convertToDYMError(_ error: Error) -> DYMError {
        // 如果已经是 DYMError，直接返回
        if let dymError = error as? DYMError {
            return dymError
        }
        
        // 根据错误类型进行智能转换
        if let nsError = error as NSError? {
            // 根据错误域和代码进行转换
            switch nsError.domain {
            case "DYMIAPManagerV2":
                // V2 的错误，使用 V1 的错误代码
                return DYMError(code: .failed, message: nsError.localizedDescription)
            case "SKErrorDomain":
                // StoreKit 错误，使用 DYMError 的构造函数自动映射
                return DYMError(error)
            default:
                // 其他错误，使用通用失败代码
                return DYMError(code: .failed, message: nsError.localizedDescription)
            }
        }
        
        // 默认转换
        return DYMError(code: .failed, message: error.localizedDescription)
    }
    

}

// MARK: - StoreKit 2 Data Conversion Extensions
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension DYMIAPFacadeManager {
    
    // MARK: - Mock Classes for V1 Compatibility
    /// Mock SKProduct for V1 compatibility
    private class MockSKProduct: SKProduct, @unchecked Sendable {
        private let _productIdentifier: String
        private let _price: NSDecimalNumber
        private let _priceLocale: Locale
        private let _localizedTitle: String
        private let _localizedDescription: String
        
        init(productIdentifier: String, price: String, priceLocale: Locale, localizedTitle: String, localizedDescription: String) {
            self._productIdentifier = productIdentifier
            self._price = NSDecimalNumber(string: price)
            self._priceLocale = priceLocale
            self._localizedTitle = localizedTitle
            self._localizedDescription = localizedDescription
            super.init()
        }
        
        override public var productIdentifier: String { _productIdentifier }
        override public var price: NSDecimalNumber { _price }
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
    
    // MARK: - Data Conversion Methods
    
    /// 将 StoreKit 2 Product 转换为 DYMProductModel
    /// - Parameter product: StoreKit 2 Product
    /// - Returns: DYMProductModel
    private func convertToDYMProductModel(from product: Product) -> DYMProductModel {
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
    
    /// 将 StoreKit 2 Transaction 转换为 DYMPurchaseDetail
    /// - Parameters:
    ///   - transaction: StoreKit 2 Transaction
    ///   - product: StoreKit 2 Product 对象
    ///   - receipt: String
    /// - Returns: DYMPurchaseDetail
    private func convertToDYMPurchaseDetail(from transaction: Transaction, product: Product, receipt: String) -> DYMPurchaseDetail {
        // 创建 Mock SKProduct 用于兼容 V1 接口，使用 Product 的完整信息
        let mockProduct = MockSKProduct(
            productIdentifier: transaction.productID,
            price: product.price.description,
            priceLocale: product.priceFormatStyle.locale,
            localizedTitle: product.displayName,
            localizedDescription: product.description
        )
        
        // 创建 Mock SKPaymentTransaction 用于兼容 V1 接口
        let mockTransaction = MockSKPaymentTransaction(
            transactionIdentifier: transaction.id.description,
            transactionDate: transaction.purchaseDate,
            transactionState: .purchased
        )
        
        return DYMPurchaseDetail(
            productId: transaction.productID,
            quantity: self.productQuantity,
            product: mockProduct,
            receipt: receipt,
            transaction: mockTransaction
        )
    }
    
    /// 将 StoreKit 2 Transaction 转换为 DYMPurchaseDetail（无 Product 信息时的重载）
    /// - Parameters:
    ///   - transaction: StoreKit 2 Transaction
    ///   - receipt: String
    /// - Returns: DYMPurchaseDetail
    private func convertToDYMPurchaseDetail(from transaction: Transaction, receipt: String) -> DYMPurchaseDetail {
        // 创建 Mock SKProduct 用于兼容 V1 接口，使用默认值
        let mockProduct = MockSKProduct(
            productIdentifier: transaction.productID,
            price: transaction.price?.description ?? "0.00",
            priceLocale: Locale(identifier: "US_USD"),
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
    
    /// 验证交易
    /// - Parameter result: 验证结果
    /// - Returns: 验证后的交易
    /// - Throws: 验证失败时抛出错误
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw DYMError(code: 401, message: "Transaction verification failed")
        case .verified(let safe):
            return safe
        }
    }
    
    /// 处理 StoreKit 2 购买结果（无 Product 信息时的重载）
    /// - Parameters:
    ///   - result: StoreKit 2 购买结果
    ///   - completion: V1 兼容的回调
    private func handleStoreKit2PurchaseResult(_ result: Product.PurchaseResult, completion: @escaping PurchaseCompletion) {
        let createPurchaseDetail = { [weak self] (transaction: Transaction, receipt: String) -> DYMPurchaseDetail? in
            guard let self = self else { return nil }
            return self.convertToDYMPurchaseDetail(from: transaction, receipt: receipt)
        }
        
        switch result {
        case .success(let verification):
            Task {
                do {
                    let transaction = try checkVerified(verification)
                    
                    // 获取收据
                    guard let receipt = await getReceipt() else {
                        let error = DYMError(code: 103, message: "Failed to get receipt")
                        completion(.failure(error), nil)
                        return
                    }
                    
                    // 验证收据 - 使用默认值
                    let mockProduct = MockSKProduct(
                        productIdentifier: transaction.productID,
                        price: transaction.price?.description ?? "0.00",
                        priceLocale: Locale(identifier: "US_USD"),
                        localizedTitle: transaction.productID,
                        localizedDescription: transaction.productID
                    )
                    DYMobileSDK.validateReceiptFirst(receipt, for: mockProduct) { firstReceiptVerifyMobileResponse, error in
                        // 确保回调在主线程执行，避免 UI 操作在后台线程
                        DispatchQueue.main.async {
                            if let err = error {
                                let dymError = DYMError(err)
                                completion(.failure(dymError), nil)
                            } else {
                                // 使用 Transaction 和 Product 信息创建购买详情
                                if let purchaseDetail = createPurchaseDetail(transaction, receipt) {
                                    completion(.succeed(purchaseDetail), firstReceiptVerifyMobileResponse)
                                } else {
                                    let error = DYMError(code: .unknown, message: "Failed to create purchase detail")
                                    completion(.failure(error), nil)
                                }
                            }
                        }
                    }
                    
                } catch {
                    let dymError = DYMError(code: 401, message: "Transaction verification failed")
                    completion(.failure(dymError), nil)
                }
            }
            
        case .pending:
            let error = DYMError(code: .paymentCancelled, message: "Purchase is pending")
            DispatchQueue.main.async {
                completion(.failure(error), nil)
            }
            
        case .userCancelled:
            let error = DYMError(code: .paymentCancelled, message: "User cancelled the purchase")
            DispatchQueue.main.async {
                completion(.failure(error), nil)
            }
            
        @unknown default:
            let error = DYMError(code: .unknown, message: "Unknown error occurred")
            DispatchQueue.main.async {
                completion(.failure(error), nil)
            }
        }
    }
    
    /// 处理 StoreKit 2 购买结果（带 Product 信息）
    /// - Parameters:
    ///   - result: StoreKit 2 购买结果
    ///   - product: StoreKit 2 Product 对象
    ///   - completion: V1 兼容的回调
    private func handleStoreKit2PurchaseResult(_ result: Product.PurchaseResult, product: Product, completion: @escaping PurchaseCompletion) {
        // 创建本地函数来处理购买详情转换，避免 Sendable 警告
        let createPurchaseDetail = { [weak self] (transaction: Transaction, receipt: String) -> DYMPurchaseDetail? in
            guard let self = self else { return nil }
            return self.convertToDYMPurchaseDetail(from: transaction, product: product, receipt: receipt)
        }
        switch result {
        case .success(let verification):
            // 在 Task 开始前捕获需要的值，避免 Sendable 警告
            let productId = product.id
            let productPrice = product.price.description
            let productPriceLocale = product.priceFormatStyle.locale
            let productDisplayName = product.displayName
            let productDescription = product.description
            
            Task {
                do {
                    let transaction = try checkVerified(verification)
                    
                    // 获取收据
                    guard let receipt = await getReceipt() else {
                        let error = DYMError(code: 103, message: "Failed to get receipt")
                        completion(.failure(error), nil)
                        return
                    }
                    
                    // 验证收据 - 使用 Product 的完整信息
                    let mockProduct = MockSKProduct(
                        productIdentifier: transaction.productID,
                        price: productPrice,
                        priceLocale: productPriceLocale,
                        localizedTitle: productDisplayName,
                        localizedDescription: productDescription
                    )
                    DYMobileSDK.validateReceiptFirst(receipt, for: mockProduct) { firstReceiptVerifyMobileResponse, error in
                        // 确保回调在主线程执行，避免 UI 操作在后台线程
                        DispatchQueue.main.async {
                            if let err = error {
                                let dymError = DYMError(err)
                                completion(.failure(dymError), nil)
                            } else {
                                // 使用 Transaction 和 Product 信息创建购买详情
                                if let purchaseDetail = createPurchaseDetail(transaction, receipt) {
                                    completion(.succeed(purchaseDetail), firstReceiptVerifyMobileResponse)
                                } else {
                                    let error = DYMError(code: .unknown, message: "Failed to create purchase detail")
                                    completion(.failure(error), nil)
                                }
                            }
                        }
                    }
                    
                } catch {
                    let dymError = DYMError(code: 401, message: "Transaction verification failed")
                    completion(.failure(dymError), nil)
                }
            }
            
        case .pending:
            let error = DYMError(code: .paymentCancelled, message: "Purchase is pending")
            DispatchQueue.main.async {
                completion(.failure(error), nil)
            }
            
        case .userCancelled:
            let error = DYMError(code: .paymentCancelled, message: "User cancelled the purchase")
            DispatchQueue.main.async {
                completion(.failure(error), nil)
            }
            
        @unknown default:
            let error = DYMError(code: .unknown, message: "Unknown error occurred")
            DispatchQueue.main.async {
                completion(.failure(error), nil)
            }
        }
    }
    
    /// 处理 StoreKit 2 恢复结果
    /// - Parameters:
    ///   - hasValidTransactions: 是否有有效交易
    ///   - verificationErrors: 验证错误
    ///   - completion: V1 兼容的回调
    private func handleStoreKit2RestoreResult(hasValidTransactions: Bool, verificationErrors: [Error], completion: @escaping RestoreCompletion) {
        if !verificationErrors.isEmpty {
            let error = DYMError(code: .failed, message: "Transaction verification failed")
            DispatchQueue.main.async {
                completion(nil, nil, error)
            }
            return
        }
        
        if !hasValidTransactions {
            let error = DYMError.noPurchased
            DispatchQueue.main.async {
                completion(nil, nil, error)
            }
            return
        }
        
        // 获取收据并验证
        Task {
            guard let receipt = await getReceipt() else {
                let error = DYMError(code: 103, message: "Failed to get receipt")
                completion(nil, nil, error)
                return
            }
            
            DYMobileSDK.validateReceiptRecover(receipt) { recoverResponse, error in
                // 确保回调在主线程执行，避免 UI 操作在后台线程
                DispatchQueue.main.async {
                    if let err = error {
                        let dymError = DYMError(err)
                        completion(nil, nil, dymError)
                    } else {
                        completion(receipt, recoverResponse, nil)
                    }
                }
            }
        }
    }
    
    /// 获取收据
    /// - Returns: 收据字符串
    private func getReceipt() async -> String? {
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
