# Progress Log

## 2026-10-02 — End-to-end integration fase 1–4 (codex/kiki-flow-core)

- Integrasi runtime qyube sepenuhnya:
  - `QyubeAppCoordinator` sekarang juga memiliki `DistractionCoordinator` dan `DistractionOverlayController`.
  - Session otomatis memulai/stop monitoring foreground activity saat aktif/berakhir.
  - Overlay gangguan muncul saat policy dilanggar: mouse-transparent, non-activating, intensitas terbatas, menghormati Reduce Motion, dan tidak menghentikan timer/catch.
- Catch engine terintegrasi ke `SessionCoordinator` dengan auto-timer (bite → reel → deposit). Pause/resume menangguhkan dan melanjutkan siklus tangkapan. Distraction tidak membatalkan catch yang sedang berlangsung.
- `NewSessionView` menampilkan kartu sesi aktif dengan kontrol pause/resume/stop dan edit tugas saat sedang ada sesi.
- `FloatingTimerController` menambahkan edit tugas langsung dari panel timer.
- `FishingReportView` muncul sebagai jendela report saat sesi completed/interrupted, memakai data ledger sungguhan.
- `InsightView` menambahkan Day/Week/Month/Year dengan `InsightAggregator` (tanpa tag atau target harian).
- `CatalogView` memakai count dari ledger banked.
- Tambah test otomatis: `SessionCoordinatorCatchTests`, `InsightAggregatorTests`.
- Build dan semua test lulus.

## 2026-10-02 — Wiring Home, dual panel, menu bar, dan Insight (codex/kiki-flow-core)

- Buat `QyubeAppCoordinator` untuk menyatukan Home window, `SessionCoordinator`, `FloatingTimerController`, `CompanionWindowController`, dan menu bar status.
- `AppDelegate.swift` sekarang menjalankan qyube runtime sebagai regular app: membuka Home window saat launch dan saat Dock diklik.
- `MenuBarController.swift` direduksi menjadi status icon only; klik icon restore timer panel (saat sesi aktif) atau buka Home window.
- `FloatingTimerController.swift` ditambahkan kontrol pause/resume/stop dan close yang hanya menyembunyikan panel.
- `CompanionWindowController.swift` diklik untuk restore timer panel.
- `InsightView.swift` menampilkan ringkasan focus time, completed/interrupted, catches, dan recent sessions dari repository.
- `CatalogView.swift` sekarang membaca count dari ledger banked dan menampilkan silhouette untuk item yang belum ditemukan.
- `FishingReportView.swift` placeholder untuk report completed/interrupted.
- Build dan semua test lulus.

## 2026-10-01 — Implementasi fase 2–4 parsial (codex/kiki-flow-core)

- Fase 2 — Policy & permission:
  - `FocusPolicyEvaluator.swift`: pure function untuk tiga mode dengan aturan browser Chrome/Safari dan normalisasi domain.
  - `ForegroundActivityMonitor.swift`: monitor app foreground terpisah dari analytics tracker, tanpa permission request saat launch.
  - `PermissionManager.swift`: contextual permission status dan capability.
  - `DistractionCoordinator.swift`: bridge activity → policy decision → cue, dengan detour interval.
- Fase 3 — Home & dua panel:
  - `QyubeHomeView.swift`: shell tiga panel dengan sidebar Focus/Catalog/Insight/Settings.
  - `NewSessionView.swift`: form task, mode picker, durasi, dan pilihan app/domain.
  - `FloatingTimerController.swift` dan `CompanionWindowController.swift`: panel terpisah (belum sepenuhnya tersambung ke `SessionCoordinator`).
  - `AppDelegate.swift`: menambahkan mode debug `--qyube-home` untuk mempreview Home baru tanpa memutus alur lama.
- Fase 4 — Catch ledger, Catalog, report:
  - `CatalogDefinitions.swift`: delapan jenis tangkapan awal.
  - `CatchEngine.swift`: roll identitas saat reel, deposit, batas bank 5 menit.
  - `CatalogView.swift`: menampilkan semua item dengan silhouette untuk yang belum ditemukan; count dari ledger banked.
  - `FishingReportView.swift`: placeholder report completed/interrupted.
- Perbaikan test:
  - `FocusSessionRecord.swift`: Hashable/Equatable berdasarkan `id` agar test `hashableConformance` lulus.
  - `AnalyticsEngine.swift`: melengkapi minggu heatmap di trailing edge agar `buildHeatmapCellsReturnsCompleteWeeks` lulus.
  - `AnalyticsStoreTests.swift`: serialisasi suite untuk menghindari race UserDefaults.
  - `BrowserActivityResolverTests.swift`: perbaiki bundle ID Arc.
- Build dan semua test lulus. UI Home dapat dipreview via `--qyube-home`; integrasi penuh panel dan menu bar masih terbuka.

