# Prompt konteks — diskusi UI dan alur Qyube yang lebih compact

> **Status 20 Oktober 2026:** rencana produk dan UI telah disepakati melalui diskusi, dengan revisi terakhir pengguna. Bagian **Rencana detail yang disepakati** di bawah adalah acuan keputusan terbaru dan mengungguli pertanyaan terbuka pada konteks awal. Bagian **Fakta source** mencatat runtime lama, bukan klaim bahwa desain baru sudah diimplementasikan. Pekerjaan pada tahap ini adalah dokumentasi dan perancangan UI.

Saya ingin berdiskusi tentang penyederhanaan tampilan dan alur aplikasi macOS Qyube. Bantu saya mengambil keputusan produk dan UX dulu. Jangan langsung mengimplementasikan perubahan. Baca konteks dan source yang relevan, lalu diskusikan dengan saya secara bertahap. Hindari memberikan terlalu banyak pertanyaan sekaligus.

## Produk dan tujuan perubahan

Qyube adalah aplikasi fokus/Pomodoro dengan companion penguin yang memancing selama pengguna bekerja. Hasil tangkapan menjadi koleksi dan bagian dari pengalaman fokus. Identitasnya cozy, cute, tenang, dengan ilustrasi hand-drawn watercolor dan garis charcoal.

Aplikasi sekarang punya jendela utama cukup besar. Saya ingin mengubahnya menjadi aplikasi berjendela kecil dan compact, dengan skala dan kesederhanaan interaksi seperti referensi Kiki yang didokumentasikan di `KIKI.md` dan `kiki-screenshots/`.

Fokus pekerjaan ini adalah tampilan, navigasi, dan transisi antarkeadaan sesi. Fitur produk yang sudah ada tetap dipertahankan dan tetap bisa diakses. Jangan mengartikan UI compact sebagai alasan menghapus Analytics, Catalog, Settings, aturan distraksi, atau fitur lain.

## Preferensi ilustrasi yang sudah diputuskan

- Pilihan visual ikan saya adalah `design/qyube-collectibles-v5-fish/02-fish-collection-sheet-no-eyes.png`, yaitu ikan tanpa mata sama sekali.
- Pembanding sebelumnya: `design/qyube-collectibles-v5-fish/01-fish-collection-sheet.png`, yang masih memiliki mata berupa titik.
- Keduanya berupa concept sheet berisi 32 ikan; jangan menganggap sudah menjadi aset terpisah atau sudah terintegrasi dalam aplikasi.
- Bentuk ikan harus sederhana, membulat, dan imut. Hindari siluet/anatomi terlalu realistis. Pertahankan watercolor dan charcoal.
- Saya memiliki pertimbangan agama pribadi tentang penggambaran makhluk hidup. Ini alasan saya memilih ikan tanpa mata. Terima sebagai batasan desain saya; tidak perlu memberi penilaian atau klaim apakah suatu ilustrasi memenuhi ketentuan agama.
- Salah satu tujuan UI kecil adalah agar ilustrasi ikan tampil sebagai elemen koleksi kecil dan tidak menjadi fokus pengamatan detail anatomi/wajah. Kecilkan skala presentasi ilustrasi, sambil menjaga teks dan kontrol nyaman dibaca serta digunakan.
- Jangan menjadikan zoom, artwork hero besar, atau detail ikan berukuran besar sebagai pusat pengalaman default. Informasi koleksi tetap perlu dapat dibaca.
- Art reference companion: `design/qyube-floating-prototype/`. Pengubahan identitas/karakter penguin bukan keputusan yang sudah saya minta dalam diskusi ini.

## Arah menu bar yang saya inginkan

Menu bar tetap ada, menampilkan waktu dan menjadi trigger untuk membuka aplikasi atau kontrol sesi yang sesuai dengan keadaan saat ini. Saya mempertimbangkan berhenti memakai panel kaya konten `MenuBarView.swift` sebagai pusat interaksi.

Jangan mengartikan ini sebagai menghapus integrasi menu bar. Yang perlu dirancang adalah tujuan klik menu bar ketika idle, aktif, paused, dan selesai. Detail seperti tampilan waktu saat idle, toggle tampil/sembunyi, serta akses Settings/Quit perlu dibahas. Jangan menghapus file atau memilih arsitektur implementasi sebelum alurnya disepakati.

## Alur utama yang perlu dibahas

