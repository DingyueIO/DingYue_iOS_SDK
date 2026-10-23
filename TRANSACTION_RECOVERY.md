# StoreKit 1 transaction recovery

This change applies to the `DYMIAPManager` StoreKit 1 path. It does not change or validate the StoreKit 2 implementation, and does not represent an official CocoaPods version release.

A purchased/restored transaction is finished only after server verification and durable journal/inbox storage. Verification failures remain in the Apple queue for bounded retry and foreground/relaunch recovery. Purchases no longer finish unrelated queued transactions. Deferred transactions report a nonterminal pending state. Recovery uses a separate product request and does not require the paywall controller to remain alive.

The host should observe `DYMTransactionDelivery.availableNotification` and drain `pendingDeliveries()` on startup. Persist the verified entitlement and handled transaction identifier before calling `acknowledge(transactionIdentifier:)`. Do not send purchase revenue again while consuming the inbox. `pendingNotification` is not a purchase failure or cancellation.

## Verification

`swift test` compiles the production StoreKit 1 manager and journal against offline adapters. The root `Package.swift` is a regression harness, **not** a Swift Package distribution of the iOS SDK. Fake UIKit/StoreKit modules exist only under `RecoveryStubs`; the CocoaPods `source_files` pattern excludes all test adapters.

The tests cover verification failure, persistence failure, restart delivery, duplicate callbacks, orphan recovery, deferred callbacks, transaction identity, and restore batch isolation. Fake purchase/restore initiation traps rather than contacting Apple. These tests do not prove Apple sandbox payment, subscription lifecycle, or external revenue attribution. iOS host builds and nonpurchase remote-paywall/session/event tests provide separate integration evidence.

Keep the existing SDK transaction owner. Do not add a second StoreKit observer or app-side purchase implementation to compensate for SDK behavior.
