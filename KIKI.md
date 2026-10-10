# Kiki — Catatan Analisis Produk untuk AI Agent

Tanggal pemeriksaan: 1 Oktober 2026; observasi tambahan dan screenshot: 3 Oktober 2026. Versi terpasang: **0.0.89 (0.0.89)**, Early Works. Target: aplikasi macOS `/Applications/Kiki.app`, bundle identifier `com.earlyworks.kiki`.

## 1. Cara membaca dokumen ini

Dokumen ini adalah studi perilaku produk melalui antarmuka, bukan audit source code Kiki. Jangan memperlakukan dugaan implementasi sebagai fakta.

- **OBSERVED**: terlihat pada UI atau accessibility tree aplikasi terpasang.
- **OFFICIAL**: disebutkan pada website resmi; belum tentu sama dengan perilaku versi terpasang.
- **INFERRED**: model penjelasan yang masuk akal, bukan implementasi yang telah dibuktikan.
- **UNVERIFIED**: belum diuji, belum terlihat, atau pengujian terhalang.

Status cakupan: **eksplorasi parsial**. Today, kalender, form sesi, pilihan mode/durasi, editor daftar, timer aktif, Settings, serta prompt break/repeat telah diperiksa. Onboarding, izin pertama kali, enforcement saat sesi berjalan, seluruh edge case, dan penyimpanan internal belum terverifikasi. Tidak ada pembongkaran bundle, pembacaan database privat, atau inspeksi trafik jaringan. Observasi tambahan 3 Oktober dilakukan pada sesi pengguna yang sudah ada; **tidak ada sesi uji baru yang dimulai**.

Pada pemeriksaan 1 Oktober, sesi uji baru **belum berhasil dimulai** karena kontrol popup dan screenshot tidak sinkron. Pada 3 Oktober, form, pilihan mode, dan daftar durasi dapat dilihat lebih jelas. Timer sesi pengguna yang sudah aktif juga terlihat. Ini membuktikan tampilan saat sesi berlangsung, tetapi **belum membuktikan transisi tombol Start → timer** atau perilaku sesi uji yang dibuat pemeriksa. Jangan membaca checklist yang belum tercentang sebagai fitur yang tidak tersedia.

Catatan privasi: teks dokumen ini tidak mereproduksi nama tugas dan daftar penggunaan pribadi. Screenshot lokal 3 Oktober dapat memperlihatkannya, sehingga jangan mempublikasikan folder screenshot tanpa memeriksanya. Nilai contoh agregat dipakai hanya untuk menjelaskan UI. Penjelajahan sesi uji telah diizinkan pengguna; hasil pengujiannya harus dibedakan dari data riwayat sebelumnya.

## 2. Penjelasan sederhana

Kiki adalah teman fokus berbentuk karakter merah. Pengguna menentukan tugas, aturan aplikasi/situs, dan durasi. Karakter membuat proses fokus terasa memiliki teman sekaligus pengingat. Website resmi menekankan mengerjakan satu tugas spesifik dan reaksi karakter ketika pengguna terdistraksi. [S1, S2]

Temuan penting pada versi terpasang: pengguna tidak wajib selalu memblokir semua hal. Form menyediakan **Allowing**, **Blocking**, dan **Timer Only**. Jadi model produk yang tepat adalah timer dengan kebijakan distraksi yang dapat dipilih, bukan satu jenis blocker saja. [E5]

## 3. Peta layar

