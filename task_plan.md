# qyube — Rencana Implementasi macOS (Alur Kiki, Identitas qyube)

**Status:** kontrak implementasi untuk AI agent; belum ada perubahan kode pada sesi perencanaan ini.

**Branch implementasi awal:** `codex/kiki-flow-core`.

**Branch audit dan perbaikan UI:** `codex/qyube-ui-rework`.

**Diperbarui:** 1 Oktober 2026.

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
