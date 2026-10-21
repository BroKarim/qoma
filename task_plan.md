# qyube — Rencana Implementasi macOS (Alur Kiki, Identitas qyube)

**Status:** main UI diimplementasikan pada 16 Oktober 2026; bagian 21 mencatat hasil dan pengecualian terhadap rencana bagian 20. Bagian 22 adalah rencana MenuBar terbaru yang disetujui pengguna, belum diimplementasikan. Login produksi serta data berat individu belum diaktifkan.

**Branch implementasi awal:** `codex/kiki-flow-core`.

**Branch audit dan perbaikan UI:** `codex/qyube-ui-rework`.

**Diperbarui:** 16 Oktober 2026 (Asia/Jakarta).

**Branch perencanaan terbaru:** `codex/main-ui-plan-2026-10-16`; baseline tersimpan pada commit `6f29b0d` di `codex/floating-timer-soft-panel`.

**Branch pekerjaan UI analytics:** `codex/analytics-responsive-heatmap-2026-10-16`.

**Branch perencanaan MenuBar terbaru:** `codex/menubar-app-rules-plan-2026-10-16`, dibuat dari `codex/daily-catches-grid-timeline-2026-10-16` sesudah snapshot commit `daaaafd` (`feat: refine daily catches grid and timeline`). Bagian 22 mengungguli keputusan MenuBar/rules/restart yang bertentangan di bagian terdahulu.

**Pembaruan 16 Oktober 2026:** Analytics Dashboard sedang diperbaiki agar adaptif terhadap lebar window. Sidebar memiliki mode compact ikon-saja, statistik memakai layout adaptif, dan heatmap memakai satu tahun sejak sesi pertama (bukan 210 hari terakhir). Heatmap akan menggunakan scroll horizontal hanya ketika lebar minimum cell tidak lagi muat.

**Fokus:** macOS lebih dulu. Rancangan iOS tetap pekerjaan lanjutan.
**Nama target kode saat ini:** `Qoma`; nama produk yang dituju: `qyube`.

## jangan dihapus, catatan pribadi 

- cara run di terminal : 
xcodebuild \
  -project qoma.xcodeproj \
  -scheme Qoma \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

open ~/Library/Developer/Xcode/DerivedData/qoma-drxrbpjdzxdevegbhqstemmkbakm/Build/Products/Debug/Qoma.app

atua klo g bisa : 
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild build \
  -project qoma.xcodeproj \
  -scheme Qoma \
  -configuration Debug \
  -destination 'platform=macOS'

lalu : 
open ~/Library/Developer/Xcode/DerivedData/qoma-drxrbpjdzxdevegbhqstemmkbakm/Build/Products/Debug/Qoma.app

cara kill : pkill -f Qoma

## 0. Cara memakai rencana ini

Dokumen ini menjadi sumber keputusan untuk implementasi macOS berikutnya. `PRODUCT_SPEC.md`, `ROADMAP.md`, `findings.md`, dan beberapa catatan desain masih memuat keputusan lama tentang tag, break, free tier, pembayaran App Store, serta fitur kolam animasi. Bila bertentangan, gunakan keputusan pengguna di dokumen ini dan buat PR dokumentasi penyelarasan sebelum rilis. Jangan menganggap contoh nama tipe/fungsi di sini sudah ada; bagian **Usulan** adalah kontrak yang harus diwujudkan atau diganti dengan alasan yang tercatat.

Agent implementasi harus mengerjakan tiap fase kecil, menjalankan validasi fase tersebut, dan menjaga perubahan lain di worktree. `KIKI.md` adalah riset antarmuka Kiki, bukan sumber kode atau kepastian cara Kiki mengimplementasikan fiturnya. Keputusan produk qyube di sini mengungguli perilaku Kiki yang belum diverifikasi.

### Referensi visual yang harus dibaca

| Kegunaan | Referensi | Status |
|---|---|---|
| Home dan New Session | [01-home-floating-form.png](design/qyube-concepts-v3/01-home-floating-form.png) | Baseline komposisi: sidebar sempit, ilustrasi tengah, kartu form kanan |
| Timer terbuka | [01-timer-open.png](design/qyube-active-session-v1/01-timer-open.png) | Draft ukuran/posisi; bukan ukuran produksi pasti |
| Timer tertutup | [02-timer-closed.png](design/qyube-active-session-v1/02-timer-closed.png) | Penguin tetap tampil; menu bar tetap menunjukkan waktu |
| Perilaku dua layar | [README active session](design/qyube-active-session-v1/README.md) | Kontrak close/restore panel |
| Pengaturan art dan state | [ART_DIRECTION.md](design/qyube-floating/ART_DIRECTION.md) | Pakai constraint visualnya; bagian `Continue`, tag, dan pembatalan catch oleh distraksi sudah kalah oleh keputusan baru |
| Implementasi animasi yang ada | [README companion](design/qyube-companion-animation/README.md) | Prototipe SpriteKit dengan pose tanpa kacamata |
| Sumber asset minimal | [README asset](design/qyube-minimum-assets-v1/README.md) | Pose/prop awal; bukan seluruh ilustrasi tangkapan |

Warna Home: putih hangat, arang, abu hangat, sedikit terracotta. Panel penguin transparan, tanpa kartu persegi, bayangan penguin, atau lingkaran riak air yang mencolok. Pertahankan es dan ember pada anchor yang sama di setiap pose. Ilustrasi Home boleh lebih besar daripada companion desktop. Jangan menyalin rupa atau suara karakter Kiki.

## 1. Kontrak produk yang sudah diputuskan

| Area | Keputusan final untuk implementasi ini |
|---|---|
| Sesi | Satu tugas bebas sebagai konteks pekerjaan; **tanpa tag**. Nama tugas boleh kosong dan memakai label tampilan netral. |
| Waktu | Pilihan awal 10 menit; ruler 10–60 menit; 180 menit sebagai pilihan khusus paling awal. Tidak ada siklus Pomodoro atau break otomatis. |
| Mode | `allowing`, `blocking`, `timerOnly`; pada penggunaan pertama pilih `timerOnly`. Dua mode pertama memberi **gangguan visual**, tidak menolak akses aplikasi/situs. |
| Browser | Jika Chrome atau Safari diizinkan sebagai aplikasi, **semua situs di browser itu aman**. Pilihan domain tersedia sebagai kontrol lanjutan, bukan syarat tambahan setelah browser diizinkan. |
| App aktif | Aplikasi yang melanggar aturan tetap dapat diklik/dipakai. Overlay ikan bersifat sementara dan mouse-transparent. Timer serta penangkapan ikan tetap berjalan. |
| Dua panel | Timer dapat disembunyikan; penguin transparan wajib tetap tampil selama sesi aktif, termasuk ketika timer disembunyikan. Saat pause penguin tidur. |
| Menu bar | Saat aktif tampilkan waktu tersisa saja. Klik membuka timer jika tersembunyi; bila timer sudah terlihat, tidak melakukan apa-apa. Saat idle klik membuka Home. |
| Sesi selesai | Tampilkan Fishing Report, lalu tawarkan `Mulai sesi lagi` dengan draft sebelumnya. Tidak ada `Continue`/perpanjangan sesi yang sama. |
| Stop awal | Minta konfirmasi dengan konsekuensi tangkapan. Simpan durasi aktif yang nyata sebagai `interrupted`; `completed` hanya bila countdown mencapai nol. |
| Koleksi | Catalog menampilkan seluruh jenis tangkapan, termasuk yang belum ditemukan. Setiap deposit yang tersimpan menambah count; semua art tangkapan yang detail dapat menyusul. Tidak ada layar kolam animasi dalam produk baru. |
| Insight | Pertahankan analisis fokus dan tangkapan. Distribusi pekerjaan memakai judul tugas persis, tanpa tag atau penggabungan otomatis judul mirip. Tidak ada target fokus harian. |
| Akses | Website login wajib; hanya Google dan Apple. Kartu dimasukkan melalui alur Stripe sebelum akses trial. Trial tujuh hari tanpa tagihan di muka dimulai saat sesi pertama diaktifkan. |
| Trial habis | Pengguna melihat layar langganan sebelum Home; data lokal/hasil koleksi **tidak dihapus**. Sesi yang sudah aktif boleh selesai sebelum gate berlaku. |
| Perangkat | Satu akun menjadi identitas lintas Mac/iOS. Sinkronisasi riwayat/koleksi melalui iCloud tetap pilihan terpisah. Timer dan posisi panel tetap lokal per perangkat. |

Konsekuensi penting: pilihan “tanpa tag” meniadakan `tagDistribution` di Insight. Hard gate setelah akses habis menggantikan gagasan lama bahwa pengguna dapat tetap menelusuri koleksi tanpa membayar. Data tetap ada, tetapi UI produk dikunci sampai akses pulih.

## 2. Alur layar dan state

```text
App launch
  ├─ belum login             → Web sign-in (Google / Apple)
  ├─ login, kartu belum siap → Stripe card setup pada web
  ├─ trial/paid aktif        → Home (Focus / Catalog / Insight / Settings)
  ├─ trial belum dimulai     → Home; Start pertama mengaktifkan trial di server
  └─ expired/unpaid          → Subscription gate; Home tidak dibuka

Home → New Session → Task / Mode / Apps-or-domains / Duration → Start
     → Active {timer panel + penguin panel + optional distraction overlay}
         ├─ Pause ↔ Resume
         ├─ Edit task / session-only rule
         ├─ Stop + confirm → Interrupted report (<5m: return to sea)
         └─ Countdown zero → Completed Fishing Report
     → Mulai sesi lagi (draft terisi, belum auto-start) / Home
```

Layar Home tetap dapat dibuka dari Dock saat sesi aktif untuk membaca Insight/Catalog; dua panel tetap berjalan. Home tidak menjadi panel ketiga yang selalu terapung. Hanya ada satu sesi aktif per perangkat; tombol New Session ketika aktif mengantar ke sesi aktif, bukan memulai timer kedua.

### State machine domain

`AccessState`: `signedOut → cardRequired → readyForFirstSession → trialing → paid`, dengan `expired`/`paymentIssue`/`unknown` sebagai keadaan gate/refresh. `readyForFirstSession` berarti metode pembayaran tersimpan, tetapi trial belum dimulai. Server harus menjamin trial dimulai paling banyak sekali per akun.

`SessionPhase`: `idle → configuring → active ↔ paused → completed | interrupted → report → idle`. Tidak ada phase break. `FocusPolicyMode` berbeda dari `SessionPhase`; jangan memakai `SessionMode.quickSession/taskPlan` yang lama untuk menyimpan `allowing/blocking/timerOnly`.

`CatchPhase`: `waiting → bite → reeling → depositing → waiting`. Roll identitas saat mulai reel; satu event baru dapat tersimpan ketika deposit di ember selesai. Visual reaksi distraksi tidak mengulang roll atau membatalkan catch yang sedang ditarik.

### Aturan waktu dan recovery

- Simpan snapshot sesi setelah Start, Pause, Resume, perubahan tugas, dan perubahan aturan. Gunakan deadline absolut untuk menghitung sisa waktu setelah app background/wake; tick UI hanya untuk menggambar angka.
- `activeSeconds` tidak memasukkan waktu pause. Ambang bank lima menit memakai nilai ini, bukan umur sesi sejak Start.
- Sesi yang melewati deadline ketika app tidak berjalan diselesaikan ketika dibuka lagi. Jangan membuat catch retroaktif untuk waktu ketika proses tidak berjalan.
- Quit yang disengaja saat aktif meminta konfirmasi dan menyimpan `interrupted`; crash atau relaunch memakai snapshot untuk pemulihan, tanpa menduplikasi laporan atau tangkapan.
- Trial/subscription yang berakhir ketika sesi sedang aktif tidak memotong sesi; gate diperiksa sebelum Start berikutnya.
- Task yang diubah di tengah sesi memperbarui judul seluruh sesi. Mode, durasi, dan identitas sesi awal tetap tersimpan sebagai snapshot untuk riwayat.

## 3. Aturan aplikasi, situs, dan visual friction

### Model aturan yang dapat diuji tanpa UI

```swift
enum FocusPolicyMode: Codable { case allowing, blocking, timerOnly }
enum FocusResource: Hashable, Codable {
    case app(bundleID: String)
    case domain(host: String)
}
struct PolicyDecision {
    let isDistraction: Bool
    let reason: Reason
}

func evaluate(_ activity: ForegroundActivity, against policy: SessionPolicy) -> PolicyDecision
```

`ForegroundActivity` memuat bundle ID dan domain aktif bila browser yang didukung berhasil dibaca. Normalisasi domain harus case-insensitive, buang awalan `www.`, dan definisikan aturan subdomain secara eksplisit dalam tes. Jangan simpan URL lengkap atau judul tab sebagai bagian minimum kebijakan baru.

| Mode | Aturan prioritas |
|---|---|
| `timerOnly` | Tidak pantau untuk policy; tidak ada overlay. |
| `allowing` | App dalam allow-list → aman, termasuk **seluruh situs** jika app adalah browser. Jika browser belum diizinkan tetapi domain aktif diizinkan → aman pada domain itu. Selebihnya → distraksi. |
| `blocking` | App dalam block-list → distraksi, termasuk semua tab browser. Jika app tidak diblokir tetapi domain aktif diblokir → distraksi pada domain itu. Selebihnya → aman. |

Pilihan domain diletakkan di bagian lanjutan UI. Chrome dan Safari menjadi browser yang didukung untuk kebijakan domain tahap awal. Browser lain dievaluasi sebagai aplikasi secara keseluruhan; kode analytics lama yang mendukung browser lain bukan janji produk baru. Bila domain tidak terbaca, evaluasi berdasarkan aturan aplikasinya dan tampilkan status kemampuan secara jelas; jangan diam-diam mengklaim situs tertentu telah diawasi.

`NSWorkspace.didActivateApplicationNotification` dapat memberi perubahan app foreground cepat. Resolver domain bekerja saat browser aktif dan bisa lebih lambat; janji animasi adalah **bereaksi pada frame pertama setelah keputusan policy tersedia**, bukan menjamin pengetahuan domain seketika. Jangan minta izin Automation/Accessibility saat launch. Minta hanya ketika mode dan jenis aturan yang dipilih benar-benar memerlukannya. Jika izin ditolak, pertahankan draft dan tawarkan retry/Settings atau Timer Only. Jika izin dicabut di tengah sesi, timer dan penguin tetap berjalan; matikan reaksi berbasis app/domain dan beri status singkat.

Overlay adalah jendela efek sementara, **bukan panel companion ketiga**. Ia tidak menjadi key window, tidak mengambil keyboard, dan tidak menangkap mouse. Mulai dari ikan kecil segera setelah pelanggaran terdeteksi, berkembang perlahan dengan batas intensitas yang tetap, dan pulih setelah kembali ke app/domain aman. Sediakan Reduce Motion berupa cue statis yang tenang. Perubahan “izinkan untuk sesi ini” dapat diakses dari panel timer, hanya mengubah snapshot policy sesi aktif, bukan daftar default permanen. Durasi detour dicatat terpisah; seluruh activeSeconds tetap dihitung sebagai waktu sesi.

## 4. Jendela, menu bar, dan antarmuka

### Main app

Bangun shell SwiftUI baru mengikuti Home v3: sidebar `Focus`, `Catalog`, `Insight`, dan `Settings`; area tengah untuk ilustrasi penguin; kartu `New Session` di kanan. Saat mengimplementasikan, gunakan kontrol native untuk keyboard/VoiceOver dan jaga hierarki visual referensi, bukan menyalin piksel mentah. Mode picker menampilkan `Allowing / Blocking / Timer Only`. Tugas boleh kosong, tetapi UI riwayat memberi label seperti `Focus session` agar daftar tidak kosong. Form tidak menampilkan tag. Ruler default 10 menit, 180 menit sebagai pilihan khusus sebelum 10–60.

### Dua panel tetap

| Permukaan | Perilaku |
|---|---|
| Timer | Panel sekitar 210 × 143 pt sebagai ukuran awal; menampilkan countdown dan close kecil. Close = `orderOut`, bukan stop. Panel timer yang dapat dibuka kembali menyediakan akses jelas untuk pause/resume, stop, edit tugas, dan pengecualian aturan tanpa mengubah komposisi waktu utama. Detail kontrolnya perlu prototipe UI ringkas. |
| Penguin | `NSPanel` transparan/nonactivating dengan art sekitar 118 pt dalam kanvas sekitar 140 pt; selalu visible ketika active/paused. Dapat dipindah dan posisi tersimpan lokal. Klik karakter membuka timer jika timer tersembunyi; tidak menutup penguin. |
| Menu bar | Saat aktif judul hanya sisa waktu; klik menampilkan timer jika tersembunyi, no-op bila sudah tampak. Saat idle, klik membuka Home. Tidak ada popover `MenuBarView` berisi preset dan kontrol timer. |

Kedua panel memakai clock dan session ID yang sama. Simpan posisi masing-masing dalam key berbeda; clamp ke visible frame saat monitor berubah. Uji Spaces/full screen/multi-display pada Mac nyata. Main app dapat dibuka melalui Dock saat sesi aktif, tetapi tidak otomatis tetap di depan. Ketika sesi berakhir, panel penguin selesai animasi lalu report muncul; tutup kedua panel hanya setelah transisi report aman.

### Gate akun dan trial

App menampilkan website login di browser sistem; pilihan identitas hanya Google/Apple. Callback kembali ke app melalui universal link atau custom URL dengan `state`/PKCE yang divalidasi. Token sesi disimpan di Keychain, bukan UserDefaults. Website menuntun pengumpulan kartu melalui Stripe Hosted Checkout dalam **setup mode** atau SetupIntent setara; data kartu dan Stripe secret key tidak masuk binary app. Backend, bukan Mac client, mengaitkan provider identity, Stripe Customer, kartu yang siap, trial, dan status entitlement.

Trial tujuh hari dimulai ketika `startFirstSession` berhasil **secara atomik di backend**. Jika offline sebelum aktivasi pertama, tampilkan permintaan koneksi; sesudah aktivasi, snapshot entitlement yang masih sah memberi akses offline sampai batas validitas yang tertera. Server membuat satu trial per akun, bukan satu trial per instalasi/perangkat. Setelah trial/akses berbayar berakhir, tampilkan gate sebelum Home tanpa menghapus database lokal. Saat session aktif sudah terlanjur dimulai, izinkan report selesai sebelum gate.

**Belum diputuskan:** apakah kartu otomatis ditagih sesudah hari ke-7 atau pengguna memilih Monthly/Yearly/Lifetime saat gate muncul. Jangan mengaktifkan tagihan otomatis atau menciptakan paket Stripe secara implisit. API dan UI billing tetap dibelakang `EntitlementProvider` sampai keputusan harga, persetujuan pembayaran, dan jalur distribusi dikunci.

### Gerbang distribusi sebelum billing produksi

