# ANALYTIC.md — SimplyTrack Approach Reference

## For AI Agent: Pomodoro App Analytics System

Reference document for migrating SimplyTrack's app/website tracking approach into a Pomodoro app.

---

## 1. Architecture Overview

SimplyTrack uses **polling + notification hybrid** approach:

```
NSWorkspace.didActivateApplicationNotification (event trigger)
    +
1-second polling timer (fallback, ensures no gaps)
    │
    ▼
TrackingService (orchestrator, @MainActor)
    ├─► updateCurrentActivity() [every 1s]
    │       ├─► get frontmost app via NSWorkspace.shared.frontmostApplication
    │       ├─► check floating overlay via WindowDetectionService
    │       ├─► extract + cache app icon
    │       ├─► updateAppSession() (create/update/end)
    │       └─► scheduleWebsitePoll() async
    │
    ├─► SessionPersistenceService [every 30s batch save]
    │       ├─► queue session + icon
    │       └─► atomic save on background context (Task.detached)
    │
    └─► SwiftData (UsageSession + Icon)
            │
            ▼
        ContentView (aggregate & display)
            ├─► computeWorkPeriods() — merge overlapping sessions
            ├─► aggregateAppSessions() — group by identifier, sum duration
            └─► aggregateWebsiteSessions() — same for domains
```

### Key files (SimplyTrack):

| File | Role |
|---|---|
| `SimplyTrack/Services/TrackingService.swift` | Core orchestrator: 1s polling, app/website session lifecycle |
| `SimplyTrack/Services/WebTrackingService.swift` | Browser AppleScript execution, favicon fetch |
| `SimplyTrack/Services/SessionPersistenceService.swift` | Batch queue, atomic SwiftData save |
| `SimplyTrack/Services/WindowDetectionService.swift` | CGWindow floating overlay detection |
| `SimplyTrack/Managers/PermissionManager.swift` | Permission status tracking + UI feedback |
| `SimplyTrack/Services/Browsers/BrowserInterface.swift` | Protocol + BaseBrowser (AppleScript engine) |
| `SimplyTrack/Services/Browsers/ChromeBrowser.swift` | Chrome impl example |
| `SimplyTrack/Services/Browsers/SafariBrowser.swift` | Safari impl example |
| `SimplyTrack/Views/ContentView.swift` | Fetch DB, aggregate, pass to UI views |
| `SimplyTrack/Models/UsageSession.swift` | Core data model (app + website) |
| `SimplyTrack/Models/Icon.swift` | Icon cache model |
| `SimplyTrack/Utils/IconUtils.swift` | NSImage → PNG conversion |

---

## 2. Data Models (SwiftData)

### 2.1 UsageSession (`SimplyTrack/Models/UsageSession.swift`)

```swift
@Model
class UsageSession {
    @Attribute(.unique) var id: UUID = UUID()
    var type: String          // "app" or "website"
    var identifier: String    // bundle ID for apps, domain for websites
    var name: String          // human-readable name
    var startTime: Date
    var endTime: Date?        // nil = still active/in-progress

    var duration: TimeInterval {  // computed
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    func endSession(at endTime: Date = Date()) {
        self.endTime = endTime
    }
}
```

Indexed on `[startTime, type]` and `[identifier]`.

### 2.2 Icon (`SimplyTrack/Models/Icon.swift`)

```swift
@Model
class Icon {
    @Attribute(.unique) var identifier: String  // bundle ID or domain
    var iconData: Data?                          // PNG data
    var lastUpdated: Date

    var needsUpdate: Bool {  // stale after 1 week
        lastUpdated < Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
    }
}
```

### 2.3 UsageType enum (`SimplyTrack/Models/UsageType.swift`)

```swift
enum UsageType: String, Codable, CaseIterable {
    case app
    case website
}
```

### 2.4 Database Registration

```swift
// SimplyTrack/Managers/DatabaseManager.swift
Schema([UsageSession.self, Icon.self])

// Registration in app entry point:
// SimplyTrack/App/SimplyTrackApp.swift
@main
struct SimplyTrackApp: App {
    var body: some Scene {
        Settings {
            SettingsWindow()
                .modelContainer(DatabaseManager.shared.modelContainer)
        }
    }
}
```

---

## 3. Permission Management

SimplyTrack needs **3 types** of macOS permissions:

### 3.1 Accessibility Permission (AXIsProcessTrusted)

Required for: Getting app icons (NSRunningApplication.icon). Also for Firefox tab detection (accessibility API).

