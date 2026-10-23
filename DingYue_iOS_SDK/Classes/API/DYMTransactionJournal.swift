import Foundation

/// Durable delivery inbox. The StoreKit queue remains the source of pending transactions.
/// A failed disk write must never authorize finishTransaction. All calls are serialized
/// by the SDK on the main queue; the lock also protects public inbox reads/acknowledgments.
final class DYMTransactionJournal {
    struct Entry: Codable {
        let id: String
        let productID: String
        var response: Data?
        var acknowledged: Bool
    }
    private var entries: [String: Entry]
    private var inFlight = Set<String>()
    private let save: (Data) throws -> Void
    private let lock = NSRecursiveLock()

    init(load: () throws -> Data?, save: @escaping (Data) throws -> Void) throws {
        self.save = save
        if let data = try load() {
            entries = try JSONDecoder().decode([String: Entry].self, from: data)
        } else { entries = [:] }
    }

    convenience init(url: URL) throws {
        try self.init(load: {
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return try Data(contentsOf: url)
        }, save: { data in
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try data.write(to: url, options: .atomic)
        })
    }

    private func commit(_ updated: [String: Entry]) throws {
        try save(JSONEncoder().encode(updated))
        entries = updated
    }

    /// Duplicate callbacks are coalesced. A verified record needs delivery/finish only.
    func begin(id: String, productID: String) throws -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !id.isEmpty, !productID.isEmpty else { return false }
        if let entry = entries[id], entry.productID != productID { return false }
        guard entries[id]?.response == nil, !inFlight.contains(id) else { return false }
        if entries[id] == nil {
            var updated = entries
            updated[id] = Entry(id: id, productID: productID, response: nil, acknowledged: false)
            try commit(updated)
        }
        inFlight.insert(id)
        return true
    }

    func retry(id: String) {
        lock.lock(); defer { lock.unlock() }
        inFlight.remove(id)
    }

    /// Persist only verified entitlement rows, not receipts, credentials or enum objects.
    func verified(id: String, response: [String: Any]) throws {
        lock.lock(); defer { lock.unlock() }
        guard var entry = entries[id], inFlight.contains(id),
              let rows = response["subscribledObject"] as? [[String: Any]],
              rows.contains(where: { $0["platformProductId"] as? String == entry.productID }) else {
            throw NSError(domain: "DYMTransactionJournal", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing matching verified entitlement"])
        }
        entry.response = try JSONSerialization.data(withJSONObject: ["subscribledObject": rows])
        var updated = entries; updated[id] = entry
        try commit(updated)
        inFlight.remove(id)
    }

    func response(id: String, productID: String) -> [String: Any]? {
        lock.lock(); defer { lock.unlock() }
        guard let entry = entries[id], entry.productID == productID, let data = entry.response else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    func pendingDeliveries() -> [[String: Any]] {
        lock.lock(); defer { lock.unlock() }
        return entries.values.filter { !$0.acknowledged && $0.response != nil }.sorted { $0.id < $1.id }.compactMap { entry in
            guard let data = entry.response,
                  var result = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
            result["transactionIdentifier"] = entry.id
            result["productIdentifier"] = entry.productID
            return result
        }
    }

    func acknowledge(id: String) throws {
        lock.lock(); defer { lock.unlock() }
        guard var entry = entries[id], entry.response != nil else { return }
        entry.acknowledged = true
        var updated = entries; updated[id] = entry
        try commit(updated)
    }
}