1. Membuka Qyube saat tidak ada sesi aktif: halaman awal kecil yang jelas dan mudah dipahami.
2. Membuat sesi baru: isi/pilih konfigurasi yang sudah didukung, lalu Start.
3. Sesi aktif: waktu, companion, dan cara membuka kontrol sesi; hindari memenuhi desktop dengan beberapa panel yang fungsinya tumpang tindih.
4. Pause: tampilkan status jeda yang jelas dan cara melanjutkan sesi yang sama.
5. Resume: kembali menjalankan sesi yang dijeda, dengan progres dan identitas sesi yang sama.
6. Sesi selesai: feedback dan ringkasan secukupnya, lalu jalur untuk mengulang konfigurasi sesi tersebut atau membuat sesi baru.
7. Mengulang sesi yang sudah selesai: bedakan dari Resume. Perlakukan sebagai sesi baru yang mengambil konfigurasi sebelumnya; jangan mengaktifkan ulang record riwayat yang sudah selesai. Tentukan bersama saya apakah perlu review konfigurasi sebelum Start.
8. Mengulang sesi lama dari riwayat: bahas jalur yang ringkas tanpa menganggap fitur tersebut sudah terhubung di runtime sekarang.
9. Stop lebih awal: tetap sediakan tindakan yang berbeda dari Pause maupun menutup jendela; pertahankan aturan penyimpanan sesi dan tangkapan.
10. Menutup dan membuka kembali jendela saat sesi berjalan: jangan menyamakan menyembunyikan UI dengan mengakhiri sesi.

Perbedaan antara **Resume**, **Repeat**, dan **New session** harus jelas dalam penamaan dan perilaku. Durasi, mode, judul tugas, dan aturan aplikasi yang dipakai saat Repeat perlu menjadi keputusan eksplisit, bukan asumsi tersembunyi.

## Fakta source saat konteks ini disusun

Fakta berikut berasal dari pembacaan kode pada 20 Oktober 2026. Periksa kembali jika source sudah berubah. Ini bukan hasil QA interaktif.

### Runtime yang benar-benar terhubung

- Entry point: `Qoma/QomaApp.swift` → `Qoma/Managers/AppDelegate.swift` → `Qoma/Managers/QyubeAppCoordinator.swift`.
- `QyubeAppCoordinator` memiliki `SessionCoordinator`, home window, floating timer, companion, overlay distraksi, dan controller menu bar. Ini tempat penting untuk memahami routing dan transisi UI.
- Home window dibuat dengan content rect **1180 × 820**, minimum **640 × 580**, dan dapat diresize.
- Root home: `Qoma/UI/Main/QyubeHomeView.swift`. Navigasi yang terhubung adalah **Analytics, Catalog, Settings, About**. Ada sidebar 220 pt, berubah menjadi 52 pt pada lebar di bawah 760 pt.
- `Qoma/UI/Main/NewSessionView.swift` memang ada dan memuat form tugas/mode/durasi, tetapi tidak dirujuk oleh root home atau app coordinator yang diperiksa. Keberadaan file bukan bukti bahwa form ini adalah jalur Start saat ini.
- Ada kode lama seperti `FocusSessionManager` dan `SessionState`. Jangan menentukan perilaku runtime hanya dari file tersebut; telusuri call site dan wiring yang aktif.

### Menu bar dan sesi sekarang

- `Qoma/Managers/MenuBarController.swift` membuat status item teks waktu dan membuka `MenuBarView` melalui panel ketika diklik.
- Lebar panel menu bar: **310 pt**, tinggi mengikuti konten. Angka 300 pt di constants adalah nilai awal tinggi, bukan tinggi tetap semua keadaan.
- `Qoma/UI/MenuBar/MenuBarView.swift` saat ini memuat penguin, duration, mode, editor aplikasi, tangkapan hari ini, status simpan/error, dan tombol Start/Pause/Resume/Stop.
- Start terhubung ke `QyubeAppCoordinator.startFromMenuBar(minutes:)`, yang membentuk draft dari `FocusPreferences` dan memanggil `SessionCoordinator.startSession(draft:)`.
- Mode: **Timer only, Allowing, Blocking**. Allowing mensyaratkan setidaknya satu aplikasi. Jangan mengubah dukungan aturan aplikasi/domain hanya karena model data memuat suatu field; cek jalur evaluasi dan penyimpanan yang nyata.
- Saat aktif/paused, durasi dan mode pada panel dikunci. Aturan aplikasi dapat diedit melalui jalur yang ada.
- Status item sekarang menampilkan countdown saat sesi active/paused; saat idle menggunakan durasi preset tersimpan. Arah baru tetap membutuhkan keputusan tampilan idle.
- Saat selesai secara normal, runtime memainkan completion sound sesuai settings dan membuka kembali panel menu bar idle melalui `showIdleAfterCompletion()`.
- Runtime yang diperiksa belum memasang alur completion → break → repeat seperti contoh Kiki. Jangan menyajikannya sebagai fitur Qyube yang sudah bekerja.