```swift
// Prompt at startup:
func checkAccessibilityPermission() {
    let trusted = AXIsProcessTrustedWithOptions(
        [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
    )
    // If not trusted, macOS shows a dialog. User must grant in
    // System Settings > Privacy & Security > Accessibility
}
```

System preferences URL:
```swift
let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
NSWorkspace.shared.open(url)
```

### 3.2 Automation Permission (Apple Events)

Required for: Reading browser tabs via AppleScript. Without this, AppleScript returns error codes -1743 or -1744.

SimplyTrack detects this at runtime:
```swift
// BrowserInterface.swift:63-64
if scriptResult.errorCode == -1743 || scriptResult.errorCode == -1744 {
    PermissionManager.shared.handleBrowserPermissionResult(success: false)
}
```

System preferences URL:
```swift
let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
NSWorkspace.shared.open(url)
```

### 3.3 Screen Recording Permission

Required for: `CGWindowListCopyWindowInfo` (floating window detection). macOS prompts automatically on first call.

### 3.4 PermissionManager (`SimplyTrack/Managers/PermissionManager.swift`)

```swift
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var automationPermissionStatus: PermissionStatus  // .granted/.denied/.notDetermined
    @Published var systemEventsPermissionStatus: PermissionStatus
    @Published var accessibilityPermissionStatus: PermissionStatus
    @Published var lastError: String?

    func isBrowserSupported(_ bundleId: String) -> Bool {
        supportedBrowserBundleIds.contains(bundleId)
    }
}
```

**Key lesson from NOTE.md**: Don't confuse Accessibility and Automation permissions. Reading frontmost app (`NSWorkspace`) needs no special permission. Reading browser tab content (AppleScript) needs Automation permission. Opening Accessibility settings won't fix Automation issues.

---

## 4. App Tracking Engine

### 4.1 Core Loop (`TrackingService.swift`)

```swift
@MainActor
class TrackingService {

    func startTracking() {
        // 1. Observer for app switches (instant detection)
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { notification in
            self.handleAppChange(notification)  // stores currentApp
        }

        // 2. Polling timer every 1 second (reliable, catches gaps)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { await self.updateCurrentActivity() }
        }

        // 3. Batch save every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { await self.sessionPersistenceService.performAtomicSave() }
        }
    }
}
```

**Why both?** NSWorkspace notifications can be delayed or missed. Polling guarantees no gaps.

### 4.2 Activity Update (run every 1 second)

```swift
func updateCurrentActivity() async {
    let systemIdleTime = getSystemIdleTime()  // CGEventSource.secondsSinceLastEventType
    if systemIdleTime >= 300 {  // 5 min idle
        await endAllActiveSessions()
        return
    }

    guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
          let bundleId = frontmostApp.bundleIdentifier,
          let name = frontmostApp.localizedName
    else { return }

    // Check floating overlay (e.g., Ghostty quick terminal)
    if let floating = windowDetectionService.detectTopmostFloatingWindow(frontmostBundleId: bundleId) {
        activeBundleId = floating.bundleIdentifier
        activeName = floating.name
    }

    // Skip system UI
    guard !excludedBundleIds.contains(activeBundleId) else {
        if activeBundleId == "com.apple.loginwindow" { await endAllActiveSessions() }
        return
    }

    // Extract icon (cached, avoids PNG conversion every second)
    if let iconData = appIconCache[activeBundleId] {
        sessionPersistenceService.queueIconData(identifier: activeBundleId, iconData: iconData)
    } else if let iconData = IconUtils.getAppIconAsPNG(for: activeApp) {
        appIconCache[activeBundleId] = iconData
        sessionPersistenceService.queueIconData(identifier: activeBundleId, iconData: iconData)
    }

    // Update session
    updateAppSession(identifier: activeBundleId, name: activeName, now: now)
    scheduleWebsitePoll(now: now)
}
```

### 4.3 Idle Detection

```swift
func getSystemIdleTime() -> TimeInterval {
    let idleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
    return TimeInterval(idleTime)
}
```

SimplyTrack threshold: 300 seconds (5 minutes). For Pomodoro (typically 25 min), match to Pomodoro duration or use shorter threshold.

### 4.4 Excluded System UI

```swift
private static let excludedBundleIds: Set<String> = [
    "com.apple.dock",
    "com.apple.loginwindow",
    "com.apple.Spotlight",
    "com.apple.notificationcenterui",
    "com.apple.controlcenter",
]
```

### 4.5 App Session Lifecycle