```text
Today
├── Kalender bulanan (toggle dalam halaman)
│   ├── Bulan sebelumnya / berikutnya
│   └── Hari terpilih → daftar sesi
├── Baris sesi → detail yang dapat dibuka
├── New → Form sesi
│   ├── Task to complete
│   ├── Mode: Allowing / Blocking / Timer Only
│   ├── Editor Allow List / Block List (sesuai mode)
│   ├── Duration
│   └── Start → sesi aktif [belum terverifikasi penuh]
└── Menu
    ├── Settings
    ├── Manage Subscription
    ├── Sign Out
    ├── Help
    ├── Give Feedback
    └── Quit

Sesi aktif yang teramati
├── Jendela timer mengambang → nama tugas, End session, Snooze
├── Ikon pensil → editor Allow List
└── Tombol Close → menutup jendela; akibatnya terhadap sesi perlu verifikasi

Prompt pascasesi yang diamati
Nice work! Break?
├── Start break [belum diuji]
└── Skip break → Repeat session?
    ├── Yes [belum diuji]
    └── No → Today [terverifikasi]
```

Tidak semua kotak di atas telah diuji sampai selesai. Label kontrol menunjukkan kemampuan yang ditawarkan, bukan bukti semua efek sampingnya.

## 3A. Alur pengguna dari awal sampai kembali ke Today

### A. Memulai sesi baru — OBSERVED untuk navigasi, UNVERIFIED untuk efek Start [E5, E8]

1. Dari **Today**, tekan **New** di bagian bawah.
2. Isi atau ganti **Task to complete**. Pada sampel, nama tugas sebelumnya sudah terisi; periksa isinya sebelum memulai.
3. Pilih **Mode**: **Allowing** (hanya aplikasi/situs terpilih), **Blocking** (memblokir aplikasi/situs terpilih), atau **Timer Only** (timer dan karakter tanpa daftar aturan di form).
4. Jika memilih Allowing atau Blocking, tekan ikon pensil di deretan aplikasi untuk membuka **Allow List** atau **Block List**. Cari dan atur resource yang dibutuhkan, lalu tekan **Done**. Detail menambah/menghapus item belum diuji.
5. Pilih **Duration**. Menu yang terlihat pada 3 Oktober memuat Stopwatch serta 1, 5, 10, 15, 20, 25, 30, 45, 50, 60, dan 90 menit. Ini daftar pada versi yang diperiksa, bukan jaminan semua opsi selalu tersedia.
6. Tekan **Start** untuk memulai menurut label UI. **Transisi setelah tombol itu belum diuji langsung**. Jendela timer yang diamati pada sesi pengguna memperlihatkan hitungan mundur, nama tugas, **End session**, dan **Snooze for 2 minutes**.

### B. Memakai sesi yang pernah dibuat — OBSERVED untuk kontrol, INFERRED untuk hasilnya [E3, E9]

1. Di Today atau kalender, pilih baris sesi lama. Baris tersebut terbuka menjadi kartu detail.
2. Kartu menampilkan ikon panah melingkar; accessibility tree menamainya **New Session**. Kontrol serupa tersedia pada tiap baris sesi Today.
3. **Kemungkinan alurnya:** tekan ikon tersebut untuk membuat draft baru dari sesi lama, periksa kembali tugas/mode/daftar/durasi, lalu tekan Start. Efek ikon panah melingkar **belum ditekan dan diverifikasi**; jangan menganggapnya langsung menjalankan timer atau menyalin seluruh aturan.
4. Tombol **New** biasa juga pernah membuka form dengan nama tugas sebelumnya yang sudah terisi. Ini tidak cukup untuk menyimpulkan bahwa form selalu memakai sesi terakhir atau menyimpan semua pengaturan sesi lama.

### C. Membuka aplikasi utama saat sesi aktif — OBSERVED dan batasnya [E8]