### Panel dan lifecycle

- Floating timer terpisah dikelola `Qoma/Managers/FloatingTimerController.swift`, berukuran **110 × 62 pt** dari constants. Companion memiliki panel tersendiri di `CompanionWindowController.swift`.
- Saat snapshot active/paused, runtime menampilkan companion dan mengatur timer sesuai preferensi; saat terminal/idle panel disembunyikan. Klik companion saat ini mencoba menampilkan kembali floating timer.
- App dapat tetap berjalan setelah jendela ditutup. Reopen aplikasi diarahkan ke home window. Keluar aplikasi saat sesi berjalan memiliki konfirmasi Stop and Quit.
- `Qoma/Domain/Focus/SessionCoordinator.swift` menangani Start, Pause, Resume, stop/interrupted, completion, pemulihan sesi, serta finalisasi penyimpanan. `FocusModels.swift` memuat `SessionDraft`, `ActiveSessionSnapshot`, `FocusSession`, dan `CatchEvent`.
- Jaga satu sesi aktif, pemulihan setelah relaunch, histori yang tidak terduplikasi, serta penanganan penyimpanan gagal. Error dan Retry yang sebelumnya tampil di panel menu bar tetap perlu tempat dalam UI baru.
- Mekanisme tangkapan otomatis dan aturan provisional/banked sudah ada. Ada ambang lima menit untuk banking saat berjalan dan konsekuensi Stop lebih awal. Pertahankan perilaku sebenarnya dengan merujuk `SessionCoordinator` dan `CatchEngine`; jangan menyederhanakan semua kasus menjadi aturan baru.
- Catalog saat ini memakai artwork card setinggi 174 pt dan memiliki detail sheet. Ini salah satu tempat yang perlu ditinjau agar tujuan ilustrasi kecil berlaku konsisten.

## Cara menggunakan referensi Kiki

Baca `KIKI.md`, terutama peta layar, alur sesi, Today, form, dan prompt pascasesi. Lihat `kiki-screenshots/today.png`, `new-session.png`, `session-timer.png`, `session-controls.png`, dan `session-detail.png` untuk proporsi visual.

Gunakan Kiki sebagai referensi skala jendela, hierarki tindakan, dan transisi yang ringkas. Identitas Qyube tetap watercolor, penguin, dan memancing. Jangan otomatis menyalin fitur, karakter, atau kebijakan Kiki.

Dokumentasi Kiki membedakan OBSERVED, INFERRED, OFFICIAL, dan UNVERIFIED. Ukuran jendela persis dalam pt belum tercatat di dokumen. Jangan mengarang angka sebagai ukuran Kiki terverifikasi atau menyamakan piksel screenshot dengan logical points. Jika mengusulkan ukuran Qyube, tandai sebagai usulan desain.

## Batas lingkup diskusi

- Fitur dipertahankan; perubahan berfokus pada presentasi dan routing UI.
- Hindari mengusulkan sistem crafting, farming, mata uang, reward baru, streak, atau perubahan peluang tangkapan untuk menyelesaikan persoalan ukuran jendela.
- Jangan otomatis menambah break timer hanya karena produk disebut Pomodoro atau Kiki memiliki prompt break. Jika penting bagi alur, cek fitur yang sudah terhubung dan bahas sebelum memasukkannya.
- Penggantian artwork produksi, pemotongan concept sheet menjadi aset terpisah, dan perubahan kode belum menjadi permintaan implementasi pada tahap diskusi ini.
- Pertahankan akses fitur yang jarang dipakai melalui navigasi sekunder yang jelas. Hindari sekadar mengecilkan dashboard besar sehingga teks dan kontrol sulit digunakan.

## Respons pertama yang saya inginkan

> Bagian ini merupakan prompt awal yang sudah dijalankan; bukan instruksi untuk mengulang wawancara atau mengabaikan keputusan terbaru.

Setelah memahami konteks dan memeriksa source bila tersedia, sampaikan singkat apa yang kamu pahami. Lalu berikan satu rekomendasi alur compact yang konkret: layar awal, form baru, active/paused, selesai, repeat, akses koleksi/analytics/settings, dan perilaku klik menu bar. Gunakan diagram alur atau wireframe teks singkat bila membantu.