```swift
func updateAppSession(identifier: String, name: String, now: Date) {
    if let currentSession = currentAppSession {
        if currentSession.identifier != identifier {
            // App changed → end old, start new
            currentSession.endSession(at: now)
            sessionPersistenceService.queueSession(currentSession)
            currentAppSession = UsageSession(type: .app, identifier: identifier, name: name, startTime: now)
        }
        // Same app → continue (no action)
    } else {
        // No active session → start new
        currentAppSession = UsageSession(type: .app, identifier: identifier, name: name, startTime: now)
    }
}
```

### 4.6 Floating Window Detection (`SimplyTrack/Services/WindowDetectionService.swift`)

Handles apps like Ghostty quick terminal, 1Password Quick Access that render floating overlays without becoming frontmost.

```swift
func detectTopmostFloatingWindow(frontmostBundleId: String) -> DetectedWindow? {
    guard let windowList = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements],
        kCGNullWindowID
    ) as? [[CFString: Any]] else { return nil }

    for windowInfo in windowList {
        // Parse: pid, bundleId, ownerName, level, width, height
        // Skip: system UI levels (≥ mainMenuWindow), tiny windows (<50pt), own windows
        // Skip: ignored bundle IDs (Dock, loginwindow, Spotlight, etc.)
        // If window belongs to frontmost app → no override, return nil
        // If window ≥ kCGFloatingWindowLevel AND ≥200x200 → it's an interactive overlay
    }
}
```

---

## 5. Website / Browser Tracking

### 5.1 Browser Interface Protocol (`SimplyTrack/Services/Browsers/BrowserInterface.swift`)

```swift
protocol BrowserInterface {
    var bundleId: String { get }
    var displayName: String { get }
    func getCurrentURL() -> String?      // AppleScript to read active tab URL
    func isInPrivateBrowsingMode() -> Bool?
}
```

### 5.2 BaseBrowser (shared AppleScript engine)

```swift
class BaseBrowser: BrowserInterface {
    var currentURLScript: String { fatalError("override") }

    func getCurrentURL() -> String? {
        let scriptResult = executeAppleScript(currentURLScript)

        // Handle permission errors
        if scriptResult.errorCode == -1743 || scriptResult.errorCode == -1744 {
            PermissionManager.shared.handleBrowserPermissionResult(success: false)
        } else if scriptResult.errorCode == -1712 {
            // timeout — transient, just return nil
        } else if scriptResult.errorCode == -1719 {
            // invalid index — race condition when tabs change during poll
        }

        PermissionManager.shared.handleBrowserPermissionResult(success: scriptResult.result != nil)
        return scriptResult.result
    }

    internal func executeAppleScript(_ script: String) -> AppleScriptResult {
        let wrappedScript = """
            with timeout of 3 seconds
            \(script)
            end timeout
            """
        let appleScript = NSAppleScript(source: wrappedScript)
        let result = appleScript?.executeAndReturnError(&error)
        return AppleScriptResult(result: result?.stringValue, errorCode: errorCode, error: error)
    }
}
```

### 5.3 Browser Implementations

**Chrome** (`SimplyTrack/Services/Browsers/ChromeBrowser.swift`):
```swift
class ChromeBrowser: BaseBrowser {
    init() { super.init(bundleId: "com.google.Chrome", displayName: "Chrome") }

    override var currentURLScript: String {
        return """
            tell application "Google Chrome"
                if (count of windows) > 0 then
                    set currentTab to active tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }

    override func isInPrivateBrowsingMode() -> Bool? {
        // AppleScript: mode of window 1 is equal to "incognito"
    }
}
```

**Safari** (`SimplyTrack/Services/Browsers/SafariBrowser.swift`):
```swift
class SafariBrowser: BaseBrowser {
    init() { super.init(bundleId: "com.apple.Safari", displayName: "Safari") }

    override var currentURLScript: String {
        return """
            tell application "Safari"
                if (count of windows) > 0 then
                    set currentTab to current tab of window 1
                    return URL of currentTab
                end if
            end tell
            """
    }

    override func isInPrivateBrowsingMode() -> Bool? {
        // System Events: check "Move Tab to New Private Window" menu item exists
    }
}
```

**All 8 supported browsers**: Safari, Chrome, Edge, Arc, Brave, Vivaldi, Dia, Firefox.

### 5.4 WebTrackingService (`SimplyTrack/Services/WebTrackingService.swift`)

