# Dzenn — Terminal Commands Reference

| Command | Kegunaan |
|---------|----------|
| `xcodebuild -list -project <project>.xcodeproj` | Lihat daftar scheme & target |
| `xcodebuild -project <project>.xcodeproj -scheme <scheme> -configuration Debug build` | Build project (debug) via terminal |
| `xcodebuild -project <project>.xcodeproj -scheme <scheme> -configuration Release build` | Build project (release) via terminal |
| `DERIVED=$(xcodebuild -project <project>.xcodeproj -scheme <scheme> -showBuildSettings \| grep BUILT_PRODUCTS_DIR \| awk '{print $NF}') && open "$DERIVED/<app>.app"` | Jalanin app hasil build |
| `Ctrl + C` | Hentikan build yg sedang berjalan di terminal |
| `pkill -9 xcodebuild` | Paksa kill semua proses xcodebuild (jika stuck) |
| `xcodebuild -project /Users/kiram/Code/dzenn/dzenn.xcodeproj -scheme dzenn -configuration Debug build 2>&1 | tee build.log` | Build + test (unit & UI) + semua warning/error dalam 1 file `build.log` |

---

xcodebuild -project /Users/kiram/Code/dzenn/dzenn.xcodeproj -scheme dzenn -configuration Debug build 2>&1 | tee build.log
# Dzenn — TODO.md (MVP Roadmap)


kalau pip yt g bs, g malsah, lanjut aja ke bentuk uI yg lain, tpi g usah image

saran fokus ke 
- bentu dasar dlu
- bagusin analytic

> Sequential development plan for Dzenn (macOS Focus App)

---

## Core Foundation

1. Project setup✅
2. Folder structure✅
3. Main app window✅
4. Floating window system✅
5. Always-on-top overlay✅
6. Drag floating window✅
7. Start / Stop focus session✅
8. Timer Engine (countdown core)✅

---

## Focus System

9. Task input UI (main app)❌ -- tdk perlu fitur ini
10. Duration selector UI -- cari ref design dlu biar enk ✅
11. Session state machine✅
12. Break mode✅
13. Pause / Resume✅
14. Multi-session per day✅ (tunda full tracking)

---

## Menu Bar App (MVP)

15. Status bar icon (menu bar) ✅
16. Menu bar UI: slider (interval) ✅
17. Menu bar UI: quick presets (5m / 15m / 25m) ✅
18. Menu bar UI: Start/Pause toggle ✅
19. Menu bar UI: Timer label (current) ✅
20. Menu bar UI: “…” menu (Settings / Contact / Quit) ✅

---

## Settings (Main App)

21. Open main app from menu bar Settings ✅
22. Configure quick presets (3 options) ✅
23. Sound toggle/config ✅
24. Floating theme selector ✅ + opacity setting ✅
25. Floating image toggle ✅
26. Show/hide timer in floating ✅

---

## UX Layer

27. Floating controls (pause/stop) ✅
28. Keyboard shortcuts ❌
29. Smooth animations ❌
30. Theme system (basic) ✅
31. UI polish ✅

## Testing

32. Coba tes dengar sound paki blutooh atua kabel

--- --- AFTER MVP (RELAES 1.1.0)

## Release 1.1.0 Priority — Task-Based Pomodoro

- Catatan penting: akun Apple Developer sudah aktif, jadi target rilis publik final nanti pakai alur `signed + notarized` sebelum dijual.
- Fokus release `1.1.0` ini adalah `task-based pomodoro` dulu.
- `App activity tracking` belum dikerjakan di fase ini.

33. Task group / task plan model ⏳
34. Task plan builder UI ⏳
35. Focus-cycle sequence engine (`focus -> break -> focus`) ⏳
36. Auto-continue antar sesi dalam 1 task group ⏳
37. Progress indicator (`current session / total`) ⏳
38. Manual controls (`pause`, `resume`, `skip break`, `stop task`) ⏳
39. Completion state + reset flow untuk task group ⏳

--- AFTER RELEASE 1.1.0

## Release 1.2.0 Priority — Analytics & Activity Tracking

- Fokus fase ini: analytics lokal untuk sesi pomodoro, heatmap, top apps, top websites/domain, dan ringkasan fokus.
- Tracking `website/domain` perlu pendekatan browser-specific. Jika URL/domain tidak bisa dibaca, fallback simpan nama browser/app saja.