- Saat sesi aktif, jendela yang tertangkap adalah **timer kecil mengambang**, bukan Today. Klik area nama/timer memperlihatkan **End session** dan **Snooze**; ikon pensil membuka editor daftar.
- Pernah dicoba menutup jendela timer lewat perintah **File → Close Window**. Jendela menghilang, tetapi ketika Kiki dibuka lagi melalui Finder, **timer sesi yang sama muncul kembali**. Jadi menutup jendela pada kejadian ini tidak sama dengan mengakhiri sesi. Ini hanya satu observasi, bukan kontrak perilaku semua kondisi.
- **Cara membuka Today tanpa mengakhiri sesi belum terverifikasi.** Tidak ditemukan tombol berlabel Home/Today pada jendela timer yang diamati. Jangan memberi instruksi pasti seperti “klik ikon Dock” atau “klik ikon menu bar” sebelum jalurnya dibuktikan.
- **Saran UI/UX:** aplikasi sebaiknya menyediakan tindakan **Open Today** yang jelas dari timer dan menu bar, sementara **End session** tetap tindakan terpisah. Ini rekomendasi, bukan fitur Kiki yang teramati.

### D. Ikon Dock atau hanya menu bar? — UNVERIFIED

Kiki tampak sebagai aplikasi macOS yang memiliki jendela, menu aplikasi native (**Kiki, File, Edit, View, Window**), dan dapat dibuka dari Finder. Menu aplikasi native di bagian atas layar **bukan bukti adanya ikon status menu bar**. Observasi ini juga **tidak membuktikan** apakah ikonnya tampil di Dock ketika berjalan. Screenshot yang tersimpan hanya menangkap jendela Kiki, bukan keseluruhan Dock/menu bar macOS. Karena itu jawaban faktual untuk “Dock atau menu bar saja?” masih **belum diketahui**. Sebagai keputusan UI/UX untuk aplikasi sejenis, menu bar cocok untuk membuka timer cepat; Dock cocok sebagai jalur yang mudah ditemukan menuju Today dan Settings. Keduanya dapat disediakan, tetapi ini rekomendasi desain, bukan deskripsi Kiki.

### E. Selesai, jeda, dan kembali — OBSERVED sebagian [E1, E3, E8]

Pada timer aktif ada **End session** dan **Snooze for 2 minutes**, tetapi efek kedua tombol belum diuji. Dalam observasi terpisah, setelah sesi lama berakhir muncul **Nice work! Break?**. Jalur **Skip break → Repeat session? → No → Today** sudah terbukti. Cabang **Start break** dan **Yes** belum diuji. Pada 3 Oktober, satu hitungan mundur mencapai nol lalu tampil lagi sekitar 10 menit untuk tugas yang sama; penyebabnya tidak diketahui, sehingga jangan menyimpulkan Kiki selalu mengulang sesi otomatis.

## 4. Today dan riwayat

### Today — OBSERVED [E3]

- Header memakai tombol tutup, motif titik, ikon kalender, dan ikon menu.
- Bagian ringkasan menampilkan waktu fokus harian dibanding target, progress bar, dan karakter.
- Daftar sesi memakai nama tugas, indikator centang pada sesi yang diamati, dan durasi ringkas.
- Tombol **New** besar di bagian bawah menjadi tindakan utama.
- Satu baris sesi terekspos sebagai tombol. Setelah interaksi, accessibility tree memperlihatkan durasi serta nama/ikon aplikasi dalam detail. Tampilan visual tidak selalu menyegarkan bersamaan; makna persis daftar tersebut belum dipastikan, sehingga jangan menyebutnya daftar distraksi atau daftar izin tanpa pengujian tambahan.

### Kalender — OBSERVED [E4]

- Ikon kalender mengganti bagian ringkasan dengan kalender bulanan di halaman yang sama.
- Ada navigasi previous/next month dan susunan minggu Minggu–Sabtu.
- Hari aktif menampilkan durasi dalam lingkaran hitam. Accessibility label memuat tanggal dan jumlah sesi.
- Hari mendatang pada bulan yang diamati dinonaktifkan.
- Daftar sesi berada di bawah kalender; tombol New tetap tersedia.
- Ada perbedaan angka pada sampel: kalender menampilkan 36m, sementara baris sesi/Today menampilkan 35m. Penyebab belum dibuktikan; bisa perbedaan pembulatan, definisi metrik, atau bug. Jangan mengasumsikan keduanya memakai perhitungan identik.