```swift
class WebTrackingService {
    private let browsers: [String: BrowserInterface] = [
        SafariBrowser(), ChromeBrowser(), ..., FirefoxBrowser()
    ].reduce(into: [:]) { $0[$1.bundleId] = $1 }

    func getCurrentWebsiteInfo() -> (domain: String, url: String)? {
        // 1. Check frontmost app is a supported browser
        // 2. Check private browsing (if disabled by user)
        // 3. Get URL via AppleScript
        // 4. Extract domain via URL(string:) → host
        // 5. Strip www. prefix
    }

    func extractDomain(from urlString: String) -> String {
        guard urlString.hasPrefix("http://") || urlString.hasPrefix("https://") else { return "" }
        guard let url = URL(string: urlString), let host = url.host else { return urlString }
        if host.hasPrefix("www.") { return String(host.dropFirst(4)) }
        return host
    }
}
```

### 5.5 Website Polling Strategy (key reliability features)

```swift
// Features in TrackingService.scheduleWebsitePoll():

// Cooldown: after repeated failures, wait 5 seconds
if let cooldownUntil, now < cooldownUntil { return }

// Max concurrent polls: 2
guard activeWebsitePollTasks < maxActiveWebsitePollTasks else { return }

// Stale poll handling: if poll takes >10 seconds, abort + cooldown
// Grace period: after 8 seconds of no successful poll, end website session
// Failure threshold: after 3 consecutive failures, end website session
```

### 5.6 Favicon Fetching

```swift
func getFaviconData(for domain: String, sourceURL: String) async -> Data? {
    // 1. Check in-memory LRU cache (FaviconCacheActor, max 200 entries)
    // 2. Parse page HTML for <link rel="icon"> href
    // 3. Fallback: domain/favicon.ico, domain/favicon.png
    // 4. Convert to 32x32 PNG
}
```

---

## 6. Session Persistence (SwiftData Batched Saves)

### 6.1 SessionPersistenceService (`SimplyTrack/Services/SessionPersistenceService.swift`)

```swift
@MainActor
class SessionPersistenceService {
    private var pendingSessions: [UsageSession] = []
    private var pendingIcons: [(identifier: String, iconData: Data)] = []
    private var freshIconIdentifiers: Set<String> = []  // in-memory staleness cache

    func queueSession(_ session: UsageSession) { pendingSessions.append(session) }

    func queueIconData(identifier: String, iconData: Data) {
        guard !freshIconIdentifiers.contains(identifier) else { return }
        pendingIcons.append((identifier, iconData))
    }

    func performAtomicSave() async {
        let sessionsToSave = pendingSessions
        let iconsToSave = pendingIcons
        pendingSessions.removeAll()
        pendingIcons.removeAll()

        await saveSessionsAndIcons(sessionsToSave, iconsToSave)
    }

    private func saveSessionsAndIcons(_ sessions, _ icons) async {
        // Runs on background thread:
        await Task.detached(priority: .utility) {
            let context = ModelContext(container)
            // Insert sessions
            // Check icon staleness, upsert if needed
            try context.save()
        }.value
    }
}
```

Key design decisions:
- **Batch save every 30 seconds** (not per-second, avoids DB thrashing)
- **Background context** via `Task.detached(priority: .utility)` — never block main thread
- **Icon staleness cache** in memory (`freshIconIdentifiers`) — cleared hourly, avoids DB query on every tick
- **Retry logic** — re-queue failed items up to 3 times, then drop to prevent unbounded growth
- **App termination** — synchronous save with 2-second timeout in `applicationWillTerminate`

---

## 7. Aggregation & Data Processing

All aggregation happens in `ContentView.swift`. Design: run DB query on background context, return raw tuples, render on main actor.

### 7.1 Daily Data Fetch

```swift
func fetchDailyData() async -> DailyDataResults {
    return await Task.detached(priority: .userInitiated) {
        let context = ModelContext(container)

        // Fetch all completed sessions for today
        let descriptor = FetchDescriptor<UsageSession>(
            predicate: #Predicate { session in
                session.startTime >= startOfDay && session.startTime < endOfDay && session.endTime != nil
            }
        )
        let allSessions = try context.fetch(descriptor)

        // Separate app vs website
        let appSessions = allSessions.filter { $0.type == "app" }
        let websiteSessions = allSessions.filter { $0.type == "website" }

        // Fetch icons for all identifiers needed
        let icons = try context.fetch(Icon descriptor matching identifiers)
        let iconMap = Dictionary(uniqueKeysWithValues: icons.map { ($0.identifier, $0.iconData) })

        // Compute
        let workPeriods = computeWorkPeriods(from: appSessions)
        let topApps = aggregateAppSessions(appSessions, iconMap: iconMap)
        let topWebsites = aggregateWebsiteSessions(websiteSessions, iconMap: iconMap)
        let totalActiveTime = appSessions.reduce(0) { $0 + $1.duration }

        return (workPeriods, totalActiveTime, topApps, topWebsites)
    }.value
}
```

