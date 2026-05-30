---
name: dzenn
description: >-
  Use when building or debugging features in Dzenn (macOS menu bar focus app)
  — tracking, analytics, SwiftUI components, timer services, browser activity
  resolution, or menu bar controllers. Covers folder structure, naming
  conventions, dependency injection, generation tracking, and code patterns
  based on SimplyTrack architecture.
license: MIT
---

# Dzenn SwiftUI Feature Development

Guide for building features in Dzenn — native macOS menu bar app (Swift + SwiftUI). Based on SimplyTrack architecture patterns.

**Tradeoff:** Prioritizes testability and separation of concerns over quick hacks.

## 1. Stack & Tools

Swift 5.9+, SwiftUI, AppKit, Combine, Foundation, CoreGraphics (idle detection), AVFoundation, UserNotifications. Target: SwiftData migration.

## 2. Folder Structure

```
dzenn/
  dzennApp.swift              # @main, @NSApplicationDelegateAdaptor
  Managers/                   # Singletons: system resources (Database, Permissions)
  Models/                     # Codable structs: records, events, enums
  Services/                   # Business logic: tracking, analytics, timers
    Browsers/                 # BrowserInterface implementations
  UI/                         # SwiftUI views (Main/MenuBar/Floating/Components)
  Utils/                      # Constants, helpers, extensions
```

**Rule:** Managers = system resources. Services = business logic. Views = pure UI. Utils = static helpers. Never mix layers.

## 3. Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Classes | PascalCase + role | `TrackingService`, `DatabaseManager` |
| Structs | PascalCase, noun | `FocusSessionRecord`, `AppActivityEvent` |
| Bool properties | is/has/can/show | `isTracking`, `hasPermission` |
| Methods | camelCase, verb-first | `startTracking()`, `queueSession()` |
| Constants | nested enum static let | `AppConstants.AnalyticsSettings.pollingInterval` |

**No UPPER_SNAKE_CASE. No abbreviations in public API.**

## 4. Feature Flow

1. Model in `Models/` → verify: `Codable`, `Identifiable`, computed properties
2. Service in `Services/` with `@MainActor` → verify: `init()` receives dependencies
3. Manager in `Managers/` if system resource → verify: `static let shared` + `private init()`
4. View in `UI/` → verify: `@State`/`@EnvironmentObject`, no direct singleton access
5. Wire in `AppDelegate.applicationDidFinishLaunching` → verify: dependency order
6. Test: build + run → verify: no MainActor violations, no singleton coupling

## 5. Code Patterns

### Singleton (Managers only)
❌ `class TrackingService { static let shared = TrackingService() }`
✅ `class DatabaseManager { static let shared = DatabaseManager(); private init() {} }`

### Dependency Injection (Services)
❌ `AnalyticsStore.shared.updateFocusSession(...)` inside service
✅ `init(analyticsStore: AnalyticsStore) { self.analyticsStore = analyticsStore }`

### @MainActor for UI/Tracking
❌ `class TrackingService { ... }`
✅ `@MainActor class TrackingService { ... }`

### Background DB/IO Work
❌ `let data = try modelContext.fetch(descriptor)` on main thread
✅ `await Task.detached { let ctx = ModelContext(container); ctx.autosaveEnabled = false; return try ctx.fetch(descriptor) }.value`

### Pure Functions
❌ `func aggregateSessions(_ s: [UsageSession])` inside @MainActor class
✅ `nonisolated static func aggregateSessions(_ s: [UsageSession]) -> [...]`

### Structured Logging
❌ `print("[Tracker] Started")`
✅ `let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Tracking"); logger.info("Starting")`

### Batch Persistence
❌ Save on every session end
✅ `queueSession()` → append → `performAtomicSave()` every 30s → single transaction

### Hybrid App Detection
❌ Polling only (misses fast switches)
✅ `NSWorkspace.didActivateApplicationNotification` observer + 1s polling fallback

### Generation Tracking
❌ Start Task, ignore stale results
✅ `generation += 1; let gen = generation; Task { ...; guard gen == self.generation else { return } }`

### Grace Period
❌ End session on single failure
✅ Track `consecutiveFailures`, end after `failureThreshold` OR `graceInterval`

### Error Enums
❌ `print("Error: \(error)")`
✅ `enum DzennError: LocalizedError { case fileIOError; var errorDescription: String? { ... } }`

## 6. Anti-Patterns

❌ Services accessing singletons directly
❌ `print()` instead of `Logger`
❌ Blocking main thread with I/O
❌ Mixing UI logic with business logic
❌ No error types (raw strings)
❌ Per-event saves (no batching)
❌ No generation tracking for async ops

## 7. Success Criteria

- [ ] Services use constructor DI (no `Shared.instance` inside)
- [ ] UI/tracking classes marked `@MainActor`
- [ ] Background work uses `Task.detached` with separate context
- [ ] Pure functions are `nonisolated static`
- [ ] Logging uses `Logger(subsystem:category:)`
- [ ] Persistence uses batch queue, not per-event saves
- [ ] Async polling has generation tracking + grace period
- [ ] Error enums conform to `LocalizedError`
- [ ] `swift-format` passes with zero violations