Belum terverifikasi: grafik mingguan/tahunan, ekspor, filter tag, detail fokus versus distraksi, rumus skor, perilaku pergantian tanggal/zona waktu.

## 5. Membuat sesi

### Form — OBSERVED [E5]

Urutan konten:

1. Tombol kembali dan karakter.
2. **Task to complete**: input teks dengan placeholder yang meminta aktivitas fokus.
3. **Mode**: pemilih kebijakan.
4. Ikon aplikasi/situs dan tombol edit pada mode Allowing.
5. **Duration**: pemilih durasi; 25 menit terlihat pada 1 Oktober dan 30 menit pada form 3 Oktober.
6. **Start**: tombol utama.

Form awal terisi nama tugas sebelumnya pada sampel. Itu menunjukkan adanya pengisian ulang nilai, tetapi belum membuktikan persistensi lintas restart atau bahwa semua pengguna mendapat nilai tersebut. Nilai 25 dan 30 menit adalah nilai yang diamati pada kesempatan berbeda, **bukan default global yang sudah dipastikan**. Daftar opsi durasi yang terlihat dicatat pada alur 3A.

Untuk pengujian 1 Oktober, input diubah menjadi `Kiki exploration test`. Validasi input kosong, batas panjang, dan kemampuan edit nama tugas saat sesi berjalan belum terverifikasi.

### Tiga mode — OBSERVED [E5]

| Mode | Penjelasan yang diberikan UI | Model logika konseptual — INFERRED |
|---|---|---|
| Allowing | Hanya aplikasi dan website yang dipilih diizinkan | Aktivitas di luar daftar menjadi kandidat distraksi |
| Blocking | Hanya aplikasi dan website yang dipilih diblokir | Aktivitas di dalam daftar menjadi kandidat distraksi |
| Timer Only | Karakter menemani pengguna bekerja | Timer/companion tanpa kebijakan pemblokiran yang dinyatakan UI |

Jangan menganggap model konseptual ini sudah menangani browser, aplikasi sistem, background processes, atau domain matching. Semua pengecualian tersebut perlu diuji.

### Editor aplikasi/situs — OBSERVED [E2]

- Judul visual **Allow List**.
- Pertanyaan mengenai aplikasi atau situs yang dibutuhkan.
- Kolom pencarian aplikasi dan situs.
- Daftar baris dengan ikon, nama, dan kategori seperti **App** atau **App & Website**.
- Tombol **Done** di footer; tombol tutup di header.
- Editor dapat dibuka dari ikon pensil pada prompt pascasesi.
- Editor ditutup tanpa mengubah pilihan daftar.

**Ketidaksesuaian pada 1 Oktober:** screenshot menunjukkan Allow List, tetapi accessibility text menyebut Block List dan pertanyaan tentang yang diblokir. Pada 3 Oktober, editor **Allow List** dan **Block List** terlihat terpisah dan masing-masing label aksesibilitas cocok dengan screenshot. Penyebab ketidaksesuaian awal tidak diketahui; itu bukan bukti bahwa aturan aktif pernah terbalik.

Pada 3 Oktober, mengetik nama aplikasi di kolom pencarian menampilkan saran yang sesuai. Belum diuji: tambah/hapus item, website kustom, wildcard/subdomain, satu layanan yang punya aplikasi dan website, prioritas izin browser versus domain, serta kapan perubahan tersimpan.

## 6. Sesi aktif dan pascasesi

### Sesi aktif — OBSERVED untuk tampilan, OFFICIAL / UNVERIFIED untuk enforcement [E8]

Jendela timer kecil teramati pada sesi pengguna yang sudah berjalan. Tampilan hitungan mundur dapat dibuka menjadi nama tugas serta kontrol **End session** dan **Snooze for 2 minutes**. Ikon pensil membuka editor Allow List. Pemeriksa tidak memulai sesi itu, tidak menekan End/Snooze, dan tidak menguji pemblokiran pada aplikasi atau situs lain.