### 7.2 Work Period Computation (Merging Sessions)

```swift
static func computeWorkPeriods(from sessions: [UsageSession]) -> [(startTime: Date, endTime: Date, duration: TimeInterval)] {
    let completedSessions = sessions
        .compactMap { session -> (Date, Date)? in
            guard let endTime = session.endTime else { return nil }
            return (session.startTime, endTime)
        }
        .sorted { $0.0 < $1.0 }

    var mergedPeriods: [(Date, Date)] = []
    var currentStart = completedSessions[0].0
    var currentEnd = completedSessions[0].1

    for (sessionStart, sessionEnd) in completedSessions.dropFirst() {
        if sessionStart <= currentEnd {
            // Overlapping or adjacent — merge
            currentEnd = max(currentEnd, sessionEnd)
        } else {
            mergedPeriods.append((currentStart, currentEnd))
            currentStart = sessionStart
            currentEnd = sessionEnd
        }
    }
    mergedPeriods.append((currentStart, currentEnd))

    return mergedPeriods.map { ($0, $1, $1.timeIntervalSince($0)) }
}
```

This converts many small sessions (every 1-second tick) into continuous work blocks. Without this, a 30-minute coding session would show as 1800 separate 1-second entries.

### 7.3 App/Website Aggregation

```swift
static func aggregateAppSessions(_ sessions: [UsageSession], iconMap: [String: Data]) -> [(identifier: String, name: String, iconData: Data?, totalTime: TimeInterval)] {
    var appData: [String: (name: String, totalTime: TimeInterval)] = [:]

    for session in sessions {
        let existing = appData[session.identifier, default: (name: session.name, totalTime: 0)]
        appData[session.identifier] = (name: existing.name, totalTime: existing.totalTime + session.duration)
    }

    return appData.map { (identifier: $0, name: $1.name, iconData: iconMap[$0], totalTime: $1.totalTime) }
        .sorted { $0.totalTime > $1.totalTime }
}
```

### 7.4 Weekly Activity

```swift
static func computeWeeklyActivity(from sessions: [UsageSession]) -> [String: TimeInterval] {
    var weeklyActivity: [String: TimeInterval] = [:]
    for session in sessions {
        let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: session.startTime) - 1]
        let dayKey = String(dayName.prefix(3)).uppercased()
        weeklyActivity[dayKey, default: 0] += session.duration
    }
    return weeklyActivity
}
```

### 7.5 Caching Strategy

- Cache valid for **30 seconds** (same as persistence interval)
- Today's cache invalidated on every popover show
- Stale-while-revalidate flags prevent double fetches (`isDailyFetching`/`isWeeklyFetching`)

---

## 8. Icon Handling

### 8.1 Extract Icon from Running App (`SimplyTrack/Utils/IconUtils.swift`)

```swift
static func getAppIconAsPNG(for app: NSRunningApplication) -> Data? {
    guard let icon = app.icon else { return nil }
    // Resize to 32x32
    let resizedImage = NSImage(size: NSSize(width: 32, height: 32), flipped: false) { rect in
        icon.draw(in: rect)
        return true
    }
    // Convert to PNG
    guard let tiffData = resizedImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
    return bitmap.representation(using: .png, properties: [:])
}
```

### 8.2 Icon Cache Hierarchy

```
In-memory: appIconCache [String: Data] — never cleared (apps rarely change icon)
    │
    ▼
In-memory: freshIconIdentifiers Set<String> — cleared hourly, avoids DB staleness check
    │
    ▼
SwiftData: Icon model — persisted
    │
    ▼
UI: IconView renders from cached PNG or generates letter fallback
```

### 8.3 IconView (`SimplyTrack/Views/IconView.swift`)

```swift
enum IconType {
    case app(identifier: String, iconData: Data?)
    case website(domain: String, iconData: Data?)
}

struct IconView: View {
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon).resizable().clipShape(iconShape)
            } else {
                Image(nsImage: createLetterIcon())  // letter fallback
                    .resizable().clipShape(iconShape)
            }
        }
        .frame(width: size, height: size)
    }

    private var iconShape: some Shape {
        switch type {
        case .app: RoundedRectangle(cornerRadius: size * 0.12)
        case .website: Circle()
        }
    }

    // createLetterIcon(): draws first letter on colored background
    // colorForString(): deterministic color from string hash
}
```

---

## 9. UI Display Components

