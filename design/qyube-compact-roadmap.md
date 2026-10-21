# Qyube compact — roadmap pengerjaan

Tanggal: 20 Oktober 2026. Status: roadmap tersedia; implementasi UI compact belum dimulai oleh pekerjaan ini.

## Acuan dan urutan prioritas

1. Keputusan terbaru pengguna di `qyube-compact-flow-context.md` mengungguli rencana lama yang bertentangan.
2. Draft 1 Ink & Ice dan prototype tiga screen menjadi acuan visual utama.
3. `../output/imagegen/compact-flow-prototype/all-screens-v1.png` menjadi inventaris visual, bukan spesifikasi piksel atau bukti fungsi runtime. Label, data contoh, proporsi, dan kontrol tambahan hasil generasi tetap harus diperiksa terhadap keputusan produk.

Urutan eksekusi: **UI native dengan data contoh → integrasi runtime lokal → perilaku baru → integrasi layanan/backend → QA dan rilis**.

Backend berarti layanan akun/subscription/sync bila memang diperlukan. Timer, histori, catches, pengaturan, dan activity tracking sudah memiliki fondasi lokal; hubungkan fondasi itu sebelum mempertimbangkan layanan baru. Jangan membangun ulang domain hanya demi mengganti UI.

## Fase 1 — UI native, tanpa ketergantungan backend

Tujuan: semua halaman dan panel dapat dilihat dan dicoba navigasinya dalam SwiftUI/AppKit dengan state contoh yang konsisten. UI memakai komponen produksi yang akan dihubungkan ke runtime, bukan kumpulan gambar mockup.

State contoh cukup berupa nilai/model presentasi sederhana. Jangan membuat session engine kedua, framework navigasi baru, repository palsu yang berlebihan, atau arsitektur besar hanya untuk preview.

### UI-01 — baseline, ukuran, dan inventaris aset

- Catat jalur runtime yang aktif dan perubahan pengguna yang sedang ada sebelum mengedit source.
- Cocokkan daftar screen/state dengan konteks terbaru; bedakan keputusan produk dari detail gambar generatif.
- Petakan aset penguin, coretan gelombang, ikan tanpa mata, ikon, dan suara yang sudah tersedia.
- Tentukan fallback artwork kecil yang jujur bila aset individual belum siap. Concept sheet bukan aset produksi per ikan; jangan menganggap mapping species/rarity sudah terintegrasi.
- Tentukan dimensi awal 420 × sekitar 700 pt serta perilaku resize/scroll, tanpa menetapkan angka minimum baru yang belum diuji.

Hasil: daftar komponen/aset yang dipakai dan baseline yang aman untuk pengerjaan UI.

### UI-02 — fondasi tampilan dan kerangka window

- Token warna Draft 1, tipografi, spacing, radius, outline ink, separator, disabled/error state.
- Header bersama: qyube di kiri, coretan gelombang di tengah, Analytics/Catalog/gear di kanan.
- Area konten yang bisa discroll dan footer tindakan yang tetap terlihat.
- Navigasi dasar Today, New session, Session detail, Analytics, Catalog, Settings; Back dan qyube → Today.
- Komponen minimum: primary/secondary button, field teks, duration dropdown, compound Mode + app summary, session row, rarity tile, grouped setting row.
- Tooltip, fokus keyboard, dan label aksesibilitas sejak komponen dibuat.

Hasil: satu window compact dengan header/footer yang dipakai ulang; font dan kontrol tetap nyaman saat resize.

### UI-03 — Today

- Goal dan penguin berdampingan; daftar tugas hari ini dan footer Create new session.
- Data contoh completed/interrupted, daftar panjang, judul panjang, dan daftar kosong.
- Variasi goal default 2h 0m, goal 0h 0m tanpa target, dan goal terlampaui.
- Varian aktif/paused: kartu sesi dan footer Back to session; kontrol Pause/Resume/Stop dan Edit rules.
- Klik Create menuju New session; klik baris histori menuju detail sesi yang dipilih.