40. Analytics permissions flow (`Accessibility` + `Automation`) ⏳
41. Foreground app tracking service ⏳
42. Browser domain / URL tracking untuk browser yang didukung ⏳
43. App + website activity logging saat focus session aktif ⏳

## Analytics Data Layer

44. Focus session record model ⏳
45. App activity event model ⏳
46. Website visit record model ⏳
47. Local persistence layer (`JSON`) ⏳
48. Session storage + safe append/update flow ⏳
49. Daily aggregation pipeline ⏳

---

## Analytics Engine

50. Analytics calculation engine ⏳
51. Daily focus totals + heatmap data builder ⏳
52. Weekly summary + streak calculation ⏳
53. Top apps / top websites ranking ⏳
54. Focus consistency + distraction logic ⏳

---

## Analytics UI

55. Analytics dashboard UI ⏳
56. Heatmap view UI ⏳
57. Activity timeline UI ⏳
58. App / website breakdown UI ⏳

---

## MVP Finalization

59. Settings panel polish ❌
60. Preferences system ❌
61. Permissions flow ❌
62. Onboarding ❌
63. Error handling ❌
64. App state recovery ❌
65. Data integrity checks ❌
66. Performance optimization ❌
67. UX refinement ❌
68. MVP stabilization ❌

---

## MVP DONE

69. Internal testing ❌
70. MVP ready build ❌

---

# Release & Distribution (Public)

71. Pastikan `Bundle Identifier` final (reverse domain) ✅
72. Pastikan `Version` + `Build` (CFBundleShortVersionString + CFBundleVersion) ❌
73. Pastikan entitlements yang dibutuhkan (Sandbox, Hardened Runtime, iCloud? etc) ✅/❌
74. Archive build via Xcode (Release) ✅/❌
75. Set signing final pakai `Developer ID Application` ❌
76. Jalankan notarization + stapling untuk build final ❌
77. Buat paket distribusi `.zip` notarized ✅/❌
78. Test install di Mac lain (fresh user) ✅/❌
79. Siapkan halaman download + release notes ✅/❌
80. (Optional) Auto‑update via Sparkle ✅/❌
81. (Optional) Homebrew tap + cask ✅/❌
82. Buat icon aplikasi (AppIcon) ✅/❌

Notes:

- Tanpa auto‑update, user harus download versi baru manual.
- Versi lama **tetap bisa jalan** selama tidak ada dependency server yang memaksa upgrade.
- Jika pakai Sparkle, kamu bisa pilih `soft update` (rekomendasi)
- `forced update` hanya jika benar‑benar perlu
- Karena akun Apple Developer sudah ada, target distribusi final bukan lagi `Open Anyway`, tapi `signed + notarized`.

---

# Homebrew (Recommended)

- Buat repo tap: `homebrew-dzenn`
- Buat cask `dzenn-pomodoro.rb`
- Isi cask: `version`, `sha256`, `url` (ZIP notarized), `name`, `desc`, `homepage`
- Update `version` + `sha256` setiap rilis
- Instruksi user:
- `brew tap <username>/dzenn`
- `brew install --cask dzenn-pomodoro`
- Update user:
- `brew update`
- `brew upgrade --cask dzenn-pomodoro`

---

# ILMU BARU

- Cara add sound ke project
  > setelh sound ada d folder, buka file inspector (⌥ + ⌘ + 1)
  > d target membership, checlist project

---