Jelaskan mana yang merupakan perilaku sekarang dan mana yang kamu usulkan. Mulai diskusi dari satu keputusan paling penting yang perlu saya pilih. Jangan langsung menulis kode, membuat PR, atau menganggap semua usulan sudah disetujui.

---

## Rencana detail yang disepakati — 20 Oktober 2026

### 1. Status, prioritas, dan batas pekerjaan

Pengguna menyetujui rekomendasi nomor 1–18 dalam diskusi, dengan revisi eksplisit pada nomor 2, 4, 8, 15, 17, dan 18. Keputusan berikut menggabungkan persetujuan tersebut. Implementasi aplikasi belum diminta pada tahap dokumentasi ini.

Prioritas saat ini adalah UI: struktur layar, navigasi, proporsi, komponen, warna, dan tampilan setiap keadaan. Manage subscription, Sign out, Help, Give feedback, dan Reset tetap dimasukkan dalam rancangan UI. Ketersediaan backend, layanan akun, URL tujuan, maupun mekanisme penghapusan data tidak menjadi prasyarat desain. Jangan menghilangkan item tersebut dari mockup karena integrasinya belum tersedia. Jangan mengklaim integrasinya sudah berfungsi.

Pertahankan fitur yang ada dan aturan penyimpanan/tangkapan yang sebenarnya. Perubahan hitungan goal lintas tengah malam dan penambahan break adalah perilaku yang direncanakan, bukan runtime yang sudah diverifikasi.

### 2. Ukuran window dan bahasa visual

**Keputusan implementasi terbaru, 21 Oktober 2026:** panel utama memakai ukuran tetap **310 × 510 pt**, tanpa traffic light dan tanpa resize. Konten panjang tetap dapat discroll dengan indikator tersembunyi. Border tinta berada sekitar 4 pt di dalam tepi panel. Angka 420 × 700 pt di bawah adalah rancangan awal dan sudah digantikan keputusan ini.

- Ukuran awal area konten window utama: **420 pt lebar × sekitar 700 pt tinggi**; sesuaikan tinggi dengan ruang layar yang tersedia.
- Window tetap dapat diresize. Ingat ukuran pilihan pengguna; jangan memaksa kembali ke ukuran awal setiap dibuka.
- Konten panjang dapat discroll. Header dan tombol utama bawah dipertahankan terlihat pada ukuran awal; jangan mengharuskan scroll untuk Start atau Create new session.
- Gunakan logical points sebagai ukuran layout. Dimensi piksel gambar konsep bukan dimensi window dalam pt.
- Acuan visual utama semua halaman adalah **Draft 1 / A — Ink & Ice**, bukan Draft 2 atau Draft 3, di `output/imagegen/menubar-draft-03/prompts.md` dan `01-ink-and-ice.png`.
- Gunakan porcelain `#FAFBF8`, ink `#253E4A`, ice blue `#E4EFF2`, dan accent petrol `#386779`. Palet ini menjadi acuan terbaru agar halaman utama dan floating timer konsisten.
- Garis ink sedikit tidak beraturan, sudut membulat secukupnya, separator tipis, kontrol presisi, SF Pro yang mudah dibaca, footer tombol utama petrol. Permukaan bersih tanpa tekstur kertas foto, scenery, gradient, atau glassmorphism.
- Penguin watercolor tetap mempertahankan identitas yang ada. Ikan tanpa mata dan skala artwork kecil mengikuti batasan pada konteks awal.
- Draft 1 asalnya menggambarkan popover sekitar 310 × 470 pt dan tidak memiliki nama tugas. Ambil bahasa visual dan komponen formnya; adaptasikan ke window 420 × sekitar 700 pt dengan field nama tugas yang diminta pengguna.
- Referensi floating timer adalah `output/imagegen/floating-timer-concepts/normal-hover-v2.png`, dengan penyesuaian warna ke Draft 1. Gambar itu referensi layout, bukan implementasi.

### 3. Header dan navigasi bersama

Semua halaman utama memiliki header yang konsisten:

- Kiri: wordmark **qyube**, dapat ditekan untuk kembali ke Today.
- Tengah: **ilustrasi coretan gelombang kecil seperti Draft 1**. Ini bagian identitas header yang wajib dipertahankan; bukan deretan titik.
- Kanan: ikon **Analytics**, **Catalog**, dan **gear** untuk membuka menu pengaturan.
- Ikon navigasi memiliki tooltip, label aksesibilitas, dan penanda halaman aktif. Pastikan ruang untuk coretan tetap tersedia pada lebar 420 pt.
- New session dan tampilan detail memiliki Back di area konten, tanpa menghilangkan identitas header.
- Tidak ada sidebar permanen pada layout compact.
- Header pada panel floating/menu bar kecil tidak harus menyalin header window utama; panel kontrol mengikuti isi minimal floating timer.

