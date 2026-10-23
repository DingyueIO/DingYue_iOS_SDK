import Foundation
public enum SKPaymentTransactionState: Int { case purchasing, purchased, failed, restored, deferred }
public struct SKError: Error { public enum Code: Int { case unknown }; public static let unknown = Code.unknown; public var errorCode: Int = 0 }
public class SKProduct: NSObject {
    public var productIdentifier = "monthly"
    public var localizedTitle = "Offline product"
    public var price = NSDecimalNumber(value: 1)
}
public class SKPayment: NSObject {
    public let productIdentifier: String
    public var quantity = 1
    public init(product: SKProduct) { productIdentifier = product.productIdentifier }
}
public class SKMutablePayment: SKPayment { public var applicationUsername: String? }
public class SKPaymentTransaction: NSObject {
    public var transactionIdentifier: String?
    public var transactionDate: Date? = Date()
    public var transactionState = SKPaymentTransactionState.purchased
    public var payment = SKPayment(product: SKProduct())
    public var error: Error?
}
public protocol SKPaymentTransactionObserver: AnyObject {}
public final class SKPaymentQueue {
    public static let shared = SKPaymentQueue()
    public static func `default`() -> SKPaymentQueue { shared }
    public var transactions: [SKPaymentTransaction] = []
    public var finished: [String] = []
    public var observerCount = 0
    public static func canMakePayments() -> Bool { false }
    public func add(_ observer: SKPaymentTransactionObserver) { observerCount += 1 }
    public func remove(_ observer: SKPaymentTransactionObserver) { observerCount -= 1 }
    public func add(_ payment: SKPayment) { fatalError("Offline tests must not initiate payment") }
    public func restoreCompletedTransactions() { fatalError("Offline tests must not initiate restore") }
    public func finishTransaction(_ t: SKPaymentTransaction) {
        finished.append(t.transactionIdentifier ?? "nil"); transactions.removeAll { $0 === t }
    }
}
public protocol SKRequestDelegate: AnyObject { func request(_ request: SKRequest, didFailWithError error: Error) }
public protocol SKProductsRequestDelegate: SKRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)
}
public class SKRequest: NSObject { public func cancel() {} }
public class SKProductsResponse { public let products: [SKProduct]; public init(_ products: [SKProduct]) { self.products = products } }
public final class SKProductsRequest: SKRequest {
    public static var available = true
    public let identifiers: Set<String>
    public weak var delegate: SKProductsRequestDelegate?
    public init(productIdentifiers: Set<String>) { identifiers = productIdentifiers }
    public func start() {
        let products = Self.available ? identifiers.map { id -> SKProduct in let p = SKProduct(); p.productIdentifier = id; return p } : []
        delegate?.productsRequest(self, didReceive: SKProductsResponse(products))
    }
}