Sumber resmi menggambarkan karakter yang menemani bekerja dan bereaksi saat pengguna membuka aktivitas yang tidak diperlukan. Presentasi tersebut mencakup efek dramatis seperti api. Itu adalah deskripsi produk, bukan bukti mekanisme blocking tingkat OS atau pengukuran latensi. [S2]

Belum boleh diklaim: Kiki menutup proses aplikasi, menolak peluncuran, memakai Screen Time, membaca seluruh layar, menggunakan AI untuk memahami tugas, atau tidak dapat dilewati.

### Prompt pascasesi — OBSERVED [E1, E3]

- Saat eksplorasi dimulai, aplikasi sudah berada pada **Nice work! Break?**.
- Panel vertikal menampilkan karakter besar dan dua tombol: Skip dan Start; label aksesibilitas memperjelas Skip break dan Start break.
- Setelah pengguna mengizinkan pengujian, **Skip break** ditekan.
- UI berganti menjadi **Repeat session?** dengan No dan Yes.
- Menekan **No** membawa kembali ke Today.

Transisi tersebut sudah dibuktikan. Namun, karena timer sebelumnya tidak dijalankan oleh pemeriksa, durasi break, syarat munculnya prompt, dan waktu penyimpanan hasil sesi tidak dapat disimpulkan dari kondisi awal saja.

## 7. Settings dan menu — OBSERVED [E6, E7]

| Pengaturan | Fungsi menurut UI | Nilai yang terlihat, bukan klaim default |
|---|---|---|
| Volume | Mengatur kerasnya suara karakter | 75% |
| Show Kiki While Focused | Menampilkan karakter juga ketika fokus, bukan hanya saat distraksi | Aktif |
| Keep Timer On Top | Menjaga jendela timer di atas jendela lain | Aktif |
| Daily Focus Goal | Target fokus harian dengan input jam dan menit | 2 jam, 0 menit |
| Check for Updates | Tindakan pemeriksaan update | Ditekan pada 3 Oktober; tidak ada perubahan tampilan yang teramati |
| Reset Application | Tindakan reset | Tidak dijalankan; berpotensi destruktif |

Versi 0.0.89 ditampilkan di bagian bawah. Menu utama juga menyediakan pengelolaan langganan, sign out, bantuan, feedback, dan quit. Pada 3 Oktober, **Manage Subscription** membuka portal tagihan Stripe di browser; screenshot portal tidak disimpan karena menampilkan data tagihan pribadi. Help dan Give Feedback tidak membuka halaman baru di jendela Kiki yang teramati. Tidak ada perubahan nilai Settings, reset aplikasi, logout, pembelian, atau pemberian permission.

## 8. Bahasa visual dan karakter

### Yang terlihat — OBSERVED

- Latar krem hangat, garis hitam tegas, sudut membulat besar.
- Bingkai ganda dan motif titik di header membentuk identitas seperti perangkat/mainan kecil.
- Tombol aksi utama menggunakan bidang hitam dan teks putih.
- Karakter merah berbentuk bintang bergerigi dengan mata besar dan kaki; bentuk sederhana serta kontras tinggi.
- Pose/mata karakter berubah antarobservasi. Ini mendukung adanya animasi, tetapi belum mengungkap format asset, frame rate, atau teknik rendering.
- Panel berubah ukuran/komposisi antara Today, Settings, editor daftar, dan prompt pascasesi.

### Interpretasi desain — INFERRED

Karakter bukan sekadar dekorasi: ia menjadi pembawa feedback dan identitas. Alur berusaha menjaga satu tindakan utama per keadaan. Kepribadian tegas pada sumber pemasaran berbeda dari suasana lembut yang dituju proyek ini.