Stripe-only untuk fitur digital adalah rencana **web/direct Mac** sampai jalur distribusi diputuskan. Pedoman App Store Apple saat ini mensyaratkan IAP untuk membuka fungsi digital, dengan pengecualian/tautan eksternal yang bergantung storefront dan entitlement; layanan multiplatform yang menerima pembelian web umumnya harus menyediakan IAP di app App Store juga. Jangan merancang Mac App Store/iOS seolah checkout Stripe wajib sudah pasti lolos review. Catat opsi distribusi sebelum implementasi pembayaran produksi: direct notarized Mac dengan Stripe; atau build App Store yang memiliki jalur StoreKit sesuai aturan; pertahankan `EntitlementProvider` yang bisa membaca keduanya ke satu akun. Ini adalah keputusan rilis, bukan alasan menunda engine sesi macOS. [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [Apple IAP multiplatform](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/), [Stripe Checkout setup mode](https://docs.stripe.com/api/checkout/sessions/create).

## 5. Peta kode: keadaan sekarang → target

### File yang sudah ada

| File | Fakta sekarang | Tindakan implementasi |
|---|---|---|
| `Qoma/Managers/AppDelegate.swift` | Launch sebagai menu-bar accessory, membuat `MenuBarController`, meminta semua permission analytics saat startup | Ubah startup ke access gate/Home; pasang URL callback; permission sesuai konteks. Pertahankan jalur preview Debug. |
| `Qoma/QomaApp.swift` | Hanya scene Settings kosong | Tentukan lifecycle main window yang bisa diakses Dock dan URL handling; hindari dua sumber pembuatan window. |
| `Qoma/Managers/FocusSessionManager.swift` | Singleton menggabungkan timer, tracker, sound, record dan break | Jadikan adaptor UI sementara atau ganti dengan `SessionCoordinator`; hapus `prepareBreak`, `breakDuration`, phase break. |
| `Qoma/Services/TimerService.swift` | Deadline in-memory, tidak menyimpan snapshot | Pindahkan perhitungan aktif/pause/restore ke clock yang dapat diuji dengan injected time. |
| `Qoma/Models/SessionState.swift` | `quickSession/taskPlan` dan break phases | Migrasi ke state sesi dan mode policy yang terpisah. |
| `Qoma/Services/ActivityTracker.swift` | Monitoring terikat analytics dan polling | Pisahkan sumber foreground activity untuk policy dari perekaman analytics; jangan gate reaksi visual pada setting analytics. |
| `Qoma/Services/BrowserActivityResolver.swift` | URL beberapa browser untuk analytics | Adapter domain Chrome/Safari bagi policy; nilai URL mentah jangan dibawa ke storage policy. |
| `Qoma/Managers/AnalyticsPermissionsManager.swift` | Prompt otomatis lewat AppDelegate | Jadikan permission request sesuai pilihan mode/website pada setup. |
| `Qoma/Managers/MenuBarController.swift` | Status item membuka `MenuBarView` popover | Status time-only dan aksi restore timer/Home; lepaskan popover setelah pengganti siap. |
| `Qoma/UI/MenuBar/MenuBarView.swift` | Preset/start/pause/cancel pada popover | Hapus dari target **setelah** semua kontrol punya tempat baru dan tes menu bar lulus. |
| `Qoma/Managers/WindowManager.swift` | Satu floating companion window dan scene | Pisahkan coordinator untuk timer, companion, overlay; pertahankan asset/scene lifecycle yang sudah benar. |
| `Qoma/UI/Floating/FloatingTimerWindow.swift` | View countdown tema lama | Restyle sesuai draft panel timer; data dari coordinator baru. |
| `Qoma/UI/Floating/Companion/CompanionPlayback.swift` | Timeline animasi dengan hitungan visual demo | Jadikan renderer/event consumer, bukan sumber reward yang disimpan. |
| `Qoma/UI/Floating/Companion/CompanionScene.swift` | SpriteKit scene untuk pose/proxy | Pakai scene/asset yang ada; tambahkan event deposit ber-ID dan policy reaction yang tidak membatalkan catch. |
| `Qoma/Models/FocusSessionRecord.swift`, `Qoma/Services/AnalyticsStore.swift` | Record/JSON lokal lama | Migrasi non-destruktif ke model baru; jangan menghapus riwayat user. |
| `Qoma/UI/SettingsView.swift` | Shell Settings gelap dengan layar percobaan kolam | Ganti shell dan nav sesuai Home qyube. Hapus entry fitur yang dibatalkan pada tahap implementasi. |
| `Qoma/UI/Main/AnalyticsDashboardView.swift` | Statistik Qoma lama | Adaptasi menjadi Insight; hapus target harian dan agregasi tag. |
| `Qoma/Assets.xcassets/Companion/` | Asset prototipe penguin/prop tersedia | Pakai sebagai visual tahap awal; jangan perlakukan fish/tree proxy sebagai item Catalog permanen. |

Source Xcode memakai synchronized group; file Swift baru yang diletakkan di `Qoma/` dan tes di `QomaTests/` harus tetap dicek membership/build. App target di project masih `macOS 11.5`, sedangkan rancangan sebelumnya meminta fitur SwiftData macOS 14+. Ubah minimum yang disetujui sebelum mengimpor SwiftData; audit dependensi target/tests dan migration path.

### File dan interface usulan (belum ada)

| Usulan lokasi | Interface utama | Tanggung jawab |
|---|---|---|
| `Qoma/Domain/Focus/FocusModels.swift` | `SessionDraft`, `FocusPolicyMode`, `SessionPolicy`, `FocusSession`, `SessionOutcome` | Tipe domain tanpa AppKit/SwiftUI. |
| `Qoma/Domain/Focus/FocusPolicyEvaluator.swift` | `evaluate(_:against:)` | Pure function app/domain precedence. |
| `Qoma/Domain/Focus/SessionClock.swift` | `start`, `pause`, `resume`, `remaining`, `activeSeconds`, `restore` | Satu sumber waktu dan boundary lima menit. |
| `Qoma/Domain/Focus/SessionCoordinator.swift` | `startSession`, `pauseSession`, `resumeSession`, `stopSession`, `completeIfDue`, `updateTask`, `allowForCurrentSession`, `restoreSession` | Mengorkestrasi state, persistence, dan satu active session. |
| `Qoma/Services/ForegroundActivityMonitor.swift` | `startMonitoring`, `stopMonitoring`, `activityStream` | Adapter `NSWorkspace` + resolver domain; hanya emit observasi. |
| `Qoma/Services/DistractionCoordinator.swift` | `consume(activity:)`, `reset` | Policy decision → companion cue, overlay, dan detour interval. |
| `Qoma/Domain/Catch/CatchEngine.swift` | `scheduleNextBite`, `beginReel`, `deposit`, `bankAtThreshold`, `cancelInFlight` | Identitas catch dan aturan reward; tidak bergantung frame SpriteKit. |
| `Qoma/Persistence/SessionRepository.swift` | `loadActive`, `saveActive`, `finalizeOnce`, `loadHistory` | Persistensi sesi idempotent, dengan implementasi SwiftData terpisah. |
| `Qoma/Persistence/CatchRepository.swift` | `saveProvisional`, `bank`, `listBanked`, `countByKind` | Ledger event; count Catalog diturunkan dari ledger. |
| `Qoma/Managers/FloatingTimerController.swift` | `show`, `hide`, `restore`, `updatePosition` | Jendela timer saja. |
| `Qoma/Managers/CompanionWindowController.swift` | `show`, `render`, `finish`, `updatePosition` | Jendela penguin; tak punya aksi user untuk dismiss saat active. |
| `Qoma/Managers/DistractionOverlayController.swift` | `show(decision:)`, `clear` | Overlay ikan sementara tembus klik; monitor-aware. |
| `Qoma/UI/Main/QyubeHomeView.swift`, `NewSessionView.swift` | `Focus / Catalog / Insight / Settings`, `Start` | Shell dan form berdasarkan konsep v3. |
| `Qoma/UI/Main/CatalogView.swift`, `InsightView.swift`, `FishingReportView.swift` | Views + query services | Collection/analytics/report tanpa tag/kolam. |
| `Qoma/Auth/AccessCoordinator.swift` | `refreshAccess`, `beginWebLogin`, `startFirstSessionTrial`, `canStartSession` | State login/trial/gate; dependency injected ke `SessionCoordinator`. |
| `Qoma/Auth/EntitlementProvider.swift` | `currentEntitlement`, `refresh`, `activateTrial` | Abstraksi backend/Stripe dan calon StoreKit; rahasia tidak di client. |
| `Qoma/UI/Access/SignInView.swift`, `CardSetupView.swift`, `SubscriptionGateView.swift` | Login/card/paywall states | Tampil sebelum Home menurut access state. |

Nama di tabel adalah target implementasi yang sengaja eksplisit agar agent berikutnya dapat menelusuri pekerjaan. Boleh menggabungkan file kecil bila itu membuat modul lebih dalam dan tidak mengubah kontrak fungsi/state.

### Data minimum dan ownership

```swift
struct SessionDraft {
    var taskTitle: String             // kosong diperbolehkan
    var plannedMinutes: Int           // 10...60 atau 180
    var policy: SessionPolicy
}
struct ActiveSessionSnapshot {
    let sessionID: UUID
    let accountID: String
    let startedAt: Date
    var deadline: Date
    var pausedAt: Date?
    var accumulatedActiveSeconds: TimeInterval
    var draft: SessionDraft
}
struct CatchEvent {
    let id: UUID
    let sessionID: UUID
    let kindID: String
    let depositedAt: Date
    var bankedAt: Date?
}
```

Snapshot tidak menyimpan gambar. Asset ditautkan dengan `kindID`. Tangkapan provisional hanya milik sesi aktif; pada lima menit aktif, deposit yang sudah terjadi dipindah ke ledger banked secara idempotent. Setelah ambang, setiap deposit langsung bank. Stop <5 menit mengembalikan provisional ke laut; stop ≥5 menit mempertahankan yang sudah banked. Tangkapan yang sedang di reel saat stop/completion tidak diberikan. Rare/legendary boleh muncul kapan pun; peluangnya tidak diikat pada selesainya timer.

Simpan domain analytics lokal hanya jika pengguna memberi izin yang terkait; jangan mengirim nama task, daftar app, domain, atau catch event ke server autentikasi kecuali diperlukan untuk fungsi yang dipilih pengguna. Partisi database lokal berdasarkan accountID supaya pergantian akun tidak mencampur koleksi. iCloud sync tetap opt-in dan tidak menyinkronkan active snapshot, permission, dan posisi panel.

## 6. Urutan implementasi untuk AI agent

Setiap fase menghasilkan satu perubahan yang dapat dijalankan/ditinjau. Jangan menjalankan seluruh migrasi sebagai satu patch besar. Kode belum dikerjakan pada sesi ini.

### Fase 0 — Validasi fondasi dan keselamatan migrasi

- [x] Catat versi scheme, macOS deployment target, entitlement, sandbox, jalur Sparkle/direct build, dan perilaku app saat launch saat ini.
- [x] Putuskan migrasi minimum macOS ke 14+ sebelum SwiftData; validasi mesin build dan target tes.
- [ ] Ambil fixture anonim dari format `AnalyticsStore` lama, uji migrasi non-destruktif, dan cadangkan data sebelum schema baru aktif.
- [ ] Uji teknis `NSWorkspace` foreground events, Chrome/Safari domain lookup, click-through overlay, Spaces/full screen, dan permission revocation dalam build sesuai target distribusi.
- [x] Tandai jalur billing/App Store sebagai release gate terpisah; jangan hardcode asumsi Stripe-only untuk binary App Store.

**Gate:** matriks kemampuan macOS nyata dan migrasi data terbukti; jangan menjanjikan domain overlay di sandbox bila spike gagal.

### Fase 1 — Domain sesi dan timer

- [x] Buat `FocusModels`, `SessionClock`, `SessionCoordinator` dengan dependency injection untuk waktu, repository, access, monitor, dan output visual.
- [x] Hapus route `prepareBreak` dan state break setelah jalur `completed → report` berfungsi.
- [x] Simpan active snapshot atomik; idempotent `completeIfDue`/`stopSession`; restore setelah relaunch tanpa timer kedua.
- [x] Pastikan task editable dan title terakhir berlaku untuk record sesi; tidak ada field tag baru.
- [x] Tulis tes batas 10/60/180, pause, wake/relaunch, deadline, interrupted, completed, dan trial yang berakhir saat sesi aktif.

**Gate:** sesi dasar selesai/berhenti/relaunch tepat satu kali tanpa UI baru dan tanpa report ganda.

### Fase 2 — Policy tiga mode dan permission

- [x] Implementasikan pure `FocusPolicyEvaluator` beserta tabel app/domain di §3.
- [x] Pisahkan `ForegroundActivityMonitor` dari `ActivityTracker` analytics lama; tidak ada permission request pada launch.
- [x] Tambahkan status unsupported/permission unavailable yang mempertahankan draft dan menawarkan Timer Only.
- [x] Implementasikan rule sementara sesi aktif dan perhitungan detour interval, tanpa menghentikan timer/catch.
- [x] Uji Chrome yang diizinkan = semua situs aman, domain-only exception, browser tak didukung, perubahan app cepat, own-app/System UI, dan permission dicabut.

**Gate:** tidak ada pemblokiran OS; keputusan policy deterministik dan efek selalu dapat dihentikan.

### Fase 3 — Home qyube dan dua panel

- [x] Bangun Home/New Session berdasar konsep v3, dengan sidebar Focus/Catalog/Insight/Settings dan form kanan.
- [x] Buat `FloatingTimerController` dan `CompanionWindowController` sebagai pengganti `WindowManager` tunggal; sambungan penuh ke `SessionCoordinator`.
- [x] Sambungkan pause/resume/stop dari timer panel; close timer hanya menyembunyikan panel, tidak stop.
- [x] Pastikan penguin terus tampil selama active/paused; kliknya restore timer panel.
- [x] Tambahkan overlay ikan yang mouse-transparent, multi-display aware, intensitas dibatasi, dan Reduce Motion.
- [x] Uji timer open/closed, menu bar no-op saat panel terbuka, Dock membuka Home, pindah Spaces/monitor, aksesibilitas keyboard/VoiceOver (tersedia secara kode; verifikasi manual di Mac nyata masih diperlukan).

**Gate:** draft visual dan interaksi dua panel dapat didemonstrasikan tanpa menyimpan reward palsu.

### Fase 4 — Catch ledger, Catalog, report, Insight

- [x] Jadikan `CatchEngine` sumber urutan wait 6–10 dtk, bite, reel cepat sesuai prototype, deposit, dan roll identitas; `CompanionScene` hanya menggambar cue/event.
- [x] Uji bank saat tepat 5 menit aktif, stop 4:59/5:00, deposit yang belum selesai, pause, gangguan app, serta idempotensi setelah relaunch.
- [x] Buat Catalog yang menampilkan semua definisi item, termasuk silhouette belum ditemukan; count berasal dari event banked. Gunakan asset proxy saat identitas art belum siap.
- [x] Buat Fishing Report completed dan compact interrupted; stop <5 menit menampilkan pengembalian lembut tanpa entry Catalog baru.
- [x] Adaptasi Insight Day/Week/Month/Year: focus time, completed/interrupted, tangkapan, distribusi judul tugas persis; tidak ada target harian atau tag.
- [x] Hilangkan entry layar percobaan fitur yang dibatalkan dari Settings/navigasi; simpan file desain lama sebagai arsip sampai proses bersih terpisah disetujui.

**Gate:** count Catalog dan report benar untuk ratusan event tanpa menduplikasi gambar/entri atau kehilangan data lama.

### Fase 5 — Akun, trial, gate, dan integrasi backend

- [ ] Buat website login Google/Apple dan callback app yang tervalidasi; simpan token di Keychain.
- [ ] Buat Stripe card setup di web, verifikasi di backend, dan state `readyForFirstSession` tanpa charge.
- [ ] Pada Start pertama, backend mengaktifkan satu trial 7 hari secara idempotent; app menerima bukti entitlement lalu memulai sesi. Jangan mulai sesi bila aktivasi gagal.
- [ ] Terapkan gate expired/unpaid sebelum Home, tetapi jangan memutus sesi aktif; data lokal tetap utuh saat logout, expiry, atau pembayaran gagal.
- [ ] Tampilkan informasi trial, tanggal berakhir, syarat tagihan/cancel, dan pilihan pembayaran sesuai keputusan billing produksi yang nanti dikunci.
- [ ] Uji dua akun pada satu Mac, login ulang, callback dibatalkan, offline entitlement masih valid, expiry offline, webhook duplikat, dan account restore di perangkat lain.

**Gate:** backend menjadi sumber akses tunggal; tidak ada Stripe secret/card di client; tidak ada trial berulang per instalasi.

### Fase 6 — Rekonsiliasi dan kesiapan rilis

- [ ] Perbarui `PRODUCT_SPEC.md`, `ROADMAP.md`, onboarding, README, dan copy pemasaran agar konsisten dengan keputusan tanpa tag/break/kolam/target harian dan paywall baru.
- [ ] Putuskan direct Mac versus Mac App Store, jalur IAP iOS, autocharge sesudah trial, paket harga final, serta bagaimana entitlement lintas provider disatukan.
- [ ] Uji offline/relaunch, Mac sleep, izin dicabut, accessibility, Reduce Motion, CPU/baterai scene, warna terang/gelap, ukuran panel asli, dan distribusi tertandatangani.
- [ ] Pertahankan iOS sebagai rencana terpisah; jangan mengimplementasikan fitur Screen Time atau sync timer pada fase macOS ini.

**Gate:** tidak ada klaim distribusi/billing yang melanggar jalur rilis yang dipilih; semua keputusan yang ditunda tercatat dan diuji.

## 7. Verifikasi minimum per commit

```sh
xcodebuild build -project qoma.xcodeproj -scheme Qoma -configuration Debug \
  -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO

xcodebuild test -project qoma.xcodeproj -scheme Qoma -configuration Debug \
  -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO
```

Tes terpenting berada di `QomaTests/` dan memeriksa transisi domain, evaluator aturan, batas bank, repository idempotent, serta pemulihan. Untuk AppKit/window/overlay, tambah pengujian manual nyata karena unit test tidak dapat membuktikan klik yang menembus jendela lain atau perilaku Spaces. Jangan mengubah `KIKI.md`, aset desain historis, atau file tidak terkait hanya untuk membuat build hijau.

## 8. Keputusan yang sengaja ditunda

1. **Billing produksi:** setelah tujuh hari, autocharge dari kartu tersimpan atau pilih paket lalu bayar? Harga final dan copy persetujuan belum dikunci. Agent tidak boleh mengaktifkan charge otomatis berdasarkan asumsi.
2. **Jalur distribusi:** direct Mac/Stripe, Mac App Store/StoreKit, dan iOS App Store memiliki aturan berbeda; pilih sebelum billing dikirim.
3. **Art koleksi:** ilustrasi per item, katalog awal dan varian animasi dapat dirinci setelah mesin sesi/ledger stabil. Prototipe fish/tree bukan identitas akhir item.
4. **Sync lintas perangkat:** akun mengenali entitlement; iCloud koleksi/riwayat tetap opsional. Skema merge final dikerjakan sesudah data lokal idempotent.
5. **Akurasi website mode:** bila Chrome/Safari domain lookup tidak dapat didukung aman pada target distribusi, lakukan evaluasi capability berdasarkan spike dan ubah UI secara jujur; jangan mengklaim kontrol per-domain yang tidak ada.

## 9. Catatan cabang dan perubahan yang harus dijaga

- Branch kerja perencanaan: `codex/kiki-flow-core`.
- `KIKI.md` telah muncul sebagai file belum dilacak dari pekerjaan sebelumnya; jangan membuangnya.
- Ada penghapusan yang sudah ada pada beberapa draft gambar `design/qyube-concepts-v1/` dan `design/qyube-concepts-v2/` di worktree pengguna. Jangan memulihkan atau menghapusnya tanpa permintaan.
- Checkbox fase 1–4 telah diperbarui sesuai implementasi yang sudah berjalan. Fase 5 (akun/trial/backend) dan fase 6 (distribusi/rilis) masih menunggu keputusan pengguna.

## 10. Riwayat keputusan yang sempat hilang saat rencana ditulis ulang

Bagian ini sengaja **dipertahankan sebagai sejarah**, bukan instruksi implementasi baru. Pada 1 Oktober, dokumen rencana lama ditimpa oleh kontrak teknis terkini; itu menghilangkan jejak mengapa arah produk berubah. Revisi selanjutnya harus **menambah catatan perubahan di bagian bawah**, bukan mengganti isi lama tanpa arsip. Untuk teks asli yang persis, Git menyimpan snapshot sebelum penulisan ulang pada `6eb2476:task_plan.md` (221 baris), pivot awal pada `1b33802:task_plan.md`, dan rencana awal pada `4c22775:task_plan.md`. Gunakan `git show <commit>:task_plan.md` untuk audit; jangan menganggap keputusan yang diberi status *superseded* di bawah masih berlaku.

| Tahap | Keputusan/cakupan yang terdokumentasi saat itu | Status sekarang |
|---|---|---|
| Rencana awal | Pomodoro, tangkapan penguin, Catalog, Aquarium, Insight, harga, sinkronisasi, dan kemungkinan iOS/Deep Focus dirancang dalam spesifikasi produk dan roadmap. | Rencana makro tetap arsip. Kontrak macOS pada §1 lebih baru. Aquarium dibatalkan, Deep Focus iOS terpisah. |
| Pivot macOS `1b33802` | Produk menjadi **qyube**, companion fokus Antartika dengan satu tugas, durasi, pilihan aplikasi, penguin yang memancing, dan visual friction alih-alih pemblokiran total. | Berlaku; rincian mode dan tugas mengikuti §1–3. |
| Konsep Home `b6c41e1` | Referensi `design/qyube-concepts-v3/01-home-floating-form.png` dipilih: latar putih hangat, sidebar, ilustrasi penguin di tengah, kartu New Session di kanan, aksen terracotta. | Berlaku; harus dicek pada app nyata, bukan hanya mockup. |
| Arah seni `13ad567` | `design/qyube-floating/ART_DIRECTION.md` menetapkan penguin watercolor tanpa kacamata, floe dan ember tetap pada anchor yang sama, transparansi panel, pose dan transisi. | Berlaku kecuali aturan `Continue`, tag, atau catch yang batal akibat distraksi. |
| Draft sesi aktif `96deb43` | Dua permukaan independen: timer sekitar 210 × 143 pt dapat ditutup; penguin sekitar 118 pt tetap hadir. Menu bar menampilkan waktu dan memulihkan timer tanpa popover. | Berlaku. Referensi `design/qyube-active-session-v1/`. |
| Asset dan animasi `1258029`–`6eb2476` | Asset pose/prop minimum dan prototipe SpriteKit dipakai sebagai representasi awal. Fish/tree hanyalah proxy visual; identitas asli tangkapan milik engine dan ledger. | Berlaku; jangan menghitung tangkapan dari frame/loop visual. |
| Kontrak prototype lama `6eb2476` | Saat itu task diwajibkan, app allow-list utama, tag masih opsional, Aquarium *deferred*, Home tidak bisa dibuka saat sesi, dan akhir timer menawarkan `Continue`/`Done`. | **Superseded**: task boleh kosong, tanpa tag, 3 mode, Aquarium dibatalkan, Home bisa dibuka dari Dock, akhir timer langsung report lalu `Mulai sesi lagi`. |
| Wawancara alur Kiki sesudah prototype | Dua panel tetap; timer bisa disembunyikan, penguin tidak; tidak ada break otomatis; trial 7 hari membutuhkan Google/Apple login dan kartu Stripe; setelah akses habis gate sebelum Home. | Berlaku sesuai §1–4. |
| Implementasi fase 0–4 pada `codex/kiki-flow-core` | Model sesi/policy/catch, Home awal, panel timer dan penguin, Catalog/Insight/report, serta test dasar masuk bertahap. | Harus dievaluasi berdasarkan **perilaku nyata**, bukan hanya checkbox/build. UI dan companion visibility memerlukan audit cabang ini. |

Catatan sejarah ini juga menjelaskan mengapa `PRODUCT_SPEC.md`, `ROADMAP.md`, dan sebagian teks desain tampak bertentangan. Jangan menghapusnya untuk menyembunyikan perubahan arah; tandai keputusan lama sebagai superseded dan arahkan agent ke §1 untuk perilaku terbaru.

## 11. Audit dan perbaikan UI macOS — 2 Oktober 2026

Keluhan pengguna: implementasi visual belum setara referensi, dan saat sesi dimulai hanya panel timer terlihat. Audit kode menemukan `CompanionWindowController.show()` membuat `CompanionScene` baru tetapi tidak memanggil `startSession()`. `CompanionScene` dimulai pada phase `.hidden`, sehingga panel transparan benar-benar ada namun semua sprite disembunyikan. Ini bukan masalah aset atau level window semata.

Kontrak UI untuk cabang `codex/qyube-ui-rework`:

- [x] Start scene saat panel penguin dibuat; simpan scene selama sesi, set pose tidur saat pause, jangan reset animasi pada setiap perubahan snapshot, dan buat cleanup jelas saat sesi selesai. Pisahkan klik untuk restore timer dari drag panel dengan ambang gerak kecil.
- [x] Pertahankan timer yang telah ditutup saat snapshot sesi berubah; menu bar/penguin hanya memulihkannya bila tersembunyi.
- [x] Ganti Home tiga kolom sempit yang tidak sesuai mockup: sidebar ±188 pt, ilustrasi di tengah, kartu kanan; jangan gunakan pose tunggal tanpa floe/ember sebagai gambar utama.
- [x] Buat Settings sebagai window native terpisah dengan `NavigationSplitView`, sidebar, toolbar, dan grouped Form. Hilangkan Aquarium dari navigasi baru; tetap simpan kode/desain prototype lama sebagai arsip hingga cleanup terpisah.
- [x] Buat timer panel ringkas seperti draft: close kecil, waktu dominan, task subtil, aksi pause/stop di menu, konfirmasi stop.
- [ ] Verifikasi pada build nyata: kedua panel terlihat saat Start; pause → penguin tidur; close timer → penguin tetap; klik menu bar → timer kembali; sesi selesai → kedua panel hilang dan report muncul.
- [ ] Bandingkan screenshot Home, Settings, dan panel dengan referensi desain pada ukuran window minimum dan normal; koreksi proporsi, clipping, kontras, serta VoiceOver.
- [ ] Jalankan build/test; catat hasil dan keterbatasan lingkungan bila pemeriksaan visual macOS tidak tersedia.

Skill `macos-settings-ui` memengaruhi Settings secara langsung: alur Settings tidak lagi placeholder di kartu kanan, melainkan `NSWindowController` dengan `NavigationSplitView` dan Form berkelompok. Skill ini tidak mengubah dua companion `NSPanel` menjadi window Settings.

**Verifikasi sementara:** build dan test Xcode lulus pada 2 Oktober. Pemeriksaan aplikasi native memperlihatkan Home dan Catalog dengan kontras terang, panel timer, serta panel penguin sebagai jendela terpisah. Ketika sesi di-pause, penguin memakai pose tidur; setelah timer ditutup, penguin tetap terlihat. Pemeriksaan klik penguin → timer dan klik menu bar → timer belum dapat dikonfirmasi secara visual melalui alat otomasi window nonactivating, sehingga checkbox integrasi di atas tetap terbuka. Uji UI juga membuat dua record sesi singkat `interrupted` pada akun lokal; jangan menyalahartikannya sebagai data pengguna sungguhan.

## 12. Pivot UI ringkas putih dan paket prototype — 2 Oktober 2026

Branch: `codex/qyube-compact-prototypes`, dibuat dari `codex/qyube-ui-rework` dengan perubahan lokal yang sudah ada tetap dipertahankan. Cakupan sesi ini adalah gambar prototype dan dokumentasi, bukan implementasi Swift.

**Aturan riwayat:** seluruh §1–11 di atas dipertahankan. Tambahkan keputusan baru sebagai bagian bertanggal; jangan mengganti task_plan dengan ringkasan fitur terkini. Bila ada konflik, gunakan keputusan terbaru yang secara eksplisit menggantikan keputusan lama dan tetap simpan alasan/perubahan arah sebelumnya.

### Keputusan visual terbaru

- Pengguna memilih alur jendela kecil seperti Kiki: Home langsung, tanpa sidebar, tombol New session membuka form; Insight, Catalog, dan gear berada di header.
- Setelah versi putih hangat, pengguna memilih putih netral yang lebih sederhana. Home kosong dan Home berisi riwayat menjadi referensi baru; lihat gambar 01 dan 02 pada [indeks prototype](design/qyube-compact-v1/README.md).
- Layout sidebar + kartu kanan dari §10/§11 dan `qyube-concepts-v3` kini **superseded untuk main UI**. Dokumen serta gambar lama tetap menjadi sejarah.
- Ilustrasi penguin di dalam main UI hanya penguin dan joran, tanpa es, ember, air, atau bayangan lantai. Gunakan identitas no-glasses dan variasi pose yang sudah ada. Perubahan ini tidak otomatis membuang props pada companion desktop.
- Dua panel sesi tetap: timer dapat ditutup, penguin tetap hadir. Tidak ada perubahan pada aturan sesi, tugas opsional, mode, catch banking, trial, atau entitlement karena mockup baru.
- Ukuran awal yang direkomendasikan sekitar 420 × 700 pt, dapat diubah ukurannya dan memiliki konten scroll. Ukuran final perlu uji native; jangan menafsirkan ukuran PNG sebagai point.

### Deliverable sesi ini

- [x] Simpan Home kosong dan Home berisi riwayat dari generasi sebelumnya.
- [x] Generate New Session, Home active, Fishing Report, Catalog, Insight Day, Insight Week sebagai pola Week/Month/Year, serta Settings dengan menu gear terbuka.
- [x] Simpan sembilan PNG di `design/qyube-compact-v1/`, berikut README dan PROMPTS.
- [x] Periksa visual; koreksi subtitle jumlah Catalog dan penempatan label Settings.
- [x] Tambahkan revisi arah seni ke `ART_DIRECTION.md` tanpa menghapus bagian lama.
- [ ] Review pengguna atas tujuh layar baru; jangan menandainya final-approved hanya karena generasi selesai.
- [ ] Implementasikan navigasi/window kompak sesudah review, lalu verifikasi ukuran nyata, keyboard, VoiceOver, Reduce Motion, dan kedua panel.

### Ketentuan untuk agent berikutnya

Mulai dari [README paket](design/qyube-compact-v1/README.md), terutama batas mockup: ruler harus mendukung 180 lalu 10–60 setiap menit, Day adalah halaman scroll, data grafik/count hanyalah contoh, dan menu Settings tidak boleh menggeser konten di bawahnya. Jangan hardcode 25 spesies, sample catch counts, durasi, atau status dari gambar. Rare/legendary tetap acak dan dapat muncul sejak awal; koleksi banked tetap milik pengguna. Report merangkum hasil, bukan memberi reward tambahan hanya karena completed. Catalog tetap satu entry per spesies, sedangkan kartu tangkapan Insight mempertahankan duplikat.

Settings dalam paket merupakan proposal halaman ringkas; menu gear dan struktur kontennya adalah referensi visual, bukan bukti bahwa billing/account actions sudah aktif. Scope macOS tetap berlaku. Layar login/trial/payment, state error, dan variasi paused/interrupted belum merupakan gambar tambahan dalam paket tujuh layar ini.

## 13. Implementasi UI compact macOS — 3 Oktober 2026

Branch: `codex/qyube-compact-ui`, dibuat dari `codex/qyube-compact-prototypes`. Perubahan lokal sebelumnya dibawa tetap utuh; penghapusan historis pada folder konsep v1/v2 sudah ada sebelum pekerjaan ini. Tidak ada reset, penghapusan dokumentasi lama, atau commit otomatis pada sesi ini. Section ini ditulis manual sesuai instruksi pengguna, tanpa workflow planning-with-files.

### Keputusan terbaru dan precedence

- Pengguna menyetujui rancangan halaman dan interaksi dari wawancara 12 poin, dengan satu koreksi: ukuran mengikuti Kiki dan proporsi prototype `design/qyube-compact-v1/`, bukan rekomendasi 420 × 700 pt. Implementasi awal memakai content window **360 × 610 pt**, kompak dengan konten scroll; resize tidak diaktifkan pada tahap ini. PNG bukan ukuran point. Ukuran native tetap dapat diperbaiki sesudah review visual.
- Settings berada dalam main window yang sama, termasuk akses `⌘,`. Ini menggantikan keputusan Settings window/sidebar terpisah pada §11, yang tetap disimpan sebagai sejarah.
- Main window: putih netral, header Close/qyube/Insight/Catalog/gear, Back untuk kembali ke Home, tanpa sidebar. Gear memakai menu overlay, tidak menggeser halaman.
- Gunakan **satu ilustrasi tangkapan bersama**, yaitu asset watercolor `CompanionFish` yang sudah dipakai animasi penguin. Catalog, report, kartu Insight, dan catch sprite desktop memakai gambar yang sama. Identitas spesies dan count tetap berbeda; art ini placeholder bersama, bukan perubahan daftar spesies atau peluang tangkapan.
- Floating timer dan penguin mengikuti `design/qyube-active-session-v1/`: timer 210 × 143 pt, stage companion 140 × 140 pt dengan floe/ember transparan; posisi masing-masing independen. Art main window hanya penguin dan joran, tanpa floe/ember.

### Implementasi dan peta kode

| Bagian | File / fungsi | Perilaku |
|---|---|---|
| Navigasi / cache tampilan | `Qoma/UI/Main/QyubeHomeView.swift`: `QyubeNavigation`, `refresh()`, `showReport(_:)`, `repeatSession(_:)` | Route Home/New Session/Catalog/Insight/Settings/Report. History dan catches dimuat saat perubahan data/navigasi, bukan setiap tick timer. Repeat mengisi draft sebelumnya dengan nama tugas terakhir; tidak auto-start. |
| Home | `CompactTodayView` dalam file Home | Today dari sesi tersimpan plus durasi aktif berjalan, tanpa menghitung ID aktif dua kali. Baris riwayat membuka report. Footer New session atau Show timer. |
| Shell native | `Qoma/Managers/QyubeAppCoordinator.swift`: `showHomeWindow()`, `onSessionEnded(_:)` | Satu main window dipertahankan ketika ditutup/dibuka kembali. Start menyembunyikan main window; akhir sesi membuka report di window yang sama. Kedua floating panel tetap terpisah. |
| Komponen bersama | `Qoma/UI/Main/QyubeCompactComponents.swift` | Tombol utama, format durasi, `QyubeCatchArt`, `QyubePenguinArt`, area drag header. Motion penguin mengikuti Reduce Motion sistem/pengaturan app. |
| Setup | `Qoma/UI/Main/NewSessionView.swift` | Tugas opsional, mode tiga pilihan, ruler 180 kemudian 10–60 setiap menit. Pemilihan aplikasi membuka sheet dengan pencarian daftar aplikasi terpasang; domain ada pada disclosure lanjutan. Draft dipertahankan saat berpindah halaman. |
| Catalog | `Qoma/UI/Main/CatalogView.swift` | Grid lima kolom pada lebar awal, urutan definisi stabil, filter All/Fish/Ocean finds, detail sheet. Undiscovered berupa siluet tanpa nama/rarity; discovered memperlihatkan nama/rarity/count. |
| Report | `Qoma/UI/Main/FishingReportView.swift` | Status, durasi nyata, total banked, jumlah spesies, paling banyak tiga kelompok highlight. Interrupted <5 menit menjelaskan pengembalian tangkapan. Melihat report lama ketika sesi aktif menawarkan Show timer. |
| Insight | `Qoma/UI/Main/InsightView.swift` | Day/Week/Month/Year, tanggal sebelumnya/berikutnya, kartu tangkapan individual Day, thumbnail individual untuk periode panjang, expanded list tanpa batas data, grabber/drag plus View all. Statistik completed/interrupted, perbandingan periode sebelumnya, distribusi tugas, daftar sesi, ringkasan tangkapan. |
| Settings | `Qoma/UI/Main/QyubeCompactSettingsView.swift`, `SettingsWindowController.compactSettingsAction`, commands di `QomaApp.swift` | Pengaturan sound/volume/auto-mute/Reduce Motion menggunakan key yang sudah ada. Settings route inline; account/billing belum terhubung. |
| Floating timer | `Qoma/Managers/FloatingTimerController.swift` | Tampilan dominan waktu; close hanya hide. Menu kecil pause/resume/stop/edit tugas; edit dalam popover. Panel dapat menerima keyboard untuk edit tanpa menjadi main window. |
| Menu bar | `Qoma/Managers/MenuBarController.swift`: `updateTitle(_:)` | Memperbaiki konfigurasi lama `imageOnly` yang menyembunyikan countdown: aktif memakai teks waktu tanpa ikon, idle kembali ke ikon. |
| Catch sprite | `Qoma/UI/Floating/Companion/CompanionScene.swift` | Semua catch memakai texture ikan yang sama; floe, ember, ukuran stage dan gerak utama tetap. |

### Ketentuan data dan batas tahap ini

- Riwayat/ledger asli tetap menjadi sumber data. Tidak mengisi database dengan contoh angka/species dari PNG. Roster masih definisi delapan item yang sudah ada; ekspansi aset menyusul.
- Grafik fokus mengelompokkan durasi nyata berdasarkan **waktu mulai sesi** (jam untuk Day, hari untuk Week/Month, bulan untuk Year). Ini bukan rekonstruksi interval aktif/pause per jam; label aksesibilitas menjelaskan basis pengelompokan.
- Satu kartu Day per catch ID; list paling bawah merangkum satu hari penuh. Grid periode panjang juga mempertahankan duplikat dan satu thumbnail per catch ID, hanya lebih kecil tanpa caption; agregasi spesies ada di ringkasan bawah. Render menggunakan lazy containers.
- Billing/login/trial/backend tetap fase terpisah. Menu Manage subscription/Sign out belum aktif; tidak dibuat endpoint atau alur pembayaran palsu. Help/feedback produksi belum memiliki tujuan yang dikonfigurasi.
- App rule editor membaca aplikasi terpasang. Perilaku monitoring/permission dan ledger mengikuti engine yang ada; pekerjaan ini tidak mengubah odds, pricing, sync, atau memulai iOS/Aquarium.

### Validasi

- [x] Xcode scheme `Qoma` diverifikasi; build Debug macOS arm64 berhasil dengan `CODE_SIGNING_ALLOWED=NO`.
- [x] Suite Xcode `QomaTests` berhasil pada 3 Oktober 2026: 143 tes, termasuk clock, coordinator, policy, catch banking, analytics dan companion playback.
- [x] Home, New Session, Catalog, Insight, dan Settings dibuka pada app native; `⌘,` menuju Settings dalam main window.
- [x] Pemeriksaan native Start → dua panel → pause (penguin tidur) → hide timer (penguin tetap) → klik penguin untuk restore timer → resume → stop → report → repeat dengan draft sebelumnya. Snapshot aktif juga pulih setelah app diluncurkan ulang selama uji.
- [x] Stop singkat menampilkan pengembalian tangkapan; stop setelah lima menit menampilkan banked catches. Catalog/Insight membaca hasil yang sama, View all Day memperluas dari enam menjadi seluruh dua belas event uji.
- [ ] Klik status menu bar secara langsung serta drag grabber, edit task via popover, dan report countdown-completed masih memerlukan pemeriksaan native terpisah; source/tes domain tidak menggantikan verifikasi interaksi tersebut.
- [ ] QA lintas Spaces/full screen/multi-display serta VoiceOver menyeluruh pada Mac nyata tetap perlu sebelum rilis.

Build pertama mengalami pembatasan cache Xcode oleh sandbox; dijalankan ulang dengan izin Xcode. Dua perbaikan compile/lint: tambahkan import Combine untuk model navigasi dan ganti nama scalar `count` menjadi `catchCount` agar tidak terkena rule collection `empty_count`. Warning historis lint/Copy Bundle Resources Info.plist masih ada; keberhasilan build bukan klaim seluruh warning sudah dibersihkan.

Smoke test membuat dua record lokal `UI verification — compact` dan `UI verification — panels` (keduanya interrupted), serta 12 banked catches dari sesi panel yang lebih panjang. Data uji ini tidak dihapus otomatis dan bukan data contoh yang disisipkan ke database. Tidak ada sesi uji yang dibiarkan aktif pada akhir pemeriksaan. Readout timer kini mempunyai observable model sendiri agar pembaruan angka tidak mengganti root view/menu setiap detik; companion yang sudah terlihat tidak diangkat ulang pada setiap snapshot.

## 14. Perencanaan efek visual aplikasi yang melanggar aturan — 4 Oktober 2026

Branch dokumentasi/perencanaan: `codex/distraction-effects-plan`, dibuat dari `codex/qyube-compact-ui` dengan perubahan lokal yang sudah ada tetap dipertahankan. Cakupan turn ini hanya memperbarui rencana; tidak ada kode aplikasi yang diubah atau dijalankan. Perubahan dokumentasi ini boleh di-commit sendiri tanpa memasukkan perubahan kode lokal lainnya.

Bagian ini memperbarui desain efek distraction dari §8 dan art direction §16. Catatan historis tetap dipertahankan. Prototype revisi: [ice flower v2](design/qyube-distraction-v1/01-ice-flower-v2.png), [dim/bright storyboard](design/qyube-distraction-v1/02-dim-bright.png), dan [art direction §16](design/qyube-floating/ART_DIRECTION.md#16-app-window-distraction-effects--2026-10-04) beserta koreksi v2 di bagian bawahnya.

### Keputusan yang dikonfirmasi

- Efek berlaku untuk **Allowing dan Blocking** saat aplikasi aktif melanggar policy sesi. Timer only tidak menampilkan efek.
- Sasaran visual adalah **jendela aktif di depan** dari aplikasi yang melanggar. Jika aplikasi memiliki banyak jendela dan fokus berpindah, efek mengikuti jendela aktif. Efek hanya dirender di batas jendela tersebut; desktop, menu bar, Dock, aplikasi lain, timer qyube, dan panel penguin tidak berubah.
- Aplikasi tetap dapat dipakai: panel efek nonaktif untuk mouse dan keyboard. Pengguna dapat mengetik, klik, scroll, menutup jendela, serta berpindah aplikasi.
- Pilih satu variasi acak ketika aplikasi/jendela yang melanggar menjadi aktif. Variasi **tidak berubah selama target yang sama tetap di depan**. Saat aplikasi pelanggar lain menjadi aktif, pilih variasi baru secara acak; ia boleh sama atau berbeda. Tidak ada pergantian efek berdasarkan timer ketika pengguna masih berada pada aplikasi/jendela yang sama. Rekomendasi probabilitas awal 50:50, dapat dituning setelah evaluasi.
- Saat target kehilangan fokus ke aplikasi yang diizinkan, jendela diminimalkan/tidak terlihat, sesi pause/selesai, atau policy tidak lagi menandainya sebagai distraction, overlay disembunyikan segera. Episode baru dimulai lagi dengan kepadatan/intensitas awal.
- **Ice flower:** kepingan snowflake biru muda bercabang, tersebar di seluruh jendela dengan celah yang menjaga keterbacaan dan klik. Mulai 6; tambah 4 setiap 10 detik; batas 24. Kepadatan hanya bertambah selama episode target aktif.
- **Dim/bright:** pose berdiri dengan kedua flipper terangkat berarti terang; pose membungkuk dengan kedua flipper lurus ke depan selaras dengan lapisan gelap transparan pada jendela sasaran. Opasitas gelap maksimal sekitar 35%; siklus awal sekitar 8 detik, semakin cepat hingga batas 3 detik. Perubahan halus, tidak berkedip/strobe, konten tetap terbaca.
- Respect Reduce Motion: pose marah statis, snowflake statis, atau veil redup statis; tanpa lompatan dan siklus terang/redup bergerak. Feedback logis tetap muncul.
- Jika batas jendela sasaran tidak dapat ditentukan dengan aman, sembunyikan overlay. Jangan pernah jatuh kembali ke overlay seluruh layar.

### Fakta kode saat ini

- `Qoma/Services/ForegroundActivityMonitor.swift` saat ini memantau `NSWorkspace.didActivateApplicationNotification` dan polling 1 detik, lalu mengirim bundle ID/nama/domain aplikasi aktif. Belum membawa identitas window aktif atau bounds.
- `Qoma/Services/DistractionCoordinator.swift` mengevaluasi policy dan menerbitkan `isDistractionActive`/`currentDecision`.
- `Qoma/Managers/QyubeAppCoordinator.swift` mengikat status tersebut ke overlay controller.
- `Qoma/Managers/DistractionOverlayController.swift` saat ini membuat satu `NSPanel` sebesar `NSScreen.main.frame`, berada di level floating, menutup sendiri setelah 2,5 detik, dan merender cue ikan. Ini perlu diganti; sifat click-through dan Reduce Motion yang sudah ada dipertahankan.

### Rencana implementasi bertahap — belum dieksekusi

1. **Spike identifikasi jendela dan urutan layer.** Tambah representasi target window dengan PID, window ID, bounds, screen/space, visibility dan waktu observasi. Evaluasi `CGWindowListCopyWindowInfo` untuk menemukan jendela on-screen teratas milik PID frontmost serta pembaruan bounds saat resize/move. Pastikan panel transparan dapat berada tepat di atas target window dan tetap di bawah jendela yang menutupinya, tanpa mengambil fokus/input. Verifikasi implikasi aksesibilitas/permission sebelum menambah permission baru. Jika tracking gagal/ambigu, sembunyikan efek; fallback global dilarang.
2. **Model episode distraction.** Ubah event aplikasi foreground menjadi episode yang punya identitas target window dan policy decision. Ketika target berubah, akhiri episode lama dan buat episode baru; untuk target yang sama pertahankan `selectedEffect` acak dan `startedAt` sehingga variasi serta eskalasi stabil. Resolusi policy atau hilangnya target menutup episode dan membersihkan overlay. Timer, catch ledger, dan status completed/interrupted tetap tidak disentuh.
3. **Renderer window-scoped.** Refactor `DistractionOverlayController` dari panel satu layar menjadi panel transparan click-through yang mengikuti frame target dan screen backing scale. Gunakan level/order relatif terhadap target (bukan `.floating` global); hitung clipping sesuai rounded window shape bila dapat dilakukan tanpa menangkap isi aplikasi. Perbarui frame pada perubahan target, posisi, ukuran, screen, Space/fullscreen; jangan tampil di depan window tak terkait. Hide saat minimization/occlusion atau batas tidak valid.
4. **Efek Ice flower.** Buat sprite transparan snowflake biru muda (beberapa bentuk ringan) sebagai layer tiled/instanced. Seed/random placement per episode untuk komposisi stabil; spawn 6 awal, tambah 4/10s sampai24. Pakai alpha/ukuran bervariasi, jangan menutupi satu area terlalu rapat; Reduce Motion mempertahankan posisi statis. Jangan memakai keseluruhan mockup atau screenshot sebagai texture.
5. **Efek Dim/bright dan karakter.** Buat aset transparan penguin untuk pose flipper-up, bow-forward, marah-hop dan steam puff, dengan anchor karakter, floe, dan bucket tetap registrasi. Controller timeline bersama menggerakkan pose flipper-up → bow-forward → flipper-up dan opasitas veil pada target window. Durasi siklus turun bertahap dari8 ke3s selama episode; cap veil35%, transisi mulus. Reduce Motion mengganti timeline dengan pose dan veil statis.
6. **Integrasi policy dan cleanup.** Update binding `QyubeAppCoordinator` agar meneruskan episode/target, bukan memunculkan pulse 2,5 detik. Mode Allowing/Blocking mengikuti `FocusPolicyEvaluator`; Timer only tidak membuat episode. Hapus efek segera saat app/window berubah ke keadaan aman, pause/stop/session end, app tutup/minimize atau izin monitoring hilang. Jangan mengganggu aktivitas tracker, analytics consent, maupun timer.
7. **Tuning visual, performa dan QA.** Verifikasi target window normal/resizable, app dengan banyak window, window tertutup window lain, minimize/restore, fullscreen, berpindah Spaces, dua monitor berbeda scale, perubahan ukuran/posisi, pergantian offending app, kembali ke app yang diizinkan, mode Allowing dan Blocking, pause/end, Reduce Motion serta input keyboard/mouse. Uji bahwa efek tidak terlihat pada menu bar/desktop/window lain/timer/companion. Ukur jumlah sprite dan pembaruan frame; hentikan animasi yang tak perlu saat episode hilang.

### Kriteria penerimaan

- [ ] Saat app yang melanggar menjadi frontmost, overlay muncul di atas jendela aktif yang benar; jendela lain dan desktop tetap bersih.
- [ ] Snowflake tersebar seperti referensi user, meningkat 6 → +4 tiap10 detik → max24; aplikasi tetap dapat digunakan.
- [ ] Varian dipilih acak per aktivasi target, tetap sama selama target itu aktif, dan undian baru terjadi saat target offending berubah. Tidak ada timer yang mengganti variasi pada target sama.
- [ ] Dim/bright menyelaraskan pose dengan veil; siklus 8→3 detik dan veil sampai35%, tanpa strobe.
- [ ] Allowing/Blocking memberi efek hanya pada activity yang dievaluasi melanggar; Timer only tidak menampilkannya.
- [ ] Reduce Motion menghilangkan hop/pulse tetapi tetap memberi cue; efek menghilang segera setelah kondisi distraction berakhir.
- [ ] Overlay click-through, tidak mengambil key/main focus, tidak mengubah layar eksternal secara global dan tidak pernah fallback ke seluruh display.
- [ ] QA window bounds/layer/Spaces/fullscreen/multidisplay selesai sebelum menyebut dukungan produksi; keterbatasan sistem didokumentasikan.

Tidak ada implementasi, build, atau test yang dilakukan untuk section rencana ini. Setelah rencana dan commit dokumentasi ditinjau, implementasi Swift dan produksi aset animasi menjadi fase berikutnya.

### Implementasi awal — 4 Oktober 2026

Permintaan berikutnya memulai implementasi pada branch yang sama. Catatan perencanaan di atas dipertahankan sebagai riwayat keputusan; status berikut menjelaskan pekerjaan kode yang sudah dilakukan, bukan menghapus rencana semula.

- [x] `DistractionTargetWindowLocator` mencari window on-screen milik PID aplikasi frontmost, membaca bounds WindowServer, dan menolak target yang tidak valid. Tidak ada fallback panel sebesar layar.
- [x] `DistractionOverlayController` memakai panel transparan click-through sebesar window sasaran, dipesan tepat di atas nomor window tersebut dan diperbarui setiap 0,2 detik. Episode efek menyimpan PID, waktu awal, seed snowflake, dan varian acak; pergantian aplikasi menutup episode lama dan dapat mengundi varian baru.
- [x] Ice flower dirender dengan vektor bercabang di `Canvas`: 6 awal, bertambah 4 setiap 10 detik, batas 24. Dim/bright memakai veil hitam maksimal 35% dan siklus halus 8→3 detik. Keduanya menggunakan clock episode yang sama dengan panel penguin.
- [x] Dua pose penguin transparan diproduksi untuk tangan terangkat dan membungkuk; animasi karakter berpindah pose selaras dengan veil. Varian ice flower memakai pose hop marah dan puff/asap. Reduce Motion mempertahankan cue statis.
- [x] Integrasi coordinator mengaktifkan monitoring hanya pada sesi aktif dengan mode Allowing/Blocking, membersihkan overlay saat pause/stop/safe app, dan menjaga jendela qyube sendiri aman agar kontrol sesi tetap dapat diakses.
- [x] Build Debug macOS arm64 berhasil. Tiga tes `DistractionMotionTests` lulus untuk eskalasi snowflake dan fase redup–terang.
- [ ] QA visual/input langsung pada window aplikasi lain, banyak window, minimize/restore, fullscreen, Spaces, monitor kedua, skala berbeda dan Reduce Motion pada Mac nyata. Urutan window lintas-proses dan full-screen tidak dianggap terverifikasi hanya karena build berhasil.

Aset pose ada di `Qoma/Assets.xcassets/Companion/CompanionPoseLightsUp.imageset` dan `CompanionPoseLightsBow.imageset`. Prompt produksi terdokumentasi di `design/qyube-distraction-v1/PRODUCTION_ASSET_PROMPTS.md`. Perubahan code/data lokal lain pada branch ini tidak dibersihkan atau dimasukkan sebagai bagian dari pekerjaan efek.

## 15. Perbaikan visual distraction dan sound effect — 4 Oktober 2026

User menguji implementasi §14 dan melaporkan gerak penguin kurang halus, snowflake terlalu sedikit/tidak terasa bertambah, serta redup–terang tidak terlihat bekerja. User juga menyediakan `ice-freezing.mp3` dan `light-switch.mp3`. Seluruh perubahan sebelumnya disimpan menggunakan `git add .` pada commit `242902f`; perbaikan dilanjutkan di branch `codex/distraction-animation-polish`.

### Temuan dan perubahan

- Transisi penguin sebelumnya mencampur alpha dua ilustrasi utuh yang bentuknya berbeda, sehingga muncul bayangan/gambar ganda. Dim/bright kini menggerakkan head, torso, dan kedua flipper dari aset watercolor yang sama secara berkesinambungan. Ice memakai pose hop yang telah ada, dengan antisipasi, loncatan, pendaratan dan puff berbentuk awan. SpriteKit dirender 60 fps; floe dan ember tetap pada anchor semula.
- Renderer SwiftUI terpisah berhasil bergerak pada pemeriksaan awal; jadi kegagalan pengguna tidak dinyatakan sebagai bukti bahwa semua `TimelineView` berhenti di background. Integrasi sekarang memakai `DistractionEffectView` AppKit dan clock controller eksplisit 30 fps untuk drawing serta audio. Pengujian mempertahankan satu episode melalui policy update berulang hingga 51 detik.
- Panel menggunakan level tepat di atas layer target dan frame window tersebut. Area jendela lain yang berada di depannya dipotong dari renderer; panel floating qyube juga dilindungi. Panel tidak dapat menjadi key/main window dan mengabaikan input. Bila target tidak tersedia, episode dan audio dihentikan.
- Snowflake diperbesar, ditambah cabang, dan disebar pada cell yang diacak agar tidak menumpuk di satu sudut. Aturan tetap 6 awal, +4 setiap 10 detik, maksimal24. Muncul dengan pertumbuhan/fade singkat; setelah menetap tidak digambar ulang tanpa perubahan.
- Monitor fokus sebelumnya meminta URL browser melalui AppleScript pada setiap polling. Sekarang lookup hanya dilakukan bila ada aturan domain yang masih perlu diperiksa; app yang sudah diizinkan/diblokir secara eksplisit tidak memerlukan lookup. Ini mengurangi pekerjaan sinkron pada jalur UI untuk penggunaan app-level yang disepakati. Analytics terpisah tidak diubah.

### Audio

- Kedua MP3 dikemas sebagai `NSDataAsset` (`IceFreezingSound` dan `LightSwitchSound`); file sumber user tetap disimpan.
- Satu suara es per batch snowflake, bukan per keping atau frame. Klip dimainkan 1,4 detik lalu fade-out 0,2 detik.
- Satu suara sakelar pada tiap perubahan terang→redup atau redup→terang, mengikuti fase visual. Tidak ada burst suara saat banyak frame terlewat.
- Volume mengikuti slider sound dengan gain efek0,65. Toggle `Distraction sound effects` tersedia di Settings. Pause, safe app, kehilangan target dan session end menghentikan audio. Reduce Motion memakai veil statis tanpa bunyi sakelar berulang; batch es tetap dapat berbunyi.

### Verifikasi dan batas

- Tes integrasi mencakup akumulasi renderer lewat repeated policy updates, pixel alpha veil, area occlusion yang tetap transparan, input click-through, resource MP3 yang dapat didekode, satu cue per transisi, dan app-level policy yang melewati browser automation.
- Render native penguin serta contoh 6/10/18/24 snowflake dan bright/mid/dark/bright disimpan di `design/qyube-distraction-v1/native-polish-check/`. Gambar ini berasal dari renderer aplikasi, bukan gambar AI baru.
- Mode Debug `--companion-snapshots <directory>` dan `--distraction-snapshots <directory>` membuat pemeriksaan ulang tanpa membuat focus session atau catch ledger. Tes fixture tidak menggantikan QA semua aplikasi, Spaces, fullscreen dan dua monitor nyata.
- Hasil akhir: build Debug arm64 berhasil; 30 tes unik dari `DistractionIntegrationTests`, `DistractionMotionTests`, `CompanionPlaybackTests`, dan `FocusPolicyEvaluatorTests` lulus. Pemeriksaan native menghasilkan `overlayAboveTarget=true`, `clickThrough=true`, count6/10/18/24 dan opacity0/0,175/0,35/0. Warning historis di area lain masih ada.

## 16. Perbaikan hasil audit flow — 8 Oktober 2026

### Urutan dan cakupan

- Semua perubahan yang sudah ada sebelum audit disimpan terlebih dahulu pada branch sebelumnya melalui commit `32a3665` (`chore: save existing distraction polish work`). Implementasi audit dikerjakan pada branch baru `codex/fix-session-ledger-audit`.
- Temuan audit website poin 15 dan 16 sengaja dilewati sesuai arahan pengguna; tidak ada source/copy website yang diubah.
- Login/trial/backend (temuan 9) belum dapat diimplementasikan dari repo macOS ini: tidak ditemukan website auth, service backend, OAuth callback, Keychain token flow, atau entitlement API. Jangan membuat gate lokal palsu; lanjutkan setelah backend/kontrak auth tersedia.

### Perubahan yang diterapkan

- Sesi kini menyimpan active segment, terminal timestamp, dan interrupted reason. Restore sesi pause/resume tidak lagi menghitung segmen aktif lama dua kali; active seconds dibatasi pada planned duration agar sleep/wake setelah deadline tidak menggelembungkan durasi.
- Start/pause/resume/edit/stop/completion hanya memperbarui state UI setelah snapshot berhasil ditulis. History finalization memeriksa decode/write, deduplikasi ID, dan membiarkan terminal snapshot tetap ada untuk recovery bila finalisasi gagal. Recovery menyelesaikan record terminal dan menerapkan aturan bank/discard yang sama.
- Ledger catch sekarang menyimpan event banked per ID (idempotent dan biaya tulis tetap per event), tetap membaca file aggregate lama, mencari provisional hanya pada session ID terkait, dan menghapus event provisional setelah bank. Hasil catch baru diumumkan ke companion setelah persistence berhasil.
- Loop visual companion tetap dekoratif; hitungan/reward hanya bertambah dari event catch yang tersimpan. Semua delapan item di katalog kini punya peluang roll; peluang ocean-find dibagi ke stick, pebble, dan shell.
- Riwayat `AnalyticsStore` lama dimigrasikan satu kali secara idempotent ke history sesi baru, mempertahankan UUID dan file sumber lama. Kegagalan baca/tulis tidak menandai migrasi selesai dan dapat dicoba ulang.
- Quit saat active/paused meminta konfirmasi dan finalisasi interrupted harus sukses sebelum aplikasi ditutup.
- Browser-domain lookup dipindahkan dari main thread ke antrean serial; hasil stale dibuang. Safari/Chrome dipilih eksplisit pada aturan website; permission Apple Events diminta saat Start, bukan saat launch. Domain blocking gagal tertutup (`noDomainRead`) jika aturan blocked domain aktif tetapi URL tidak terbaca.
- Tes coordinator memakai folder temporary unik dan menghapusnya setelah tes, bukan singleton/Application Support. Ditambah regresi untuk timer overshoot, fail-closed domain, katalog, terminal recovery, dan catch companion.

### Ditunda / batas verifikasi

- Temuan 14 (membersihkan flow legacy) belum dihapus: `--companion-preview`, menu debug, dan pemeriksaan visual masih memanggil `WindowManager`/flow lama. Hapus setelah preview dipindah ke controller baru dan dites agar developer tooling tidak ikut rusak.
- Rules berbasis website hanya dijamin untuk Safari/Chrome; browser lain tetap dinilai sebagai aplikasi keseluruhan. Verifikasi prompt Apple Events dan pencabutan izin secara manual pada macOS masih diperlukan.
- `xcodebuild -project Qoma.xcodeproj -scheme Qoma -configuration Debug -destination 'platform=macOS' build` berhasil. Test suite tidak dijalankan pada turn ini; perubahan tes sudah diisolasi untuk run berikutnya.

## 17. Rencana revisi alur menu bar dan jendela utama — 10 Oktober 2026

**Status:** alur inti telah diimplementasikan pada branch `codex/menubar-first-plan-2026-10-10`; pemeriksaan interaksi manual pada Mac masih terbuka. Bagian ini mengungguli keputusan UI/alur di bagian 1–15 yang bertentangan, terutama Home/New Session, judul tugas, aturan per sesi, klik status item, Dock, dan Fishing Report otomatis. Aturan domain, penghitungan waktu aktif, ledger tangkapan, recovery, serta perbaikan audit bagian 16 tetap berlaku. Jangan mengubah data lama secara destruktif.

**Dasar pembandingan:** `task_plan.md` tidak ada di branch `main`; perilaku lama diperiksa langsung pada `MenuBarView.swift`, `MenuBarController.swift`, dan `FocusSessionManager.swift` di branch itu. Tombol Restart lama memanggil `start()` lagi, yang membuat record analytics baru tanpa mempertahankan identitas sesi lama. Permintaan produk sekarang adalah **satu sesi logis saat Restart**, jadi perilaku visual menu bar diambil dari `main`, sedangkan semantik ID/persistence harus diperbaiki di coordinator baru. Branch `main` juga membuka panel untuk break ketika countdown habis; fase ini mengikuti keputusan dokumen saat ini untuk tidak memakai break otomatis.

### Keputusan produk dan batas fase

| Area | Alur target |
|---|---|
| Pusat interaksi | qyube berjalan sebagai aplikasi menu bar. Saat launch normal, jendela utama tidak dibuka. Klik ikon menu bar membuka panel ringkas untuk memilih durasi, Start, Pause/Resume, Restart, Stop, membuka aplikasi utama, Settings, dan Quit. Kontrol sesi memakai satu `SessionCoordinator`/clock aktif; jangan menghidupkan kembali `FocusSessionManager` lama sebagai sumber state kedua. |
| Dock dan jendela | Saat jendela utama tertutup, aplikasi bersifat accessory dan tidak menampilkan ikon Dock. Ikon Dock muncul ketika jendela utama dibuka; menutup jendela menyembunyikannya kembali tanpa menghentikan sesi. `Open qyube` di panel menu bar selalu dapat membuka jendela utama. Quit adalah aksi terpisah. |
| Durasi | Pilihan awal 25 menit; preset 10/25/60 menit; pilihan manual 1–60 menit mengikuti kontrol sederhana branch `main`. Durasi terakhir yang dipilih disimpan untuk Start berikutnya. Istilah Pomodoro di fase ini hanya berarti countdown fokus; tidak ada break atau siklus otomatis. Pilihan khusus 180 menit dari rancangan lama tidak menjadi bagian panel ringkas fase ini. |
| Identitas sesi | Pengguna tidak diminta memberi nama sesi/tugas dan tidak melihat form New Session. Sesi baru memakai label netral `Focus session` pada riwayat dan aksesibilitas. Data historis yang sudah punya judul tetap dibaca; jangan hapus atau ubah judul lama saat migrasi. Distribusi berdasarkan judul tugas baru tidak relevan, sedangkan metrik fokus, waktu, aplikasi, domain, dan tangkapan tetap ada. |
| Aturan fokus | Mode `timerOnly`/`allowing`/`blocking`, daftar aplikasi/domain, dan browser pilihan menjadi preferensi global persisten di Settings; `timerOnly` adalah default pertama kali. Daftar Allowing dan Blocking disimpan terpisah ketika mode berganti. Saat Start, salin aturan saat itu ke snapshot sesi agar riwayat dan evaluasi sesi stabil; perubahan Settings berlaku untuk sesi berikutnya, bukan mengubah sesi aktif diam-diam. Jika izin yang diperlukan tidak tersedia, tampilkan keadaan izin dan opsi Timer Only sebelum Start, jangan mengklaim aturan domain sedang bekerja. |
| Panel floating | Saat active/paused, penguin dan timer tampil otomatis. Pause membuat penguin tidur. Menutup timer hanya menyembunyikan timer; penguin tetap tampil dan dapat memulihkan timer. Preferensi `Hide floating timer` di Settings berlaku langsung dan tetap tersimpan untuk sesi berikutnya; menu bar tetap menyediakan kontrol sesi. Saat idle kedua panel tidak tampil. |
| Selesai | Countdown nol menghasilkan satu sesi `completed`. Penguin/timer menutup setelah transisi aman; panel menu bar ringkas muncul dengan `Start again` dan `Lihat hasil tangkapan`. Jendela utama tidak terbuka otomatis. Tombol hasil membuka **Insight** pada hari/sesi yang baru selesai, karena Insight menampilkan event tangkapan individual; Catalog tetap halaman koleksi spesies keseluruhan. Panel selesai memuat ringkasan singkat saja, bukan Fishing Report besar. |
| Stop/Restart/Quit | Stop meminta konfirmasi dan menyimpan `interrupted` dengan waktu aktif nyata. Restart mengulang countdown durasi sesi saat ini **dalam sesi logis yang sama**: ID sesi tetap, tidak menambah record interrupted/completed, dan tidak membuat reward tambahan. Quit ketika active/paused meminta konfirmasi `Stop and Quit`, menyimpan interrupted lebih dulu, lalu keluar; menutup jendela utama bukan Quit. |
| Akses akun | Implementasi auth, trial, langganan, pembayaran, serta gate akses ditunda pada fase ini. Jangan menambahkan gate lokal palsu atau mengubah penyimpanan riwayat/tangkapan karena penundaan ini. |

### Urutan pengalaman pengguna

```text
Launch → hanya ikon menu bar; tidak membuka main window
Klik ikon → panel ringkas idle (durasi 25m awal; preset/manual; Start; Open qyube; Settings; Quit)
Start → snapshot sesi dengan aturan global saat Start → penguin + timer floating
      → panel menu bar active: sisa waktu, Pause, Restart, Stop, Open qyube
Pause → waktu aktif dan proses tangkapan berhenti; penguin tidur; Resume dari panel
Restart → countdown kembali penuh dalam ID sesi yang sama; tidak finalisasi sesi
Stop + konfirmasi → interrupted; aturan bank/discard tangkapan saat ini → panel ringkas idle
Countdown nol → completed; finalisasi sekali → panel selesai ringkas
               ├─ Start again → sesi baru memakai durasi terakhir dan aturan global terbaru
               └─ Lihat hasil tangkapan → jendela utama / Insight / hari atau sesi tersebut
Open qyube → jendela utama pada Analytics; pilih Insight, Catalog, Calendar, Settings
Tutup jendela → kembali ke menu bar; sesi tetap berjalan bila aktif
Quit saat aktif → konfirmasi → simpan interrupted → keluar
```

Klik status item selalu membuka/menutup panel menu bar sesuai keadaan idle, active, paused, atau completed. Karena itulah perilaku lama `klik active → restore timer / no-op` pada bagian 1, 4, dan 12 diganti. Pengguna tetap bisa memulihkan timer dari penguin atau dari aksi ringkas di panel menu bar. `Start again` baru membuat sesi **setelah** sesi terdahulu selesai; berbeda dari `Restart` yang mempertahankan sesi aktif.

### Struktur jendela utama

- Satu jendela utama dengan warna putih/hangat dari UI qyube saat ini dan bentuk sidebar native seperti `Qoma/UI/SettingsView.swift`: lebar sidebar sekitar 200 pt, jendela minimum sekitar 700 × 520 pt. Pertahankan komponen dan isi yang sudah bekerja; ubah shell/navigasi hanya sejauh perlu. Referensi `SettingsView.swift` di `.agents/skills/macos-settings-ui/references/` menjadi acuan pola, bukan source yang langsung menggantikan UI produk.
- **Analytics** adalah halaman awal jendela, memakai `Qoma/UI/Main/AnalyticsDashboardView.swift`; heatmap-nya ada di `Qoma/UI/Components/AnalyticsHeatmapView.swift`. Dashboard lama masih membaca `AnalyticsStore`, sedangkan sesi/tangkapan baru ada di repository baru: penyelarasan sumber data diperlukan agar heatmap dan ringkasan tidak kosong/terbelah. Jangan membuat analitik contoh sebagai data pengguna.
- Sidebar memuat Analytics, Insight, Catalog, Calendar, dan Settings. Calendar dapat menavigasi pilihan tanggal/heatmap analytics yang sama; jangan membuat mesin agregasi kedua hanya untuk Calendar. Insight saat ini (`Qoma/UI/Main/InsightView.swift`) menampilkan periode fokus, daftar sesi, dan event tangkapan; pertahankan kemampuan itu dan dukung navigasi langsung dari tombol `Lihat hasil tangkapan`. Catalog tetap daftar semua spesies beserta count, termasuk yang belum ditemukan.
- Halaman Today/`CompactTodayView` dan alur `NewSessionView` tidak menjadi bagian navigasi target. Jendela utama tidak memerlukan tombol Start atau form task/mode/durasi duplikat. Settings berada dalam jendela utama; `⌘,` dan aksi Settings dari menu bar membuka route itu, bukan membuat alur konfigurasi sesi yang kedua.
- Tampilan sesi baru pada Insight/Analytics memakai tanggal, jam, durasi, status, dan hasil tangkapan, bukan judul tugas buatan pengguna. Riwayat lama yang mempunyai judul tetap tampil sesuai data lama. Metrik distribusi judul tugas boleh diganti ringkasan yang memang tersedia, tanpa menghilangkan total fokus atau statistik completed/interrupted.

### Aturan sesi, Restart, dan tangkapan yang harus dijaga

- `SessionCoordinator` tetap satu sumber state untuk menu bar, floating timer, penguin, policy overlay, Insight, dan report. Satu sesi aktif per perangkat. Start/pause/resume/restart/stop/completion hanya dianggap berhasil setelah state penting tersimpan; kegagalan persistence tidak boleh membuat UI/tangkapan seolah aksi berhasil.
- Restart mengembalikan **sisa countdown** ke durasi penuh yang dipilih saat sesi dimulai, tanpa membuat UUID baru. Waktu fokus aktif yang sudah dijalani tetap kumulatif, waktu pause tidak dihitung, dan catch yang sudah banked tidak dibuang. Provisional mengikuti ambang lima menit berdasarkan waktu aktif kumulatif; jangan reset ambang untuk memperoleh/kehilangan tangkapan secara tidak sengaja. Karena clock sekarang membatasi durasi aktif terhadap `plannedMinutes`, implementasi nanti harus memisahkan panjang putaran countdown dari total waktu aktif sesi yang telah di-restart, lalu menjaga restore setelah relaunch. Satu finalisasi dan satu entri riwayat untuk ID tersebut.
- Stop sebelum lima menit aktif mengembalikan provisional ke laut; Stop pada/di atas lima menit menyimpan catch yang telah terdeposit. Catch yang masih di reel ketika Stop/selesai tidak diberikan. Rare/legendary tetap dapat muncul kapan pun; tidak ada reward tambahan karena completed. Persistensi catch per event dan bank/recovery idempotent dari bagian 16 tidak diubah.
- Jika perubahan Settings dibuat saat sesi aktif, snapshot policy sesi itu tetap dipakai sampai berakhir, sementara pilihan baru tersimpan untuk Start berikutnya. Pengecualian hanya untuk preferensi tampilan `Hide floating timer`, yang langsung menyembunyikan/menampilkan panel timer tanpa mengubah sesi atau tangkapan.
- `completed` hanya ketika countdown benar-benar mencapai nol. `interrupted` hanya dari Stop/Quit yang dikonfirmasi. Setelah report ringkas ditutup, user kembali ke panel idle; riwayat dan hasil tetap dapat dibuka dari Insight/Catalog. Crash/relaunch tetap memulihkan satu active snapshot tanpa duplikasi.

### Peta dampak implementasi berikutnya

| Area kode | Perubahan terencana; bukan perubahan pada branch dokumentasi ini |
|---|---|
| `Qoma/Managers/AppDelegate.swift`, `Qoma/Managers/QyubeAppCoordinator.swift` | Launch tanpa `showHomeWindow()`, kendalikan policy accessory/regular sesuai jendela, route Analytics/Insight/Settings, dan tampilkan panel selesai tanpa membuka jendela otomatis. Pertahankan konfirmasi Quit dan jalur debug preview. |
| `Qoma/Managers/MenuBarController.swift`, `Qoma/UI/MenuBar/MenuBarView.swift` | Pulihkan panel ringkas branch `main` sebagai permukaan kontrol, tetapi hubungkan ke `SessionCoordinator` baru. Status item/panel memiliki keadaan idle, active, paused, completed; aksi Open qyube/Settings/Quit dan hasil tangkapan masuk panel tanpa membesarkannya menjadi report penuh. |
| `Qoma/Domain/Focus/SessionCoordinator.swift`, `SessionClock.swift`, `FocusModels.swift` | Bentuk draft internal dari durasi + snapshot policy global tanpa nama pengguna; tambah restart in-place yang persisten, durasi aktif kumulatif, satu finalisasi, dan restore aman. Pertahankan format baca data lama/migrasi. |
| `Qoma/UI/Main/QyubeHomeView.swift`, `AnalyticsDashboardView.swift`, `InsightView.swift`, `CatalogView.swift`, `Qoma/UI/SettingsView.swift` | Jadikan dashboard analytics halaman awal; pindahkan navigasi ke sidebar putih; integrasikan Settings dan route hasil tangkapan. Singkirkan Today/New Session dari navigasi setelah kontrol menu bar lengkap, tanpa menghapus data atau fitur Insight/Catalog. |
| `Qoma/UI/Main/NewSessionView.swift`, `Qoma/UI/Main/FishingReportView.swift`, floating timer | Form New Session dan report besar tidak dipakai pada alur utama; pertahankan sementara sampai seluruh aksesnya terganti. Timer/penguin tetap dua panel dengan state coordinator yang sama, tanpa edit nama tugas atau aturan per sesi sebagai jalur utama. |
| `Qoma/Services/AnalyticsStore.swift`, repository sesi/tangkapan, agregator analytics | Pastikan heatmap, statistik fokus, sesi baru, dan hasil tangkapan membaca data nyata yang konsisten; migrasi historis tetap idempotent. Hapus ketergantungan tampilan baru pada distribusi judul tugas, bukan record historisnya. |

### Kriteria selesai untuk fase implementasi nanti

1. Launch hanya menampilkan ikon menu bar; menu bar dapat Start dengan 25 menit awal, preset 10/25/60, dan pilihan 1–60. Jendela utama hanya terbuka lewat aksi eksplisit dan menutupnya tidak mengakhiri sesi. Ikon Dock mengikuti visibilitas jendela.
2. Satu sesi berjalan melalui Start → Pause → Resume → Restart → Stop maupun Start → completed tanpa timer kedua, record ganda, atau catch ganda. Restart mempertahankan UUID, total waktu aktif, serta catch banked; restore setelah relaunch tetap benar.
3. Settings mode dan daftar aplikasi/domain tersimpan lintas launch, dipakai sebagai snapshot pada Start berikutnya, dan perubahan saat sesi aktif tidak mengubah evaluasi policy sesi itu. Timer Only tidak meminta izin policy yang tidak diperlukan.
4. Penguin dan timer muncul pada Start, kecuali timer memang disembunyikan oleh preferensi pengguna; pause menidurkan penguin; menyembunyikan timer mempertahankan penguin; aksi menu bar tetap dapat mengendalikan sesi. Preferensi hide timer berlaku segera dan persisten.
5. Countdown nol menampilkan panel menu bar ringkas dengan Start again dan Lihat hasil tangkapan. Tombol hasil membuka Insight pada hasil sesi yang tepat. Catalog, Insight, Analytics, dan Calendar menampilkan data nyata yang konsisten, termasuk hasil sesi lama.
6. Stop <5 menit, Stop ≥5 menit, completion, Quit saat aktif, kegagalan tulis, dan recovery mengikuti aturan ledger/audit yang sudah ditetapkan. Verifikasi native panel/menu bar/Dock dan tes domain yang berkaitan diperlukan saat kode benar-benar diubah.

### Hasil implementasi — 10 Oktober 2026

- Launch sekarang memakai activation policy accessory dan tidak membuka jendela utama. Menu bar menampilkan panel kontrol untuk memilih durasi, Start, Pause/Resume, Restart, Stop, Settings, Open qyube, dan Quit. Saat completed, panel yang sama menampilkan ringkasan pendek, Start again, serta tautan hasil tangkapan ke Insight.
- Jendela utama memakai sidebar native sekitar 200 pt dan tampilan putih. Analytics dengan heatmap menjadi halaman awal; Calendar memakai heatmap dan ringkasan harian yang sama tanpa penggandaan agregator. Insight dan Catalog tetap membaca riwayat/tangkapan yang ada. Form Today/New Session dan report besar tidak lagi menjadi route utama, tetapi source lamanya dipertahankan sementara.
- Mode dan daftar aplikasi/domain menjadi preferensi persisten di Settings. Start menyalin policy global ke snapshot sesi; edit policy di tengah sesi tidak mengubah snapshot aktif. Preferensi Hide floating timer berlaku langsung. Penguin tetap aktif selama sesi, termasuk saat timer disembunyikan.
- Restart memakai ID sesi yang sama, mengulang countdown, mempertahankan akumulasi waktu fokus dan tangkapan tersimpan, serta tetap dapat dipulihkan setelah relaunch. Stop dan completion mempertahankan finalisasi/ledger yang idempotent; Stop setelah deadline yang sudah tercapai diselesaikan sebagai completed.
- Dashboard menggabungkan sesi repository baru dan AnalyticsStore lama berdasarkan UUID agar heatmap tidak kehilangan sesi baru atau menghitung migrasi dua kali. ActivityTracker merekam aktivitas aplikasi selama sesi baru; pembacaan situs hanya dijalankan bila izin Automation sudah benar-benar diberikan. Timer Only tidak menandai izin itu sebagai granted.
- Tes domain tambahan mencakup Restart + restore, tangkapan provisional melintasi Restart, preferensi global, dan Timer Only tanpa izin browser. Dua tes companion yang masih mengasumsikan landing visual otomatis memberi reward diselaraskan dengan kontrak bahwa reward hanya bertambah dari event tersimpan. Pemeriksaan native menu bar, Dock, dan posisi panel pada beberapa Spaces/monitor tetap perlu dilakukan pada Mac nyata.
- Verifikasi otomatis pada 10 Oktober: build Debug macOS berhasil; suite penuh `xcodebuild test` lulus dengan 164 tes. Pemeriksaan manual visual dan interaksi di aplikasi nyata belum dilakukan pada perubahan ini.

### Perbaikan regresi menu bar dan layout — 11 Oktober 2026

- Penyebab Start terkunci: riwayat sesi lama belum menyimpan `SessionDraft.domainBrowserBundleID`. Decoder yang mewajibkan kolom itu menolak seluruh riwayat; finalisasi terminal tertahan dan panel menampilkan Retry saving. Pembacaan draft kini menerima kolom yang tidak ada dengan default Safari, sesuai perilaku sesi lama. Riwayat dan ledger tidak dihapus; recovery pada launch berikutnya menyelesaikan sesi tertahan dan membuka Start kembali. Penanganan kegagalan tulis tetap dipertahankan.
- Shell utama dan Settings kembali ke struktur `main`: HStack, sidebar tetap 220 pt, row 13 pt, titlebar transparan, footer versi, minimum jendela 860 × 580 pt. Warna tetap putih. Analytics/Insight/Catalog/Calendar/Settings tetap tersedia tanpa label sidebar terpotong oleh List native.
- General dan Appearance memakai kembali pane/kartu/layout lama: quick presets, completion sound, volume, auto-mute, compact icon, opacity, dan tema timer. Focus rules, Hide floating timer, distraction sound, serta reduce companion motion ditambahkan pada struktur kartu yang sama. Preset tersimpan dan compact icon terhubung kembali ke menu bar.
- Tes regresi mereproduksi kegagalan recovery akibat draft lama sebelum fix, lalu lulus setelah fix: riwayat lama dipertahankan, terminal terselesaikan, dan sesi berikutnya dapat dimulai. Build + suite penuh `xcodebuild test` lulus: 165 tes, 0 gagal. Pemeriksaan decoding format lama juga lulus.
- Recovery data asli terkonfirmasi sesudah build baru diluncurkan: riwayat lama tetap dapat dibaca, sesi terminal tertahan masuk ke riwayat, dan snapshot terminal sudah dibersihkan. Verifikasi visual melalui otomatisasi native belum selesai: alat UI tidak dapat mengakses build accessory yang tidak memiliki jendela. Tampilan akhir, klik menu bar pada build terbaru, dan interaksi panel masih perlu diperiksa di aplikasi nyata.


## 18. Menu bar mengikuti main dengan panel putih — 13 Oktober 2026

### Keputusan dan batas perubahan

Semua rekomendasi interview menu bar disetujui pengguna pada 13 Oktober. Bagian ini menjadi acuan terbaru untuk desain panel dan preset, menggantikan ketentuan menu bar/preset yang berbeda di bagian 17. Implementasi dikerjakan pada branch `codex/menubar-white-ruler-2026-10-13`. Scope: menu bar saja; halaman dan layout aplikasi utama tetap mengikuti hasil perbaikan sebelumnya.

- Baseline source: `main:Qoma/UI/MenuBar/MenuBarView.swift`, `main:Qoma/Managers/MenuBarController.swift`, dan `main:Qoma/Utils/Constants.swift`. Bentuk panel mengikuti main; gambar 1 menjadi acuan idle dan seluruh layout gambar 3 menjadi acuan aktif dengan warna putih. Gambar 2 menjelaskan perubahan preset menjadi cancel/restart.
- Panel tetap **250 × 138 pt** untuk idle, active, paused, completed, dan recovery error; sudut 12 pt, border tipis, bayangan native, tanpa panah popover. Panel berupa NSPanel borderless/nonactivating seperti main, muncul di bawah ikon dan dibatasi ke layar tempat ikon berada.
- Background putih lembut, teks gelap, ruler abu-abu, indikator merah. Teks kontrol 13 pt mengikuti main. Countdown aktif 32 pt dengan monospaced digits di kanan bawah.

### Tampilan dan interaksi per state

| State | Ruler dan baris atas | Bagian bawah | Perilaku |
| --- | --- | --- | --- |
| Idle | Ruler durasi 1–60 menit; tiga preset tersimpan di bawahnya | start kiri, … kanan | Ruler dapat diklik/diseret dan disesuaikan via accessibility. Pilihan terakhir tersimpan. Default instalasi baru 5/10/25; durasi awal 25. Preferensi yang sudah tersimpan tidak ditimpa. |
| Active | Ruler progres menuju kiri, cancel/restart kiri, … kanan | pause kiri, countdown besar kanan | Ruler hanya menampilkan progres terhadap durasi awal sesi; tidak dapat mengubah durasi. Start yang berhasil menutup panel dan menampilkan penguin/timer sesuai preferensi. |
| Paused | Sama seperti active; indikator berhenti | resume kiri, countdown yang berhenti kanan | Pause/Resume memakai clock yang sama; penguin mengikuti state paused yang sudah ada. |
| Completed | Focus complete dan ringkasan durasi/jumlah tangkapan | start again dan Lihat hasil tangkapan | Panel otomatis terbuka. Start again memakai durasi sesi yang selesai dan snapshot preferensi global terbaru. Hasil membuka Insight untuk sesi tersebut. |
| Recovery error | Pesan gagal simpan dan Retry saving | … | Hanya muncul ketika finalisasi benar-benar gagal; perlindungan data dan perbaikan kompatibilitas riwayat lama tetap dipakai. |

### Kontrol dan lifecycle

1. Restart mengulang countdown memakai durasi asli, ID sesi yang sama, waktu fokus kumulatif, dan tangkapan tersimpan. Restart dari paused langsung kembali aktif. Ruler yang berjalan bukan picker kedua.
2. Cancel menampilkan konfirmasi singkat lalu memanggil Stop coordinator. Aturan tangkapan tetap: <5 menit melepas provisional; >=5 menit mempertahankan tangkapan banked. Panel kembali idle setelah penyimpanan berhasil. Kegagalan penyimpanan tetap terlihat dan dapat dipulihkan.
3. Menu … berisi Open qyube, Settings…, Show floating timer ketika active/paused, Check for Updates… (disabled bila updater unavailable), Contact Us, dan Quit. Tidak ada footer/tombol Open terpisah yang memperbesar panel.
4. Klik di luar, klik ulang ikon, dan Escape menutup panel tanpa mengubah sesi. Start atau Start again menutup panel hanya setelah berhasil; kegagalan Start tetap terlihat dan pengguna dapat mencoba kembali. Enter menjalankan aksi utama.
5. Ikon Q/timer di menu bar mengikuti preferensi Compact icon dari main. Start tetap berasal dari satu coordinator terbaru. Clock, recovery, policy global, catch ledger, penguin, floating timer, Quit confirmation, dan analytics tidak diganti dengan engine lama.

### Implementasi dan verifikasi

- `MenuBarView.swift`: struktur ruler/preset main, panel putih, countdown besar, menu tambahan, completion ukuran tetap, Start again dengan durasi sesi sebelumnya, dan pesan error yang tetap mempertahankan state.
- `MenuBarController.swift`: mengganti NSPopover dengan NSPanel dan pola hosting/posisi/klik luar dari main; menambahkan Escape serta penutupan setelah Start berhasil.
- `Constants.swift`: default quick presets kembali 5/10/25 tanpa menimpa UserDefaults pengguna.
- Tes domain tambahan mengunci Restart dari paused: kembali active, mempertahankan UUID dan akumulasi waktu, memakai durasi awal. Render lokal idle/active/paused/completed dipakai untuk pemeriksaan visual tanpa mengubah data pengguna.

- Hasil verifikasi 13 Oktober: build Debug berhasil; 18 tes terkait coordinator, catch ledger, dan preferensi lulus tanpa kegagalan. Render AppKit untuk idle, active, paused, dan completed berhasil dan sudah diperiksa secara visual; screenshot tersimpan di `build/menubar-preview/`. Probe render sementara sudah dibersihkan. `git diff --check` bersih.
- Pengujian klik native (drag ruler, dropdown, Escape, klik luar, multi-monitor/Spaces) belum dilakukan secara langsung; render membuktikan layout, bukan seluruh interaksi window. Suite penuh tidak diulang pada perubahan tampilan ini.


## 19. Cancel langsung dan timer mengikuti main — 13 Oktober 2026

Permintaan terbaru pengguna menggantikan konfirmasi Cancel dan pilihan Compact icon pada bagian 18. Branch: `codex/timer-display-main-style-2026-10-13`.

- Cancel pada panel menu bar langsung memanggil Stop tanpa confirmation popup. Error penyimpanan tetap terlihat, dan aturan provisional/banked catch serta finalisasi coordinator tetap berlaku.
- Menu bar selalu menampilkan MM:SS, tanpa logo Q. Ketika idle, tampil durasi terakhir yang dipilih pada ruler/preset (misalnya 35:00 lalu 10:00), termasuk setelah relaunch. Selama active/paused, countdown sesi menjadi sumber tampilan. Notification preferensi memperbarui teks saat pilihan idle berubah; preferensi Compact icon lama tidak memengaruhi tampilan. Baris pengaturan tersebut menjadi informasi Timer display agar tidak menawarkan opsi yang sudah tidak berlaku.
- Floating timer kembali memakai `FloatingTimerWindow.swift` dari main: 110 × 62 pt, sudut 18 pt, font Roboto Mono 30 pt, baseline, warna tema, opacity, border, dan efek background lama. View yang sebelumnya mengamati TimerService legacy kini mengamati TimerReadoutModel dari coordinator terbaru, sehingga hanya ada satu clock.
- `FloatingTimerController` memakai view tersebut dan ukuran constants main; header close/menu actions serta label Paused pada panel floating baru dihapus. Pause/Resume/Cancel dan Show floating timer tetap lewat menu bar; Hide floating timer lewat Settings. Posisi tersimpan, kemampuan drag, dan visibilitas lintas Spaces tetap berlaku. Floating ilustrasi tidak diubah.
- Tes display mencakup default 25:00, pilihan idle 35:00 → 10:00, prioritas countdown sesi, preferensi icon lama yang diabaikan, serta batas 1–60 menit. Tes coordinator/catch tetap memeriksa aturan Stop dan recovery.

- Verifikasi: build Debug macOS berhasil; 19 tes terkait display/coordinator/catch lulus. Diff floating view terhadap main hanya perubahan model sumber waktu. Pemeriksaan klik native dan screenshot floating runtime belum dilakukan; suite penuh tidak diulang.

## 20. Rencana main app berdasarkan prototype — 16 Oktober 2026

### Status, prioritas, dan referensi

Ini rencana pekerjaan berikutnya, belum implementasi UI. Commit `6f29b0d` menyimpan seluruh perubahan saat ini, termasuk floating timer Soft Panel/Liquid Glass, perubahan menu bar yang sudah berada di worktree, dan file prototype. Pembaruan dokumen dikerjakan pada branch `codex/main-ui-plan-2026-10-16` setelah commit tersebut. Catatan pribadi dan hasil implementasi terdahulu tetap dipertahankan sebagai riwayat; keputusan di bagian ini menggantikan ketentuan navigasi, isi Settings, dan pemisahan Insight/Calendar yang berbeda di atas.

| Halaman | Prototype yang dipakai |
|---|---|
| Analytics | [a-cozy-journal.png](output/imagegen/analytics-concepts/a-cozy-journal.png) |
| Daily Catches, bagian dari Analytics | [c-ledger.png](output/imagegen/daily-catches-concepts/c-ledger.png) |
| Catalog | [catalog-collectors-desk-v1.png](output/imagegen/catalog-concepts/catalog-collectors-desk-v1.png) |
| Settings | [settings-cozy-journal-v1.png](output/imagegen/settings-concepts/settings-cozy-journal-v1.png) |
| About | Belum ada prototype yang dipilih |

Sidebar memiliki tepat empat route: **Analytics, Catalog, Settings, About**, tanpa gambar. Analytics menjadi halaman awal. Insight dan Calendar dihapus dari navigasi setelah seluruh caller hasil tangkapan berpindah. Jangan menganggap isi/data contoh dalam gambar sebagai data produksi atau mengembalikan fitur yang sudah dibatalkan hanya karena masih terlihat pada prototype lama.

### A. Kontrak fungsi dan hubungan data

Nama fungsi baru di bawah adalah **usulan**, bukan klaim bahwa API-nya sudah tersedia. Utamakan mengubah fungsi yang ada daripada membuat store, repository, atau coordinator kedua.

```text
SessionCoordinator → SessionRepository / CatchRepository
ActivityTracker → AnalyticsStore (app activity + website visits)
                         ↓
QyubeNavigation.refresh() + pemuatan dashboard untuk accountID yang sama
                         ↓
riwayat digabung berdasarkan UUID + catch banked dideduplikasi berdasarkan event ID
  ├─ AnalyticsEngine.buildHeatmapCells() → pilihan tanggal
  ├─ selectedDay → interval harian → ringkasan + top apps + top websites
  ├─ interval harian + depositedAt → Daily Catches + urutan waktu
  └─ semua catch banked → Catalog counts + discovery progress

Settings → preferensi tersimpan → timer / audio / companion
Account → identitas akun + access state → accountID untuk pembacaan dan sesi berikutnya
About → versi aplikasi + tautan informasi
```

- `SessionCoordinator` tetap pemilik clock, catch lifecycle, Restart, Stop, completion, dan recovery. Redesign tidak mengganti engine sesi, probabilitas rarity, ambang banking lima menit, atau idempotensi persistence.
- `QyubeNavigation.refresh()` sekarang membaca accountID literal `local`; dashboard juga membaca repository langsung dengan literal yang sama. Saat integrasi akun dibuat, kedua jalur harus menerima identitas yang konsisten. Jangan memindahkan data `local` diam-diam ke akun yang baru login.
- `AnalyticsStore` menyimpan data legacy dan aktivitas; `SessionRepository` menyimpan sesi baru. Pertahankan merge berdasarkan UUID seperti `makeStoredData()` saat ini, dengan record repository baru mengungguli duplikat legacy. Jangan menjumlahkan dua representasi sesi yang sama.
- Refresh setelah finalisasi/deposit yang benar-benar tersimpan, ketika membuka halaman, dan ketika konteks akun berubah. Tanggal yang dipilih tidak di-reset setiap refresh. Satu pembaruan konsisten memberi data ke semua bagian halaman, tanpa masing-masing komponen membaca disk pada setiap render.
- Bedakan loading, data kosong, izin situs belum diberikan, dan kegagalan baca. Jangan menyamarkan kegagalan baca sebagai koleksi kosong; API repository yang saat ini hanya mengembalikan array perlu ditinjau pada jalur yang akan menampilkan error.

### B. Navigasi dan akses hasil tangkapan

1. Ubah `QyubeNavigation.Page` serta switch detail `QyubeHomeView` menjadi empat route final. Hilangkan state `settingsTab`; Settings tidak lagi memiliki General/Appearance/About tabs. About memakai route sendiri.
2. Ubah fungsi existing `showCatches(for:)`: refresh data, pindah ke Analytics, pilih hari dari hasil sesi, lalu scroll ke Daily Catches. Jangan lagi menunjuk `.insight` atau bergantung pada `selectedResult` untuk merender halaman yang dihapus.
3. Untuk sesi lintas tengah malam, usulan tujuan tautan adalah hari `depositedAt` tangkapan banked terbaru milik sesi itu; bila tidak ada, gunakan `endedAt ?? startedAt`. Tandai perilaku ini dalam tes navigasi. Tautan tetap menunjukkan seluruh hasil pada hari terpilih, bukan filter sesi tersembunyi.
4. Caller pada panel completed menu bar dan `QyubeAppCoordinator` harus ikut diperbarui. `SettingsWindowController.compactSettingsAction`, menu Settings, dan `⌘,` membuka route Settings yang sama. About dibuka dari sidebar; tidak membentuk instance jendela utama baru.
5. Menutup jendela utama tidak menghentikan sesi atau menghilangkan companion. Launch/menu bar/Dock tetap mengikuti perilaku yang sudah bekerja. Hapus source Insight/Calendar hanya setelah pencarian caller dan penggantian route selesai; record historis tidak dihapus.

### C. Analytics: semua detail mengikuti tanggal terpilih

**Fungsi existing yang dipakai ulang:** `loadData()`, `makeStoredData()`, `syncSelectedDay(using:)`, `selectedDaySessions(in:)`, `selectedDayApps(in:)`, `selectedDayDomains(in:)`, serta `AnalyticsEngine.buildHeatmapCells`, `buildTopApps`, dan `buildTopDomains`.

**Fungsi/perilaku yang harus dibuat atau disesuaikan:**

| Fungsi usulan / existing | Input → output dan tanggung jawab |
|---|---|
| `selectDay(_:)` | Tanggal dari heatmap atau route hasil → normalisasi awal hari, simpan pilihan, perbarui seluruh detail secara bersamaan. Default pertama hari ini; hari kosong tetap boleh dipilih. |
| `dayInterval(for:calendar:)` | Tanggal + kalender → interval `[startOfDay, nextStartOfDay)`. Gunakan perhitungan kalender, bukan menambah 86.400 detik. |
| `makeStoredData()` | Sesi legacy + sesi repository + aktivitas + catch banked akun → input dashboard konsisten tanpa duplikasi. Tambahkan catch ke model dashboard yang ada, bukan database analytics baru. |
| `buildDaySummary(...)` | Sesi dalam hari terpilih → total fokus, jumlah sesi, completed, interrupted. Gunakan aturan atribusi sesi yang konsisten dengan heatmap. |
| `selectedDayApps` / `selectedDayDomains` | Aktivitas yang beririsan dengan interval → ranking harian; potong durasi di batas hari agar waktu dari hari lain tidak masuk. Pastikan predicate existing tidak kehilangan event yang mulai sebelum tengah malam. |
| `selectedDayCatches(...)` | Catch banked + interval → event dengan `depositedAt >= start && depositedAt < end`; jangan memakai tanggal banking sebagai tanggal tangkapan. |
| `buildDailyCatchRows(...)` | Event harian → kelompok per `kindID`, nama/rarity/art dari CatalogDefinitions, jumlah, jam pertama/terakhir, dan daftar event terurut. Jumlah seluruh kelompok harus sama dengan jumlah event harian unik. |
| `toggleCatchHistory(...)` | Kelompok terpilih → buka/tutup riwayat berbasis waktu; tidak membutuhkan nama sesi, judul tugas, atau pengelompokan per sesi. |

**Aturan hasil harian:**

- Focus Activity boleh merangkum beberapa bulan sebagai pemilih hari. Semua angka ringkasan, breakdown, dan Daily Catches di bawahnya hanya untuk satu hari terpilih. Tidak ada filter Week/Month/Year, perbandingan periode, statistik all-time, atau progress koleksi keseluruhan pada Analytics.
- Ringkasan sesi mengikuti baseline existing: sesi diatribusikan ke tanggal `startedAt`, termasuk total `actualActiveSeconds` sesi tersebut. Heatmap dan ringkasan harus memakai aturan sama; jangan membagi durasi sesi lintas hari secara tebakan karena record ringkasan tidak menyimpan seluruh segmen aktif/pause. Aktivitas aplikasi/situs tetap dipotong ke interval harian. Perbedaan ini perlu diuji dan dijelaskan lewat label bila membingungkan pengguna.
- Daily Catches ditempatkan setelah Daily Breakdown (Top Apps dan Top Websites), mengikuti prototype `c-ledger.png`. Tampilkan count per jenis dan jam tangkapan; pengurutan waktu stabil dengan ID sebagai tie-breaker. Provisional yang belum banked tidak masuk analytics maupun Catalog. Banking terlambat boleh menambah hasil hari deposit sebelumnya setelah refresh.
- Hari tanpa sesi tetap menampilkan angka nol dan empty state yang sesuai; jangan otomatis mengganti pilihan menjadi hari terakhir aktif. Hari dengan catch tetapi tanpa sesi yang terbaca tetap menampilkan catch yang benar, sambil menangani error sumber sesi secara terpisah.
- Analytics dan Catalog memakai lookup jenis/art/rarity yang sama. Unknown `kindID` dari data lama tidak boleh crash atau menghilang tanpa penjelasan; gunakan label netral dan placeholder khusus.
- Hilangkan bagian Insight yang menduplikasi statistik; riwayat detail yang masih dibutuhkan ditampung dalam hasil harian. Tidak perlu nama sesi baru. Judul historis tetap tersimpan tanpa menjadi syarat tampilan.

### D. Catalog: koleksi keseluruhan dan berat ikan

**Existing:** `CatalogView.counts`, `kinds`, filter All/Fish/Ocean finds, detail sheet, `CatalogDefinitions.allKinds`, `kind(id:)`, dan `CatchRepository.listBanked` / `countByKind`.

1. Bentuk card dari definisi semua jenis, lalu gabungkan count event banked akun. Fungsi usulan `buildCatalogItems(kinds:catches:)` menghasilkan identity jenis, discovered, count, rarity, art, dan berat bila ada. Ini transformasi presentasi; tidak mengubah ledger atau roll engine.
2. `discoveryProgress(...)` menghitung jumlah jenis dikenal dengan count > 0 dibanding total definisi, bukan jumlah individu ikan. Filter kategori tidak mengubah denominator progress keseluruhan. Jenis lama yang belum dikenal tidak menambah denominator secara sembarang.
3. Jenis ditemukan menampilkan nama, berat ikan jika tersedia, jumlah tangkapan, dan rarity. Jenis belum ditemukan memakai siluet hitam art jenis yang sama dan nama `???`; jangan membocorkan nama/berat/rarity melalui detail sheet, tooltip, atau accessibility label.
4. Art ikan tampak atas tanpa mata; art unik dipetakan berdasarkan `kindID`, digunakan bersama oleh Catalog dan Daily Catches. Siluet dibuat dari alpha asset yang sama agar bentuk cocok. Jangan memakai satu gambar ikan yang sama untuk semua spesies seperti placeholder existing. Ketersediaan asset final merupakan pekerjaan terpisah dari mockup halaman.
5. `rarityColor(_:)` atau pemetaan existing menjadi satu sumber warna nama, disertai label rarity agar informasi tidak hanya mengandalkan warna. Data rarity tetap mengikuti `CatalogDefinitions`, bukan ditebak dari warna gambar.
6. **Berat belum diputuskan.** `CatchEvent` dan `Kind` saat ini tidak memiliki field berat. Angka kilogram di prototype adalah contoh. Sebelum implementasi data berat, pilih apakah card menunjukkan berat tetap spesies, catch terakhir, atau rekor terberat; jangan menganggap mockup menetapkan salah satunya.
7. Bila berat per individu dipilih, tambahkan field opsional yang kompatibel dengan record lama, tentukan distribusi/batas per jenis, roll sekali saat identitas catch ditetapkan, simpan bersama event, lalu gunakan kembali setelah banking/recovery. Dilarang random ulang saat render, refresh, atau login. Data lama tanpa berat tampil `—`; jangan mengarang backfill. Bila berat tetap spesies dipilih, cukup metadata Kind dan tidak perlu migrasi event.
8. Ocean finds tetap koleksi yang bisa difilter; jangan memaksakan satuan kg ikan pada batu/kayu/kerang tanpa keputusan produk. Detail card, bila dipertahankan, membaca model yang sama sehingga count dan discovery tidak berbeda dari grid.

### E. Settings: satu halaman, preferensi yang benar-benar terhubung

| Kelompok | Fungsi dan hubungan |
|---|---|
| Account | Menampilkan status login, nama/email nyata bila tersedia, aksi login/logout, loading/error/retry; detail integrasi di bagian F. |
| Sound | Pilih suara akhir sesi termasuk Off, atur volume, dan preview memakai player yang sama dengan completion. Hentikan preview sebelumnya sebelum memutar baru; clamp volume ke 0...1. Suara berhenti otomatis paling lambat lima detik. |
| Floating timer | Show floating timer adalah invers dari `FocusPreferences.hideFloatingTimer`; perubahan berlaku langsung pada panel existing. Warna angka memakai key tema existing dan preview. Liquid Glass memakai key existing dan hanya tersedia pada macOS 26+; sistem lebih lama selalu memakai panel solid. |
| Comfort | Reduce motion memakai preferensi existing dan diterapkan pada companion serta cue distraksi; menghormati pengaturan aksesibilitas sistem. |

- Gabungkan pemakaian preferensi dari `GeneralSettingsPane`, `AppearanceSettingsPane`, dan wrapper `QyubeGeneralSettingsPane` ke satu route. Pertahankan key penyimpanan yang relevan dan default pengguna; jangan membuat state terpisah yang hanya mengubah preview.
- Hapus kontrol Quick presets, informasi Timer display, Opacity, serta toggle Auto mute. Menghapus editor preset tidak menghapus preset menu bar atau nilai lama yang telah disimpan; panel menu bar masih membaca nilai existing, default instalasi baru tetap 5/10/25. Menghapus Opacity membuat timer solid benar-benar menggunakan opacity tetap 1; nilai lama boleh tetap tersimpan tetapi tidak boleh menyisakan panel transparan yang tak lagi bisa diatur.
- Auto mute lima detik menjadi perilaku tetap untuk preview dan completion, termasuk pengguna yang pernah menyimpan `false`. Pilihan Off harus mencegah pemutaran suara, bukan hanya menyetel volume UI menjadi nol. Pilihan suara mockup seperti Soft bell tidak menjamin asset tersedia; gunakan asset berlisensi yang ada atau sediakan asset sebelum menampilkan pilihan baru.
- Audit `CompletionSoundPlayer` di `FocusSessionManager.swift` dan alur `QyubeAppCoordinator.onSessionEnded`. Player existing berada di jalur manager legacy; pastikan sesi coordinator baru memutar completion tepat sekali tanpa menghidupkan clock legacy. Playback terjadi setelah finalisasi berhasil; restore record terminal tidak boleh mengulang alarm setiap launch.
- Liquid Glass sudah diimplementasikan pada baseline; pakai kembali availability guard dan `FloatingTimerView`, jangan menambahkan panel/clock baru. Preferensi warna, visibility, glass, motion, dan volume berlaku segera tanpa restart sesi. Peninggalan glass=true pada macOS lama harus diabaikan dengan aman.
- **Akses Focus rules harus tetap ada sampai penggantinya berfungsi.** Prototype Settings tidak menampilkannya, tetapi implementasi saat ini mengatur policy global di Settings dan menu bar belum memiliki editor pengganti. Sebelum menghapus section itu, pindahkan pengaturan Allowing/Blocking/Timer Only serta daftar app/domain ke akses konfigurasi yang jelas dari menu bar, memakai `FocusPreferences` yang sama. Tidak membuat halaman sidebar kelima. Jika tujuan kontrol belum disepakati, pertahankan akses existing sementara dan catat sebagai keputusan implementasi yang belum final.
- Policy baru tetap menjadi snapshot untuk Start berikutnya, tidak mengubah sesi aktif. Preferensi distraction sound yang tidak muncul pada prototype juga tidak boleh diam-diam menjadi suara yang tak bisa dimatikan: tetapkan hubungannya dengan Off/volume atau pertahankan kontrol existing sampai diputuskan. Jangan menghapus kemampuan tanpa memeriksa caller.

### F. Account: login/logout sederhana, integrasi nyata terpisah dari mockup

**Fakta baseline:** `Qoma/Auth/AccessCoordinator.swift` adalah stub lokal yang mengembalikan state akses. Ada `AccessState`, tetapi belum ada API login/logout, profil pengguna, atau penyimpanan token produksi. AccountID repository dan coordinator masih `local`. Nama/email pada prototype hanya contoh.

| Fungsi usulan | Kontrak |
|---|---|
| `restoreAccount()` | Baca credential dari Keychain, validasi/refresh melalui layanan akun, hasilkan signedOut/signedIn/loading/error; jangan menganggap state stub sebagai bukti autentikasi. |
| `signIn()` | Buka alur web Google/Apple yang sudah direncanakan; validasi callback/state/PKCE, simpan token aman, lalu muat profil dan refresh access. Cancel kembali ke state sebelumnya; error dapat dicoba lagi. |
| `signOut()` | Akhiri autentikasi dan hapus credential sesuai hasil layanan, bersihkan profil/cache presentasi akun, lalu tampilkan signedOut. Jangan menghapus riwayat/catch lokal. |
| `refreshAccountContext()` | Sesudah login/logout → selaraskan accountID pembacaan, access gate, dan coordinator untuk sesi berikutnya; reset pilihan/detail akun sebelumnya agar tidak bocor antar akun. |

- Hubungkan fungsi di lapisan akun existing bila memungkinkan, tanpa membuat sistem billing/sync baru. Tampilkan login ketika signedOut dan nama/email + logout ketika signedIn. Jangan tampilkan Synced, paket subscription, atau keberhasilan palsu dari tombol yang hanya mengubah Boolean lokal.
- Backend URL, callback scheme/universal link, konfigurasi provider, profil dan refresh/revoke endpoint adalah dependensi yang harus ditetapkan sebelum login produksi dinyatakan selesai. Bagian ini tidak mengotorisasi pembuatan layanan berbayar atau perubahan paket Stripe.
- Saat sesi active/paused, logout atau perpindahan akun harus menunggu sesi diselesaikan/dihentikan lewat coordinator; jangan mengganti accountID sesi yang sedang berjalan. Beri penjelasan singkat bila aksi ditunda. Finalisasi dan ledger tetap milik akun awal sesi.
- Migrasi koleksi `local` ke akun belum ditentukan; jangan menyalin/menggabungkan otomatis atau memperlihatkan riwayat satu akun ke akun lain. Penyimpanan aktivitas AnalyticsStore saat ini tidak dipartisi akun sehingga perlu batas akun yang nyata sebelum dukungan banyak akun produksi. Tetapkan ownership/migrasi eksplisit dan tes isolasi sebelum mengaktifkan perpindahan akun dengan data nyata.
- Login tidak otomatis mengaktifkan sinkronisasi iCloud. Kontrak trial/billing lama tidak diubah oleh redesign ini; implementasi autentikasi/gate tetap perlu keputusan layanan yang sudah disebut di bagian terdahulu.

### G. About: route keempat

- Pindahkan isi `QyubeAboutSettingsPane` menjadi halaman About tersendiri; tampilkan identitas aplikasi, deskripsi singkat, versi/build dari Bundle, dan tautan Privacy Policy serta bantuan/contact yang memang tersedia. Jangan menulis versi hardcoded atau mengarang alamat layanan.
- Fungsi usulan `openAboutLink(_:)` memakai pembukaan URL platform dengan URL konfigurasi yang valid. Link yang belum tersedia tidak tampil sebagai aksi aktif palsu. Tidak perlu profil, statistik, achievement, atau pengaturan tambahan untuk mengisi halaman.
- Check for Updates dapat memakai updater yang sudah tersedia; jangan memasang Sparkle atau jalur distribusi baru hanya untuk redesign About. Jangan duplikasi seluruh About di footer Settings.

### H. Peta perubahan dan urutan pengerjaan

| Tahap | File/caller yang harus dijangkau | Hasil yang harus dapat diperiksa |
|---|---|---|
| 1. Data harian dan route | `QyubeHomeView.swift`, `QyubeAppCoordinator.swift`, `MenuBarView.swift`, `AnalyticsDashboardView.swift`, `AnalyticsEngine.swift`, model analytics, repository sesi/catch | Empat route, pemilihan tanggal yang stabil, hasil menu bar menuju Daily Catches hari yang tepat, merge legacy tanpa duplikasi. |
| 2. Analytics + Daily Catches | Dashboard, `AnalyticsHeatmapView`, `AnalyticsBreakdownView`, komponen catch harian seperlunya | Ringkasan/breakdown/catches hanya hari terpilih; ledger waktu tanpa nama sesi; empty/error/permission states. |
| 3. Catalog | `CatalogView.swift`, `CatalogDefinitions.swift`, `QyubeCatchArt` dan asset catalog; `CatchEvent`/engine/repository hanya bila keputusan berat membutuhkannya | Filter, discovery, count, rarity, art tampak atas, siluet, dan kontrak berat yang telah dikunci. |
| 4. Settings | Shell Settings, pane General/Appearance, `FocusPreferences`, `Constants.swift`, `FloatingTimerWindow.swift`, completion audio dan companion | Satu halaman dengan preferensi efektif, availability Glass, penghapusan kontrol yang aman, akses rules tetap berfungsi. |
| 5. Account | `AccessCoordinator.swift`, lifecycle AppDelegate/QomaApp untuk callback, repository scope dan coordinator injection | Login/logout nyata setelah dependensi backend tersedia; isolasi akun dan perlindungan sesi aktif. UI akun tidak dianggap integrasi selesai sebelum ini. |
| 6. About + pembersihan | About pane/route, semua caller Insight/Calendar/tab Settings lama, project resources | About terpisah; tidak ada route yatim atau penghapusan data. Source lama dihapus setelah pengganti lengkap. |

Jangan menambah dependency untuk transformasi grouping, filter, formatter, atau penyimpanan preferensi sederhana. Pisahkan commit fungsi dari asset bila membantu review. Asset ikan final, keputusan berat, backend autentikasi, tujuan editor rules, dan kontrol distraction sound dicatat sebagai dependensi spesifik; pekerjaan data harian/navigasi yang independen dapat berjalan lebih dahulu.

### I. Validasi dan kriteria selesai

- Tes agregasi: merge UUID legacy/baru; hari kosong; batas awal/akhir hari; DST; aktivitas menyeberang tengah malam; atribusi sesi sesuai heatmap; catch banked terlambat tetap masuk tanggal deposit; provisional tidak masuk; event duplikat tidak menambah count; unknown kind tidak crash.
- Tes hubungan halaman: memilih sel heatmap memperbarui semua bagian; refresh tidak meloncat tanggal; tautan completed menuju Analytics + Daily Catches; jumlah kelompok harian sama dengan event unik; Catalog memakai total akun, bukan tanggal/filter Analytics.
- Tes Catalog: kategori dan denominator progress; siluet/name/accessibility tak membocorkan item terkunci; pembacaan record lama tanpa berat bila schema berubah; berat tidak berubah setelah bank/restore bila per-event dipilih.
- Tes Settings: key existing, invers show/hide, preferensi langsung diterapkan, Glass tersimpan pada OS lama, opacity solid tetap 1, suara Off/volume/stop lima detik, completion sekali setelah persistence berhasil. Tes snapshot policy tetap melindungi sesi aktif.
- Tes akun ketika layanan tersedia: callback tidak sah ditolak, cancel/error/retry, refresh credential, logout tidak menghapus data, perpindahan akun tidak membuka data akun sebelumnya, sesi aktif tidak dipindah identitas. Preview/mock akun hanya pada Debug, tidak dianggap bukti login berhasil.
- Build Debug macOS dan tes domain yang terdampak wajib lulus saat implementasi. Periksa native window resizing, keyboard/VoiceOver, scroll ke catches, login callback, menu bar, timer/companion, serta Glass pada Mac pendukung. Pemeriksaan render tidak menggantikan klik native.
- Tidak termasuk scope: achievement, fullscreen penguin, background scene/audio ambience baru, halaman Insight/Calendar terpisah, sync cloud, dan billing baru. Penyederhanaan tidak boleh merusak Start/Pause/Resume/Restart/Stop/recovery yang sudah bekerja.

### Hasil pembaruan dokumen — 16 Oktober 2026

- Rencana dan referensi prototype dicatat; belum ada implementasi main UI atau account pada branch ini.
- Baseline sudah di-commit sebelum branch perencanaan dibuat. Validasi pembaruan ini hanya struktur dokumen, path referensi prototype, dan `git diff --check`; build/test aplikasi tidak diulang untuk perubahan Markdown.


## 21. Implementasi main UI — 16 Oktober 2026

### Keputusan terbaru pengguna dan scope

- Fokus UI/offline; login tidak diaktifkan. Account menunjukkan penggunaan lokal dengan tombol login nonaktif dan keterangan, tanpa profil/token/keberhasilan login palsu.
- Art ikan final belum dikunci. Analytics memakai asset existing `design/qyube-collectibles-v1/assets/`; Catalog sementara memakai satu ikan tampak atas **dengan mata** untuk semua jenis ikan. Keputusan tanpa mata di bagian 20 dibatalkan. Ocean finds memakai asset masing-masing. Siluet berasal dari alpha asset lewat template rendering, bukan file terpisah.
- Asset ikan placeholder Catalog dibuat memakai imagegen bawaan dan dibundel pada `Qoma/Assets.xcassets/CatalogFishPlaceholder.imageset`. Asset harian dibundel pada `Collectible-<kindID>.imageset`. Sembilan gambar berukuran maksimum 512 px, sekitar 1,5 MB total; halaman tidak mengunduh asset maupun favicon.
- Berat memakai kg dengan dua desimal (contoh `0.01 kg`), termasuk nilai positif kecil yang dibulatkan minimal `0.01 kg`. Record existing tidak memiliki berat; UI menampilkan `— kg` dan keterangan belum tercatat. Tidak ada random/backfill berat, perubahan schema catch, atau klaim bahwa format satuan menentukan apakah berat per individu/rekor/spesies.

### Perubahan yang sudah dibuat

- Shell memiliki Analytics, Catalog, Settings, About; sidebar tanpa gambar, Settings satu halaman. Window awal 1180 × 820 pt; minimum 860 × 580 pt tetap didukung dengan scroll/reflow. Lifecycle window/menu bar dan clock sesi tetap memakai coordinator existing.
- Analytics memakai tanggal bersama milik navigation. Heatmap memilih hari, ringkasan/breakdown/ledger mengikuti hari itu; hari kosong tidak berpindah otomatis. Sesi legacy dan repository digabung berdasarkan UUID seperti baseline. Top apps/websites kini memotong event yang beririsan dengan batas hari, termasuk event yang dimulai sehari sebelumnya.
- Daily Catches sesudah Daily Breakdown mengelompokkan event banked berdasarkan jenis, menampilkan count dan waktu, serta disclosure riwayat urut waktu. Event dideduplikasi berdasarkan ID, difilter tanggal deposit `[start, nextDay)`, provisional dikecualikan. Unknown kind diberi placeholder/label netral. Hasil menu bar mengarah ke Analytics dan scroll ke ledger hari tangkapan banked terakhir sesi itu, fallback ke hari selesai sesi.
- Catalog memakai total tangkapan banked akun lokal, kategori All/Fish/Ocean finds, progress jenis ditemukan, count, nama/rarity berwarna, detail, dan `???` untuk jenis terkunci. Teks aksesibilitas/detail tidak membocorkan nama/rarity jenis terkunci. Grid empat kolom pada ukuran awal dan menyesuaikan saat dipersempit.
- Settings menghubungkan Sound/Off/volume/preview, show timer, warna angka, Liquid Glass macOS 26+, reduce motion, dan distraction sounds ke preferensi existing. Focus rules tetap tersedia melalui disclosure karena belum ada editor pengganti di menu bar; policy snapshot sesi aktif tetap terlindungi.
- Quick presets, Timer display, Opacity dan Auto mute editor tidak ada pada route Settings baru. Preset menu bar dan nilai tersimpan tetap dipakai. Panel solid selalu opacity 1; completion/preview berhenti setelah lima detik. Pemutar audio existing dipakai ulang untuk completion coordinator baru setelah finalisasi berhasil, tanpa menghidupkan timer legacy.
- About memiliki route sendiri, versi/build dari Bundle, deskripsi lokal, dan Contact support dari alamat existing. Tidak mengarang tautan Privacy Policy yang belum tersedia. Source Insight/Settings lama dipertahankan untuk menghindari penghapusan jalur legacy di luar scope, tetapi tidak muncul sebagai route utama.
- Belum termasuk integrasi akun, migrasi akun lokal, cloud sync, final art seluruh ikan, random berat, achievement, atau fullscreen. Repository existing masih memiliki keterbatasan membedakan kegagalan baca dari array kosong; redesign ini tidak mengklaim menyelesaikan kontrak error persistence tersebut.

### Verifikasi

- Build Debug macOS berhasil; suite akhir `xcodebuild test` lulus 172 tes, 0 gagal. Probe render terpisah juga lulus dan sudah dihapus dari suite permanen. SwiftLint strict pada 16 file yang berubah bersih; SwiftFormat lint pada 15 file lolos (coordinator mempertahankan format existing untuk meminimalkan diff); `git diff --check` bersih. Warning lama dari file proyek lain dan konfigurasi Xcode masih ada.
- Render lokal memakai NSHostingView pada lebar 1180/860 pt dan memeriksa empat halaman serta ledger setelah scroll. Probe render sementara tidak menjadi bagian produk atau suite permanen. Uji klik native, VoiceOver, multi-monitor/Spaces dan tampilan Glass saat aktif masih perlu pemeriksaan langsung.

## 22. Rencana MenuBar: mode, live app rules, reset timer, dan ikan harian — 16 Oktober 2026

### 22.1 Status, tujuan, dan prioritas keputusan

**Status: diimplementasikan pada 17 Oktober 2026.** Batas “planning only” berlaku pada pembaruan dokumen tanggal 16 Oktober; implementasi pada branch ini sekarang mengikuti kontrak dan koreksi desain terbaru di bagian ini.

Tujuan: MenuBar menjadi tempat mengatur durasi, mode dan aplikasi, mengontrol sesi, serta melihat sekilas ikan hari ini. Gunakan palette Arctic yang sudah diterapkan, asset lokal dan coordinator/repository existing. Tidak menambah halaman utama, dependency, network service, clock sesi kedua, atau sistem blocking OS baru.

Urutan sumber keputusan: koreksi pengguna setelah sesi grill → bagian 22 ini → implementasi baseline sebagai fakta teknis → rencana lama. Bagian lama yang menyatakan aturan hanya berlaku pada sesi berikutnya, editor domain tersedia, Restart melanjutkan sesi yang sama, completion card, dan tombol hasil tangkapan MenuBar sudah kalah oleh bagian ini.

### 22.2 Keputusan produk final

| Area | Kontrak |
|---|---|
| Mode | Timer only / Allowing / Blocking; default instalasi baru Timer only, pilihan terakhir disimpan. Mode terkunci selama active dan paused. |
| Allowing | Semua app dianggap tidak diizinkan kecuali app yang dipilih. Minimal satu app pilihan diperlukan saat Start maupun setelah edit live. qyube sendiri tetap dapat digunakan agar kontrol tidak mengunci pengguna. |
| Blocking | Semua app diizinkan kecuali app yang dipilih. Daftar kosong sah; editor tetap ditampilkan dan Start tetap bisa. |
| Browser | Chrome, Safari dan browser lain diperlakukan sebagai app biasa. Tidak ada input, search, filter, atau permission khusus untuk `x.com`, `instagram.com`, dan domain lain pada versi ini. |
| Edit app | Dapat dilakukan pada idle, active, paused untuk Allowing/Blocking. Setiap checkbox langsung disimpan dan diterapkan; Done hanya menutup, bukan Save. Escape/klik luar tidak membatalkan perubahan yang berhasil. |
| Penyimpanan daftar | Allowing dan Blocking memiliki set terpisah; berganti mode tidak menghapus set lainnya. Edit live juga menjadi pilihan default sesi berikutnya untuk mode itu. |
| Ringkasan aturan | Di bawah mode: maksimal lima ikon app, `+N`, tombol pensil; tooltip nama app. Empty state tetap menawarkan Edit. |
| Kontrol aktif | `restart` dan `pause` berdampingan sebagai teks lowercase di footer; `pause` menjadi `resume` ketika paused. Tidak ada angka countdown atau tombol ikon pada state active/paused. Cancel dihapus, termasuk tidak dipindah menjadi End session di menu `…`. |
| Restart / reset | Maknanya mengakhiri sesi sekarang, menyimpan waktu fokus yang telah dijalani menurut aturan Stop existing, lalu kembali idle dengan durasi awal siap dimulai. Play/Start berikutnya membuat sesi baru; tidak otomatis mulai. |
| Selesai alami | Kembali ke kontrol idle, MenuBar otomatis terbuka, completion sound existing tetap. Tidak ada completion card, total focus/catch summary, Start again atau Lihat hasil tangkapan. |
| Ikan harian | View-only, satu baris horizontal di bawah area mode + ringkasan app. Maksimal 20 ikan terbaru hari lokal ini; duplikat jenis tetap tampil sebagai event terpisah; terbaru di kiri. |
| Tampilan ikan | Gambar saja tanpa background, border atau card; scrollbar disembunyikan. Tooltip nama dan jam boleh; tidak ada klik, detail, View all atau navigasi dari ikan. |
| Empty catches | `No catches today. Start a focus session.` Hanya banked/permanen yang tampil; provisional tidak ditampilkan. |
| Ukuran | Lebar tetap ringkas; tinggi mengikuti mode, aturan, ikan/error. Tidak mempertahankan tinggi fixed 138 pt yang memotong konten baru. |

**Batas arti blocking:** kontrak di atas menentukan app yang melanggar policy. Mekanisme penanganan distraksi tetap overlay/companion/audio existing, bukan mencegah launch, force quit, menutup dokumen, atau menghalangi klik app lewat API OS. Tidak memperkenalkan tindakan merusak pekerjaan pengguna. Jika diperlukan pemblokiran OS nyata, itu scope baru yang memerlukan keputusan terpisah.

**Interpretasi Restart yang dipakai:** koreksi nomor 15 pengguna (restart juga bermakna end session) menggantikan rekomendasi lama nomor 13–14. Karena itu hasil reset adalah **idle**, bukan snapshot baru dalam status paused. Waktu sesi lama disimpan sekali, tidak dibawa lagi menjadi accumulated time sesi baru. Ikon Play saat idle berarti Start sesi baru; saat paused berarti Resume sesi yang sama.

### 22.3 Fakta baseline yang sudah diperiksa

| File / API existing | Fakta dan implikasi |
|---|---|
| `Qoma/UI/MenuBar/MenuBarView.swift` | Ruler/preset, Start/Pause/Resume/Restart/Cancel, error teks, `completion(_:)`, `onViewCatches`, dan `Menu` untuk More actions. Lebar/tinggi fixed dari constants. Belum ada mode atau app picker. |
| `Qoma/Managers/MenuBarController.swift` | Host berupa custom `NSPanel`, bukan NSPopover. `MenuBarPanelState` menyimpan completedSession/count; `showCompletion` membuka panel; Start berhasil menutup panel. Local/global mouse monitors menutup panel bila klik di luar frame parent/status item. |
| `Qoma/Utils/Constants.swift` | Baseline panelWidth **250 pt**, panelHeight **138 pt**; koreksi ringkasan percakapan sebelumnya yang menyebut sekitar 300×180. Ubah kontrak height di view dan controller sekaligus. |
| `Qoma/Domain/Focus/FocusPreferences.swift` | `policy` disimpan JSON di UserDefaults; set allowed/blocked terpisah; `draft(minutes:)` mengambil policy global berikut browserBundleID. Published didSet belum menyediakan hasil kegagalan persistence. |
| `SessionCoordinator` | `currentPolicy` dari snapshot; saveActive sebelum publish pada Pause/Resume. `restartSession()` saat ini mempertahankan UUID dan cumulative time lalu langsung active; ini harus berubah atau tidak dipakai oleh UI baru. |
| `stopSession(reason:)` | Menghasilkan interrupted, mempertahankan active time; provisional sebelum 5 menit dibuang, sesudah threshold di-bank. Return session non-nil belum selalu berarti finalisasi sukses; wajib periksa outcome/snapshot. |
| `completeIfDue()` / `retryFinalization()` | Ada jalur terminal snapshot dan idempotent history. Banking atau saveActive bisa gagal sebelum status terminal dipublish; UI yang hanya mengecek terminal snapshot belum mencakup semua error. |
| `QyubeAppCoordinator` | `startFromMenuBar` mengambil FocusPreferences; snapshot subscription memulai/menghentikan monitor/panel. lastCatchEvent me-refresh navigation dan mem-post collectionChanged. `onSessionEnded` memainkan sound lalu showCompletion untuk completed. |
| `DistractionCoordinator.start` | Menangkap policy dalam subscription, lalu stop/restart monitor bila policy berubah. Edit live harus mengevaluasi aktivitas saat ini, bukan menunggu user pindah app. Periksa pula akumulasi detour agar tidak ter-reset/terhitung ganda. |
| `ForegroundActivityMonitor` | NSWorkspace untuk app foreground; resolver domain terpisah. App-only tidak membutuhkan browser Automation. |
| `QyubeAppRuleEditor` di `NewSessionView.swift` | Sudah ada search/checkbox, scanning app roots, AppIcon, dan domain advanced. Reuse logika yang berguna; jangan menyalin domain UI ke editor MenuBar. Scanning sekarang sinkron dan perlu dijauhkan dari render/tick. |
| `QyubeJournalSettingsView.focusRules` | Saat ini masih ada pengaturan global dan akses editor domain. Harus diselaraskan agar tidak menjadi pintu bypass mode lock/app-only/live rules. |
| `DailyCatchSummary.events` | Memfilter banked menurut depositedAt pada interval hari lokal `[start,nextDay)`, dedupe UUID dan sort ascending. Reuse untuk MenuBar, jangan mengubah urutan Analytics hanya demi MenuBar. |
| Repository | JSON `.atomic`, history finalization idempotent berdasarkan UUID, banked-event per ID. Belum ada transaksi lintas file; beberapa API baca mengembalikan kosong pada error dan deleteProvisional tidak mengembalikan hasil. Jangan menjanjikan zero data loss pada disk yang tidak dapat ditulis. |

### 22.4 Alur UI dan state

Urutan konten yang ditargetkan: ruler/durasi → preset saat idle → Mode → ikon allowed/blocked + Edit (hanya dua mode itu) → Today's catches → error/save status bila ada → footer `start` saat idle atau `restart` + `pause`/`resume` saat sesi, beserta More actions. Detail spacing menyesuaikan panel ringkas; tidak menambah task name, website, ilustrasi dekoratif atau statistik all-time.

| State | Mode dan app | Timer / tindakan | Ikan |
|---|---|---|---|
| Idle | Picker enabled; editor app enabled bila Allowing/Blocking | Ruler editable 1–60 menit + preset existing; Start/Play aktif kecuali Allowing kosong / operasi belum selesai | Hari ini |
| Active | Mode read-only; Edit app enabled | Ruler indikator tersisa; teks `restart` + `pause` di footer | Hari ini; update sesudah banking |
| Paused | Mode read-only; Edit app enabled | Waktu berhenti; teks `restart` + `resume` di footer | Hari ini |
| Finishing / retrying | Jangan tampilkan idle palsu; mode/editor/start dikunci sementara | Indikasi menyimpan yang ringkas; tidak membuat sesi baru | Banked yang valid tetap boleh terlihat |
| Save failed | Status jelas dengan Retry saving, data pending dipertahankan | Jangan membuat sesi baru/reset success palsu | Jangan mengarang catch sebagai berhasil |
| Completed berhasil | Kontrol idle; mode terakhir tetap | Otomatis buka panel; durasi pilihan terakhir tetap; tanpa completion card | Refresh lalu tampilkan hari ini |
| Reset berhasil | Idle; mode dapat dipilih lagi | Durasi sesi yang di-reset menjadi pilihan siap Start; panel tetap terbuka, tidak bunyi completion | Banked dipertahankan, provisional sesuai threshold |

- Pause menunda timer/catch/monitor seperti behavior existing; edit saat paused mengubah snapshot tersimpan, evaluasi efektif saat Resume. Tidak menghidupkan kembali monitoring/overlay selama paused.
- Jangan biarkan default keyboard action parent memulai/pause sesi ketika fokus ada di search/checkbox/popover. Enter di editor dapat menutup Done; Space mengubah checkbox; Escape menutup editor lebih dahulu.
- Semua ikon kontrol memiliki tooltip dan accessibilityLabel yang sesuai aksi aktual. Mode lock harus terbaca, misalnya `Mode cannot be changed during a session`.
- App ditandai melalui bundle ID stabil; nama/icon hanya presentasi. qyube sendiri selalu aman seperti exception existing, bukan item yang dapat dipilih untuk memblokir akses kontrolnya sendiri.

### 22.5 Kontrak app-only, preferensi, dan edit live

**Satu sumber sesi:** selama active/paused, ringkasan/editor membaca `snapshot.draft.policy`, bukan hanya preferences yang bisa berbeda. Idle membaca FocusPreferences. Tidak membuat policy kedua di @State tanpa sinkronisasi.

Fungsi usulan di `SessionCoordinator` (nama boleh disesuaikan):

`updateAppRules(allowedApps: Set<String>, blockedApps: Set<String>) -> Bool`

1. Hanya menerima active/paused, bukan nil/terminal/finalizing. Jangan menerima mode baru dari view; pertahankan mode dalam snapshot. Trim/validasi bundle ID nonkosong dan jangan membuat dependensi nama app/file path.
2. Update set relevan untuk mode sesi; set mode lain dipertahankan. Tolak menghapus app terakhir pada Allowing, tampilkan alasan ringkas dan biarkan checkbox tetap selected. Blocking kosong sah.
3. Buat candidate snapshot tanpa mengubah UUID, deadline, accumulated time, pausedAt, catch phase, analytics segment atau accountID.
4. Persist candidate melalui saveActive lebih dahulu. Bila gagal: tidak publish policy baru, tidak centang UI sukses palsu, pertahankan policy efektif lama dan tampilkan Retry/change error.
5. Sesudah berhasil: publish snapshot → app coordinator menerima perubahan → policy monitor/overlay memakai aturan baru. Salin perubahan app set relevan ke preference default untuk sesi berikutnya. Jangan membiarkan observer policy global mengubah mode sesi.
6. Pastikan `@Published`/subscription ordering tidak membaca snapshot lama saat mengevaluasi perubahan. Jangan restart clock, pause/resume, reset catch atau analytics hanya karena app list berubah.

Idle: setiap toggle memperbarui preferensi langsung. Untuk active/paused, urutan authoritative adalah snapshot tersimpan kemudian preferences. UserDefaults bukan transaksi bersama file snapshot; jika aplikasi crash di sela keduanya, sesi yang dipulihkan harus tetap memakai snapshot valid. Tambahkan pengujian round-trip preferences dan pesan jika jalur persist yang dipilih dapat melaporkan failure; jangan mengklaim fsync guarantee dari didSet yang menelan error encoding.

**Efek langsung:** `DistractionCoordinator` harus reevaluate foreground activity dengan policy terbaru dalam siklus update yang sama, termasuk ketika user menutup editor kembali ke app yang sudah aktif. Reuse/resample NSWorkspace; cegah async result policy lama atau domain lookup lama menimpa decision baru. Bila app yang tadinya diblokir diizinkan, overlay harus berhenti; sebaliknya app yang baru diblokir mendapat respons existing. Pause tetap bebas overlay.

**Legacy domains:** jangan menghapus field Codable, riwayat atau domain tersimpan secara destruktif. Untuk Start baru dari semua entry point, buat policy efektif app-only dengan kedua set domain kosong; jangan request Automation untuk rules app-only. Preference legacy boleh disimpan untuk kompatibilitas tetapi tidak diam-diam dipakai oleh draft baru. Sesi legacy active/paused yang dipulihkan harus dinormalisasi ke app-only melalui saveActive terkontrol sebelum dilanjutkan, sambil mempertahankan mode/app/time/account/UUID. Bila gagal simpan, tampilkan error dan jangan mengumumkan migrasi sukses. Catat normalisasi satu kali untuk recovery. Field browser/domain boleh tetap ada pada model demi decode history; bukan alasan menampilkan editor website lagi.

**Settings:** setelah editor MenuBar berfungsi, hapus disclosure Focus rules dari Settings utama dan akses legacy yang masih reachable, atau alihkan ke editor yang sama dengan lock/update callback yang sama. Pilihan utama: konfigurasi focus lewat MenuBar saja, tanpa dua UI yang menulis policy dengan aturan berbeda. Audit `NewSessionView` dan seluruh pemanggil `QyubeAppRuleEditor`, `FocusPreferences.draft`, `startSession` supaya entry point lain yang masih dapat dicapai tidak memulai Allowing kosong, mengaktifkan domain, atau melewati aturan live.

### 22.6 Editor app native dan lifecycle panel

- Gunakan SwiftUI `.popover` anchored ke tombol Edit, berisi TextField search, ScrollView/LazyVStack app row dengan AppIcon + nama + checkbox, tombol `Choose application…`, dan Done. Popover berinteraksi dengan keyboard; jangan mencoba menaruh TextField di SwiftUI Menu/NSMenu `moreActions`.
- Reuse scanning dari editor existing dengan ekstraksi sekecil yang diperlukan. Scan `/Applications`, `/System/Applications`, `~/Applications`, skip hidden/package descendants, dedupe bundleID, sertakan pilihan tersimpan yang hilang dari disk. Tampilkan nama fallback bundleID dan ikon fallback; tetap bisa uncheck app yang telah dihapus.
- Scan sekali saat dibutuhkan, bukan per body, per keypress, atau per detik countdown. Lakukan pekerjaan file enumeration di luar main actor lalu publish hasil di main actor; gunakan ikon lokal/cache existing, bukan network. Search lokal case-insensitive, urutan selected first lalu nama; jangan memindahkan row fokus mendadak saat toggle (stabilkan urutan selama popover terbuka).
- `Choose application…` memakai NSOpenPanel untuk satu `.app`; validasi Bundle dan bundleIdentifier. Cancel tidak mengubah data. App di path khusus masuk pilihan dan selected lewat callback yang sama. Jangan meminta akses filesystem luas hanya untuk discovery.
- UI menunjukkan `Changes apply immediately`; Done/Escape/klik luar hanya menutup. Checkbox memakai hasil callback persistence, bukan binding yang selalu dianggap sukses. Handle loading/empty search/error discovery tanpa menghapus selected IDs.
- **Wajib audit mouse monitor parent:** saat ini klik child popover dianggap di luar NSPanel dan menutup parent. Track popover/editor presentation dan window ownership/frame secara terarah; klik di popover atau NSOpenPanel milik editor tidak menutup parent. Jangan mematikan seluruh dismiss behavior secara permanen. Klik luar sesungguhnya menutup child lalu parent dengan aman, dan tidak mengonsumsi klik aplikasi lain.
- Escape menutup layer teratas; app picker/dialog tidak ditutup parent sebelum hasil diterima. Pastikan keyboard focus/search tidak hilang tiap snapshot/tick. Uji dengan actual NSPanel karena render statis tidak menguji event routing ini.

### 22.7 Reset: akhir sesi lama, bukan restart clock lama

- Cari semua caller `restartSession()` dan tes restart sebelum mengubah API. UI baru memanggil aksi reset/end yang melakukan finalisasi satu kali lewat coordinator existing; ubah nama API bila itu menghindari kontrak lama yang menyesatkan. Jangan meninggalkan caller yang diam-diam masih melanjutkan clock lama.
- Gunakan aturan Stop existing: active time tetap tercatat; banked catches tidak hilang. Provisional di bawah threshold lima menit dibuang, di atas/sama threshold di-bank; jangan memberi hadiah tambahan karena reset.
- Setelah finalisasi benar-benar berhasil, snapshot nil, timer/companion/overlay ditutup mengikuti alur existing; simpan durasi sesi sebagai selectedPresetMinutes. UI menjadi Start/Play untuk sesi baru. UUID/startedAt baru hanya dibuat saat user benar-benar menekan Start.
- Reset saat paused sama dengan reset saat active; pause time tidak ikut focus. Reset saat deadline sudah tercapai harus menyelesaikan completed lewat completeIfDue, bukan menciptakan interrupted yang terlambat.
- Ketika saving gagal, jangan mengosongkan snapshot atau membuat idle yang dapat Start lagi. Tahan pending outcome dengan Retry. Multiple clicks tidak menggandakan history, banking, callback, atau sound.
- Hapus Cancel dan rekomendasi End session di More actions; reset adalah jalan pengguna untuk mengakhiri. Tooltip disarankan `Reset and end session` agar aksi yang menyimpan sesi lama jelas. Tidak ada confirmation dialog tambahan untuk alur normal ini.

### 22.8 Completion dan kegagalan penyimpanan yang aman

**Jangan menjanjikan bahwa penulisan disk selalu berhasil.** Tangani kegagalan secara terukur: pertahankan data sumber recovery, jangan menampilkan sukses sebelum aman, dan sediakan retry idempotent.

1. Hilangkan `completedSession`/count sebagai penentu tampilan MenuBar dan hapus completion card/callback `onViewCatches` dari jalur ini setelah seluruh caller diperbarui. `QyubeNavigation.showCatches` hanya dihapus jika tidak dipakai di tempat lain.
2. Pisahkan aksi membuka panel dari data completion, misalnya `showIdleAfterCompletion()` hanya membuka panel setelah finalisasi sukses. `onSessionEnded` refresh navigation/catches, mempertahankan sound untuk completed, lalu membuka MenuBar kontrol idle. Interrupted/reset tidak memainkan completion sound.
3. Tambahkan state penyimpanan kecil pada coordinator, misalnya `finalizationState` dengan idle/saving/failed dan pending terminal intent. Ini diperlukan karena banking/saveActive bisa gagal sebelum snapshot menjadi terminal. UI tidak boleh menyimpulkan semua error hanya dari `snapshot.status`.
4. Bekukan waktu akhir dan activeSeconds pada finalization attempt pertama. Sesudah deadline jangan terus menambah focus seconds atau menjalankan catch saat disk error. Stop timer/catch/monitor pada transisi finishing dengan outcome yang dapat dicoba ulang; jangan mereset ledger/clock sumber sebelum persist berhasil.
5. Tulis terminal intent/snapshot secara atomic sebelum destructive cleanup provisional dan sebelum menghapus active record. Simpan ID/account/mode/draft/time/status yang sama untuk retry. Audit urutan Stop sekarang (menghapus provisional sebelum saveActive) dan Complete (bank sebelum saveActive); perbaiki hanya bagian yang dibutuhkan agar intent/recovery tidak hilang. Banked yang sudah tercatat tidak boleh dibatalkan bila langkah berikutnya gagal.
6. Setelah terminal snapshot durable: reconcile provisional → finalizeOnce history → cleanup active. Bila satu langkah gagal, tahan pending snapshot dan error; retry melanjutkan ID/outcome yang sama. Hanya panggil onSessionEnded/reset UI setelah ledger/history mencapai outcome sukses. Hapus active hanya setelah history tersimpan.
7. Gagal deleteActive sesudah history sukses tidak boleh membuat duplikasi atau replay sound pada launch berikutnya. Recovery perlu membedakan terminal yang sudah ada di history dari completion baru; finalization yang didedupe tidak mengulang callback/notifikasi/sound/panel tanpa alasan. Buktikan lewat tes restore proses baru, bukan cuma Set ID in-memory.
8. Retry manual jelas dan operasi tunggal. Boleh satu retry otomatis saat membuka panel/restore jika state pending, tanpa loop tanpa batas. Jangan busy retry tiap frame/tick atau mengganggu user dengan alert berulang. Jika semua penulisan gagal, jelaskan bahwa data masih pending dan jangan menyembunyikannya sebagai idle.
9. `deleteProvisional` sekarang Void/try?; bila penghapusan menjadi prasyarat outcome yang aman, ubah return/error secara minimal dan sesuaikan protocol, concrete repo, mocks, callers, tests. Jangan menambah framework transaksi/database hanya untuk alur ini. Corrupt history tidak boleh ditimpa dengan array kosong agar retry tampak berhasil.

Auto-open normal completion tetap berlaku seperti permintaan pengguna. Jika completion terjadi saat editor sedang terbuka, tutup editor dengan aman sebelum mengganti isi/height parent. Error finalisasi juga perlu terlihat saat panel dibuka otomatis pada akhir timer; tidak boleh meninggalkan sesi macet tanpa penjelasan.

### 22.9 Today's catches: data, render, refresh

- Sumber authoritative `CatchRepository.listBanked(accountID:)` dengan account sesi/local existing; jangan menggabungkan akun. Reuse `DailyCatchSummary.events(on:from:calendar:)` → filter kind.isFish → reverse urutan event → prefix(20). Ocean finds tetap ada di Analytics/Catalog, tidak masuk baris khusus ikan ini. Unknown kind tidak crash; jangan menebak artwork spesies.
- Filter berdasarkan **depositedAt**, bukan bankedAt; catch kemarin yang baru dibank hari ini tetap milik kemarin, sesuai Analytics. Deduplicate UUID, bukan kindID. Jangan memakai groups(for:) karena user ingin duplikat ikan tetap terlihat.
- Reuse `QyubeCatchArt(kindID:catalog:false)` dan asset Collectible lokal. Ukuran gambar konsisten sekitar 32–40 pt, satu baris, tanpa bg/border/card. Seluruh daftar maksimum 20 node, tanpa gambar baru atau unduhan favicon.
- Gunakan ScrollView horizontal + `.scrollIndicators(.hidden)`; jangan pasang modifier custom QyubeScrollIndicator di baris ini. Beri fade/partial next fish sebagai petunjuk overflow bila perlu, tanpa scrollbar. Trackpad/Shift-wheel dan accessibility scrolling tetap berfungsi.
- View-only: tidak ada Button/onTapGesture, pointer affordance, View all atau navigasi. Tooltip nama/jam dan accessibility label boleh; setiap event yang diketahui tetap dibacakan sebagai item berbeda.
- Refresh saat panel muncul, catch deposit/banking sukses, banking threshold lima menit (meskipun tidak ada deposit baru), finalisasi/recovery, dan hari lokal berubah. Notification existing lastCatchEvent saja belum cukup untuk banking batch; emit collectionChanged setelah mutation bank sukses atau refresh melalui outcome coordinator yang tepat.
- Refresh juga saat wake/timezone/system day change; panel yang dibiarkan terbuka melewati tengah malam harus menjadi hari baru. Recompute interval dengan Calendar.current; hindari hardcode 86400 detik/DST. Data lama di-cache untuk presentasi saja, tidak dibaca ulang dari disk tiap countdown tick.
- Jika baca repository hanya mengembalikan [], jangan mengklaim bisa membedakan disk error dari hari kosong. Untuk jalur load yang perlu membedakan error, tambahkan hasil/error lokal yang minimal; jangan tampilkan `No catches today` sebagai pesan untuk kegagalan baca yang diketahui.

### 22.10 Ukuran, warna, dan integrasi file

- Reuse qyubeBackground, qyubeInk, qyubeLine, qyubeSelection dan qyubeAccent Arctic. Tidak generate asset baru pada pekerjaan ini. Ukuran lebar mulai dari 250 pt existing; sesuaikan hanya jika search/controls membutuhkan ruang dan catat ukuran akhir.
- Tinggi parent harus memakai satu sumber ukuran yang dihitung dari state/konten, diterapkan ke frame root dan NSPanel positioning. Reposition saat mode/empty/error berubah; anchor tetap di bawah status item, clamp ke visibleFrame monitor yang relevan. Child popover tidak keluar layar bila status item di ujung kanan.
- App list detail boleh scroll vertikal pada tinggi terbatas. Panel parent tetap ringkas; jangan memasukkan seluruh daftar app ke parent atau membiarkan tinggi tumbuh mengikuti jumlah ikan.

| File / area | Perubahan implementasi yang diharapkan |
|---|---|
| `Qoma/UI/MenuBar/MenuBarView.swift` | Mode picker/locked state, rule summary + live editor, kontrol footer berbasis teks, reset, view-only catch strip, idle completion, error/retry, height adaptif. |
| `Qoma/Managers/MenuBarController.swift` | Injection preferences/data/callback seperlunya, hapus state completion card, show idle on finish, resize/reanchor, child popover/file picker dismissal handling. |
| `Qoma/Managers/QyubeAppCoordinator.swift` | Start app-only, bind live snapshot rules ke monitoring, refresh catch saat banking, completion/reset outcome, no duplicate sound, account source konsisten. |
| `Qoma/Domain/Focus/SessionCoordinator.swift` | updateAppRules, reset/end semantics, pending/error finalization/retry/recovery, outcome yang tidak mengandalkan optional session semata. |
| `Qoma/Domain/Focus/FocusPreferences.swift` | Default mode/set reuse, draft app-only, validasi Allowing, kompatibilitas legacy. Jangan mengganti key preference pengguna. |
| `Qoma/UI/Main/NewSessionView.swift` / editor | Reuse/extract app discovery/editor secara minimal; hapus reachable domain UI, selaraskan validasi dan call sites. Jangan refactor seluruh file legacy tanpa kebutuhan. |
| `Qoma/UI/Main/QyubeJournalSettingsView.swift` | Hapus Focus rules sementara setelah MenuBar replacement berfungsi; audit akses legacy lainnya. |
| `Qoma/Services/DistractionCoordinator.swift`, `ForegroundActivityMonitor.swift` | Reevaluate app sekarang, stale-result protection, paused semantics; tidak reset clock/catches/detour tanpa sebab. |
| `Qoma/Domain/Focus/FocusPolicyEvaluator.swift` | Reuse allowing/blocking app semantics; tests app-only browser dan empty Blocking. Domain model/history tetap decode-compatible. |
| `Qoma/Models/DailyCatchSummary.swift` / strip helper bila perlu | Reuse day filter/dedupe; helper latest fish hanya bila mempermudah tes tanpa menduplikasi Analytics aggregation. |
| `Qoma/Persistence/SessionRepository.swift`, `CatchRepository.swift` | Perubahan terarah hanya untuk failure/retry/cleanup correctness; atomik per file, UUID idempotence dan compatibility dipertahankan. |
| `Qoma/Utils/Constants.swift` | Ukuran adaptif/konstanta batas 20 bila perlu; hapus height fixed sebagai kontrak tunggal yang salah. |
| `QomaTests` | Update kontrak restart lama, tambah live rules/failure/selection/catch day tests; mocks mengikuti API yang benar-benar berubah. |

### 22.11 Urutan pengerjaan agent implementasi

1. **Audit baseline:** git status, AGENTS/skills yang berlaku, semua caller restart/stop/start/editor/showCompletion, repo mocks dan tes. Baca dua referensi `kiki-screenshots/new-session.png` dan `kiki-screenshots/allow-list.png` untuk komposisi, bukan menyalin karakter/warna Kiki. Verifikasi Arctic tokens sudah ada.
2. **Kunci behavior domain dengan tes:** app-only draft/legacy compatibility, Allowing nonempty vs Blocking empty; updateAppRules transactional candidate; reset ke idle dan sesi baru saat Start. Tes existing yang menyatakan restart same UUID + langsung active harus diperbarui, bukan dibiarkan melindungi behavior yang dibatalkan.
3. **Finalisasi aman:** audit ordering, error state dan recovery; implement/fault-test sebelum UI membuang completion state. Jangan membuat panel idle lebih dulu untuk menyembunyikan failure.
4. **Editor dan monitor:** native popover/app discovery + immediate callback, snapshot→monitor update, stale decisions dan paused handling. Hubungkan Settings/entry point existing ke kontrak yang sama.
5. **Panel UI:** mode + summary, icons, reset, daily fish strip, adaptif height, completion auto-open dan child window lifecycle. Hapus callback/state yatim hanya sesudah semua caller dipindahkan.
6. **Verifikasi terarah kemudian suite/build:** cek domain tests, lint file berubah, render state, native interaction. Catat keterbatasan tes hardware. Tidak menambah akun/backend/website atau fitur di luar scope.

### 22.12 Rencana pengujian dan acceptance criteria

**Tes behavior/data yang bermakna (gunakan clock/repository injection existing):**

- Start Allowing kosong ditolak pada semua reachable entry points; Blocking kosong boleh; Timer only tidak menjalankan policy monitor. Memilih browser berlaku seluruh browser dan tidak meminta Automation untuk rules.
- Edit app saat active tersimpan di active snapshot + efektif tanpa mengubah mode/UUID/time/account/catch phase. Resume sesudah edit paused memakai aturan baru. Restore membaca aturan live terakhir. Last allow item tidak bisa dihapus; Blocking dapat dikosongkan.
- saveActive gagal pada live update: checkbox/snapshot/policy efektif tidak berubah dan error terlihat; retry valid sukses. Edit app yang sedang foreground memperbarui isDistractionActive tanpa pindah app. Result lama tidak mengembalikan overlay setelah app diizinkan; pause tidak memunculkan overlay.
- Preferences mempertahankan dua set lintas mode/launch. Domain legacy tetap decode dan tersimpan pada history; draft baru app-only. Mode tidak dapat dibypass melalui Settings yang masih reachable. Normalisasi restore tidak mengubah duration/ID/account.
- Reset active dan paused: history interrupted satu kali, actualActiveSeconds benar, snapshot akhirnya nil, tidak autostart, durasi awal tetap. Start berikutnya UUID baru dan activeSeconds nol. Reset pada deadline menjadi completed satu kali. Provisional <5 menit dibuang, >=5 menit di-bank, banked existing tetap ada.
- Fault injection untuk bank, terminal save, history write, delete active, delete provisional bila contract diubah; retry tidak menduplikasi history/catch/callback, tidak menambah active time setelah deadline, dan tidak menghapus sumber recovery sebelum durable intent. Restore proses baru mengatasi partial bank/history success/cleanup failure tanpa replay alarm.
- Catch strip: tanggal lokal/DST/tengah malam/timezone change; depositedAt versus bankedAt; provisional exclude; fish-only, duplicate species retain, UUID dedupe, newest-first stable tie, >20 dibatasi, unknown kind aman, account isolation. Bulk banking threshold memperbarui daftar tanpa menunggu deposit baru.

**Native UI QA wajib sebelum dinyatakan selesai:**

- Idle tiga mode, Allowing kosong, Blocking kosong, banyak pilihan, active, paused, save failed dan completion auto-open. Tidak ada completion card, Cancel atau End session menu yang tertinggal.
- Checkbox/search/Done/Escape/klik luar, membuka NSOpenPanel, pilih file valid/cancel, menutup dan membuka ulang parent; parent tidak menutup ketika interaksi child. Fokus text tidak direbut keyboard Start/defaultAction.
- `restart`/`pause`/`resume` actual behavior sesuai label teks; disabled/loading/error mencegah double submit; mode read-only tetapi Edit tersedia selama active/paused.
- Horizontal catches tanpa scrollbar, tidak clickable, tooltip dan VoiceOver/keyboard labels masuk akal; input scroll tetap berfungsi.
- Panel bertambah/mengecil tanpa crop dan tetap di layar pada monitor kanan/kiri/berbeda skala; completed saat child terbuka/waktu layar tidur tidak meninggalkan popover yatim. Floating timer/companion existing tetap sinkron.
- Build Debug macOS dan tes domain terdampak wajib lulus; lint/format file yang diubah dan `git diff --check`. Laporkan warning baseline terpisah; jangan mengklaim native clicks teruji hanya dari NSHostingView render.

**Definition of done:** mode/app editor berfungsi dari MenuBar, edit live durable dan efektif, reset mengakhiri sesi secara aman, completion otomatis membuka idle, strip ikan harian view-only benar, Settings tidak menjadi jalur aturan yang bertentangan, serta failure/recovery dan native popover QA sudah dibuktikan.

### 22.13 Hasil pembaruan dokumen hari ini

- Snapshot perubahan branch sebelumnya disimpan sebagai `daaaafd`; branch baru dibuat dari HEAD itu tanpa reset/cherry-pick atau perubahan kode aplikasi.
- Rencana di atas menggabungkan seluruh persetujuan dan pengecualian pengguna terhadap pertanyaan grill. Restart/end, live edit apps, app-only, Blocking kosong, auto-open completion, scrollbar hidden dan view-only catches adalah keputusan terbaru.
- Validasi saat perencanaan: sumber kode dan referensi telah diperiksa, struktur/link file dicek dan `git diff --check` dijalankan. Build/test runtime belum dijalankan pada tahap perencanaan tersebut.

### 22.14 Hasil implementasi — 17 Oktober 2026

- MenuBar sekarang memakai panel Arctic adaptif 280 pt dengan mode, ringkasan app, editor popover native, strip ikan harian, status penyimpanan, dan footer teks `start` / `restart` + `pause` / `resume`.
- Policy sesi baru dan policy yang dipulihkan dinormalisasi menjadi app-only. Allowing kosong ditolak, Blocking kosong sah, dan perubahan app live disimpan ke snapshot sebelum dipublikasikan.
- Reset mengakhiri sesi ke idle dan Start berikutnya membuat UUID baru. Finalisasi menyimpan terminal intent lebih dahulu, membekukan waktu saat gagal, dan menyediakan retry idempotent.
- Completion card dan jalur Focus rules lama di Settings dihapus. Completion alami me-refresh data, memainkan sound existing, lalu membuka kontrol idle.
- QA native membuktikan mode menu tidak menutup parent, pencarian/checkbox memperbarui pilihan langsung, dan Done hanya menutup popover. Build Debug dan seluruh test suite macOS lulus; warning lint/concurrency yang tersisa berasal dari baseline di luar scope ini.

### 22.15 Redesign Ink & Ice — 17 Oktober 2026

- Semua perubahan branch sebelumnya disimpan dalam `5990f1a`, lalu redesign dikerjakan di `codex/menubar-ink-and-ice`.
- Panel 310 pt mengikuti draft `output/imagegen/menubar-draft-03/01-ink-and-ice.png`: header qyube/gelombang/gear, penguin watercolor bergerak lembut, dropdown durasi, mode dan ringkasan app, ikan harian, serta footer Start atau Pause/Resume dan Stop dengan proporsi 4:1. Permukaan warna polos dengan border tinta, tanpa background image.
- Editor app tetap popover terpisah. Header `list` dan `Allow List`/`Block List`, pencarian, baris app bercheckbox, akses Choose application, serta footer Done mengikuti referensi Kiki dan palette yang sama. Callback live update, guard Allowing kosong, error, dan persistence tetap memakai alur existing.
- Build Debug macOS, tes coordinator/reset/live rules, daily catch summary, dan menu-bar timer lulus. Render AppKit memeriksa idle timer-only/Allowing, active, paused, serta kedua editor; screenshot tersimpan di `output/menubar-ink-and-ice/`. Harness render sementara dihapus sesudah inspeksi.
- Klik/keyboard native pada panel, pencarian, NSOpenPanel, dan multi-monitor belum diuji ulang pada redesign ini; hasil render tidak dianggap bukti event routing.

## 23. Hand-drawn Arctic untuk app utama — 17 Oktober 2026

**Status:** complete

### 23.1 Scope

- Buat primitive border/surface yang stabil, sedikit miring, tidak terpotong, dan deterministik.
- Gunakan palette Arctic v1 secara persis untuk foundation, interaction, rarity, dan heatmap.
- Terapkan melalui komponen bersama ke Settings, Analytics, Catalog, navigation selection, catch cards, dan timeline cards.
- Pertahankan kontrol macOS native, data flow, accessibility, dan perilaku navigasi existing.
- Hindari background image, texture, dependency baru, dan dekorasi pada setiap row.

### 23.2 Fase

1. **complete — Foundation:** palette tokens, ink surface/divider, border MenuBar yang tidak clipping.
2. **complete — Shared components:** SettingsSurfaceCard, navigation selection, headers, catch cards.
3. **complete — Page treatment:** Settings, Analytics, Catalog dan detail sheet.
4. **complete — Validation:** lint, build, tests terdampak, render pada ukuran window minimum dan normal.

### 23.3 Acceptance

- Border organik tetap utuh pada semua sisi dan tidak berubah antar-render.
- Informasi chart/heatmap tetap geometris dan terbaca; gaya hand-drawn berada pada struktur dan selection.
- Settings standalone dan halaman Settings dalam app berbagi visual language yang sama.
- Build Debug macOS, tests terkait, lint file berubah, dan `git diff --check` lulus.

### 23.4 Error log

- Patch gabungan pertama gagal karena konteks extension rarity berada di `QyubeCompactComponents.swift`, bukan `CatalogView.swift`; patch dipecah dan target diperbaiki tanpa perubahan parsial.
- `xcodebuild -list` di sandbox gagal mengakses DerivedData/SwiftPM cache pengguna; validasi dipindahkan ke derived data `/tmp` dengan izin build yang sesuai.
- `ImageRenderer` tidak dapat menangkap kontrol AppKit dan menghasilkan placeholder; harness sementara diganti dengan `NSHostingView` di window buffer.
- Dua percobaan output visual awal tertahan sandbox test karena jalur `/tmp` lama/bersama; output dipindahkan ke container temp unik dan parallel testing dimatikan.
- Render halaman anak sempat mengikuti Dark Mode karena berada di luar root app; capture final memakai light scheme yang sama dengan `QyubeHomeView`.

### 23.5 Hasil implementasi

- Border tinta sekarang diinset aman dan dipakai melalui satu modifier surface; divider organik baru menggantikan garis kaku pada struktur utama.
- Settings standalone/in-app, Analytics, Catalog, sidebar selection, kartu tangkapan, timeline, dan theme preview memakai bahasa Ink & Ice yang konsisten.
- Palette memakai nilai Arctic v1 persis, termasuk `Interrupted` dan rarity; native controls serta geometri chart tetap dipertahankan.
- Build Debug macOS, 49 tes Analytics/Daily Catch, visual render pada ukuran minimum/normal, lint seluruh Swift yang berubah, dan `git diff --check` lulus.

## 24. Storage lokal, persetujuan analytics, dan kesiapan rilis — 18 Oktober 2026

**Status:** sedang dikerjakan. Pekerjaan dipisah dalam branch bertingkat pada worktree yang sama; tidak membuat worktree baru.

### 24.1 Batas scope

- Termasuk: SQLite untuk catch/session/analytics, query berbasis indeks, migrasi JSON non-destruktif, persistence analytics yang dapat gagal secara eksplisit, opt-in analytics, koreksi deteksi idle, penyamaan target macOS, tes migrasi/data besar/disk failure/reopen, dan pembersihan prototype yang terbukti tidak terpakai.
- Tidak termasuk pada tahap ini sesuai keputusan pengguna: paywall wajib sebelum login/billing siap, pemisahan data antar akun riil, serta jalur produksi download dan auto-update.
- Tetap gunakan `accountID` sebagai ownership key di database untuk struktur dan query lokal; nilai aktif masih `local`. Ini bukan implementasi multi-account atau autentikasi.
- Jangan menghapus source JSON setelah migrasi. UUID tetap menjadi kunci idempotensi; marker migrasi hanya ditulis setelah transaksi import berhasil.

### 24.2 Branch dan hasil yang diharapkan

1. `codex/sqlite-storage-foundation` — connection SQLite bersama, transaksi, schema/index awal dan strategi WAL/FULL sync.
2. `codex/legacy-data-migration` — catch/session JSON lama masuk ke database tanpa menghapus sumber, query repository memakai account/session/date/kind.
3. `codex/analytics-safety-consent` — AnalyticsStore SQLite, penulisan mengembalikan sukses/gagal, analytics nonaktif sampai opt-in pada pembukaan Home pertama; pilihan dapat diubah dari Settings.
4. `codex/storage-load-and-platform-tests` — checkpoint analytics, failure/reopen recovery, tes volume/migrasi/disk penuh atau lokasi tak dapat ditulis, target test disamakan dengan minimum aplikasi, dan idle detection mencakup keyboard serta interaksi mouse.
5. `codex/remove-obsolete-prototypes` — hapus hanya implementasi prototype yang tidak memiliki caller, resource reference, test harness aktif, atau jalur debug yang masih dipakai.

Setiap branch harus dapat dibangun dari parent branch sebelumnya dan memiliki catatan hasil/risiko yang terlihat di commit. Perubahan lokal yang sudah ada sebelum pekerjaan ini tetap milik pengguna dan tidak dimasukkan ke commit implementasi.

### 24.3 Urutan migrasi dan ketahanan

- [x] Satu database `Application Support/Qoma/qoma.sqlite3`, WAL, `synchronous=FULL`, foreign keys, timeout busy, tabel record bertipe dengan kolom payload Codable dan kolom indeks yang dibutuhkan query.
- [x] Catch: indeks `(account_id, deposited_at)`, `(account_id, kind_id)`, `(account_id, session_id, banked_at)`; provisional dan banked tetap event yang sama, UUID idempotent.
- [x] Session: simpan active snapshot dan history terpisah menurut `record_type`; finalisasi satu transaksi/upsert idempotent dan dapat dipulihkan.
- [x] Analytics: indeks per account/tanggal dan account/session; app activity serta website visit checkpoint agar crash tidak menghilangkan seluruh sesi aktivitas.
- [x] Migrasi legacy aggregate dan per-event catch JSON, active/history session JSON, serta tiga JSON Analytics; marker berada dalam database dan sumber legacy dipertahankan sebagai backup sampai ada proses backup/cleanup eksplisit.
- [x] Jika decode, transaksi, atau disk write gagal, jangan menulis marker sukses atau melaporkan operasi berhasil. Operasi dapat dicoba ulang saat aplikasi dibuka lagi.
- [x] Terapkan consent opt-in pada pembukaan Home pertama; dashboard tetap membaca histori yang sudah ada, sementara tracker baru tidak merekam sebelum izin diberikan. User dapat mengubah pilihan di Settings; pencabutan izin menghentikan tracker dan menghapus aktivitas sesi yang sedang berjalan.
- [x] Uji reopen setelah committed state, duplikasi migrasi, dataset besar, gagal membuka/menulis database, transaksi rollback, dan finalisasi recovery.

### 24.4 Platform dan validasi

- [x] Aplikasi dan test target disamakan ke deployment target macOS 14.0 (build memakai macOS SDK 26.2).
- [x] Idle detection memakai event input umum CoreGraphics, tidak lagi hanya `mouseMoved`.
- [x] Build Debug macOS dan seluruh 185 tes lulus; test dijalankan pada macOS 26.5.2, sehingga runtime langsung di macOS 14 masih perlu QA terpisah. Warning SwiftLint/concurrency dan Info.plist resource tetap dicatat sebagai warning, bukan dianggap error build.
- [x] Audit reference sebelum menghapus file prototype; pertahankan visual guide/design archive yang masih menjadi dokumentasi arah aset.
- [x] Tinjau `git diff --check`, perubahan tidak menyertakan imagegen user yang telah ada, dan dokumentasikan file/behavior yang berubah per branch.

### 24.5 Persiapan setelah pekerjaan ini

Setelah storage, consent, recovery, serta platform tests stabil, lanjutkan finalisasi aset ikan/penguin dan konsistensi visual. Landing page, login, backend, payment, akun riil, direct download produksi, serta auto-update tetap fase berikutnya dan bukan gate untuk menilai branch storage ini.

### 24.6 Hasil implementasi — 18 Oktober 2026

- Branch 1–3 telah dicommit berurutan: `598a742` SQLite foundation, `aee02b1` migrasi legacy, dan `640aca7` analytics consent/checkpoint.
- Pada branch 4, migrasi catch memakai lokasi legacy yang benar dan tanggal ISO-8601 konsisten; migrasi analytics JSON memakai tipe record yang tepat; transaksi SQLite rollback tetap atomic. Test histori tidak lagi bergantung pada urutan dua sesi dengan timestamp sama.
- Build Debug berhasil pada target deployment 14.0; seluruh 185 tes lulus pada macOS 26.5.2. Cakupan meliputi volume 5.000 tangkapan, migrasi idempotent/retry, file JSON sumber tetap ada, disk/database failure, commit/reopen, rollback, recovery terminal session, serta consent dan checkpoint analytics.
- Warning SwiftLint/concurrency dan peringatan Info.plist dalam Copy Bundle Resources masih ada; semuanya nonfatal. Tes runtime langsung pada macOS 14 dan QA fisik/UX tetap perlu dilakukan.
- Perubahan UI analytics dan folder ilustrasi collectible yang sudah ada sebelum pekerjaan ini tetap tidak dimasukkan ke commit implementasi.

### 24.7 Audit prototype tak terpakai — 18 Oktober 2026

- Branch `codex/remove-obsolete-prototypes` telah diaudit terhadap source call sites, test/debug routes, SwiftUI previews, dan referensi proyek.
- `Qoma/UI/Aquarium/` tidak memiliki caller di alur produk dan user sudah mengeluarkan Aquarium dari scope fitur. Namun `AquariumView.swift` serta `AquariumArtwork.swift` masih dipakai oleh `#Preview("Aquarium • standalone")` sebagai harness ilustrasi interaktif. Karena preview itu masih berguna dan belum ada persetujuan eksplisit untuk menghapus prototype visualnya, tiga file Aquarium tidak dihapus.
- `CompanionVisualCheck` dan `DistractionVisualCheck` tidak dihapus: keduanya dirujuk oleh argument routes `AppDelegate` untuk render-check visual.
- Tidak ada file prototype yang terbukti aman dihapus setelah audit; branch ini berisi dokumentasi keputusan saja. Aset dan folder desain user tetap dipertahankan.

## Compact UI — roadmap terbaru, 20 Oktober 2026

Status: penyusunan roadmap selesai; implementasi compact UI belum dimulai dalam pekerjaan ini.

Acuan keputusan terbaru: `design/qyube-compact-flow-context.md`. Rencana eksekusi: `design/qyube-compact-roadmap.md`. Keduanya mengungguli keputusan lama yang bertentangan mengenai ukuran window, goal, nama tugas wajib, break, repeat, routing menu bar, dan presentasi Catalog. Kebijakan bisnis/backend lama perlu diselaraskan sebelum integrasi layanan; redesign UI tidak otomatis menggantinya.

- [x] Gabungkan keputusan dan inventaris screen terbaru.
- [x] Susun urutan UI, milestone, integrasi lokal, perilaku baru, backend, dan QA.
- [ ] Fase 1: UI-01–UI-11 (mulai Batch 1: fondasi, Today, form/editor, detail sesi).
- [ ] Fase 2: wiring runtime/data lokal existing.
- [ ] Fase 3: daily goal, break, repeat dan transisi baru.
- [ ] Fase 4: integrasi layanan/backend yang diperlukan.
- [ ] Fase 5: QA menyeluruh dan persiapan rilis.

Checkbox fase implementasi adalah pekerjaan masa depan, bukan permintaan untuk mulai coding pada turn perencanaan ini.

## Compact UI — mulai Batch 1, 21 Oktober 2026

Catatan ini memperbarui status rencana tanggal 20 Oktober di atas tanpa menghapus keputusan historisnya.

- Pengguna mengizinkan implementasi **fondasi + Today** setelah mempelajari `Qoma/UI/MenuBar/MenuBarView.swift` sebagai rujukan visual dan pola UI.
- Sebelum coding, simpan semua perubahan yang sudah ada pada branch `codex/remove-obsolete-prototypes` dalam commit; majukan checkpoint `codex/storage-load-and-platform-tests`, lalu kerjakan Batch 1 pada branch terpisah `codex/qyube-foundation-today`.
- Scope kode Batch 1: kerangka window awal 420 × sekitar 700 pt yang tetap resizable, header bersama dengan qyube/coretan dan navigasi, gaya Ink & Ice serta komponen seperlunya, lalu Today dengan progress daily goal, penguin, daftar sesi hari ini, dan footer Create new session.
- Reuse komponen atau perilaku `MenuBarView` yang memang sama. Today tetap layar mandiri; CTA membuka `NewSessionView` yang sudah ada, jadi desain ulang form tetap berada di UI-04.
- Data Today memakai histori lokal yang sudah tersedia. Goal 2 jam masih default presentasi; goal yang bisa diedit dan persistence mengikuti fase roadmap. CTA memakai alur Start lokal yang ada dan menutup main window setelah sukses; backend tidak disentuh.
- [x] Checkpoint commit `916c4d5` menyimpan semua perubahan pending pada branch `codex/remove-obsolete-prototypes`; branch `codex/storage-load-and-platform-tests` fast-forward ke commit yang sama.
- [x] Branch kerja `codex/qyube-foundation-today` dibuat dari checkpoint.
- [x] Fondasi UI: window dibuka pada 420 × 700 pt, tetap resizable dengan minimum 360 × 480 pt, menyimpan ukuran/frame, memakai header ink-wave yang sama dengan MenuBar, dan memulai di Today.
- [x] Today: ringkasan progress goal default 2 jam dengan ilustrasi penguin, daftar sesi lokal hari ini dengan status, empty state, footer Create new session, serta Back to session saat sesi aktif/paused.
- [x] CTA Today memakai form sesi yang sudah ada; keberhasilan Start menutup window utama, dan Back to session memilih floating timer atau popover menu bar sesuai preferensi.
- [x] Build Debug macOS berhasil dengan Xcode/macOS SDK 26.2; test suite tidak dijalankan. Warning SwiftLint/concurrency lama pada file lain tetap ada.
- Status: fondasi + Today selesai pada working tree branch `codex/qyube-foundation-today`; perubahan UI belum di-commit. Redesign New Session dan pengaturan daily goal tetap tahap berikut.


### Revisi kepadatan Today — 21 Oktober 2026

- Arahan terbaru menggantikan ukuran 420 × 700 pt: panel tetap 310 × 470 pt, tanpa traffic light dan tanpa resize. Isi tetap dapat discroll.
- Window borderless tetap menerima fokus/keyboard, bisa digeser dari area kosong, dan dapat ditutup dengan Escape. Ukuran frame lama tidak dipulihkan.
- Border tinta masuk sekitar 6 pt dari tepi panel; contour dan divider organik deterministik diperjelas, header/goal/ilustrasi dirapatkan.
- Palette diselaraskan: porcelain #FAFBF8, ink #253E4A, ice #E4EFF2, accent #386779.
- Penghapusan gambar draft 02/03 yang sudah ada pada working tree tidak disentuh.
- Validasi revisi: build Debug arm64 berhasil dan `git diff --check` bersih. Inspeksi visual langsung serta test suite belum dijalankan.

### Penyesuaian ukuran Today — 21 Oktober 2026

- Tinggi panel dinaikkan dari 470 menjadi 700 pt; lebar tetap 310 pt, tanpa traffic light dan tanpa resize.
- Jarak border tinta dari tepi dikurangi sekitar 2 pt (dari sekitar 6 menjadi 4 pt). Ukuran preview Today mengikuti panel.

### New Session dan detail sesi — 21 Oktober 2026

- Fondasi Today di-commit sebagai `c3604f4` pada `codex/qyube-foundation-today`; pekerjaan berikutnya dilakukan di branch baru `codex/qyube-new-session-detail`.
- Panel utama diturunkan menjadi 310 × 510 pt. Scrollbar Today, form, dan editor aturan disembunyikan, tetapi konten tetap bisa discroll.
- New Session memakai area konten panel utama dengan header dan border yang sama. Nama sesi wajib diisi; Duration dropdown, Mode, dan baris aplikasi mengikuti pola MenuBarView. Footer Start tetap terlihat.
- Baris histori Today membuka detail sesi terpilih: status, durasi aktual/rencana, draft konfigurasi asal, serta tangkapan milik sesi itu di bawah Mode. Start memakai draft baru dan tidak mengubah histori asal.
- Pilihan durasi dan mode terakhir disimpan setelah sesi baru berhasil Start. Saat membuka ulang app ketika sesi aktif, Today ditampilkan kembali.
- Validasi: build Debug arm64 berhasil; `git diff --check` bersih. Percobaan test suite penuh berhenti dengan `BUILD INTERRUPTED` (exit 143), sehingga hasil test belum dapat diklaim lulus. Inspeksi visual langsung belum dilakukan.
- Test terarah `QomaTests/DailyCatchSummaryTests` lulus (exit 0); test suite penuh tetap belum lulus karena interupsi di atas.

### Koreksi scrollbar panel compact — 21 Oktober 2026

- Indikator di Today dan New Session masih terlihat pada sistem pengguna. Penyebab lain yang ditemukan: Analytics, Catalog, Settings, About, dan timeline tangkapan memakai indikator custom `qyubeScrollIndicator()`.
- Helper AppKit yang sudah ada dipasang pada konten ScrollView agar `NSScrollView` terdekat mematikan scroller native meski preferensi macOS menampilkannya selalu. Helper mengulang pengaturan saat view diperbarui.
- Indikator custom pada halaman panel utama dilepas; scroll vertikal dan horizontal tetap tersedia. Editor aturan aplikasi dan daftar tangkapan dalam detail juga memakai helper yang sama.
- Validasi: build Debug arm64 berhasil dan `git diff --check` bersih. Perilaku pada preferensi macOS “Show scroll bars: Always” belum diuji langsung di layar.

### Timer, menu bar, dan akhir sesi — 21 Oktober 2026

- Branch `codex/qyube-new-session-detail` di-commit sebagai `ca78b00`; kerja UI-06/UI-07 berada di branch baru `codex/qyube-timer-menubar-completion`.
- Floating timer memakai konsep `prompt-v2.md`: panel 200 × 110 pt, countdown serif normal; hover/klik mengganti isi dengan judul bold satu baris terpotong dan ikon Pause/Resume serta Stop. Stop meminta konfirmasi.
- Klik menu bar saat idle atau floating timer ON membawa ke Today. Saat sesi aktif/paused dan timer OFF, klik membuka popover kontrol yang memakai komponen judul/tombol sama. Klik kanan menyediakan Open Qyube, Settings, Quit.
- Setelah finalisasi sukses, sesi completed membuka panel Nice work tanpa membuka window utama: fokus aktual, tangkapan sesi, Break 5 min, Repeat session, Done. Stop lebih awal tetap interrupted tanpa panel sukses. Error finalisasi tetap punya Retry.
- Break berjalan di panel yang sama dengan countdown dan Skip break; sesudahnya Repeat/Done. Break tidak memengaruhi focus goal atau catches. Break disimpan di memori selama aplikasi hidup; recovery break setelah relaunch masih pekerjaan berikutnya.
- Repeat menggunakan draft tersimpan, membuat sesi baru, dan menolak nama kosong atau allow-list kosong. New Session dinonaktifkan selama break, dengan pesan penjelas. Today menunjukkan status break.
- Validasi: build Debug arm64 berhasil; test terarah `SessionRepeatDraftTests`, `MenuBarTimerDisplayTests`, dan `MenuBarRoutingTests` lulus; `git diff --check` bersih. Tampilan dan interaksi panel di layar macOS belum diuji langsung.

### Edit sesi aktif dan pemanggilan window — 21 Oktober 2026

- Klik menu bar saat sesi berjalan kini mengaktifkan kembali window utama walau sebelumnya sudah terbuka di belakang aplikasi lain. Window utama memakai perilaku `.moveToActiveSpace` agar berpindah ke desktop aktif saat dimunculkan.
- Tombol Edit ditambahkan ke kontrol floating timer dan panel kontrol menu bar. Keduanya membuka window utama langsung ke form edit sesi aktif.
- Form memakai snapshot sesi aktif; nama tugas dan daftar aplikasi bisa diubah, sementara mode dan durasi terkunci. Penyimpanan satu kali memvalidasi nama/allow-list dan mempertahankan sesi serta timer yang sama.
- Timer only tetap dapat menyimpan perubahan nama; pembaruan aturan aplikasi untuk sesi timer only tetap ditolak.
- Validasi otomatis belum dijalankan. Perpindahan Spaces dan tampilan form masih perlu dicoba langsung di macOS.
