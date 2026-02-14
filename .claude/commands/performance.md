---
description: "Performance audit checklist — targets, profiling, optimization for app launch, scroll, memory, SwiftData, network, battery"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Performance Audit

## Đọc Context Trước
1. `CLAUDE.md`
2. `docs/ARCHITECTURE.md`
3. `docs/DESIGN-SYSTEM.md`

## Performance Targets Reference

| Metric | Target |
|--------|--------|
| App launch (cold) | < 1 second |
| App launch (warm) | < 0.5 second |
| Transaction input → save | < 100ms |
| Receipt scan → result | < 3 seconds |
| AI categorization | < 50ms |
| Search 10K transactions | < 200ms |
| Sync conflict resolution | < 500ms |
| Exchange rate API response | < 2 seconds |
| App size (binary) | < 50MB |
| Memory (typical usage) | < 100MB |
| Memory (peak) | < 200MB |
| Transaction list scroll | 60fps smooth |

---

## Audit Checklist

### 1. App Launch Performance
- [ ] Cold launch < 1 second (measured from process start to first frame)
- [ ] Warm launch < 0.5 second (measured from foreground to interactive)
- [ ] No synchronous work on main thread during launch
- [ ] Lazy initialization of non-critical services (AI models, sync engine)
- [ ] Pre-main time optimized (minimize static initializers, reduce dylib count)
- [ ] `os_signpost` markers placed at launch milestones
- [ ] SwiftData container setup is async or background
- [ ] No network requests blocking launch

**Pass criteria:** Instruments Time Profiler shows launch < 1s on oldest supported device (iPhone 15 / M1 Mac).

### 2. Transaction List Scroll Performance
- [ ] `LazyVStack` (NOT `VStack`) for all transaction lists
- [ ] No heavy computation in `body` property of list row views
- [ ] Category icons preloaded / cached (SF Symbols are fine, custom images need cache)
- [ ] Amount formatting cached or computed once (not on every scroll frame)
- [ ] Date formatters created once and reused (NOT created per-row)
- [ ] No `.task` or `.onAppear` triggers per-row that cause layout thrash
- [ ] Smooth scroll with 10,000+ transactions loaded
- [ ] No dropped frames visible in Instruments Core Animation tool

**Pass criteria:** 60fps sustained scroll with 10,000 transactions, 0 hitches > 8ms.

### 3. Memory Management
- [ ] Typical usage (dashboard + transaction list) < 100MB
- [ ] Peak usage (receipt scan + AI processing) < 200MB
- [ ] No memory leaks in ViewModel → View binding cycle
- [ ] `@Observable` ViewModels do not retain Views
- [ ] Core ML models loaded on-demand and released when not in use
- [ ] Receipt images downsampled for display (full resolution only for OCR)
- [ ] Transaction list uses pagination / windowed loading for large datasets
- [ ] CloudKit sync buffers cleaned after sync completion
- [ ] No retain cycles in async closures (use `[weak self]` where needed)

**Pass criteria:** Instruments Allocations shows no persistent growth after repeated navigation cycles.

### 4. SwiftData Query Optimization
- [ ] All frequently queried properties have `@Attribute(.spotlight)` or indexed
- [ ] `Transaction.date` is indexed for date-range queries
- [ ] `Transaction.category` is indexed for category filtering
- [ ] `Transaction.account` is indexed for account filtering
- [ ] `#Predicate` used instead of in-memory filtering
- [ ] Batch fetch with `fetchLimit` for paginated lists
- [ ] `FetchDescriptor.propertiesToFetch` used to avoid loading full objects when only summary needed
- [ ] No N+1 query patterns (e.g., loading category for each transaction separately)
- [ ] Background context used for import/export operations
- [ ] Search 10,000 transactions returns results < 200ms

**Pass criteria:** SwiftData Instruments shows no query > 200ms for standard operations.

### 5. SwiftUI View Performance
- [ ] `@Observable` used correctly — only observed properties trigger re-render
- [ ] No `AnyView` type erasure in lists (kills diffing performance)
- [ ] `EquatableView` or custom `Equatable` conformance for complex list rows
- [ ] `.id()` modifier not used with changing values on large collections
- [ ] Chart views use `drawingGroup()` for complex renders
- [ ] Conditional views use `if/else` not `opacity(0)` to avoid layout cost
- [ ] Preview data uses lightweight mocks, not real database
- [ ] `@State` and `@Binding` scoped to smallest necessary view
- [ ] No unnecessary `@Environment` reads in frequently re-rendered views
- [ ] Dashboard cards do not all re-render when one value changes

**Pass criteria:** Instruments SwiftUI profiler shows no view body called > 1000 times/second.

