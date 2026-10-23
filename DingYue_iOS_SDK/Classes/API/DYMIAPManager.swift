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
    private typealias PurchaseTemplate = (product: DYMProductModel, payment: SKPayment, createdAt: Date, completion: PurchaseCompletion?)
    
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
    private var observing = false
    private var lifecycleTokens: [NSObjectProtocol] = []
    private var retryCounts: [String: Int] = [:]
    private var recoveryRequests: [String: DYMRecoveryProductRequest] = [:]
    private var restoredTransactions: [String: SKPaymentTransaction] = [:]
    private var restoringVerification = false
    private var restoreBatchFinished = false
    private var pendingNotified = Set<ObjectIdentifier>()
    private let receiptReader: (() -> String?)?
    // Internal injection seam for offline queue/verification regression tests.
    init(receiptReader: (() -> String?)? = nil) { self.receiptReader = receiptReader; super.init() }
    
    func startObserverPurchase() {
        guard Thread.isMainThread else { DispatchQueue.main.async { self.startObserverPurchase() }; return }
        guard !observing else { return }
        observing = true
        startObserving()
        lifecycleTokens.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.retryCounts.removeAll()
            self.reconcileUnfinishedTransactions()
            DYMTransactionDelivery.notifyAvailable()
        })
        reconcileUnfinishedTransactions()
        DYMTransactionDelivery.notifyAvailable()
    }

    private func reconcileUnfinishedTransactions() {
        paymentQueue(SKPaymentQueue.default(), updatedTransactions: SKPaymentQueue.default().transactions)
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
        let cproduct = DYMProductModel(productId: productId)
        currentProducts.append(cproduct)

        requestProducts(identifiers: [productId]) { products, error in
            if error != nil {
                completion?(.failure(error!),nil)
                return
            }
            guard let product = products?.first(where: { $0.vendorIdentifier == productId && $0.skproduct != nil }) else {
                completion?(.failure(.noProducts), nil)
                return
            }
            self.createPayment(for: product, completion: completion)
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
        guard Thread.isMainThread else { DispatchQueue.main.async { self.createPayment(for: product, completion: completion) }; return }
        guard let skProduct = product.skproduct else { completion?(.failure(.noProducts), nil); return }
        // One live intent per product. Never attach an old queued transaction to a new UI.
        guard !purchaseTemplates.contains(where: { $0.product.vendorIdentifier == product.vendorIdentifier }),
              !SKPaymentQueue.default().transactions.contains(where: { $0.payment.productIdentifier == product.vendorIdentifier }) else {
            completion?(.failure(DYMError(code: .failed, message: "An unfinished transaction already exists for this product")), nil)
            reconcileUnfinishedTransactions()
            return
        }
        let payment = SKMutablePayment(product: skProduct)
        payment.applicationUsername = UserProperties.requestUUID
        payment.quantity = self.productQuantity
        purchaseTemplates.append((product:product,
                                  payment:payment,
                                  createdAt: Date(),
                                  completion:completion))
        SKPaymentQueue.default().add(payment)
    }

    /// Retained for internal source compatibility; reconciliation must not bulk-finish.
    public func finishTransactionInSKPaymentQueue() {
        guard Thread.isMainThread else { DispatchQueue.main.async { self.finishTransactionInSKPaymentQueue() }; return }
        reconcileUnfinishedTransactions()
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
        guard Thread.isMainThread else { DispatchQueue.main.async { self.restrePurchase(completion: completion) }; return }
        guard !isRestoringManually else { completion?(nil, nil, DYMError(code: .failed, message: "Restore is already in progress")); return }
        isRestoringManually = true
        restoreBatchFinished = false
        retryCounts.removeValue(forKey: "restore-batch")
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
            self.isRestoringManually = false
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
        if let reader = receiptReader { return reader() }
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
        guard Thread.isMainThread else { DispatchQueue.main.async { self.paymentQueue(queue, updatedTransactions: transactions) }; return }
        transactions.forEach { transaction in
            print("Transaction State: \(transaction.transactionState.rawValue)----\(transaction.payment.productIdentifier)")
            switch transaction.transactionState {
            case .failed: failed(transaction)
            case .purchased: purchased(transaction)
            case .restored: restored(transaction)
            case .deferred:
                if pendingNotified.insert(ObjectIdentifier(transaction)).inserted {
                    NotificationCenter.default.post(name: DYMTransactionDelivery.pendingNotification, object: nil,
                        userInfo: ["productIdentifier": transaction.payment.productIdentifier])
                }
            default: break
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
        guard let id = transaction.transactionIdentifier, !id.isEmpty,
              let journal = DYMTransactionDelivery.journal else {
            notifyVerificationPending(transaction); return
        }
        let productID = transaction.payment.productIdentifier
        if journal.response(id: id, productID: productID) != nil {
            // A crash after persist but before finish needs no second verification/revenue request.
            DYMTransactionDelivery.notifyAvailable()
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }
        do {
            guard try journal.begin(id: id, productID: productID) else { return }
        } catch {
            DYMLogManager.logError("Transaction journal write failed; transaction retained")
            notifyVerificationPending(transaction); return
        }
        guard let receipt = lastReceipt else { deferVerification(transaction); return }
        if let skProduct = product(for: productID)?.skproduct {
            verifyPurchased(transaction, receipt: receipt, product: skProduct)
        } else {
            // Independent request: never cancel a paywall catalog request during queue recovery.
            let request = DYMRecoveryProductRequest(productID: productID) { [weak self] product in
                guard let self = self else { return }
                self.recoveryRequests.removeValue(forKey: id)
                guard let product = product else { self.deferVerification(transaction); return }
                let model = DYMProductModel(productId: productID); model.skproduct = product
                self.currentProducts.append(model)
                self.verifyPurchased(transaction, receipt: receipt, product: product)
            }
            recoveryRequests[id] = request
            request.start()
        }
    }

    private func verifyPurchased(_ transaction: SKPaymentTransaction, receipt: String, product: SKProduct) {
        DYMobileSDK.validateReceiptFirst(receipt, for: product) { response, error in
            DispatchQueue.main.async {
                guard error == nil, let response = response,
                      let id = transaction.transactionIdentifier,
                      let journal = DYMTransactionDelivery.journal else {
                    self.deferVerification(transaction); return
                }
                do { try journal.verified(id: id, response: response) }
                catch { self.deferVerification(transaction); return }
                let detail = DYMPurchaseDetail(productId: transaction.payment.productIdentifier,
                    quantity: transaction.payment.quantity, product: product, receipt: receipt, transaction: transaction)
                self.callBackPurchaseCompletion(for: self.purchaseTemplate(for: transaction), .success(detail), response)
                DYMTransactionDelivery.notifyAvailable()
                SKPaymentQueue.default().finishTransaction(transaction)
                self.retryCounts.removeValue(forKey: id)
            }
        }
    }

    private func notifyVerificationPending(_ transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: DYMTransactionDelivery.pendingNotification, object: nil,
            userInfo: ["productIdentifier": transaction.payment.productIdentifier, "reason": "verification_pending"])
    }

    private func deferVerification(_ transaction: SKPaymentTransaction) {
        guard let id = transaction.transactionIdentifier else { return }
        DYMTransactionDelivery.journal?.retry(id: id)
        notifyVerificationPending(transaction)
        let count = retryCounts[id, default: 0]
        guard count < 3 else { return } // Queue retains it for next activation/relaunch.
        retryCounts[id] = count + 1
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(5 * (count + 1))) { [weak self] in
            guard let self = self, SKPaymentQueue.default().transactions.contains(where: { $0.transactionIdentifier == id }) else { return }
            self.purchased(transaction)
        }
    }

    private func purchaseTemplate(for transaction: SKPaymentTransaction) -> PurchaseTemplate? {
        return purchaseTemplates.first {
            guard $0.payment == transaction.payment else { return false }
            // An old same-product purchase must never complete a new page operation.
            if let date = transaction.transactionDate { return date >= $0.createdAt }
            return transaction.transactionState == .failed
        }
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
        guard let id = transaction.transactionIdentifier, !id.isEmpty else { return }
        if restoredTransactions[id] == nil { restorePurchaseTimes += 1 }
        restoredTransactions[id] = transaction
        if !isRestoringManually || restoreBatchFinished { verifyRestoredTransactions() }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        restoreBatchFinished = true
        guard !restoredTransactions.isEmpty else {
            callBackRestoreCompletion(.failure(.noPurchased)); return
        }
        verifyRestoredTransactions()
    }

    private func verifyRestoredTransactions() {
        guard !restoringVerification, !restoredTransactions.isEmpty else { return }
        guard let journal = DYMTransactionDelivery.journal else {
            callBackRestoreCompletion(.failure(DYMError(code: .failed, message: "Transaction storage unavailable; transactions retained")))
            return
        }
        // Finish only individually verified restored transactions, never unrelated purchases.
        var cachedResponse: [String: Any]?
        for (id, transaction) in restoredTransactions where journal.response(id: id, productID: transaction.payment.productIdentifier) != nil {
            cachedResponse = journal.response(id: id, productID: transaction.payment.productIdentifier)
            DYMTransactionDelivery.notifyAvailable()
            SKPaymentQueue.default().finishTransaction(transaction)
            restoredTransactions.removeValue(forKey: id)
        }
        guard !restoredTransactions.isEmpty else {
            if isRestoringManually, let receipt = lastReceipt, let response = cachedResponse {
                callBackRestoreCompletion(.success(receipt), response)
            }
            return
        }
        guard let receipt = lastReceipt else { scheduleRestoreRetry(); return }
        let batch = restoredTransactions
        do {
            for (id, transaction) in batch { _ = try journal.begin(id: id, productID: transaction.payment.productIdentifier) }
        } catch { scheduleRestoreRetry(); return }
        restoringVerification = true
        DYMobileSDK.validateReceiptRecover(receipt) { response, error in
            DispatchQueue.main.async {
                self.restoringVerification = false
                guard error == nil, let response = response else {
                    for id in batch.keys { journal.retry(id: id) }
                    self.scheduleRestoreRetry(); return
                }
                do {
                    for (id, _) in batch { try journal.verified(id: id, response: response) }
                } catch {
                    for id in batch.keys { journal.retry(id: id) }
                    self.scheduleRestoreRetry(); return
                }
                DYMTransactionDelivery.notifyAvailable()
                for (id, transaction) in batch {
                    SKPaymentQueue.default().finishTransaction(transaction)
                    self.restoredTransactions.removeValue(forKey: id)
                }
                self.callBackRestoreCompletion(.success(receipt), response)
                if !self.restoredTransactions.isEmpty { self.verifyRestoredTransactions() }
            }
        }
    }

    private func scheduleRestoreRetry() {
        let key = "restore-batch"
        let count = retryCounts[key, default: 0]
        guard count < 3 else {
            callBackRestoreCompletion(.failure(DYMError(code: .failed, message: "Receipt verification pending; transactions retained")))
            return
        }
        retryCounts[key] = count + 1
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(5 * (count + 1))) { [weak self] in self?.verifyRestoredTransactions() }
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