### 4. Inventaris halaman dan tampilan pendukung

Lima halaman utama:

1. **Today**.
2. **New session**.
3. **Analytics**.
4. **Catalog**.
5. **Settings**.

Tampilan pendukung:

- Detail sesi dari Today/riwayat, termasuk Repeat.
- Editor Allow list / Block list.
- Detail item Catalog dengan artwork kecil.
- Menu gear dan tampilan About.
- Floating timer normal, hover, paused, dan kontrol yang dibuka lewat klik.
- Popover menu bar pengganti floating timer ketika preferensi floating timer dimatikan.
- Panel sesi selesai, break berjalan, dan break selesai.
- Konfirmasi Stop, Quit saat sesi berjalan, Reset settings, dan Erase all data.
- Pesan validasi form, gagal Start, finalisasi/simpan gagal, dan Retry.
- Tampilan kosong Today/Catalog/Analytics serta jalur izin/persetujuan yang diperlukan fitur sekarang.

### 5. Today dan daily focus goal

Layout:

- Ringkasan di atas: waktu fokus hari ini dibanding target harian, dengan penguin di sebelahnya.
- Di bawahnya: daftar nama tugas/sesi hari ini.
- Footer: tombol **Create new session** yang tetap terlihat.
- Daftar kosong tetap menampilkan ringkasan dan ajakan membuat sesi pertama.

Daily goal:

- Pengaturan goal **wajib memiliki nilai**, dengan **dua input terpisah: jam dan menit**.
- Default **2h 0m**. Nilai **0h 0m valid**; jangan menolaknya sebagai input kosong.
- Nilai nol diartikan sebagai **tanpa target durasi**: tampilkan jumlah fokus hari ini dan keterangan tanpa target. Jangan membagi dengan nol atau menampilkan persentase pencapaian yang menyesatkan.
- Tidak perlu layar onboarding goal tambahan: nilai default sudah tersedia dan dapat diubah di Settings.
- Jam berupa bilangan bulat nonnegatif; menit 0–59. Batas maksimum jam belum menjadi keputusan produk; jangan mengarang batas sebagai persetujuan pengguna.
- Hitung waktu fokus aktual, termasuk waktu yang sudah dijalankan pada sesi yang dihentikan lebih awal. Pause dan Break tidak menambah goal.
- Hari mengikuti tanggal lokal. Rencana perhitungan sesi lintas tengah malam membagi waktu fokus menurut hari sebenarnya. Today dan Analytics perlu memakai definisi yang konsisten; ini dapat memerlukan penyesuaian di luar restyling saat implementasi kelak.
- Saat melebihi goal, durasi aktual tetap ditampilkan; bar visual boleh penuh tanpa menyembunyikan kelebihan waktunya.

Daftar sesi:

- Tampilkan sesi completed, interrupted/stopped, aktif, dan paused dengan status yang berbeda dan jelas.
- Sesi aktif/paused di atas; sesi lainnya terbaru lebih dahulu.
- Klik baris membuka detail: nama, durasi rencana dan aktual, mode, ringkasan aturan, status, dan hasil tangkapan yang relevan.
- Klik sesi lama langsung membuka detail berbentuk form seperti New session: nama, Duration, Mode, lalu **hasil tangkapan sesi tersebut tepat di bawah Mode**, seperti baris tangkapan MenuBarView. Footer bertuliskan **Start**. Pengguna dapat meninjau konfigurasi di layar ini; Start membuat sesi baru, bukan melanjutkan atau mengubah record sesi lama.
- Saat ada sesi aktif/paused, tombol bawah Today berubah menjadi **Kembali ke sesi**. Jangan mengizinkan sesi fokus kedua.
- Today saat sesi aktif memiliki kartu sesi dengan waktu/status, Pause atau Resume, Stop, dan akses Edit aturan.

### 6. New session

Urutan utama: **nama tugas/sesi → duration → mode dan aturan → Start**.