Tidak ada pengukuran CPU/GPU/memori/baterai. Tampilan 2D yang sederhana tidak membuktikan aplikasi ringan. Label image `sprite` pada aksesibilitas juga tidak membuktikan teknik sprite sheet tertentu.

## 9. Model domain untuk dipahami agent — INFERRED, BUKAN SCHEMA KIKI

| Konsep | Data konseptual minimum | Mengapa diperlukan |
|---|---|---|
| Session draft | task, duration, mode, selected resources | Menjelaskan form sebelum Start |
| Resource rule | identitas aplikasi/situs, jenis, mode yang berlaku | Menjelaskan Allowing dan Blocking |
| Focus session | task snapshot, start/end, duration, status | Menjelaskan timer dan riwayat |
| Activity interval | resource, mulai/selesai, klasifikasi | Hipotesis jika produk mengukur distraksi |
| Daily summary | tanggal, agregat waktu, target | Menjelaskan Today dan kalender |
| Companion state | idle, focus, distraction, completion, break | Model animasi yang mungkin, bukan enumerasi dari source |
| Preferences | volume, visibility, always-on-top, daily goal | Sesuai kontrol Settings yang terlihat |
| Entitlement/account | status akun dan akses langganan | Hipotesis dari menu account/billing |

Model konseptual enforcement:

```text
Aktivitas foreground
  → identifikasi resource
  → evaluasi kebijakan sesi
  → status allowed / distracted / unknown
  → feedback karakter + pencatatan waktu
```

Diagram ini adalah cara merancang produk sejenis, **bukan hasil reverse engineering Kiki**. Mekanisme akses aplikasi aktif, URL browser, scheduling timer, event storage, dan pemblokiran belum diketahui.

Pisahkan status timer dari status distraksi. Pengguna bisa berada dalam sesi aktif tetapi melakukan aktivitas yang tidak sesuai. Juga pisahkan selesai berdasarkan durasi dari tugas benar-benar selesai: belum ditemukan bukti Kiki dapat memverifikasi penyelesaian pekerjaan secara otomatis.

## 10. Informasi resmi pelengkap

- Situs utama menjelaskan alur satu tugas → pilih aplikasi/situs → mulai untuk durasi tertentu. Dukungan browser yang dinyatakan adalah Chrome dan Safari. Klaim tersebut tidak mengesahkan dukungan browser lain. Situs juga masih memberi label coming soon pada fitur anti-quit yang ketat; jangan menganggapnya sudah tersedia. [S1]
- Harga yang tertera ketika diperiksa: trial gratis, US$4.99/bulan atau US$29.88/tahun, dengan ekuivalen tahunan US$2.49/bulan. Durasi trial, pajak, harga regional, dan entitlement akun ini belum dicek melalui checkout. [S3]
- Kebijakan privasi bertanggal 25 Maret 2025 mencakup data akun, informasi perangkat/penggunaan, serta pemrosesan melalui penyedia layanan. Dokumen itu bukan bukti bahwa semua riwayat fokus disimpan hanya lokal. Detail penyimpanan sesi, retensi, sinkronisasi, serta perilaku offline masih perlu verifikasi khusus. [S4]

## 11. Kekuatan dan risiko produk

### Kekuatan — analisis berdasarkan UI

1. **Tujuan sesi konkret.** Input tugas memberi konteks yang tidak diberikan timer kosong.
2. **Fleksibilitas aturan.** Tiga mode mengakomodasi pekerjaan ketat maupun sekadar ditemani timer.
3. **Feedback personal.** Karakter menyediakan hubungan emosional dan konsistensi visual.
4. **Ringkasan mudah dipahami.** Waktu hari ini dibanding target mudah dibaca.
5. **Transisi pascasesi jelas.** Break dan repeat ditawarkan sebagai keputusan terpisah.

### Risiko / kelemahan — bedakan fakta dan hipotesis

