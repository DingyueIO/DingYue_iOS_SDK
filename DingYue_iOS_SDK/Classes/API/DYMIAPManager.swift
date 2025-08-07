//
//  DYMIPAManager.swift
//  DingYueMobileSDK
//
//  Created by 靖核 on 2022/4/4.
//

import UIKit
import StoreKit

class DYMIAPManager: NSObject {
    
    public typealias PaywallCompletion = (_ products: [DYMProductModel]?,_ error: DYMError?) -> Void
    public typealias PurchaseCompletion = (_ purchase: DYMPurchaseResult,_ receiptVerifyMobileResponse:[String:Any]?) -> Void
    public typealias RestoreCompletion  = (_ receipt: String?,_ receiptVerifyMobileResponse:[String:Any]?,_ error: DYMError?) -> Void
    private typealias PurchaseTemplate  = (product: DYMProductModel, payment: SKPayment,completion:PurchaseCompletion?)
    
    private var productRequest: SKProductsRequest?
    private var paywallProductIds: Set<String>? {
        if let productIds = paywallProducts?.map({$0.vendorIdentifier}) {
            return Set(productIds)
        }
        return nil
    }
    
    private var paywallProducts: [DYMProductModel]?
    private var templateProductIds: Set<String>?
    private var templateProducts: [DYMProductModel]?
    
    private var currentProducts: [DYMProductModel] = []
    private var purchaseProducts: [DYMProductModel] = []
    private var paywallCompletion: PaywallCompletion?
    
    private var purchaseTemplates: [PurchaseTemplate] = []
    
    private var restoreCompletion: RestoreCompletion?
    private var restorePurchaseTimes: Int = 0
    public var productQuantity: Int = 1
    private var isRestoringManually: Bool = false
    static let shared = DYMIAPManager()
    override private init() { super.init() }
    