- Nama tugas wajib berisi teks setelah whitespace dibuang. Judul panjang tetap bisa disimpan; truncation hanya untuk tampilan sempit.
- New session biasa memulai dengan nama kosong; durasi dan mode mengingat pilihan terakhir.
- Tampilan Duration, Mode, ringkasan ikon aplikasi, dan tombol Edit **mengikuti komponen yang sekarang tampil di `Qoma/UI/MenuBar/MenuBarView.swift`**, sesuai revisi pengguna.
- Duration berupa kontrol dropdown outlined seperti sekarang, bukan menggantinya dengan ruler.
- Mode: Timer only, Allowing, Blocking. Dropdown mode dan baris aplikasi berada dalam satu kelompok outlined dengan separator seperti MenuBarView.
- Timer only tidak menampilkan baris aturan aplikasi. Allowing/Blocking menampilkan ringkasan dan akses editor sesuai mode.
- Allowing tanpa aplikasi tidak dapat Start; tampilkan petunjuk yang jelas. Pertahankan validasi runtime lain yang relevan.
- Footer Start tetap terlihat; jangan memulai sesi jika validasi gagal. Tampilkan kegagalan Start di form.
- Setelah Start berhasil, sembunyikan window utama dan tampilkan companion serta timer sesuai preferensi. Jangan menyembunyikan window sebelum keberhasilan Start diketahui.
- Saat membuka kembali app selama sesi aktif, arahkan ke Today dengan kartu sesi aktif dan akses kontrol.
- Durasi dan mode sesi yang sedang berjalan tetap terkunci. Aturan aplikasi tetap dapat diedit melalui jalur yang didukung sekarang.

### 7. Analytics, Catalog, dan Settings

**Analytics:** pertahankan fungsi pada `Qoma/UI/Main/AnalyticsDashboardView.swift`: pemilihan hari/heatmap, total fokus, jumlah sesi, completed/interrupted, breakdown aplikasi/website, dan tangkapan harian. Ubah komposisi menjadi vertikal untuk 420 pt; jangan mengecilkan seluruh dashboard menjadi teks kecil. Detail panjang dapat discroll.

**Catalog — revisi visual terbaru:** gunakan grid **lima kolom**, setiap tile hanya memuat gambar ikan kecil tanpa mata. **Jangan tampilkan nama ikan atau jumlah ikan pada grid.** Empat tingkat rarity dibedakan melalui warna latar tile: Common abu-abu; usulan untuk board berikutnya Uncommon biru muda, Rare lilac lembut, Legendary emas pucat. Warna usulan: `#E5E7E9`, `#DCE8F2`, `#E9E1F0`, `#F2E4BC`. Label rarity boleh berada pada legenda terpisah, bukan caption setiap ikan. Progres penemuan dan filter All/Fish/Ocean finds tetap tersedia. Detail koleksi tetap kecil, tanpa hero/zoom besar; rancangan tidak perlu menampilkan nama/jumlah di detail. Informasi koleksi yang tersimpan tidak dihapus hanya karena presentasinya disederhanakan. Jangan menyatakan concept sheet ikan sudah menjadi aset produksi.

**Settings:** pertahankan isi pengaturan yang relevan dari `Qoma/UI/SettingsView.swift` dan pane yang dirujuknya, termasuk General, Appearance, dan informasi About. Ubah layout sidebar besar menjadi kelompok vertikal atau navigasi bertingkat yang muat di 420 pt.

Tambahan/akses pengaturan:

- Daily focus goal: input jam dan menit, default 2h 0m, boleh 0h 0m.
- Preferensi tampil/sembunyikan floating timer, dengan penjelasan bahwa kontrol pindah ke menu bar ketika dimatikan.
- Check for Updates; integrasi Sparkle sudah ada, rancangan cukup menyediakan akses yang jelas.
- Reset settings dan Erase all data dirancang sebagai dua tindakan berbeda, dengan konfirmasi. Desain Erase all data tidak tersedia saat sesi aktif. Detail implementasi penghapusan ditunda karena fokus saat ini UI.

Menu gear memuat item yang diminta pengguna:

1. Settings.
2. Manage subscription.
3. Sign out.
4. Help.
5. Give feedback.
6. About.
7. Quit.

Semua item masuk dalam mockup UI. Pengelompokan dengan separator boleh digunakan. Integrasi akun, subscription, tautan bantuan, feedback, dan reset bukan pekerjaan tahap ini. About cukup tampilan pendukung, tidak wajib halaman utama keenam.

### 8. Floating timer saat sesi aktif/paused