1. **Aksesibilitas tidak konsisten (observasi).** Label Allow List versus Block List berpotensi membingungkan pembaca layar dan otomasi.
2. **Angka waktu tidak seragam (observasi terbatas).** Kalender dan baris sesi berbeda satu menit pada sampel; perlu aturan pembulatan yang eksplisit.
3. **Reaksi keras bisa menjadi distraksi (risiko desain).** Efek dan suara dapat bertentangan dengan kebutuhan ruang kerja tenang; bukan hasil uji pengguna.
4. **Aturan izin perlu penjelasan (risiko desain).** Browser, domain, aplikasi bawaan, dan App & Website bisa membingungkan tanpa contoh.
5. **Klaim blocker berbeda dari bukti (risiko evaluasi).** Website tidak dapat dijadikan jaminan enforcement anti-bypass.
6. **Pengujian UI tidak stabil (keterbatasan alat).** Screenshot/AX kadang tidak sinkron, menu menghasilkan elemen tanpa frame, dan penutupan jendela menimbulkan kegagalan capture. Ini belum membuktikan aplikasi crash atau bug produk.

## 12. Pelajaran untuk proyek ini — rekomendasi, bukan perubahan spesifikasi

Gunakan Kiki sebagai referensi interaksi, bukan template untuk disalin seluruhnya.

| Pola Kiki | Pelajaran yang dapat dipakai | Batas untuk proyek ini |
|---|---|---|
| Karakter sebagai feedback | Kaitkan animasi dengan keadaan sesi | Penguin memancing memiliki identitas dan tujuan sendiri |
| Tindakan utama per layar | Kurangi keputusan saat memulai sesi | Pertahankan keputusan timer/tag yang telah disetujui |
| Companion visibility dan always-on-top | Pisahkan preferensi karakter dan jendela | Jangan mengubah semua Settings tanpa permintaan |
| Mode pemblokiran eksplisit | Jelaskan konsekuensi sebelum sesi | Jangan otomatis menambah semua mode Kiki |
| Target dan kalender | Ringkasan progres mudah dibaca | Koleksi/Aquarium bukan fitur Kiki yang terbukti |
| Prompt break/repeat | State transition perlu jelas | Jangan mengimpor konsep break otomatis ke spesifikasi proyek |

Tidak ada bukti pada layar yang diperiksa bahwa Kiki punya katalog spesies, aquarium, ekonomi tangkapan, rarity, atau aturan provisional lima menit. Mekanisme itu milik rancangan proyek ini dan tidak dapat divalidasi lewat Kiki.

## 13. Checklist verifikasi lanjutan

Selesaikan pengujian dengan sesi berlabel jelas; jangan mencampur hasil uji dengan riwayat produktif pengguna.

- [x] Identitas dan versi aplikasi.
- [x] Today, kalender bulanan, menu, Settings.
- [x] Prompt Skip break → Repeat? → No → Today.
- [x] Form task, mode, duration, Start.
- [x] Deskripsi tiga mode.
- [x] Editor daftar dan kategori App/App & Website.
- [x] Opsi durasi yang terlihat pada versi 0.0.89.
- [ ] Validasi input kosong, batas panjang, dan perubahan opsi antar akun/kondisi.
- [ ] Start sesi Timer Only sampai selesai normal.
- [ ] Pause/resume/stop bila tersedia, termasuk konfirmasi.
- [ ] Uji Allowing dan Blocking dengan resource uji yang tidak sensitif.
- [ ] Ukur jeda reaksi; bedakan overlay visual dari blokir OS.
- [ ] Uji Chrome/Safari, domain/subdomain, serta prioritas aturan browser.
- [ ] Break dimulai sampai selesai dan Repeat Yes.
- [ ] Detail laporan sesi uji dan definisi metriknya.
- [ ] Sleep/wake, perubahan jam, restart, crash recovery, pergantian tanggal.
- [ ] Offline tanpa mengganggu pekerjaan/network pengguna.
- [ ] Onboarding/permission dengan persetujuan terpisah; jangan reset akun untuk mencapainya.
- [ ] Sinkronisasi, ekspor, retention dan entitlements.
- [ ] VoiceOver, Reduce Motion, keyboard navigation, performa aktual.