    func startObserverPurchase() {
        startObserving()
        NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationWillTerminate, object: nil, queue: .main) { notification in
            self.stopObserving()
        }
    }
    
    public func requestProducts(identifiers: Set<String>?, completion:@escaping PaywallCompletion) {
        if let productIds = identifiers {
            templateProductIds = productIds
        }else {
            guard let productIds = paywallProductIds else {
                DispatchQueue.main.async {
                    completion(nil,.noProductIds) }
                return
            }
            templateProductIds = productIds
            if currentProducts.isEmpty {
                currentProducts.append(contentsOf: paywallProducts ?? [])
            }else {
                paywallProducts?.forEach({ product in
                    if self.product(for: product.vendorIdentifier) == nil {
                        currentProducts.append(product)
                    }
                })
            }
        }
        if templateProductIds!.isEmpty {
            templateProductIds = nil
            DispatchQueue.main.async { completion(nil,.noProductIds) }
            return
        }

        productRequest?.cancel()
        paywallCompletion = completion
        templateProducts = templateProductIds!.map{DYMProductModel(productId: $0)}
        productRequest = SKProductsRequest(productIdentifiers: templateProductIds!)
        productRequest?.delegate = self
        productRequest?.start()
    }
    
    func callBackPaywallCompletion(result: Result<[DYMProductModel],DYMError>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let products):
                DYMLogManager.logMessage("Successfully loaded list of products: [\(self.templateProductIds?.joined(separator: ",") ?? "")]")
                self.paywallCompletion?(products,nil)
            case .failure(let error):
                DYMLogManager.logError("Failed to load list of products.\n\(error.localizedDescription)")
                self.paywallCompletion?(nil,error)
            }
            self.templateProductIds = nil
            self.paywallCompletion = nil
        }
    }
    
    // MARK: - Purchase
    public func buy(productId: String, completion:PurchaseCompletion? = nil) {
        isRestoringManually = false
        guard canMakePayments else {
            DispatchQueue.main.async {
                completion?(.failure(.unablePayment),nil)
            }
            return
        }
        finishTransactionInSKPaymentQueue()
        let cproduct = DYMProductModel(productId: productId)
        currentProducts.append(cproduct)

        requestProducts(identifiers: [productId]) { products, error in
            if error != nil {
                completion?(.failure(error!),nil)
                return
            }
            self.createPayment(for: products![0], completion: completion)
        }
    }
    
    public func buy(product:SKProduct?, completion:PurchaseCompletion? = nil) {
        isRestoringManually = false
        guard canMakePayments else {
            DispatchQueue.main.async {
                completion?(.failure(.unablePayment),nil)
            }
            return
        }
        finishTransactionInSKPaymentQueue()
        guard let skproduct = product else {
            DispatchQueue.main.async {
                completion?(.failure(.noProducts),nil)
            }
            return
        }
        if let cproduct = self.product(for: skproduct) {
            createPayment(for: cproduct, completion: completion)
            return
        }
        let cproduct = DYMProductModel(productId: skproduct.productIdentifier)
        cproduct.skproduct = skproduct
        currentProducts.append(cproduct)
        createPayment(for: cproduct, completion: completion)
    }
    
    private func createPayment(for product:DYMProductModel,completion:PurchaseCompletion? = nil) {
        let payment = SKMutablePayment(product: product.skproduct!)
        payment.applicationUsername = UserProperties.requestUUID
        payment.quantity = self.productQuantity
        purchaseTemplates.append((product:product,
                                  payment:payment,
                                  completion:completion))
        SKPaymentQueue.default().add(payment)
    }

    public func finishTransactionInSKPaymentQueue() {
        let transactions = SKPaymentQueue.default().transactions
        guard !transactions.isEmpty else { return }
        for transaction in transactions {
            if transaction.transactionState == SKPaymentTransactionState.purchased || transaction.transactionState == SKPaymentTransactionState.restored || transaction.transactionState == SKPaymentTransactionState.failed{
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }

    private func callBackPurchaseCompletion(for template: PurchaseTemplate?,_ result:Result< DYMPurchaseDetail,DYMError>,_ firstReceiptVerifyMobileResponse:[String:Any]? = nil) {
        DispatchQueue.main.async {
            switch result {
            case .success(let purchese):
                    if let response = firstReceiptVerifyMobileResponse {
                        template?.completion?(.succeed(purchese),response)
                    } else {
                        template?.completion?(.succeed(purchese),nil)
                    }

            case .failure(let error):
                template?.completion?(.failure(error),nil)
            }
            if let template = template {
                self.purchaseTemplates.removeAll { $0.product == template.product && $0.payment == template.payment }
            }
        }
    }
    // MARK: - Restore
    ///恢复购买
    func restrePurchase(completion:RestoreCompletion? = nil) {
        isRestoringManually = true
        restoreCompletion = completion
        restorePurchaseTimes = 0
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    ///恢复购买结果返回
    private func callBackRestoreCompletion(_ result: Result<String,DYMError>,_ receiptVerifyMobileResponse:[String:Any]? = nil) {
        DispatchQueue.main.async {
            switch result {
            case .success(let receipt):
                    if let response = receiptVerifyMobileResponse {
                        self.restoreCompletion?(receipt,response,nil)
                    } else {
                        self.restoreCompletion?(receipt,nil,nil)
                    }
            case .failure(let error):
                    self.restoreCompletion?(nil,nil,error)
            }
            self.restoreCompletion = nil
        }
    }
    // MARK: - Observer
    ///开启支付监控
    private func startObserving() {
        SKPaymentQueue.default().add(self)
    }
    ///关闭支付监控
    private func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
    ///判断能否支付
    private var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    // MARK: - Receipt
    ///最新支付收据
    var lastReceipt: String? {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else { return nil }
        guard FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else { return nil }

        var receiptData: Data?
        do { receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped) } catch {
            DYMLogManager.logError("Couldn't read receipt data.\n\(error)")
        }

        guard let receipt = receiptData?.base64EncodedString() else {
            DYMLogManager.logError(DYMError.noReceipt)
            return nil
        }
        return receipt
    }
    ///展示支付代码
    func presentCodeRedemptionSheet() {
        #if swift(>=5.3) && os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *) {
            SKPaymentQueue.default().presentCodeRedemptionSheet()
        } else {
            DYMLogManager.logError("Presenting code redemption sheet is available only for iOS 14 and higher.")
        }
        #endif
    }
}