Hasil: layar pertama yang dapat ditinjau di ukuran sebenarnya, dengan data contoh konsisten.

### UI-04 — New session dan editor aturan

- Penguin kecil, nama sesi, Duration, Mode, footer Start.
- Duration dan Mode mengikuti tampilan `MenuBarView.swift`; reuse komponen yang sesuai.
- Ketiga mode serta tampilan conditional baris aplikasi.
- Allow list / Block list: pencarian, daftar pilihan, Done, keadaan kosong.
- Nama kosong, Allowing tanpa aplikasi, requesting/disabled Start, dan pesan gagal Start.
- Nilai form bertahan selama membuka editor; perubahan draft tidak langsung mengubah sesi aktif atau histori.

Hasil: form dan editor dapat dicoba dengan state lokal UI. Belum memulai timer sungguhan.

### UI-05 — Detail sesi dari Today

- Gunakan struktur dan komponen form New session.
- Tampilkan status serta waktu aktual sesi asal.
- Baris hasil tangkapan **milik sesi terpilih**, tepat di bawah Mode.
- Tombol bawah **Start**; rancangan tindakan membuat sesi baru dari konfigurasi yang ditinjau.
- Variasi completed/interrupted, tanpa tangkapan, banyak tangkapan, dan judul panjang.
- Jangan menambahkan langkah Repeat → form kedua untuk histori.

Hasil: alur Today → detail → draft baru terasa menyatu, tanpa mengubah record lama.

**Checkpoint UI A:** tinjau kerangka + Today + New session + detail sebelum memperbanyak halaman. Perbaikan header, field, footer, dan spacing dilakukan di sini agar tidak diulang pada semua screen.

### UI-06 — floating timer dan fallback menu bar

- Normal: countdown. Hover/klik: judul bold satu baris dengan truncation, ikon Pause/Stop, tanpa countdown.
- Paused: status jelas; kontrol Resume/Stop. Dimensi panel stabil.
- Saat floating timer OFF: popover menu bar memakai komponen kontrol yang sama; countdown tetap di status item.
- Context menu status item menyediakan Open Qyube, Settings, Quit.
- Preview penempatan panel dekat tepi layar, title panjang, pointer masuk/keluar dan fokus keyboard.
- Companion tetap panel tersendiri. Pada fase ini cukup gunakan state contoh; jangan mengubah aturan session coordinator.

Hasil: varian panel dan kontrol memakai satu sumber tampilan, tanpa duplikasi layout yang mudah berbeda.

### UI-07 — completion, break, konfirmasi, dan pesan

- Nice work: task, fokus aktual, catches kecil, Break 5 min, Repeat session, Done.
- Break berjalan dan break selesai. Countdown break bukan sesi fokus baru.
- Stop, Stop and Quit, Reset settings, Erase all data: tampilan konfirmasi.
- Finalizing, save error + Retry, start error; pesan tidak mengklaim berhasil jika belum tersimpan.
- Panel completion boleh lebih besar dari timer normal agar isi tetap nyaman.
- Kontrol break berjalan serta New session saat break ditentukan secara eksplisit sebelum wiring; tombol tambahan pada atlas bukan persetujuan otomatis.

Hasil: rangkaian state dapat diperagakan menggunakan data contoh, termasuk jalur error.

### UI-08 — Catalog

- Grid lima kolom dengan ikan kecil tanpa mata; tidak ada nama/jumlah pada tile.
- Empat background rarity: Common abu-abu; Uncommon biru muda; Rare lilac lembut; Legendary emas pucat.
- Progres penemuan, filter yang sudah didukung, legenda rarity, undiscovered/empty state.
- Detail koleksi tetap kecil. Jangan menambah zoom hero.
- Siapkan mapping aset individual yang benar bila aset siap; jangan mengganti identitas penguin atau menduplikasi hasil tangkapan untuk mengisi UI produksi.

Hasil: density grid sudah nyaman di 420 pt; thumbnail tidak memaksa teks/target klik terlalu kecil.

### UI-09 — Analytics