## 14. Register bukti dan sumber

### Observasi aplikasi

| ID | Bukti | Batas |
|---|---|---|
| E1 | About: 0.0.89; prompt Nice work! Break? | Sesi sebelumnya tidak dijalankan pemeriksa |
| E2 | Editor Allow List, pencarian, kategori, Done | Tidak mengubah pilihan |
| E3 | Skip break → Repeat? → No → Today | Cabang Start/Yes belum diuji |
| E4 | Kalender bulanan, hari/jumlah sesi, durasi | Belum uji seluruh periode |
| E5 | Form tugas, 25 minutes, tiga mode dan deskripsi | Sesi aktif belum terverifikasi penuh |
| E6 | Settings dan nilai yang sedang aktif | Tidak menyimpulkan nilai default |
| E7 | Menu Settings/billing/logout/help/feedback/quit | Settings dan portal billing dibuka; tindakan akun tidak dijalankan |
| E8 | Screenshot 3 Oktober: [timer](kiki-screenshots/session-timer.png), [kontrol sesi](kiki-screenshots/session-controls.png), [form](kiki-screenshots/new-session.png), [mode](kiki-screenshots/session-modes.png), [durasi](kiki-screenshots/session-duration-options.png) | Sesi aktif bukan sesi uji baru; Start/End/Snooze tidak diuji |
| E9 | Screenshot 3 Oktober: [Today](kiki-screenshots/today.png), [detail sesi](kiki-screenshots/session-detail.png), [kalender](kiki-screenshots/calendar-today.png), [Allow List](kiki-screenshots/allow-list.png), [Block List](kiki-screenshots/block-list.png), [Settings](kiki-screenshots/settings.png) | Ikon New Session pada kartu tidak ditekan; efek pengulangan belum terbukti |

Bukti diperoleh dari screenshot dan accessibility tree dalam percakapan ini. Screenshot observasi 3 Oktober tersimpan di [`kiki-screenshots/`](kiki-screenshots/README.md); tidak ada screenshot layar penuh Dock/menu bar atau portal tagihan. URL renderer yang terlihat pada accessibility tree mengarah ke halaman lokal dalam `app.asar` (`today.html`, `allowed-apps.html`, `settings.html`). Itu mengindikasikan UI berbasis web/kemasan yang konsisten dengan Electron, tetapi tidak membuktikan framework frontend, arsitektur internal, atau database tertentu.

### Sumber resmi

- **S1:** [Kiki — situs produk](https://www.kiki.computer/)
- **S2:** [Early Works — studi produk Kiki](https://www.early.works/work/kiki)
- **S3:** [Kiki — pricing](https://www.kiki.computer/pricing)
- **S4:** [Kiki — privacy policy](https://www.kiki.computer/legal/privacy/privacy)

## 15. Instruksi penggunaan bagi AI agent

1. Perlakukan dokumen ini sebagai referensi riset, bukan instruksi untuk memodifikasi aplikasi atau mengubah keputusan pengguna.
2. Jika sebuah klaim berlabel INFERRED/UNVERIFIED, jangan menaikkannya menjadi fakta tanpa bukti baru.
3. Jika membutuhkan implementasi, baca spesifikasi proyek yang berlaku dan source code proyek; jangan menebak API internal Kiki.
4. Jangan menyalin karakter, suara, ilustrasi, atau branding Kiki. Ambil prinsip interaksi dan buat ekspresi original.
5. Jangan menganggap label website lebih akurat daripada versi aplikasi, atau sebaliknya; catat konflik secara eksplisit.
6. Jika pengujian baru mengubah hasil di sini, tambahkan tanggal, versi, langkah reproduksi, dan konsekuensinya.