### 9.1 ActiveTimeCard (`SimplyTrack/Views/ActiveTimeCard.swift`)
Wrapper: header (total active time) + segmented picker (timeline vs pie chart).
- Day mode: HourlyTimelineChart or UsagePieChart
- Week mode: WeeklyBarChart or UsagePieChart

### 9.2 HourlyTimelineChart (`SimplyTrack/Views/HourlyTimelineChart.swift`)
24-hour horizontal bar. Blue rectangles positioned proportional to start time, width proportional to duration.

```swift
GeometryReader { geometry in
    let startPosition = (sessionStart / dayDuration) * timelineWidth
    let sessionWidth = max((sessionDuration / dayDuration) * timelineWidth, 2)
    Rectangle().fill(Color.blue.opacity(0.8))
        .frame(width: sessionWidth, height: 80)
        .offset(x: startPosition)
}
```

### 9.3 WeeklyBarChart (`SimplyTrack/Views/WeeklyBarChart.swift`)
Swift Charts `BarMark` for 7 days (MON–SUN). Animated transitions.

### 9.4 UsagePieChart (`SimplyTrack/Views/UsagePieChart.swift`)
Swift Charts `SectorMark` donut chart. Top 5 apps with colored legend.

### 9.5 UsageListView (`SimplyTrack/Views/UsageListView.swift`)
List apps/websites with IconView + name + formattedDuration.
- Default: show top 5, expandable via "Show more"/"Show less"

---

## 10. Key Differences: SimplyTrack vs Current Approach

| Aspect | Current (Pomodoro App) | SimplyTrack |
|---|---|---|
| Detection | `NSWorkspace.didActivateApplicationNotification` only | Notification + 1s polling timer |
| Idle handling | None | `CGEventSource.secondsSinceLastEventType`, 5-min threshold |
| Floating windows | Not handled | `CGWindowListCopyWindowInfo` scanning |
| Website polling | Only on app switch event | Every 1 second (async, concurrent=2 max) |
| Website failure handling | Silent fail | Cooldown (5s), grace period (8s), threshold (3 fails) |
| Data storage | JSON local file | SwiftData (indexed, typed) |
| Save strategy | On session end | Batch queue every 30s, atomic background save |
| Permission model | Mixed Automation/Accessibility | Clear separation + runtime detection + UI feedback |
| Browser compatibility | 4 browsers (Safari, Chrome, Edge, Brave) | 8 browsers (adds Arc, Vivaldi, Dia, Firefox) |
| Icon caching | Not implemented | 3-tier: in-memory → staleness set → SwiftData |
| Session merging | Raw events | `computeWorkPeriods()` merges overlapping sessions |

### Why SimplyTrack's approach is more reliable:

1. **Polling prevents gaps**: Notifications alone are unreliable. 1-second timer guarantees no missing ticks even if user is in same app for hours.

2. **Grace periods prevent flickering**: Website sessions don't end immediately on first failure. 8-second grace window absorbs transient AppleScript failures.

3. **Batch persistence reduces overhead**: Per-second DB writes would be expensive. 30-second batch with background context keeps UI smooth.

4. **Icon staleness cache prevents redundant work**: In-memory `freshIconIdentifiers` set avoids DB query on every 1-second tick for icons that haven't changed.

5. **Work period merging produces meaningful timeline**: Without merging, the timeline would show 1800 tiny bars for 30 minutes of work.

---

## 11. Minimal Integration for Pomodoro App

### Core changes needed:

1. **Model**: Add `pomodoroId: UUID` to `TrackedSession` (or equivalent) to correlate with Pomodoro sessions
2. **Controller**: `TrackerController` that `startTracking(pomodoroId)` / `stopTracking()` per Pomodoro state
3. **App detection**: Copy `TrackingService.updateCurrentActivity()` + `NSWorkspace` polling
4. **Website detection**: Copy `BrowserInterface` protocol + Chrome + Safari implementations
5. **Display**: On Pomodoro end, query by `pomodoroId`, aggregate, show in result view

### Flow:

```
Pomodoro starts → TrackerController.startTracking(pomodoroId: UUID)
    │
    ▼
1s polling loop:
    ├─► NSWorkspace.frontmostApplication → create/update app session
    └─► AppleScript browser URL → create/update website session
    │
    ▼
Pomodoro ends → TrackerController.stopTracking()
    │
    ▼
End all active sessions + batch save
    │
    ▼
Query DB WHERE pomodoroId == sessionID
→ aggregateAppSessions() + aggregateWebsiteSessions()
→ render in result view
```

### Minimal code sketch:

