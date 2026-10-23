import Foundation
import StoreKit

/// Verified transaction inbox. Observe availableNotification and drain on application startup.
/// Acknowledge only after the host has persisted its entitlement update. No revenue is replayed.
public enum DYMTransactionDelivery {
    public static let availableNotification = Notification.Name("DYMVerifiedTransactionAvailable")
    public static let pendingNotification = Notification.Name("DYMTransactionPending")
    static var journal: DYMTransactionJournal? {
        get { return storage }
        set { storage = newValue }
    }
    private static var storage: DYMTransactionJournal? = {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = directory.appendingPathComponent("DingYue/verified-transactions-v1.json")
        do { return try DYMTransactionJournal(url: url) }
        catch { DYMLogManager.logError("Cannot read transaction journal; transactions will be retained"); return nil }
    }()
    public static func pendingDeliveries() -> [[String: Any]] { return journal?.pendingDeliveries() ?? [] }
    @discardableResult public static func acknowledge(transactionIdentifier: String) -> Bool {
        guard let journal = journal else { return false }
        do { try journal.acknowledge(id: transactionIdentifier); return true }
        catch { return false }
    }
    static func notifyAvailable() {
        NotificationCenter.default.post(name: availableNotification, object: nil)
    }
}

/// This request is retained separately from the mutable paywall product loader.
final class DYMRecoveryProductRequest: NSObject, SKProductsRequestDelegate {
    private let productID: String
    private let completion: (SKProduct?) -> Void
    private var request: SKProductsRequest?
    private var completed = false
    init(productID: String, completion: @escaping (SKProduct?) -> Void) {
        self.productID = productID; self.completion = completion
    }
    func start() {
        let request = SKProductsRequest(productIdentifiers: [productID])
        self.request = request; request.delegate = self; request.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in self?.finish(nil) }
    }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async { self.finish(response.products.first { $0.productIdentifier == self.productID }) }
    }
    func request(_ request: SKRequest, didFailWithError error: Error) { DispatchQueue.main.async { self.finish(nil) } }
    private func finish(_ product: SKProduct?) {
        guard !completed else { return }; completed = true
        request?.cancel(); request?.delegate = nil; request = nil
        completion(product)
    }
}
