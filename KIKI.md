# Kiki — Catatan Analisis Produk untuk AI Agent

Tanggal pemeriksaan: 1 Oktober 2026. Versi terpasang: **0.0.89 (0.0.89)**, Early Works. Target: aplikasi macOS `/Applications/Kiki.app`, bundle identifier `com.earlyworks.kiki`.

## 1. Cara membaca dokumen ini

Dokumen ini adalah studi perilaku produk melalui antarmuka, bukan audit source code Kiki. Jangan memperlakukan dugaan implementasi sebagai fakta.

- **OBSERVED**: terlihat pada UI atau accessibility tree aplikasi terpasang.
- **OFFICIAL**: disebutkan pada website resmi; belum tentu sama dengan perilaku versi terpasang.
- **INFERRED**: model penjelasan yang masuk akal, bukan implementasi yang telah dibuktikan.
- **UNVERIFIED**: belum diuji, belum terlihat, atau pengujian terhalang.

Status cakupan: **eksplorasi parsial**. Today, kalender, form sesi, pilihan mode, editor daftar, Settings, serta prompt break/repeat telah diperiksa. Onboarding, izin pertama kali, enforcement saat sesi berjalan, seluruh edge case, dan penyimpanan internal belum terverifikasi. Tidak ada pembongkaran bundle, pembacaan database privat, atau inspeksi trafik jaringan.

Hasil usaha sesi uji: pengguna memberi izin, tetapi sesi baru **belum berhasil dimulai**. Kontrol popup menghasilkan state yang tidak konsisten dengan screenshot dan beberapa elemen kehilangan frame. Pemeriksaan berhenti di form sesi; accessibility tree terakhir memuat draft `Kiki exploration test`, mode Allowing, durasi 25 menit. Tidak ada bukti sesi uji telah tercatat di riwayat. Pengguna diminta membawa Kiki ke foreground untuk pengujian lanjutan. Jangan membaca checklist yang belum tercentang sebagai fitur yang tidak tersedia.

Catatan privasi: nama tugas dan daftar penggunaan pribadi tidak direproduksi di sini. Nilai contoh agregat dipakai hanya untuk menjelaskan UI. Penjelajahan sesi uji telah diizinkan pengguna; hasil pengujiannya harus dibedakan dari data riwayat sebelumnya.

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
│   ├── Editor aplikasi dan situs
│   ├── Duration
│   └── Start → sesi aktif [belum terverifikasi penuh]
└── Menu
    ├── Settings
    ├── Manage Subscription
    ├── Sign Out
    ├── Help
    ├── Give Feedback
    └── Quit

Prompt pascasesi yang diamati
Nice work! Break?
├── Start break [belum diuji]
└── Skip break → Repeat session?
    ├── Yes [belum diuji]
    └── No → Today [terverifikasi]
```

Tidak semua kotak di atas telah diuji sampai selesai. Label kontrol menunjukkan kemampuan yang ditawarkan, bukan bukti semua efek sampingnya.

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
5. **Duration**: pemilih durasi; nilai yang terlihat 25 minutes.
6. **Start**: tombol utama.

Form awal terisi nama tugas sebelumnya pada sampel. Itu menunjukkan adanya pengisian ulang nilai, tetapi belum membuktikan persistensi lintas restart atau bahwa semua pengguna mendapat nilai tersebut. Demikian pula 25 menit adalah nilai yang diamati, **bukan minimum/maksimum atau default global yang sudah dipastikan**.

Untuk pengujian, input diubah menjadi `Kiki exploration test`. Validasi input kosong, batas panjang, daftar lengkap durasi, serta kemampuan edit saat sesi berjalan belum terverifikasi.

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

**Ketidaksesuaian aksesibilitas:** screenshot menunjukkan Allow List, tetapi accessibility text menyebut Block List dan pertanyaan tentang yang diblokir. Ini bukti label tidak sinkron pada kondisi yang diperiksa, bukan bukti bahwa aturan aktif benar-benar terbalik.

Belum diuji: hasil pencarian, tambah/hapus item, website kustom, wildcard/subdomain, satu layanan yang punya aplikasi dan website, prioritas izin browser versus domain, serta kapan perubahan tersimpan.

## 6. Sesi aktif dan pascasesi

### Sesi aktif — OFFICIAL / UNVERIFIED

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
| Check for Updates | Tindakan pemeriksaan update | Tidak dijalankan |
| Reset Application | Tindakan reset | Tidak dijalankan; berpotensi destruktif |

Versi 0.0.89 ditampilkan di bagian bawah. Menu utama juga menyediakan pengelolaan langganan, sign out, bantuan, feedback, dan quit. Tujuan akhir dan efek tombol-tombol tersebut tidak diuji. Tidak ada perubahan nilai Settings, reset aplikasi, logout, pembelian, atau pemberian permission.

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
- [ ] Daftar durasi lengkap dan validasi input.
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
| E7 | Menu Settings/billing/logout/help/feedback/quit | Hanya Settings yang dibuka |

Bukti diperoleh dari screenshot dan accessibility tree dalam percakapan ini. Screenshot pengguna tidak disalin menjadi asset dokumentasi. URL renderer yang terlihat pada accessibility tree mengarah ke halaman lokal dalam `app.asar` (`today.html`, `allowed-apps.html`, `settings.html`). Itu mengindikasikan UI berbasis web/kemasan yang konsisten dengan Electron, tetapi tidak membuktikan framework frontend, arsitektur internal, atau database tertentu.

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