```swift
@Model
class TrackedSession {
    @Attribute(.unique) var id = UUID()
    var pomodoroId: UUID       // ← link to pomodoro session
    var type: String           // "app" / "website"
    var identifier: String     // bundle ID / domain
    var name: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval { endTime?.timeIntervalSince(startTime) ?? 0 }
}

@MainActor
class TrackerController {
    private var timer: Timer?
    private var currentAppSession: TrackedSession?
    private var currentWebsiteSession: TrackedSession?
    private var activePomodoroId: UUID?
    private var appIconCache: [String: Data] = [:]

    func startTracking(pomodoroId: UUID) {
        self.activePomodoroId = pomodoroId
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { await self.tick() }
        }
    }

    func stopTracking() {
        timer?.invalidate()
        endAllSessions()
        // Batch save, then trigger UI refresh
    }

    private func tick() {
        // Same logic as TrackingService.updateCurrentActivity()
        // But attach activePomodoroId to each session
    }
}
```

---

## 12. Checklist for Implementation

### Data Layer
- [ ] Create `TrackedSession` model with `pomodoroId`
- [ ] Create `Icon` model for caching
- [ ] Setup `ModelContainer` with both models
- [ ] Add indexing on `pomodoroId` + `startTime`

### Permission Handling
- [ ] Add Accessibility permission request at app launch
- [ ] Add Automation permission request details in Info.plist (NSAppleEventsUsageDescription)
- [ ] Add Screen Recording usage description in Info.plist
- [ ] Create permission error handling in browser AppleScript execution

### App Tracking
- [ ] Class `AppTracker` with 1-second polling timer
- [ ] Get `NSWorkspace.shared.frontmostApplication` each tick
- [ ] Extract + cache app icon via `NSRunningApplication.icon`
- [ ] Skip excluded system UIs (Dock, loginwindow, Spotlight, etc.)
- [ ] Implement `updateAppSession()` lifecycle (create/update/end)
- [ ] Handle idle detection (`CGEventSource`)

### Website Tracking
- [ ] Create `BrowserInterface` protocol + `BaseBrowser` (AppleScript engine)
- [ ] Implement Chrome browser support
- [ ] Implement Safari browser support
- [ ] Implement Edge/Brave/Firefox support
- [ ] Create `WebsiteTracker` polling loop (every 3s)
- [ ] Extract domain from URL (strip www, filter non-http)
- [ ] Add failure handling: cooldown + grace period + threshold
- [ ] Handle private browsing detection

### Persistence
- [ ] Batch session queue (append to array, save every 30s)
- [ ] Background context for saves (`Task.detached(priority: .utility)`)
- [ ] Icon staleness cache (in-memory set, cleared hourly)
- [ ] App termination save (with timeout)

### Aggregation
- [ ] Group sessions by identifier, sum duration
- [ ] `computeWorkPeriods()` — merge overlapping sessions
- [ ] Sort descending by total time
- [ ] Limit to top N items

### UI / Display
- [ ] List view with IconView + name + duration
- [ ] Pie chart (top 5 apps)
- [ ] Timeline view (active periods as bars)
- [ ] Weekly bar chart

### Integration with Pomodoro
- [ ] `TrackerController.startTracking(pomodoroId:)` on focus start
- [ ] `TrackerController.stopTracking()` on focus end
- [ ] Query by `pomodoroId` when session completes
- [ ] Display aggregated results in result view
- [ ] Handle pause/resume (pause polling during Pomodoro break)


## 13. Icon Handling Checklist

### 13.1 Extract App Icon (copy `IconUtils.swift`)

```swift
// Utils/IconUtils.swift
enum IconUtils {
    static func getAppIconAsPNG(for app: NSRunningApplication) -> Data? {
        guard let icon = app.icon else { return nil }
        // Resize to 32x32
        let resizedImage = NSImage(size: NSSize(width: 32, height: 32), flipped: false) { rect in
            icon.draw(in: rect)
            return true
        }
        // Convert to PNG
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
```

Required permission: Accessibility (`AXIsProcessTrusted`). Call this at app launch:
```swift
let trusted = AXIsProcessTrustedWithOptions(
    [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
)
```

### 13.2 Cache Icon During Tracking Loop

Add `appIconCache` to your TrackerController:
```swift
private var appIconCache: [String: Data] = [:]  // bundleId → PNG data

// Inside 1s polling tick, right after detecting frontmost app:
if let iconData = appIconCache[activeBundleId] {
    // Already cached in memory — queue for DB save
    persistenceService?.queueIconData(identifier: activeBundleId, iconData: iconData)
} else if let iconData = IconUtils.getAppIconAsPNG(for: activeApp) {
    appIconCache[activeBundleId] = iconData  // cache in memory
    persistenceService?.queueIconData(identifier: activeBundleId, iconData: iconData)
}
```

