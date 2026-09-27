# Dzenn / Qoma — Product & Codebase Context

> Ditulis dari pembacaan source code, `README.md`, `TODO.md`, `release.md`, project Xcode, dan test pada 27 September 2026. Source code adalah acuan utama saat dokumen saling bertentangan.

## 1. Ringkasan produk

Project ini adalah aplikasi macOS native berbasis SwiftUI/AppKit untuk fokus dengan metode Pomodoro. Produk saat ini masih bernama **Qoma** dalam source, target Xcode, bundle ID (`com.dzulkiram.qoma`), direktori data, dan sebagian besar teks UI. **Dzenn** adalah arah/nama baru yang muncul di `TODO.md`, tetapi belum menjadi migrasi produk yang tuntas.

Nilai utama produk:

- Timer Pomodoro yang dikendalikan dari menu bar dan ditampilkan sebagai panel kecil yang selalu di atas aplikasi lain.
- Pelacakan aplikasi aktif dan domain browser selama sesi fokus.
- Analitik lokal untuk melihat heatmap fokus serta aplikasi/domain teratas per hari.
- Preferensi sederhana untuk durasi cepat, suara, dan tampilan floating timer.

Tidak ada backend, akun pengguna, sinkronisasi cloud, atau dependensi server untuk fungsi inti. Semua data analitik disimpan lokal.

## 2. Struktur dan teknologi

| Area | Implementasi |
| --- | --- |
| App native | Swift, SwiftUI, AppKit, target Xcode `Qoma` |
| Startup | `QomaApp` → `AppDelegate` → menu bar, updater, permission request |
| Timer/focus | `FocusSessionManager` + `TimerService` |
| Floating overlay | `WindowManager` + `NSPanel` + `FloatingTimerView` |
| Analytics | `ActivityTracker`, `BrowserActivityResolver`, `AnalyticsStore`, `AnalyticsEngine` |
| Penyimpanan | Tiga file JSON atomik di `~/Library/Application Support/Qoma/Analytics/` |
| Update | Sparkle (`UpdaterManager`) dan `appcast.xml` |
| Website pemasaran | Next.js 16 / React 19 di folder `website/`; terpisah dari aplikasi macOS |
| Test | Swift Testing, terutama model dan fungsi agregasi analytics |

Folder native utama:

- `Qoma/Managers`: lifecycle aplikasi, menu bar, sesi fokus, window, permissions, updater.
- `Qoma/Services`: timer, tracker, resolusi browser, JSON store, mesin analytics, icon cache.
- `Qoma/Models`: state sesi dan record analytics.
- `Qoma/UI`: settings, floating panel, menu bar, dashboard, dan komponen visual.
- `QomaTests`: unit test untuk model, resolver, store constants, dan engine analytics.

## 3. Alur aplikasi saat ini

```text
Launch
  QomaApp
    → AppDelegate: app menjadi menu-bar-only, start Sparkle, buat MenuBarController,
      lalu meminta Accessibility / Automation permission.

Mulai sesi
  MenuBarView pilih 1–60 menit
    → FocusSessionManager.start("Focus Session", duration)
      → TimerService countdown berbasis DispatchSourceTimer
      → ActivityTracker mulai merekam (jika analytics aktif)
      → WindowManager menampilkan floating timer.

Saat berjalan
  ActivityTracker: event aktivasi aplikasi + polling setiap 1 detik
    → app foreground dicatat sebagai AppActivityEvent
    → jika browser yang didukung, AppleScript membaca tab aktif
    → domain dicatat sebagai WebsiteVisitRecord.

Selesai / Stop
  FocusSessionManager menghentikan tracker
    → menghitung actual focus time
    → menyimpan focus session, app events, dan website visits ke JSON
    → menyembunyikan floating timer dan kembali ke menu bar.

Tampil analytics
  Settings → Analytics
    → membaca ketiga JSON
    → membuat heatmap + ringkasan hari terpilih + top apps/websites.
```

## 4. Fitur yang benar-benar tersedia