# RELEASE v0.1.5 — Analytics Testing + Distribution
### Phase 1 — Simplify Floating (Timer Only)
- [ ] `R1` Hapus `mixed` + `imageOnly` dari `FloatingLayoutMode` enum
- [ ] `R2` Simplify `FloatingTimerView` — hanya timer content, hapus image/mixed code
- [ ] `R3` Simplify `FloatingAppSettingsView` — hapus style selector, image section, semua struct pendukung
- [ ] `R4` Bersihkan `Constants.swift` — hapus konstanta tidak terpakai
- [ ] `R5` Simplify `WindowManager.updateFloatingSize()` — fixed size
- [ ] `R6` Hapus file tidak terpakai: `FloatingImageFraming.swift`, `FloatingImageStorage.swift`
- [ ] `R7` Build + test — floating window hanya timer, settings hanya opacity + theme
### Phase 2 — Analytics Testing
- [ ] `R8` Test start focus session → app activity tercatat
- [ ] `R9` Test browser tracking (Safari/Chrome) → domain tercatat
- [ ] `R10` Test pause/resume → durasi tidak dobel
- [ ] `R11` Test stop session → data tersimpan ke JSON
- [ ] `R12` Test relaunch app → analytics dashboard load data lama
- [ ] `R13` Test heatmap → klik cell → summary + breakdown update
- [ ] `R14` Test empty state → analytics tanpa data tampil rapi
- [ ] `R15` Fix bug/crash yang ditemukan saat testing
### Phase 3 — App Export & Distribution
- [ ] `R16` Set version + build number final (CFBundleShortVersionString + CFBundleVersion)
- [ ] `R17` Archive build via Xcode (Release scheme)
- [ ] `R18` Sign dengan `Developer ID Application`
- [ ] `R19` Notarization + stapling
- [ ] `R20` Buat paket distribusi `.dmg` atau `.zip`
- [ ] `R21` Test install di Mac lain (fresh user)
- [ ] `R22` Siapkan release notes
### Phase 4 — Final QA
- [ ] `R23` Test sound alert via Bluetooth/speaker
- [ ] `R24` Test menu bar → start/stop/pause
- [ ] `R25` Test floating window → drag, opacity, theme
- [ ] `R26` Test permissions → Accessibility, Automation
- [ ] `R27` Test session lifecycle → start → pause → resume → stop → break
- [ ] `R28` Test analytics end-to-end → session → data → dashboard
- [ ] `R29` Final build → RELEASE v0.1.5

----------

# RELEASE v0.1.6 - Anlytic App

- fokus rapikan ui panel dlu
- setelh itu clone repo ini : https://github.com/renjfk/SimplyTrack, dan acri tahu cara dia tracking
- done

---

# CODE IMPROVEMENTS — Based on SimplyTrack Architecture Review

> Checklist perbaikan codebase Dzenn berdasarkan perbandingan dengan SimplyTrack.
> Urutan berdasarkan prioritas: Tinggi → Medium → Rendah.
> SwiftData migration ada di paling akhir (R38).

## HIGH PRIORITY

### 1. Dependency Injection over Singleton Access
- [x] `I1` Identifikasi semua tempat yang akses singleton langsung (`ActivityTracker.shared`, `AnalyticsStore.shared`, `AnalyticsEngine.shared`, `FocusSessionManager.shared`)
- [x] `I2` Buat dependency injection via constructor di `AppDelegate` / `MenuBarController`
- [x] `I3` Inject `ActivityTracker`, `AnalyticsStore`, `AnalyticsEngine` ke `FocusSessionManager`
- [x] `I4` Inject `BrowserActivityResolver` ke `ActivityTracker`
- [ ] `I5` Update semua View yang observe singleton → inject via `@EnvironmentObject` atau constructor
- [x] `I6` Test: semua fitur tetap jalan tanpa singleton access

### 2. Custom Error Enums with LocalizedError
- [x] `I7` Buat `enum DzennError: LocalizedError` di `Models/` atau `Utils/`
- [x] `I8` Ganti semua `print("error")` dengan `Logger` structured logging
- [x] `I9` Tambahkan `case fileIOError`, `case decodeError`, `case trackingError`, `case permissionError`
- [x] `I10` Implementasi `errorDescription` dan `failureReason` untuk setiap case
- [ ] `I11` Buat centralized error display (seperti `AppDelegate.showError()` di SimplyTrack)
- [x] `I12` Test: error muncul user-friendly, bukan crash/print

### 3. NSWorkspace Notification for App Tracking
- [x] `I13` Tambahkan observer `NSWorkspace.didActivateApplicationNotification` di `ActivityTracker`
- [x] `I14` Keep polling 1s sebagai fallback (hybrid approach)
- [x] `I15` Handle app change via notification → langsung update session, tidak perlu tunggu polling cycle
- [x] `I16` Test: app switch terdeteksi lebih responsif (<1s delay)

### 4. Generation Tracking for Website Polling
- [x] `I17` Tambahkan `websitePollGeneration` counter di `ActivityTracker` (dipindah dari BrowserActivityResolver karena async task ada di sana)
- [x] `I18` Increment generation setiap start new poll → cancel stale tasks
- [x] `I19` Check generation di awal poll task → abort jika generation tidak match
- [x] `I20` Test: tidak ada duplicate/stale website session saat cepat switch browser tab