extension DYMIAPManager: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { transaction in
            print("Transaction State: \(transaction.transactionState.rawValue)----\(transaction.payment.productIdentifier)")
            switch transaction.transactionState {
            case .failed: failed(transaction)
            case .purchased: purchased(transaction)
            case .restored: restored(transaction)
            default:break
            }
        }
    }
    ///订单失败或订单被取消时调用
    func failed(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
        
        let temple = purchaseTemplate(for: transaction)
        
        if let error = transaction.error {
            callBackPurchaseCompletion(for: temple, .failure(DYMError(error)))
        } else {
            callBackPurchaseCompletion(for: temple, .failure(.purchaseFailed))
        }

        if let paywallIdentifier = DYMDefaultsManager.shared.cachedPaywallPageIdentifier {
            let str = paywallIdentifier as NSString
            let subStrs =  str.components(separatedBy: "/")
            if subStrs.count == 2 {
                let paywallId = subStrs[0]
                let paywallVersion = subStrs[1]
                DYMobileSDK.track(event: "PURCHASE_CANCLED", extra: paywallId, user: paywallVersion)
            } else {
                DYMobileSDK.track(event: "PURCHASE_CANCLED")
            }
        } else {
            DYMobileSDK.track(event: "PURCHASE_CANCLED")
        }

    }
    ///支付完成后
    func purchased(_ transaction: SKPaymentTransaction) {
        
        let template = purchaseTemplate(for: transaction)

        guard let receipt = lastReceipt else {
            callBackPurchaseCompletion(for: template, .failure(.noReceipt))
            return
        }

        guard let product = template?.product else {
            callBackPurchaseCompletion(for: template, .failure(.noProducts))
            return
        }
        DYMobileSDK.validateReceiptFirst(receipt, for: product.skproduct) { firstReceiptVerifyMobileResponse, error in
            let detail = DYMPurchaseDetail(productId: transaction.payment.productIdentifier,
                                           quantity: transaction.payment.quantity,
                                           product: product.skproduct!,
                                           receipt: receipt,
                                           transaction: transaction)
            if let err = error {
                self.callBackPurchaseCompletion(for: template, .failure((err as? DYMError) ?? DYMError(err)))
            } else {
                self.callBackPurchaseCompletion(for: template, .success(detail), firstReceiptVerifyMobileResponse)
            }
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }
    
    private func purchaseTemplate(for transaction: SKPaymentTransaction) -> PurchaseTemplate? {
        return purchaseTemplates.filter({ $0.payment.productIdentifier == transaction.payment.productIdentifier }).first
    }
    
    private func product(for transaction: SKPaymentTransaction) -> DYMProductModel? {
        return product(for: transaction.payment.productIdentifier)
    }
    
    private func product(for skProduct: SKProduct) -> DYMProductModel? {
        return product(for: skProduct.productIdentifier)
    }
    
    private func product(for productId: String) -> DYMProductModel? {
        return currentProducts.filter({ $0.vendorIdentifier == productId }).first
    }
    
    private func skProduct(for product: DYMProductModel) -> SKProduct? {
        return currentProducts.filter({ $0.vendorIdentifier == product.vendorIdentifier }).first?.skproduct
    }
    
    // MARK: - Restore
    ///恢复订单时调用
    func restored(_ transaction: SKPaymentTransaction) {
        restorePurchaseTimes += 1
        SKPaymentQueue.default().finishTransaction(transaction)
        if isRestoringManually {
        }else {
        }
    }
    
    ///从购买历史中恢复
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        //验证订单
        #if os(iOS)
        guard restorePurchaseTimes != 0 else {
            ///未购买
            callBackRestoreCompletion(.failure(.noPurchased))
            return
        }
        #endif
        guard let receipt = lastReceipt else {
            callBackRestoreCompletion(.failure(.noReceipt))
            return
        }
        DYMobileSDK.validateReceiptRecover(receipt) { recoverResponse, error in
            if error != nil {
                self.callBackRestoreCompletion(.failure(DYMError(error!)))
            }else {
                self.callBackRestoreCompletion(.success(receipt),recoverResponse)
            }
            self.finishTransactionInSKPaymentQueue()
        }
    }
    ///从购买历史中恢复遇到错误
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        //回调失败内容
        callBackRestoreCompletion(.failure(DYMError(error)))
    }
}

extension DYMIAPManager: SKProductsRequestDelegate {
    ///请求订阅产品返回
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            DYMLogManager.logMessage("Found product: \(product.productIdentifier) \(product.localizedTitle) \(product.price.floatValue)")
        }
        
        response.products.forEach { skProduct in
            paywallProducts?.filter({$0.vendorIdentifier == skProduct.productIdentifier}).forEach({$0.skproduct = skProduct})
            currentProducts.filter({ $0.vendorIdentifier == skProduct.productIdentifier}).forEach { $0.skproduct = skProduct }
            
        }
        let productIds = response.products.map { $0.productIdentifier }.joined(separator: ", ")
        DYMEventManager.shared.track(event: "PRODUCTS_REQUEST", extra: productIds)

        var products:[DYMProductModel] = []
        templateProductIds?.forEach({ productId in
            if let cproduct = self.product(for: productId) {
                products.append(cproduct)
            }
        })
        if response.products.count > 0, !products.isEmpty {
            callBackPaywallCompletion(result: .success(products))
        } else {
            callBackPaywallCompletion(result: .failure(.noProducts))
        }
    }
    ///请求结束
    func requestDidFinish(_ request: SKRequest) {
    }
    ///请求失败
    func request(_ request: SKRequest, didFailWithError error: Error) {
        if #available(iOS 14.0, *), let error = error as? SKError, SKError.Code(rawValue: error.errorCode) == SKError.unknown {
            DYMLogManager.logError("Unable to get product from store. Please make sure you are running the simulator under iOS 14 and above, or if you want to continue using iOS 14 and above, make sure you are running it on a real device.")
        }else {
            DYMLogManager.logError(error)
        }
        callBackPaywallCompletion(result: .failure(DYMError(error)))
    }
}