- Restyle fitur runtime yang benar-benar terhubung: total fokus, sesi, completed/interrupted, heatmap/pilih hari, top apps/websites, daily catches dan detail/timeline yang sudah tersedia.
- Susun vertikal; metrik boleh grid 2 × 2; pertahankan perilaku heatmap yang relevan, termasuk scroll horizontal jika diperlukan.
- Halaman tetap window compact yang scroll; gambar memanjang hanya cara meninjau seluruh konten sekaligus.
- Loading, empty, error, judul/domain panjang, hari banyak data.
- Jangan mengurangi rentang heatmap atau menambah metrik karena gambar generatif menampilkannya.

Hasil: informasi yang ada tetap dapat diakses dan terbaca tanpa dashboard lebar.

### UI-10 — Settings, gear menu, About, izin

- Settings berkelompok vertikal, tanpa sidebar 220 pt.
- Goal jam/menit wajib bernilai, default 2h 0m; nol valid.
- Pengaturan existing: preset, sound/volume/auto-mute, timer visibility, distraction sound, appearance, motion, opacity/color, dan activity consent sesuai fitur sebenarnya.
- Helper floating timer OFF menjelaskan kontrol pindah ke menu bar dan prompt selesai tetap dapat muncul.
- Check for Updates, Reset settings, Erase all data, About.
- Gear menu: Settings, Manage subscription, Sign out, Help, Give feedback, About, Quit. Tampilkan dalam desain meski integrasi eksternal belum dikerjakan.
- Izin dan persetujuan yang benar-benar diperlukan fitur, dengan copy yang akurat terhadap mekanisme distraksi; jangan menjanjikan blocking OS jika runtime hanya memberi overlay.
- Pada prototype, aksi akun/reset memiliki batas simulasi yang jelas; belum menghapus data atau mengakses layanan.

Hasil: semua menu, panel izin, dan pengaturan punya tampilan konsisten.

### UI-11 — review UI menyeluruh

- Coba seluruh jalur prototype native dengan fixtures: Today → form/editor → active/paused → completion/break → repeat/done serta detail histori.
- Tinjau 420 × sekitar 700 pt, window lebih pendek, resize lebih lebar, scroll, panel di tepi layar.
- Periksa keyboard, fokus, truncation, label aksesibilitas, Reduce Motion, dan target klik.
- Cocokkan palet, coretan header, footer, iconography, rarity tiles dan artwork tanpa mata.
- Pastikan gambar atlas yang padat tidak menjadi alasan mengecilkan font UI produksi.

**Syarat selesai Fase 1:** semua screen/state yang disepakati tersedia sebagai UI native dan dapat ditinjau; jalur simulasi dikenali; belum ada ketergantungan backend untuk mengevaluasi UX.

## Fase 2 — integrasi fitur dan data lokal yang sudah ada

Kerjakan satu alur lengkap per langkah, mengganti fixture dengan runtime nyata secara bertahap.

1. **Start:** New session → validasi → `SessionCoordinator.startSession(draft:)` → hide window setelah berhasil → timer/companion; satu sesi aktif.
2. **Kontrol:** Pause/Resume/Stop → snapshot yang sama → floating timer atau popover menu bar, termasuk perubahan preferensi di tengah sesi.
3. **Navigasi/lifecycle:** Close/reopen window, status item, Dock/Finder, perubahan halaman saat aktif, Quit confirmation. Tidak ada panel duplikat atau timer kedua.
4. **Finalisasi:** completed/interrupted → penyimpanan yang ada → ringkasan → save error/Retry. Pertahankan provisional/banked dan konsekuensi Stop.
5. **Today/detail:** histori dan tangkapan nyata per session ID; Start dari detail menghasilkan record baru dengan draft tersalin.
6. **Catalog/Analytics:** hubungkan repository/agregasi yang ada, refresh saat data berubah, filter/pilih hari yang konsisten.
7. **Settings/izin/update:** preferences tersimpan, permission state nyata, Sparkle yang sudah tersedia. Hubungkan reset lokal setelah cakupan dan konfirmasinya jelas.