## 2026-10-01 — Implementasi fase 0–1 (codex/kiki-flow-core)

- Updated `qoma.xcodeproj` app target deployment target dari 11.5 ke 14.0 untuk mengaktifkan SwiftData nanti.
- Menambahkan domain model baru di `Qoma/Domain/Focus/`:
  - `FocusModels.swift`: `FocusPolicyMode`, `SessionPolicy`, `ForegroundActivity`, `PolicyDecision`, `SessionDraft`, `ActiveSessionSnapshot`, `FocusSession`, `CatchEvent`, `AccessState`.
  - `FocusPolicyEvaluator.swift`: pure evaluator untuk tiga mode (allowing/blocking/timerOnly) dengan aturan browser Chrome/Safari dan normalisasi domain.
  - `SessionClock.swift`: clock injectable dengan deadline absolut, pause/resume, dan perhitungan active seconds.
  - `SessionCoordinator.swift`: orkestrasi sesi, persistence atomik, restore, finalize idempotent, integrasi catch engine.
- Menambahkan persistence layer di `Qoma/Persistence/`:
  - `SessionRepository.swift`: JSON atomik untuk active snapshot dan history.
  - `CatchRepository.swift`: ledger provisional dan banked.
- Menambahkan catch engine dan definisi katalog di `Qoma/Domain/Catch/`:
  - `CatalogDefinitions.swift`: delapan jenis tangkapan awal.
  - `CatchEngine.swift`: urutan bite/reel/deposit, roll identitas saat reel, batas bank 5 menit.
- Menambahkan stub `AccessCoordinator` di `Qoma/Auth/`.
- Menambahkan unit test baru:
  - `FocusPolicyEvaluatorTests.swift`
  - `SessionClockTests.swift`
  - `SessionCoordinatorTests.swift`
  - `CatchEngineTests.swift`
- Memperbaiki `BrowserActivityResolverTests.swift`: bundle ID Arc yang salah (`company.com.Arc` → `company.thebrowser.Browser`).
- Build dan test baru lulus. Satu test lama (`AnalyticsEngineTests/buildHeatmapCellsReturnsCompleteWeeks`) masih gagal karena dependensi tanggal; tidak terkait pekerjaan fase 0–1.
- Memperbarui checkbox fase 0–1 di `task_plan.md`.

## 2026-10-01 — Kiki-flow technical planning (complete)

- Created and switched to branch `codex/kiki-flow-core` earlier in the interview.
- Collected the user's corrections for tags, dual panels, Stripe card-first trial, Google/Apple-only login, expired-access gate, Aquarium removal, and no daily goal.
- Read current `task_plan.md`, planning skill instructions, source entry points, and selected qyube design references. No application implementation has started.
- Reviewed current Apple and Stripe primary documentation for the distribution/billing constraint. This is a release gate, not a change to the user's desired web trial flow.
- Observed unrelated pre-existing deletions under `design/qyube-concepts-v1/` and `design/qyube-concepts-v2/`; preserve them. `KIKI.md` remains untracked from the earlier task.
- Rewrote `task_plan.md` as an agent-ready implementation contract with UI references, state machines, policy precedence, proposed Swift interfaces/files, migration sequence, test gates, and billing/distribution constraints. The canceled Aquarium and daily goal are not product features in this plan.
- Verified the plan against inspected code/design references and ran `git diff --check`. No application code was changed.
- Inspection detail: the actual app delegate path is `Qoma/Managers/AppDelegate.swift`; one read of `Qoma/AppDelegate.swift` failed because that path does not exist. Resolved by reading the correct path. No files were changed by that failed read.

## Session: 2026-09-27

### Phase 1: Consolidate Approved Product Decisions

- **Status:** complete
- **Started:** 2026-09-27
- Actions taken:
  - Ran the product-design interview through session, collection, analytics, monetization, sync, animation, and Deep Focus behavior.
  - Confirmed the user’s product decisions and recorded the corrected timer model: no Pomodoro default and no automatic break; default timer is 10 minutes, with a 10–60 minute ruler plus a separate 180-minute option.
  - Captured the confirmed Release-1 pricing and Lifetime promise.
- Files created/modified:
  - `task_plan.md` (created)
  - `findings.md` (created)
  - `progress.md` (created)

### Phase 2: Verify Existing Product Baseline and External Constraints

- **Status:** complete
- Actions taken:
  - Reviewed project structure and existing product documents; prior exploration was recorded in `CONTEXT.md`.
  - Inspected the supplied fishing video and aquarium image.
  - Verified Apple platform constraints and relevant public product patterns.
- Files created/modified:
  - `CONTEXT.md` (created in prior exploration)
  - `findings.md` (created)

### Phase 3: Write Product and Technical Specification