**Why cache?** `getAppIconAsPNG()` involves PNG conversion every call. Without cache, app would do this 3600 times per hour per app. With cache, once per app per launch.

### 13.3 Fetch Website Favicon

Copy from `WebTrackingService.getFaviconData()`:
```swift
func getFaviconData(for domain: String, sourceURL: String) async -> Data? {
    // 1. Parse page HTML for <link rel="icon"> href
    // 2. Fallback: domain/favicon.ico, domain/favicon.png
    // 3. Cache result in memory (LRU, max 200)
    // 4. Return 32x32 PNG
}
```

Call it from website tracking:
```swift
// After successful domain detection:
Task {
    let iconData = await webTrackingService.getFaviconData(for: domain, sourceURL: url)
    await MainActor.run {
        persistenceService?.queueIconData(identifier: domain, iconData: iconData)
    }
}
```

### 13.4 Save Icon to Database (batch persistence)

```swift
// In persistence service:
private var pendingIcons: [(identifier: String, iconData: Data)] = []
private var freshIconIdentifiers: Set<String> = []  // skip already-saved icons

func queueIconData(identifier: String, iconData: Data) {
    guard !freshIconIdentifiers.contains(identifier) else { return }
    pendingIcons.append((identifier, iconData))
}

// During batch save (every 30s), run on background context:
await Task.detached(priority: .utility) {
    let context = ModelContext(container)
    for iconInfo in icons {
        let descriptor = FetchDescriptor<Icon>(
            predicate: #Predicate<Icon> { icon in
                icon.identifier == iconInfo.identifier
            }
        )
        let existingIcons = try context.fetch(descriptor)
        if let existingIcon = existingIcons.first {
            existingIcon.updateIcon(with: iconInfo.iconData)
        } else {
            context.insert(Icon(identifier: iconInfo.identifier, iconData: iconInfo.iconData))
        }
    }
    try context.save()
}
```

### 13.5 Render Icon in UI (copy `IconView.swift`)

```swift
enum IconType {
    case app(identifier: String, iconData: Data?)
    case website(domain: String, iconData: Data?)
}

struct IconView: View {
    let type: IconType
    let size: CGFloat

    var body: some View {
        Group {
            if let iconData = iconData, let nsImage = NSImage(data: iconData) {
                Image(nsImage: nsImage)
                    .resizable().aspectRatio(contentMode: .fit)
                    .clipShape(iconShape)
            } else {
                // Letter fallback: first letter on colored background
                Image(nsImage: createLetterIcon())
                    .resizable().aspectRatio(contentMode: .fit)
                    .clipShape(iconShape)
            }
        }
        .frame(width: size, height: size)
    }

    private var iconShape: some Shape {
        switch type {
        case .app: RoundedRectangle(cornerRadius: size * 0.12)
        case .website: Circle()
        }
    }

    // createLetterIcon(): draw letter on NSImage with color from string hash
    // colorForString(): deterministic color from hash % 8 preset colors
}
```

**Usage in list:**
```swift
// Use in Top Apps list:
ForEach(topApps, id: \.identifier) { app in
    HStack {
        IconView(type: .app(identifier: app.identifier, iconData: app.iconData), size: 25)
        Text(app.name)
        Spacer()
        Text(app.totalTime.formattedDuration)
    }
}

// Use in Top Websites list:
ForEach(topWebsites, id: \.identifier) { site in
    HStack {
        IconView(type: .website(domain: site.name, iconData: site.iconData), size: 20)
        Text(site.name)
        Spacer()
        Text(site.totalTime.formattedDuration)
    }
}
```

### 13.6 Checklist

- [ ] Copy `IconUtils.swift` — extract app icon from `NSRunningApplication`
- [ ] Call `AXIsProcessTrustedWithOptions` at app launch
- [ ] Add `appIconCache: [String: Data]` to tracker (in-memory, never cleared)
- [ ] Cache icon on first detection → queue for DB save
- [ ] Copy favicon fetch from `WebTrackingService.getFaviconData()`
- [ ] Queue favicon data after successful website poll
- [ ] Create `Icon` SwiftData model (identifier, iconData, lastUpdated)
- [ ] Add `freshIconIdentifiers: Set<String>` to avoid redundant DB writes
- [ ] Save icons in same 30s batch as sessions
- [ ] Copy `IconView.swift` — render with letter fallback
- [ ] Pass `iconData` through aggregation pipeline (iconMap)
- [ ] Render `IconView` in all app/website list views