### Timer dan menu bar

- Aplikasi berjalan sebagai menu bar app (`NSApplication.ActivationPolicy.accessory`).
- Panel menu bar punya ruler durasi 1–60 menit, tiga quick preset yang dapat diubah, tombol start/pause/resume/cancel/restart, dan menu Settings/Update/Contact/Quit.
- Timer menggunakan waktu selesai absolut (`endTime`), sehingga hitungan lebih tahan terhadap keterlambatan tick dibanding mengurangi satu detik setiap tick.
- Ada suara selesai dengan tiga file alarm, volume, serta auto-mute setelah lima detik.
- Ada state machine dasar: `idle`, `configured`, `running`, dan `completed`; model juga mendefinisikan `quickSession` dan `taskPlan`.

### Floating timer dan visual preference

- Floating `NSPanel` borderless, draggable, always-on-top, tampil di semua Space dan full-screen auxiliary.
- Saat ini bentuknya tetap: hanya waktu `MM:SS`, ukuran 110×62. Tidak ada image, task name, atau control di floating panel.
- Pilihan tema warna dan opacity 40–100% tersimpan di `UserDefaults`.
- Tampilan menu bar bisa berupa icon ringkas atau label waktu.

### Analytics dan activity tracking

- Fokus session menyimpan planned minutes, actual focus seconds, status selesai/terputus, alasan terputus, dan tempat untuk task plan ID.
- App foreground tracking memakai kombinasi `NSWorkspace.didActivateApplicationNotification` dan polling 1 detik.
- Browser yang didukung: Safari, Chrome, Edge, Brave, Opera, Arc, Vivaldi, dan Firefox.
- Browser Chromium/Safari memakai AppleScript; Firefox membaca address bar melalui Accessibility, sehingga perlu konfigurasi Firefox tambahan.
- Tracking domain memiliki cooldown setelah kegagalan, batas dua polling async, generation counter untuk mengabaikan hasil lama, dan grace period delapan detik agar session domain tidak langsung terputus saat tab berubah.
- Favicon dapat diambil dari halaman/domain dan di-cache di memori; app icon juga di-cache dengan actor LRU 200 entri.
- Dashboard saat ini menampilkan heatmap sekitar 210 hari, pemilih hari, total focus, jumlah/completed/interrupted session, serta lima app dan domain teratas untuk hari tersebut.

### Pengaturan, distribusi, dan web

- General settings: quick presets, pilihan/volume suara, auto-mute, compact menu bar icon.
- Appearance settings: opacity dan tema floating timer.
- Analytics settings: dashboard dan banner permission, tetapi belum ada kontrol analytics yang lengkap.
- Sparkle sudah terintegrasi; update tidak berjalan pada build Debug.
- Folder `website/` berisi landing page Next.js untuk pemasaran Qoma.

## 5. Yang baru berupa pondasi atau belum tersambung

| Kemampuan | Kondisi sebenarnya |
| --- | --- |
| Task-based Pomodoro | Baru enum/model placeholder (`taskPlan`, `taskPlanId`). Tidak ada model task group, builder UI, cycle engine, progress, atau auto-continue. Semua sesi UI sekarang memulai `quickSession` bernama tetap `Focus Session`. |
| Break workflow | Fokus selesai membuat state short break `configured`, tetapi tidak memulai timer break dan menu bar hanya menawarkan Start baru. Long break didefinisikan tetapi tidak pernah dipilih. Jadi klaim “break mode” hanya parsial. |
| Activity timeline / active time | Engine dan beberapa component UI sudah ada, tetapi pemanggilannya dikomentari/deferred di dashboard. User belum mendapat timeline. |
| Summary mingguan / streak / daily snapshots | `AnalyticsEngine` dapat menghitungnya, tetapi dashboard sekarang tidak merendernya. |
| Private/incognito protection | Metode deteksi ada di beberapa browser, tetapi tidak dipanggil oleh tracker; toggle `trackPrivateBrowsing` belum ada. |
| Retention / data pruning | `pruneOldData()` ada, tetapi tidak ditemukan pemanggilnya. |
| Favicon persistence | Favicon fetch dan cache in-memory ada; tidak dipersisten ke storage meski TODO lama menuliskannya sebagai pekerjaan masa depan. |
| Data recovery | Tidak ada restore sesi timer saat app relaunched dan tidak ada checkpoint analytics saat sesi sedang berjalan. |