- Usulan ukuran **200 × 110 pt**, persegi panjang horizontal dengan rounded corners, mengikuti konsep v2. Ukuran akhir masih dapat disesuaikan saat QA visual, tanpa mengubah perilaku yang disepakati.
- **Normal aktif:** hanya countdown sebagai fokus utama.
- **Hover aktif:** countdown diganti nama tugas yang besar dan **bold**, satu baris dengan end truncation `...`; di bawahnya ikon Pause dan Stop.
- Contoh: judul penuh `hakjsdhakjscbkajshaksjdlajsasnkansajda` ditampilkan sesuai ruang, misalnya `hakjsdhakjscbka...`. Jangan mengecilkan font untuk memaksa seluruh teks muat, jangan membungkus ke beberapa baris, dan jangan memotong data judul yang disimpan.
- Ukuran panel tidak berubah saat hover; posisi tombol stabil dan panel tidak melompat.
- Klik/fokus keyboard juga dapat membuka kontrol yang sama; hover bukan satu-satunya akses.
- **Paused:** status Dijeda terlihat pada keadaan normal, waktu tersisa berhenti; saat kontrol dibuka, tampilkan judul, Play/Resume, dan Stop.
- Pause/Resume bekerja pada sesi yang sama, mempertahankan progres dan identitas sesi.
- Stop adalah tindakan berbeda, dengan konfirmasi singkat; penyimpanan/tangkapan mengikuti aturan domain yang ada.
- Tooltip dan label aksesibilitas wajib untuk ikon Pause/Resume/Stop. Timer tidak perlu memiliki ilustrasi penguin karena companion adalah panel tersendiri.

### 9. Menu bar dan fallback saat floating timer dimatikan

Status item tetap menampilkan waktu:

| Keadaan | Teks menu bar | Klik saat floating timer ON | Klik saat floating timer OFF |
|---|---|---|---|
| Idle | Durasi preset, misalnya 25:00 | Buka/bawa Qyube ke depan, Today | Buka/bawa Qyube ke depan, Today |
| Fokus aktif | Countdown | Buka Qyube, Today dengan sesi aktif | Buka popover kontrol sesi |
| Paused | Waktu tersisa + indikator jeda | Buka Qyube, Today dengan sesi paused | Buka popover judul + Resume/Stop |
| Selesai, belum ditutup | Preset idle; hasil masih tersedia | Buka Qyube dengan akses hasil sesi | Buka Qyube dengan akses hasil sesi |
| Break | Countdown break | Buka Qyube dengan status break | Buka Qyube dengan status break |

Fallback aktif/paused adalah revisi eksplisit pengguna:

- Saat floating timer OFF, **kontrolnya pindah ke popover menu bar**.
- Isi utama popover **sama seperti floating timer saat hover**: nama tugas besar/bold satu baris dengan `...`, lalu Pause atau Resume dan Stop. Tidak ada countdown di dalam popover ini; countdown sudah berada di status item.
- Jangan mengembalikan form Duration/Mode, penguin, tangkapan, dan tombol Start lama ke popover kontrol ini.
- Menutup popover hanya menyembunyikan UI; sesi tetap berjalan/paused.
- Mengubah preferensi floating timer saat sesi aktif memindahkan tempat kontrol tanpa restart sesi. Companion tetap mengikuti pengaturannya sendiri.

**Detail pelengkap untuk menjaga akses:** karena klik utama membuka kontrol ketika floating timer OFF, sediakan **Buka Qyube** melalui menu sekunder/context menu status item; akses app melalui Dock/Finder juga tetap membuka Today. Ini keputusan pelengkap untuk konsistensi navigasi, bukan tambahan isi pada popover hover yang diminta identik. Klik pada wordmark/header utama tetap membawa ke Today.

Klik status item membawa window yang sudah ada ke depan dan membuka kembali window yang ditutup. Close window bukan Quit; aplikasi dan sesi tetap hidup. Quit selama sesi aktif memakai konfirmasi Stop and Quit yang sudah menjadi perilaku produk.

### 10. Completion, break, repeat, dan done

Saat fokus selesai normal:

1. Finalisasi sesi dan tangkapan melalui mekanisme domain yang ada.
2. Mainkan completion sound sesuai Settings.
3. Tampilkan panel ringkasan kecil yang dikembangkan dari floating timer, **tanpa otomatis membuka window utama dan tanpa merebut fokus keyboard**.
4. Tampilkan Nice work, waktu fokus aktual, ringkasan jumlah tangkapan kecil, **Break 5 min**, **Repeat session**, dan tindakan sekunder **Done**.
5. Panel tetap tersedia sampai pengguna memilih atau menutupnya; tidak memulai fokus berikutnya otomatis.

Preferensi floating timer OFF menyembunyikan countdown mengambang saat bekerja. **Prompt selesai tetap boleh muncul**, sebagaimana rekomendasi nomor 15 sebelumnya yang disetujui; revisi pengguna pada nomor itu memindahkan kontrol Pause/Stop ke menu bar, bukan membatalkan prompt selesai. Jelaskan perbedaan ini dalam teks Settings. Ringkasan selesai, break, dan kontrol aktif adalah keadaan yang berbeda.

