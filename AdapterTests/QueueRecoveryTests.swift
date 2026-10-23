import XCTest
import StoreKit
@testable import DYMTransactionRecovery

/// Entirely offline: StoreKit is a SwiftPM fake module; initiating purchase/restore traps.
final class QueueRecoveryTests: XCTestCase {
    let response: [String: Any] = ["subscribledObject": [["platformProductId": "monthly", "originalTransactionId": "chain", "expiresAt": 1000]]]
    override func setUpWithError() throws {
        SKPaymentQueue.shared.transactions = []; SKPaymentQueue.shared.finished = []; SKPaymentQueue.shared.observerCount = 0
        SKProductsRequest.available = true; DYMobileSDK.calls = 0
        DYMTransactionDelivery.journal = try DYMTransactionJournal(load: { nil }, save: { _ in })
        DYMobileSDK.verify = { $0(self.response, nil) }
    }
    func transaction(_ id: String, _ state: SKPaymentTransactionState = .purchased) -> SKPaymentTransaction {
        let t = SKPaymentTransaction(); t.transactionIdentifier = id; t.transactionState = state
        SKPaymentQueue.shared.transactions.append(t); return t
    }
    func drain() { let done = expectation(description: "async callbacks"); DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { done.fulfill() }; wait(for: [done], timeout: 1) }
    func testOrphanedTransactionRecoversWithoutAnyPageTemplate() {
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" }); let t = transaction("orphan")
        manager.purchased(t); drain()
        XCTAssertEqual(SKPaymentQueue.shared.finished, ["orphan"])
        XCTAssertEqual(DYMTransactionDelivery.pendingDeliveries().count, 1)
        XCTAssertEqual(DYMobileSDK.calls, 1)
    }
    func testVerificationFailureNeverFinishes() {
        DYMobileSDK.verify = { $0(nil, DYMError.noReceipt) }
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" }); let t = transaction("offline")
        manager.purchased(t); drain()
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty)
        XCTAssertTrue(DYMTransactionDelivery.pendingDeliveries().isEmpty)
    }
    func testMissingReceiptOrMissingProductNeverFinishes() {
        let manager = DYMIAPManager(receiptReader: { nil }); manager.purchased(transaction("no-receipt")); drain()
        SKProductsRequest.available = false
        let other = DYMIAPManager(receiptReader: { "offline-receipt" }); other.purchased(transaction("no-product")); drain()
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty); XCTAssertEqual(DYMobileSDK.calls, 0)
    }
    func testDuplicateQueueCallbacksCoalesceVerification() {
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" }); let t = transaction("duplicate")
        manager.purchased(t); manager.purchased(t); drain()
        XCTAssertEqual(DYMobileSDK.calls, 1); XCTAssertEqual(SKPaymentQueue.shared.finished, ["duplicate"])
    }
    func testPersistedVerificationFinishesWithoutRevenueReverification() throws {
        let journal = DYMTransactionDelivery.journal!; _ = try journal.begin(id: "persisted", productID: "monthly")
        try journal.verified(id: "persisted", response: response)
        let manager = DYMIAPManager(receiptReader: { nil }); manager.purchased(transaction("persisted")); drain()
        XCTAssertEqual(SKPaymentQueue.shared.finished, ["persisted"]); XCTAssertEqual(DYMobileSDK.calls, 0)
    }
    func testDeferredStateIsNonterminalAndNotCancellation() {
        let manager = DYMIAPManager(); let t = transaction("deferred", .deferred)
        let notice = expectation(forNotification: DYMTransactionDelivery.pendingNotification, object: nil)
        manager.paymentQueue(SKPaymentQueue.shared, updatedTransactions: [t]); wait(for: [notice], timeout: 1)
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty); XCTAssertEqual(DYMobileSDK.calls, 0)
    }
    func testReconciliationNeverBlindlyFinishesOtherTransactions() {
        let manager = DYMIAPManager(receiptReader: { nil }); _ = transaction("pending"); _ = transaction("deferred", .deferred)
        manager.finishTransactionInSKPaymentQueue(); drain()
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty)
    }
    func testDiskFailureAfterServerResponseKeepsQueueTransaction() throws {
        var writes = 0
        DYMTransactionDelivery.journal = try DYMTransactionJournal(load: { nil }, save: { _ in
            writes += 1; if writes > 1 { throw DYMError.noReceipt }
        })
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" }); manager.purchased(transaction("disk-error")); drain()
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty)
    }
    func testRestoredStateCannotFinishOnVerificationError() {
        DYMobileSDK.verify = { $0(nil, DYMError.noReceipt) }
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" }); manager.restored(transaction("restored", .restored)); drain()
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty)
    }
    func testRestoredStateOnlyFinishesVerifiedBatch() {
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" }); _ = transaction("unrelated-purchase")
        manager.restored(transaction("restored", .restored)); drain()
        XCTAssertEqual(SKPaymentQueue.shared.finished, ["restored"])
        XCTAssertEqual(SKPaymentQueue.shared.transactions.map { $0.transactionIdentifier! }, ["unrelated-purchase"])
    }
    func testInitialStorageFailureEmitsPendingAndKeepsTransaction() throws {
        DYMTransactionDelivery.journal = try DYMTransactionJournal(load: { nil }, save: { _ in throw DYMError.noReceipt })
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" })
        let t = transaction("initial-disk-error")
        let notice = expectation(forNotification: DYMTransactionDelivery.pendingNotification, object: nil)
        manager.purchased(t); wait(for: [notice], timeout: 1)
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty); XCTAssertEqual(DYMobileSDK.calls, 0)
    }
    func testUnavailableJournalEmitsPendingAndKeepsTransaction() {
        DYMTransactionDelivery.journal = nil
        let manager = DYMIAPManager(receiptReader: { "offline-receipt" })
        let t = transaction("unavailable-disk")
        let notice = expectation(forNotification: DYMTransactionDelivery.pendingNotification, object: nil)
        manager.purchased(t); wait(for: [notice], timeout: 1)
        XCTAssertTrue(SKPaymentQueue.shared.finished.isEmpty); XCTAssertEqual(DYMobileSDK.calls, 0)
    }

}