### 6. Image & Receipt Caching
- [ ] Receipt thumbnails cached at display resolution (not full resolution)
- [ ] Full-resolution receipts loaded on-demand (detail view only)
- [ ] Image cache has memory limit (50MB max)
- [ ] Image cache evicts on memory pressure (`didReceiveMemoryWarning`)
- [ ] Receipt images stored as files (not inline in SwiftData)
- [ ] Image file paths stored in SwiftData, not raw `Data`
- [ ] Thumbnail generation happens on background thread
- [ ] Category icon images (if custom) cached in `NSCache`
- [ ] No duplicate image data in memory

**Pass criteria:** Memory stays < 100MB after viewing 50+ receipts.

### 7. Network Performance
- [ ] Exchange rate API response handled within 2 seconds
- [ ] Exchange rate cached locally (daily for free, more frequent for premium)
- [ ] Network requests use `URLSession` with proper timeout (15s)
- [ ] Retry logic with exponential backoff for failed requests
- [ ] CloudKit sync uses `CKFetchRecordZoneChangesOperation` (incremental, not full fetch)
- [ ] Cloud AI requests (premium) have loading states and timeouts (10s)
- [ ] No redundant API calls (debounce search, cache rates)
- [ ] Background URLSession for large sync operations
- [ ] Network reachability check before triggering sync

**Pass criteria:** App remains responsive (no UI freeze) during all network operations.

### 8. Battery Optimization
- [ ] Background sync uses `BGAppRefreshTaskRequest` with appropriate intervals
- [ ] No continuous polling (use push notifications / CloudKit subscriptions)
- [ ] Location services used only when user explicitly adds location to transaction
- [ ] Core ML inference batched when possible (not per-keystroke)
- [ ] Widget timeline updates at reasonable intervals (not every minute)
- [ ] No unnecessary `Timer` running when app is in background
- [ ] Energy Impact in Xcode Organizer shows "Low" for typical usage
- [ ] Reduce Motion setting disables animations (saves GPU energy)

**Pass criteria:** Energy Impact rated "Low" in Xcode Organizer for 10-minute typical session.

### 9. Large Dataset Stress Test (10,000+ Transactions)
- [ ] App launches normally with 10,000 transactions in database
- [ ] Dashboard loads and displays within 1 second
- [ ] Transaction list scrolls smoothly at 60fps
- [ ] Search returns results within 200ms
- [ ] Category breakdown report generates within 500ms
- [ ] Export to CSV completes within 5 seconds
- [ ] CloudKit sync handles 10K records without timeout
- [ ] Memory stays under 200MB during bulk operations
- [ ] No UI freeze during background data processing

**Pass criteria:** All above metrics met with 10,000 transactions + 500 receipts in database.

### 10. Instruments Profiling Guide
- [ ] **Time Profiler**: Run on cold launch, identify top 5 heaviest call stacks
- [ ] **Allocations**: Check for leaks and persistent growth after 5 navigation cycles
- [ ] **Core Data / SwiftData**: Verify no queries > 200ms, check fetch counts
- [ ] **Core Animation**: Confirm 60fps scroll, identify offscreen renders
- [ ] **Network**: Verify no unnecessary requests, check payload sizes
- [ ] **Energy Log**: Confirm low energy impact during typical usage
- [ ] **Metal System Trace**: Check GPU usage for chart rendering
- [ ] Profile on OLDEST supported device (not just latest hardware)
- [ ] Profile with Release build configuration (not Debug)

**Pass criteria:** No critical issues (P0) found in any Instruments trace.

### 11. Widget Refresh Performance
- [ ] Widget timeline generation < 500ms
- [ ] Widget data read from shared App Group container (not main app database)
- [ ] Widget does not trigger full app launch for data refresh
- [ ] Small widget memory budget < 30MB
- [ ] Medium/Large widget memory budget < 50MB
- [ ] Widget timeline entries pre-computed for next 24 hours
- [ ] Widget uses `IntentTimelineProvider` for configurable widgets efficiently

**Pass criteria:** Widget appears within 1 second of home screen display, no blank states.

---

## Actions
For each failed check:
1. Create a performance fix task with priority (P0 = blocks release, P1 = should fix, P2 = nice to have)
2. Profile with Instruments to identify root cause
3. Implement fix
4. Re-measure and verify improvement
5. Add regression test if applicable

## Output
Generate a performance report:
- Pass count / Total checks
- **P0 Critical** (blocks release): launch > 2s, scroll < 30fps, crash on 10K data
- **P1 Important** (should fix before release): targets missed by < 50%
- **P2 Nice to have** (post-release): minor optimizations
- Device tested + build configuration
- Instruments traces attached (screenshots or .trace files)
