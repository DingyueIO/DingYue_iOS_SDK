import Foundation
import StoreKit
public final class DYMProductModel: NSObject {
    let vendorIdentifier: String
    var skproduct: SKProduct?
    init(productId: String) { vendorIdentifier = productId }
}
public struct DYMError: Error {
    public enum Code { case failed }
    public init(_ error: Error) {}
    public init(code: Code, message: String) {}
    public static let noProductIds = DYMError(code: .failed, message: "no IDs")
    public static let noProducts = DYMError.noProductIds
    public static let unablePayment = DYMError.noProductIds
    public static let noReceipt = DYMError.noProductIds
    public static let noPurchased = DYMError.noProductIds
    public static let purchaseFailed = DYMError.noProductIds
}
public struct DYMPurchaseDetail {
    public init(productId: String, quantity: Int, product: SKProduct, receipt: String, transaction: SKPaymentTransaction) {}
}
public enum DYMPurchaseResult { case succeed(DYMPurchaseDetail), failure(DYMError) }
enum DYMLogManager { static func logMessage(_ value: Any) {}; static func logError(_ value: Any) {} }
enum UserProperties { static let requestUUID = "offline" }
final class DYMDefaultsManager { static let shared = DYMDefaultsManager(); var cachedPaywallPageIdentifier: String? }
final class DYMEventManager {
    static let shared = DYMEventManager()
    func track(event: String, extra: String? = nil, user: String? = nil) {}
}
enum DYMobileSDK {
    typealias Completion = ([String: Any]?, Error?) -> Void
    static var calls = 0
    static var verify: (Completion) -> Void = { $0(nil, DYMError.noReceipt) }
    static func validateReceiptFirst(_ receipt: String, for product: SKProduct?, completion: @escaping Completion) { calls += 1; verify(completion) }
    static func validateReceiptRecover(_ receipt: String, completion: @escaping Completion) { calls += 1; verify(completion) }
    static func track(event: String, extra: String? = nil, user: String? = nil) {}
}
