import XCTest
@testable import DYMTransactionRecovery

final class TransactionJournalTests: XCTestCase {
    final class Disk {
        var data: Data?
        var failing = false
        func journal() throws -> DYMTransactionJournal {
            try DYMTransactionJournal(load: { self.data }, save: {
                if self.failing { throw NSError(domain: "disk", code: 1) }
                self.data = $0
            })
        }
    }
    let response: [String: Any] = ["subscribledObject": [["platformProductId": "monthly", "expiresAt": 1000, "originalTransactionId": "chain"]]]

    func testNetworkErrorRemainsRetryableAfterRelaunch() throws {
        let disk = Disk(); let j = try disk.journal()
        XCTAssertTrue(try j.begin(id: "tx1", productID: "monthly"))
        j.retry(id: "tx1")
        XCTAssertNil(j.response(id: "tx1", productID: "monthly"))
        XCTAssertTrue(try disk.journal().begin(id: "tx1", productID: "monthly"))
    }
    func testDuplicateDeliveryDoesNotReverifyOrCrossProduct() throws {
        let j = try Disk().journal()
        XCTAssertTrue(try j.begin(id: "tx1", productID: "monthly"))
        XCTAssertFalse(try j.begin(id: "tx1", productID: "monthly"))
        try j.verified(id: "tx1", response: response)
        XCTAssertFalse(try j.begin(id: "tx1", productID: "monthly"))
        XCTAssertNil(j.response(id: "tx1", productID: "annual"))
        XCTAssertTrue(try j.begin(id: "tx2", productID: "monthly")) // Renewal has a distinct ID.
    }
    func testDiskFailureCannotAuthorizeFinish() throws {
        let disk = Disk(); let j = try disk.journal()
        _ = try j.begin(id: "tx1", productID: "monthly")
        disk.failing = true
        XCTAssertThrowsError(try j.verified(id: "tx1", response: response))
        XCTAssertNil(j.response(id: "tx1", productID: "monthly"))
        disk.failing = false; j.retry(id: "tx1")
        XCTAssertTrue(try j.begin(id: "tx1", productID: "monthly"))
    }
    func testCrashBetweenVerificationAndHostDeliveryReplaysInbox() throws {
        let disk = Disk(); let j = try disk.journal()
        _ = try j.begin(id: "tx1", productID: "monthly")
        try j.verified(id: "tx1", response: response)
        let recovered = try disk.journal()
        XCTAssertEqual(recovered.pendingDeliveries().count, 1)
        XCTAssertNotNil(recovered.response(id: "tx1", productID: "monthly"))
        try recovered.acknowledge(id: "tx1")
        XCTAssertTrue(try disk.journal().pendingDeliveries().isEmpty)
        XCTAssertNotNil(try disk.journal().response(id: "tx1", productID: "monthly"))
    }
    func testMissingOrWrongEntitlementNeverConfirms() throws {
        let j = try Disk().journal(); _ = try j.begin(id: "tx1", productID: "monthly")
        XCTAssertThrowsError(try j.verified(id: "tx1", response: [:]))
        XCTAssertThrowsError(try j.verified(id: "tx1", response: ["subscribledObject": [["platformProductId": "other"]]]))
        XCTAssertNil(j.response(id: "tx1", productID: "monthly"))
    }
    func testCorruptLedgerFailsClosedAndIsNotOverwritten() throws {
        let disk = Disk(); disk.data = Data("broken".utf8)
        XCTAssertThrowsError(try disk.journal())
        XCTAssertEqual(disk.data, Data("broken".utf8))
    }
    func testPendingAndEmptyIdentityNeverBecomeDelivery() throws {
        let j = try Disk().journal()
        XCTAssertFalse(try j.begin(id: "", productID: "monthly"))
        _ = try j.begin(id: "tx1", productID: "monthly")
        XCTAssertTrue(j.pendingDeliveries().isEmpty)
        try j.acknowledge(id: "tx1")
        XCTAssertNil(j.response(id: "tx1", productID: "monthly"))
    }
    func testAtomicFileRoundTripPreservesFieldTypes() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("journal.json")
        let j = try DYMTransactionJournal(url: url)
        _ = try j.begin(id: "tx1", productID: "monthly"); try j.verified(id: "tx1", response: response)
        let rows = try DYMTransactionJournal(url: url).pendingDeliveries()[0]["subscribledObject"] as! [[String: Any]]
        XCTAssertEqual(rows[0]["expiresAt"] as? Int, 1000)
        XCTAssertNil(rows[0]["expiresAt"] as? String)
    }
}