- **Status:** complete
- Actions taken:
  - Initialized persistent planning files using the planning-with-files workflow.
  - Consolidated all approved rules into `PRODUCT_SPEC.md`: timer/session model, fishing and banking, rarity, Catalog, Aquarium, analytics, Deep Focus, pricing, sync, privacy, accessibility, and Release-1 exclusions.
  - Wrote `ROADMAP.md` with a 16-week implementation sequence, acceptance gates, and Deep Focus entitlement contingency.
  - Added the Universal Purchase distribution constraint: Mac App Store must be the primary Release-1 channel, while any legacy direct-DMG/Sparkle route requires a separate entitlement policy.
  - Cross-checked the specification against approved interview decisions and the existing Qoma architecture documented in `CONTEXT.md`.
- Files created/modified:
  - `PRODUCT_SPEC.md` (created)
  - `ROADMAP.md` (created)

### Phase 4: Build the Four-Month Release-1 Roadmap

- **Status:** complete
- Actions taken:
  - Sequenced the work into 16 weeks, with data/session foundations before visual surfaces and iOS before premium/sync release gates.
  - Added mandatory physical-device testing, performance gates, App Store distribution constraints, and a non-blocking Deep Focus entitlement branch.
- Files created/modified:
  - `ROADMAP.md` (created)

### Phase 5: Deliver and Verify Documentation

- **Status:** complete
- Actions taken:
  - Verified document structure and key product invariants with repository searches.
  - Ran trailing-whitespace validation after correcting document metadata formatting.
  - Confirmed all requested planning artifacts exist in the project root.
- Files created/modified:
  - `task_plan.md` (updated)
  - `findings.md` (updated)
  - `progress.md` (updated)

## Test Results

| Test | Input | Expected | Actual | Status |
|---|---|---|---|---|
| Planning-file discovery | `rg --files` for planning files | Determine whether prior planning state exists | No prior planning files found | ✓ |
| Skill template review | Read three planning templates | Use correct persistent planning structure | Templates reviewed | ✓ |
| Documentation format | Trailing-whitespace scan | No trailing whitespace in planning/spec docs | Passed after correction | ✓ |
| Requirement cross-check | Search specification/roadmap invariants | Approved rules are represented | Confirmed | ✓ |

## Error Log

| Timestamp | Error | Attempt | Resolution |
|---|---|---:|---|
| 2026-09-27 | Web result formatter expected an MCP content array | 1 | Switched to direct JSON output and preserved findings. |
| 2026-09-27 | Markdown validation found trailing whitespace in document metadata | 1 | Removed the trailing spaces. |
| 2026-09-27 | Completion-log patch used an outdated line context | 1 | Read current content and applied a narrower patch. |

## 5-Question Reboot Check

| Question | Answer |
|---|---|
| Where am I? | Documentation task complete. |
| Where am I going? | Next approved task: implementation preparation or Release-1 development. |
| What’s the goal? | An implementation-ready Dzenn Release-1 product specification and roadmap. |
| What have I learned? | See `findings.md` and `CONTEXT.md`. |
| What have I done? | Authored and verified the product specification, 16-week roadmap, and persistent planning records. |

## Session: 2026-09-29

### Phase 1: Freeze macOS Pivot Contract

- **Status:** complete
- Actions taken:
  - Replaced the former Dzenn documentation plan with a qyube macOS-first pivot plan.
  - Recorded the New Session → task/duration/allow-list → independent timer and penguin companion session flow.
  - Preserved fishing, the five-minute banking threshold, Catalog, Insight, and Fishing Report.
  - Deferred Aquarium and iOS changes from the current prototype phase.
  - Defined click-through fish-based visual friction for unallowed applications and recorded the sandbox/accessibility feasibility gate.
- Files modified:
  - task_plan.md
  - findings.md
  - progress.md

## Error Log

| Timestamp | Error | Attempt | Resolution |
|---|---|---:|---|
| 2026-09-29 | Git rejected a codex/ prefixed branch | 1 | Used qyube-macos-pivot-plan; the user allowed any branch name. |
| 2026-09-29 | Sandbox could not write the Git ref | 1 | Created the branch with approved Git access. |

## Session: 2026-09-30

### Floating companion art and animation contract

- **Status:** complete
- Actions taken:
  - Analyzed the user-provided 2940 × 1912 macOS screenshot and recorded approximate Kiki timer and character footprints, with an explicit 2× Retina assumption.
  - Wrote an implementation-facing art direction and animation contract covering fixed scene layers, penguin identity, states, state precedence, immediate event response, timing guidance, Reduce Motion, and permission fallback.
  - Updated the root plan and findings to point to the floating companion contract and the latest neutral palette.
  - Created and switched to the requested branch qyube-floating-art-spec.
- Files modified:
  - design/qyube-floating/ART_DIRECTION.md
  - task_plan.md
  - findings.md
  - progress.md
- Validation:
  - `git diff --check` passed for all four documentation files.
  - Confirmed the referenced product plan and spec paths exist.