## 6. Kelemahan dan risiko utama

### P0 — perlu diselesaikan sebelum redesign besar

1. **Identitas produk dan dokumentasi tidak konsisten.** Source adalah Qoma 1.0.0, tetapi roadmap memakai Dzenn. `release.md` mengklaim v1.1.0 serta sistem extension/Todolist dan panel expanded, sementara source tidak memiliki implementation fitur tersebut. `TODO.md` juga memuat beberapa fase/release yang saling menimpa. Ini membuat scope redesign, desain data, dan release target tidak punya satu source of truth.

2. **Promise inti “task-based Pomodoro” belum ada.** Data model menyisakan hook, tetapi pengalaman pengguna tetap quick timer tunggal. Jika task plan menjadi arah utama Dzenn, struktur state, persistence, analytics, dan UI perlu dirancang ulang bersama—bukan ditambah sebagai fitur kecil di atas `FocusSessionManager` sekarang.

3. **Reliabilitas analytics belum cukup untuk dijadikan klaim produk kuat.** Event aktivitas hanya berada di memori sampai sesi berakhir. Jika app crash, dipaksa quit, atau sistem restart, sesi dan activity sedang berjalan hilang. JSON file memang ditulis atomik, tetapi pola baca-seluruh-file → tambah → tulis-seluruh-file tidak akan nyaman untuk data yang tumbuh dan belum ada migration/versioning.

4. **Break flow tidak selesai.** Short break tidak dimulai otomatis maupun memiliki UI untuk memulainya, sedangkan long break tidak pernah terjadi. Ini menciptakan state yang ada di code tetapi tidak dapat dipakai secara jelas oleh user.

### P1 — akurasi, privasi, dan UX

5. **Idle detection berpotensi salah saat user mengetik.** Code memakai `secondsSinceLastEventType(..., .mouseMoved)`. Bila seseorang mengetik lama tanpa menggerakkan mouse, app dapat menganggapnya idle setelah lima menit dan memotong tracking. Gunakan any-input event atau strategi idle yang tepat.

6. **Filter floating app berisiko menghilangkan waktu kerja.** `WindowDetectionService` selalu mengecualikan bundle ID tertentu—termasuk Figma dan Slack—tanpa mengecek apakah user sedang memakai jendela normal. Selain itu, saat app dikecualikan/floating di foreground, tracker kembali tanpa menutup current session; durasi app/domain sebelumnya dapat terus bertambah secara keliru.

7. **Private browsing belum benar-benar dilindungi.** URL/domain private bisa tetap direkam karena tracker tidak memakai `isInPrivateBrowsingMode()`. Ini adalah risiko privasi yang perlu diputuskan secara eksplisit dalam redesign.

8. **Permission UX tidak mewakili status per browser.** Satu nilai `automationPermissionStatus` global bisa dianggap granted karena satu browser berhasil, padahal browser lain mungkin belum diizinkan. Prompt di launch juga dapat terasa agresif karena memicu Accessibility, System Events, dan semua browser yang sedang terbuka.

9. **Analytics UI belum memenuhi scope yang dijanjikan.** Timeline, active-time chart, summary mingguan, streak, dan session detail telah mempunyai sebagian code tetapi tidak tersedia di layar. Dashboard juga hanya refresh saat muncul/ketika aplikasi aktif, bukan ketika sesi baru saja difinalisasi.

10. **Global singleton masih dominan.** Focus manager, tracker, store, analytics engine, window/menu controller, permissions, dan updater masih banyak diakses langsung dari view. Ada constructor injection di beberapa service, tetapi UI belum memakai dependency environment seperti TODO I5. Ini membuat redesign dan test end-to-end lebih sulit.

