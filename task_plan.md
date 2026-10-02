# qyube — Rencana Implementasi macOS (Alur Kiki, Identitas qyube)

**Status:** kontrak implementasi untuk AI agent; belum ada perubahan kode pada sesi perencanaan ini.

**Branch:** `codex/kiki-flow-core`.

**Diperbarui:** 1 Oktober 2026.

**Fokus:** macOS lebih dulu. Rancangan iOS tetap pekerjaan lanjutan.
**Nama target kode saat ini:** `Qoma`; nama produk yang dituju: `qyube`.

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
- [ ] Hapus route `prepareBreak` dan state break setelah jalur `completed → report` berfungsi.
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
- [ ] Tambahkan overlay ikan yang mouse-transparent, multi-display aware, intensitas dibatasi, dan Reduce Motion.
- [ ] Uji timer open/closed, menu bar no-op saat panel terbuka, Dock membuka Home, pindah Spaces/monitor, aksesibilitas keyboard/VoiceOver.

**Gate:** draft visual dan interaksi dua panel dapat didemonstrasikan tanpa menyimpan reward palsu.

### Fase 4 — Catch ledger, Catalog, report, Insight

- [x] Jadikan `CatchEngine` sumber urutan wait 6–10 dtk, bite, reel cepat sesuai prototype, deposit, dan roll identitas; `CompanionScene` hanya menggambar cue/event.
- [x] Uji bank saat tepat 5 menit aktif, stop 4:59/5:00, deposit yang belum selesai, pause, gangguan app, serta idempotensi setelah relaunch.
- [x] Buat Catalog yang menampilkan semua definisi item, termasuk silhouette belum ditemukan; count berasal dari event banked. Gunakan asset proxy saat identitas art belum siap.
- [x] Buat Fishing Report completed dan compact interrupted; stop <5 menit menampilkan pengembalian lembut tanpa entry Catalog baru.
- [x] Adaptasi Insight dasar: focus time, completed/interrupted, tangkapan, dan recent sessions; tidak ada target harian atau tag.
- [ ] Hilangkan entry layar percobaan fitur yang dibatalkan dari Settings/navigasi; simpan file desain lama sebagai arsip sampai proses bersih terpisah disetujui.

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
- Sesi ini hanya memperbarui dokumen perencanaan. Semua checkbox implementasi di atas tetap terbuka untuk agent pelaksana.