Break:

- Dimulai hanya setelah pengguna memilih Break 5 min.
- Durasi 5 menit, countdown break dan label Break yang jelas.
- Tidak menerapkan aturan distraksi fokus, tidak menghasilkan tangkapan, dan tidak menambah waktu goal.
- Saat break berakhir, tampilkan **Repeat session / Done**; jangan otomatis Start fokus.
- Detail visual panel break berjalan perlu dirancang; aturan Pause/Stop untuk break tidak otomatis disamakan dengan sesi fokus.
- Rute app yang dibuka saat break perlu memperlihatkan status break. Transisi jika pengguna memilih New session saat break masih berlangsung merupakan detail lanjutan yang belum ditentukan; jangan menjalankan break dan fokus bersamaan secara diam-diam.

Repeat:

- Menyalin **nama tugas, durasi, mode, dan aturan aplikasi** dari sesi yang dipilih, bukan mengambil aturan terbaru secara tersembunyi.
- Dari prompt completion/break selesai: langsung Start sesi baru setelah validasi, tanpa mewajibkan membuka form.
- Dari riwayat: detail sesi itu sendiri adalah form terisi dengan hasil tangkapan sesi asal di bawah Mode dan tombol **Start**. Tidak perlu langkah tombol Repeat untuk membuka form lain.
- Bila konfigurasi tidak lagi valid, arahkan ke form dengan pesan yang jelas; jangan memulai konfigurasi lain diam-diam.
- Selalu buat sesi/record baru. Jangan mengaktifkan ulang record terminal.
- Resume hanya untuk sesi paused yang sama; New session biasa membuka draft nama kosong.
- Start berikutnya menunggu finalisasi sesi sebelumnya selesai. Gagal simpan tetap memiliki pesan dan Retry; UI tidak boleh memberi kesan hasil sudah tersimpan jika gagal.

Done atau menutup panel completion:

- Menyembunyikan prompt, kembali ke keadaan idle, tanpa sesi fokus baru.
- Histori/tangkapan yang berhasil disimpan tetap dapat diakses dari Today/Analytics.
- Stop lebih awal memakai status interrupted dan hasil aktual sesuai aturan domain; jangan menampilkan pesan completed yang keliru.

### 11. Ringkasan alur desain

```text
Buka Qyube → Today
  ├─ Create new session → Form → Start berhasil → window tersembunyi
  │    └─ Fokus aktif
  │         ├─ Timer ON  → floating timer → hover/klik → Pause / Stop
  │         ├─ Timer OFF → klik menu bar → popover judul + Pause / Stop
  │         ├─ Pause → Resume sesi yang sama
  │         ├─ Stop → konfirmasi → finalisasi interrupted → idle
  │         └─ Waktu habis → panel Nice work
  │              ├─ Break 5 min → break selesai → Repeat / Done
  │              ├─ Repeat → validasi → sesi baru, konfigurasi yang sama
  │              └─ Done/tutup → idle
  ├─ Klik sesi hari ini → Detail/form terisi + tangkapan di bawah Mode → Start sesi baru
  ├─ Analytics
  ├─ Catalog → Detail koleksi
  └─ Gear → Settings / Manage subscription / Sign out /
            Help / Give feedback / About / Quit
```

### 12. Detail yang sengaja belum dianggap keputusan final

Keputusan produk utama di atas sudah disepakati; jangan mengulang seluruh wawancara. Detail berikut cukup diselesaikan pada tahap desain terkait, tanpa menganggap usulan teknis sebagai implementasi yang sudah diizinkan:

- Batas maksimum input jam goal dan rincian visual goal nol/terlampaui.
- Detail kontrol break berjalan dan transisi New session saat break.
- Ukuran final panel completion yang memuat ringkasan dan tombol dengan nyaman; tidak wajib sama dengan timer 200 × 110 pt.
- Layout rinci konfirmasi/empty/error states serta perlindungan draft form jika berpindah halaman.
- Tujuan nyata item akun/subscription/help/feedback dan mekanisme reset; saat ini cukup desain UI.
- Jalur pemulihan break setelah relaunch belum ditetapkan. Pemulihan sesi fokus, satu sesi aktif, histori tidak terduplikasi, dan Retry penyimpanan tetap wajib dipertahankan.

Dokumen ini menjadi acuan untuk mockup berikutnya. Membuat dokumentasi ini tidak berarti aplikasi baru sudah dibangun, perilaku break sudah terhubung, atau semua gambar konsep sudah dipakai sebagai aset produksi.