### P2 — kualitas, test, dan rilis

11. **Test berfokus pada pure model/engine, belum lifecycle nyata.** Tidak ada test untuk timer pause/resume/completion, focus manager, crash recovery, JSON persistence aktual, permission behavior, foreground tracking, atau browser automation. Ada ketidaksesuaian test Arc: test memakai `company.com.Arc`, sedangkan resolver memakai `company.thebrowser.Browser`; test browser support tersebut kemungkinan gagal.

12. **Data debug dan production belum dipisahkan.** Keduanya memakai UserDefaults standar dan Application Support `Qoma`, sesuai TODO I44–I47. Pengembangan lokal dapat mencampur data pengguna/rilis.

13. **Release posture bertentangan.** `release.md` menyatakan belum ada akun Apple Developer dan distribusi ad-hoc/notarization di-skip, sementara TODO menyatakan akun sudah aktif dan target final signed + notarized. Versi Xcode 1.0.0 juga tidak cocok dengan dokumen release 1.1.0.

14. **Website masih template-level di dokumentasi.** `website/README.md` belum menjelaskan produk/operasional situs dan folder web tidak tampak sebagai bagian rencana rilis native yang terintegrasi.

## 7. Dokumentasi: mana yang dipercaya

| Dokumen | Nilai | Catatan |
| --- | --- | --- |
| `README.md` | Deskripsi produk dan setup permission cukup dekat dengan code | Perlu koreksi klaim break flow dan menyelaraskan brand Dzenn/Qoma. |
| `TODO.md` | Inventaris ide, debt, dan fase yang kaya | Bukan roadmap eksekusi tunggal; banyak item lama, status yang tidak cocok dengan source, serta beberapa release strategy bersamaan. |
| `release.md` | Referensi proses manual universal DMG/Homebrew | “What’s new v1.1.0” tidak ditemukan di code. Status Apple Developer juga bertentangan dengan TODO. |
| Source code | Source of truth perilaku saat ini | Masih memerlukan test integrasi/manual untuk mengonfirmasi behavior macOS dan browser. |

## 8. Implikasi untuk perombakan besar

Sebelum mulai UI atau feature work besar, tetapkan keputusan produk berikut dalam satu spec/roadmap baru:

1. **Brand dan versi:** apakah produk final bernama Dzenn, serta kebijakan migrasi bundle ID, data folder, updater feed, website, dan user settings dari Qoma.
2. **Job utama:** apakah Dzenn adalah task-plan Pomodoro, focus timer minimalis dengan analytics, atau gabungan keduanya. Pilihan ini menentukan domain model inti.
3. **Kontrak privasi analytics:** kapan tracking aktif, apa yang direkam, penanganan private browsing, excluded apps, retention, export/delete data, dan copy permission.
4. **Model data tahan rilis:** pilih migrasi JSON yang berversi ke SwiftData (atau storage lain), recovery session, checkpoint/batch save, serta pemisahan Debug/Release.
5. **Session engine eksplisit:** representasikan focus/break/cycle/task plan secara deterministik—termasuk skip, stop, auto-continue, completion, dan recovery—dengan test terlebih dahulu.
6. **Scope dashboard:** pilih metrik yang benar-benar akan muncul di rilis pertama; hapus atau hubungkan code analytics/UI yang masih deferred agar tidak menciptakan janji palsu.

## 9. Status awal yang disarankan

Anggap aplikasi saat ini sebagai **prototype/foundation yang sudah punya timer, overlay, local tracking, dan dashboard dasar**, bukan sebagai v1.1 task-based Pomodoro yang siap dirilis. Fondasinya cukup berguna untuk dipertahankan, terutama timer berbasis end time, hybrid app tracking, model event analytics, dan komponen dashboard. Namun domain focus session, persistence, privacy controls, dokumentasi, dan ownership dependency perlu dibereskan sebelum menambah banyak fitur atau mengunci desain baru.