Syarat selesai: alur fokus lama bekerja melalui UI baru, tanpa mengandalkan fixtures atau mengubah record histori lama saat Repeat.

## Fase 3 — perilaku produk baru

1. **Daily goal:** persist nilai jam/menit; agregasi fokus aktual, exclude paused/break, nol valid, pembagian lintas tengah malam dan konsistensi Today/Analytics.
2. **Break 5 menit:** state terpisah, tanpa aturan distraksi/catches, prompt selesai, dan keputusan eksplisit tentang skip/stop serta perilaku relaunch.
3. **Repeat:** langsung dari completion/break selesai setelah validasi dan finalisasi; dari histori melalui detail/form. Salin task/durasi/mode/rules sesi asal; tangkapan lama hanya ditampilkan sebagai hasil asal.
4. **Transisi bersamaan:** guard Start/Repeat double-click, finalisasi tertunda, aplikasi/sumber aturan tidak tersedia, perubahan hari/time zone, dan New session saat break.

Syarat selesai: setiap transisi punya satu hasil yang jelas; break/fokus tidak berjalan bersamaan tanpa keputusan produk; recovery fokus yang sudah ada tetap berfungsi.

## Fase 4 — layanan eksternal dan backend

Mulai dengan memeriksa integrasi yang ada dan kebutuhan produk. Jangan menganggap semua item menu memerlukan endpoint baru.

1. Tentukan kontrak akun/subscription yang dipakai: provider, login/sign-out, status akses, tujuan Manage subscription, state offline/expired/error. Selaraskan dengan keputusan bisnis lama yang belum dibahas dalam redesign ini; jangan mengubah kebijakan trial atau gate lewat asumsi.
2. Integrasikan login/session akun dan Sign out; tentukan penanganan sesi fokus aktif serta data lokal saat akun berganti.
3. Integrasikan status subscription dan Manage subscription dengan layanan yang dipilih; wiring hasil pembayaran dan error/loading state.
4. Hubungkan Help dan Give feedback ke tujuan yang valid; dapat berupa URL/email, tidak wajib backend khusus.
5. Sinkronisasi cloud hanya jika kebutuhan tersebut ditegaskan: identitas, kepemilikan data lokal, migrasi, konflik, offline/retry. Bukan prasyarat UI compact atau timer lokal.
6. Jika akun memiliki data server, selaraskan Reset settings versus Erase all data lokal/server dengan scope nyata sebelum mengaktifkan aksi.

Syarat selesai: menu yang memerlukan layanan memiliki perilaku nyata; UI mencerminkan status akses dan error, bukan sekadar menutup popover.

## Fase 5 — QA integrasi dan persiapan rilis

- Build dan pemeriksaan yang sesuai setiap perubahan kode, bukan menunggu seluruh roadmap selesai.
- Uji transisi berisiko: Start/Pause/Resume/Stop, completion/Retry, Repeat, recovery, close/reopen dan timer OFF fallback.
- QA visual seluruh layar/state pada ukuran dan screen space yang relevan.
- Verifikasi data existing, permission/consent, dan pemisahan data development saat mencoba reset atau error recovery.
- Baru setelah siap, lakukan packaging/release melalui alur macOS yang berlaku. Roadmap bukan otorisasi untuk publish.

## Batch UI yang disarankan untuk mulai

**Batch pertama: UI-01 sampai UI-05.** Fokus satu window compact dengan header/coretan dan footer bersama, Today, New session, editor aturan, serta detail sesi + catches. Ini potongan terkecil yang memperlihatkan kualitas visual dan alur utama secara nyata.

Urutan berikutnya: UI-06/07 untuk timer dan akhir sesi → UI-08 Catalog → UI-09 Analytics → UI-10 Settings/menu → UI-11 review menyeluruh.

Setiap batch menghasilkan daftar perubahan dan screenshot/preview state yang bisa ditinjau. Status implementasi tiap batch tetap **belum dimulai** sampai ada pekerjaan kode; pembuatan roadmap tidak menandai UI selesai.