## MEDIUM PRIORITY

### 5. Actor for Thread-Safe Cache
- [x] `I21` Buat `actor IconCacheActor` untuk app icon caching di `ActivityTracker`
- [x] `I22` Implementasi LRU eviction (max 200 entries seperti SimplyTrack)
- [x] `I23` Ganti dictionary cache biasa dengan actor-based cache
- [x] `I24` Test: tidak ada race condition saat concurrent icon fetch

### 6. Grace Period for Website Sessions
- [x] `I25` Tambahkan `websitePollGraceInterval: 8.0` constant (sudah ada di `AppConstants`)
- [x] `I26` Saat website tidak terdeteksi, tunggu grace period sebelum end session
- [x] `I27` Jika website muncul lagi dalam grace period → continue session
- [x] `I28` Test: tidak ada flicker session saat brief tab switch

### 7. Floating Window Detection
- [x] `I29` Buat `WindowDetectionService` (seperti SimplyTrack)
- [x] `I30` Detect floating/overlay windows (Ghostty, 1Password, Spotlight)
- [x] `I31` Exclude floating windows dari tracking atau handle khusus
- [x] `I32` Test: overlay apps tidak mengganggu tracking app utama

### 8. Nonisolated Static Functions for Pure Computation
- [x] `I33` Identifikasi pure functions di `AnalyticsEngine` (tidak perlu state)
- [x] `I34` Ubah menjadi `nonisolated static func` untuk thread safety
- [x] `I35` Test: functions bisa dipanggil dari background task tanpa MainActor isolation

## LOW PRIORITY

### 9. Favicon Caching with Multi-Strategy Fetch
- [ ] `I36` Implementasi favicon fetch: page extraction → domain/favicon.ico → www.domain/favicon.ico
- [ ] `I37` Simpan favicon di cache + persist ke storage
- [ ] `I38` Tambahkan staleness check (update favicon jika sudah lama)
- [ ] `I39` Test: favicon muncul untuk website yang sering dikunjungi

### 10. Private Browsing Detection
- [ ] `I40` Tambahkan detection untuk private/incognito mode per browser
- [ ] `I41` Tambahkan toggle `trackPrivateBrowsing` di settings (default: OFF)
- [ ] `I42` Jika private mode + toggle OFF → skip tracking untuk browser tersebut
- [ ] `I43` Test: private browsing tidak tercatat saat toggle OFF

### 11. Debug/Release Storage Isolation
- [ ] `I44` Tambahkan `#if DEBUG` check untuk storage paths
- [ ] `I45` Separate JSON storage directory untuk debug vs release
- [ ] `I46` Separate UserDefaults suite untuk debug vs release
- [ ] `I47` Test: development data tidak mengganggu production data

### 12. Batch Persistence with Retry Logic
- [ ] `I48` Implementasi queue-based batch save (seperti `SessionPersistenceService`)
- [ ] `I49` Save setiap 30 detik, bukan setiap session end
- [ ] `I50` Tambahkan retry logic (max 3 retries) untuk failed saves
- [ ] `I51` Test: data tidak hilang saat app crash mid-session

## FINAL — SWIFTDATA MIGRATION

### 13. Migrate from JSON to SwiftData
- [ ] `R32` Buat `@Model` types: `FocusSessionRecord`, `AppActivityEvent`, `WebsiteVisitRecord`
- [ ] `R33` Tambahkan `#Index` macro untuk query optimization (date, type, identifier)
- [ ] `R34` Buat `DatabaseManager` singleton (seperti SimplyTrack) dengan `ModelContainer`
- [ ] `R35` Implementasi migration dari JSON ke SwiftData (one-time import)
- [ ] `R36` Replace `AnalyticsStore` dengan SwiftData queries (`#Predicate`)
- [ ] `R37` Update `AnalyticsEngine` untuk use SwiftData fetch requests
- [ ] `R38` Hapus JSON storage layer setelah migration verified
- [ ] `R39` Test: semua analytics features jalan dengan SwiftData, performance lebih baik
- [ ] `R40` Test: migration dari JSON lama berjalan smooth, tidak ada data loss


SimplyTrack needs access to control your web browsers to track which websites you visit for accurate time tracking and productivity insights.