---
description: "Triển khai iCloud Sync — F1.9 CloudKit private database, offline-first, conflict resolution"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build: iCloud Sync (CloudKit)

## Feature Spec References
- F1.9: iCloud Sync

## Đọc Context Trước
1. `CLAUDE.md`
2. `FinanceApp-Feature-Specification.md` → F1.9
3. `docs/DATA-MODEL.md`
4. `docs/ARCHITECTURE.md`

## Tasks

### CloudKit Configuration
1. Enable CloudKit capability in both iOS and macOS targets
2. Create CloudKit container: `iCloud.com.vela.finance`
3. Configure `ModelContainer` with CloudKit:
   - `NSPersistentCloudKitContainer` integration with SwiftData
   - Private database (user's own data only)
   - Automatic schema migration to CloudKit

### Sync Infrastructure (Packages/FinanceData/Sources/FinanceData/CloudKit/)
4. `CloudKitSyncManager`:
   - Monitor sync status: synced, syncing, error, offline
   - Publish status via `@Observable` or Combine
   - Handle `NSPersistentCloudKitContainer` events
   - Manual sync trigger
5. `SyncStatus` enum:
   - synced — all data up to date
   - syncing — transfer in progress
   - offline — no network, working locally
   - error(SyncError) — sync failed
6. `SyncError` enum:
   - networkUnavailable, accountNotAvailable, quotaExceeded
   - conflictDetected, unknownError(Error)

### Conflict Resolution
7. `ConflictResolver`:
   - Default strategy: last-write-wins (by updatedAt timestamp)
   - Transaction merge: if same UUID modified on 2 devices, keep most recent
   - Account balance: recalculate from transactions (source of truth)
   - Category: last-write-wins
8. Handle `NSManagedObjectContext` merge notifications
9. Deduplicate on UUID (in case of create conflict)

### Offline-First
10. App works 100% offline — all data in local SwiftData
11. Queue changes locally when offline
12. Auto-sync when connectivity restored
13. No loading states that block UI (optimistic updates)

### Sync UI
14. `SyncStatusView` (FinanceUI component):
    - Icon: ✓ synced (green), ↻ syncing (blue, animated), ○ offline (gray), ⚠ error (red)
    - Tap → sync details sheet
15. `SyncDetailSheet`:
    - Last sync time
    - Items pending sync count
    - Manual "Sync Now" button
    - Error details + retry
16. Show sync status in:
    - iOS: Settings, optionally in toolbar
    - macOS: Toolbar or status bar

### Entitlements & Capabilities
17. iOS entitlements:
    - com.apple.developer.icloud-services: CloudKit
    - com.apple.developer.icloud-container-identifiers
18. macOS entitlements: same + App Sandbox
19. App Group for Widget data sharing:
    - group.com.vela.finance

### Tests
20. SyncStatus — state transitions correct
21. ConflictResolution — last-write-wins picks correct record
22. BalanceRecalculation — correct after conflict merge
23. OfflineMode — CRUD works without network
24. Deduplication — same UUID created on 2 devices → merged
25. Migration — CloudKit schema handles new fields gracefully
