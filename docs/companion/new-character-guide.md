# Membuat karakter companion baru

Panduan ini dipakai setiap kali menambahkan karakter yang bisa dipilih pengguna. Anggap karakter sebagai satu paket visual untuk semua tempat companion tampil, bukan hanya satu sprite memancing. Mulai dari karakter yang sudah ada, lalu ganti aset dan konfigurasi yang memang khas karakter itu.

## Cakupan

Untuk karakter siap dipakai, siapkan:

1. **Identitas karakter**: tampak depan/samping yang disetujui, proporsi, palet, aksesori, dan ekspresi. Periksa keterbacaan pada ukuran kecil.
2. **Siklus companion saat sesi aktif**: muncul, mulai memancing, menunggu, mendapat gigitan, menarik, memperlihatkan hasil, memasukkan hasil ke ember, lalu kembali memancing.
3. **Tampilan distraction**: karakter harus tetap dikenali saat overlay muncul. Minimal buat pose reaksi/menegur yang terbaca; buat variasi frame bila overlay memang menganimasikannya. Jangan menganggap pose memancing otomatis cocok untuk konteks ini.
4. **Integrasi pemilihan karakter**: daftarkan identitas dan asetnya agar pilihan pengguna menentukan karakter di semua tampilan yang mendukung companion.
5. **Preview dan pemeriksaan**: render hasil dari runtime aplikasi, periksa latar terang/gelap, lalu build dan jalankan pemeriksaan yang relevan.

Untuk prototipe visual, butir 1 dan satu siklus memancing cukup. Itu belum berarti karakter siap dipilih di aplikasi: distraction dan integrasi pemilihan tetap perlu diselesaikan.

## Aset yang perlu dibuat

| Aset | Kebutuhan | Catatan |
|---|---|---|
| Referensi karakter | Satu pose dasar dan detail ciri khas | Tetapkan aksesori yang tidak berubah, misalnya kacamata bulat hitam. Jaga bentuknya konsisten dari pose ke pose. |
| Pose masuk/idle | Pose muncul dan pose menunggu | Napas atau gerak kecil boleh dibuat runtime; jangan mengganti siluet utama tanpa alasan. |
| Gerak memancing | Lempar pancing dan kembali ke posisi menunggu | Pastikan tangan, batang pancing, ujung pancing, tali dan arah pandang tetap tersambung. |
| Gigitan dan tarikan | Antisipasi, tarikan, dan beat saat tangkapan terlihat | Buat perubahan berat badan/kemiringan, bukan hanya memindahkan pancing. Sisakan jeda singkat agar hasil tangkapan terbaca. |
| Memasukkan tangkapan | Angkat, bawa menuju ember, lepaskan, lalu pulih ke idle | Rencanakan jalur tangkapan bersama posisi ember dan ruang panggung sejak awal. |
| Tangkapan dan alat | Satu atau beberapa hasil tangkapan serta alat khas karakter | Hasil dapat berupa ikan atau benda. Jangan menambahkan detail wajah pada ikan/benda bila tidak sesuai gaya proyek. |
| Distraction | Pose reaksi yang cocok dengan overlay | Aset ini boleh memakai karakter dasar yang sama, tetapi ekspresi, arah pandang, crop, dan kontrasnya perlu diperiksa khusus untuk overlay. |
| Ikon pilihan | Gambar kecil karakter untuk pemilih, bila UI pemilih memerlukannya | Gunakan pose sederhana yang tetap terbaca pada ukuran ikon. |

> Es dan air dapat tetap menjadi latar bersama jika karakter duduk di atasnya. Pisahkan karakter, pancing/tali, tangkapan, ember dan latar hanya jika runtime memang perlu menggerakkannya secara terpisah. Jangan memisahkan elemen yang tidak akan dianimasikan sendiri.

## Membuat animasi yang terasa halus

Gunakan alur lengkap `muncul → lempar → menunggu → gigitan/tarikan → tangkapan → ember → kembali memancing`. Jangan hanya membuat tarikan jika karakter akan dipakai dalam siklus penuh.

- Buat keyframe untuk perubahan pose utama, lalu gambar frame penghubung khusus pada perpindahan yang paling terasa meloncat. Siklus penguin saat ini memakai atlas 12 gambar untuk lempar dan memasukkan tangkapan; itu titik awal yang terbukti di proyek, bukan angka wajib untuk semua karakter.
- Sebagai titik awal, jalankan gambar berurutan sekitar 12 gambar/detik dan gerak runtime pada 30/60 FPS. Gerakkan posisi tangkapan, tali, percikan, atau respons ember secara kontinu di antara perubahan gambar.
- Pertahankan titik kontak kaki dan tinggi badan yang konsisten. Ukur anchor kaki dan ujung pancing per frame bila margin gambar berubah.
- Periksa arc gerak, timing, antisipasi, follow-through, dan jeda hasil tangkapan. Frame tambahan tidak otomatis membuat gerakan terasa bagus.
- Hindari perubahan mendadak pada skala, posisi, siluet, aksesori, arah cahaya, tekstur watercolor, dan ketebalan garis.
- Pastikan animasi berakhir di pose yang cocok untuk frame berikutnya. Pose akhir lemparan harus tersambung ke idle; pose lepas tangkapan harus pulih ke idle tanpa teleport.
- Hormati Reduce Motion: gunakan pose stabil dan kurangi perpindahan besar, sambil tetap menampilkan status gigitan/tangkapan dengan jelas.

## Menyiapkan sprite atlas dengan imagegen

1. Lampirkan ilustrasi karakter yang sudah disetujui sebagai referensi identitas dan gaya. Sertakan contoh frame yang runtime-nya sudah benar jika tersedia.
2. Minta satu aksi saja dalam satu atlas transparan dengan grid dan urutan baca yang pasti. Untuk atlas 12 frame, nyatakan grid 4 kolom × 3 baris, urutan kiri-ke-kanan lalu atas-ke-bawah, satu penguin penuh per sel, dan tanpa nomor/garis panel.
3. Kunci ciri karakter dalam prompt: proporsi, warna, bentuk aksesori (contoh: kacamata bulat hitam), mata sesuai desain, tanpa mulut jika desain proyek melarangnya, gaya watercolor, arah cahaya, dan outline.
4. Nyatakan pose awal/akhir dan progres aksi secara berurutan. Minta latar transparan dan jangan menambahkan elemen lingkungan ke atlas karakter kecuali memang bagian yang ikut bergerak.
5. Buat atlas terpisah untuk aksi yang berbeda, seperti lempar pancing, tarikan, dan memasukkan tangkapan. Jangan menggabungkan aksi dengan skala/komposisi berbeda dalam satu sheet.
6. Simpan prompt final dan hasil render di `docs/companion/` agar revisi selanjutnya dapat diulang. Prompt proyek sebelumnya ada di [full-cycle-v4.md](full-cycle-v4.md); sesuaikan dengan karakter dan aksi baru, jangan salin ciri penguinnya mentah-mentah.
7. Periksa hasil per sel. Regenerasi atau koreksi sel yang mengubah identitas, memotong aksesori/anggota badan, mengubah ukuran karakter, atau membuat sambungan aksi tidak masuk akal.

Contoh kerangka prompt:

```text
Buat sprite atlas transparan untuk karakter [nama/deskripsi], gunakan gambar referensi
sebagai acuan identitas dan gaya. Grid [kolom] × [baris], urutan kiri-ke-kanan,
atas-ke-bawah. Setiap sel berisi satu karakter penuh dengan ukuran dan titik kaki
yang konsisten. Pertahankan [ciri khas], warna, watercolor hand-drawn, outline dan
pencahayaan yang sama di semua frame. Aksi: [urutan pose per frame]. Jangan tambahkan
nomor, batas sel, teks, latar, atau aksesori baru. Sisakan margin agar seluruh
karakter dan properti tidak terpotong.
```

## Integrasi di aplikasi

Sebelum mengubah kode, telusuri penggunaan companion saat ini dan catat tempat yang harus menerima pilihan karakter: pemilih karakter, sesi aktif, distraction, serta layar lain yang benar-benar menampilkan companion. Pertahankan controller/timing bersama jika perilakunya sama; letakkan artwork, metadata frame, anchor, dan perbedaan gerak dalam aset/konfigurasi karakter.

Saat ini dokumentasi runtime penguin dan alur frame ada di [full-cycle-v4.md](full-cycle-v4.md), dengan preview [full-cycle-v4.gif](full-cycle-v4.gif) dan [full-cycle-v4.mp4](full-cycle-v4.mp4). Gunakan itu sebagai contoh hasil akhir, bukan asumsi bahwa setiap karakter memakai aset atau gerak yang sama.

Per karakter, pastikan:

- nama aset unik dan atlas terbaca dengan grid yang benar;
- urutan frame, durasi, titik kaki, tinggi badan, ujung pancing, tali, ember dan tangkapan cocok dengan gambar;
- animasi masuk ke idle dan kembali ke siklus tanpa loncatan;
- jeda menunggu produksi tetap memakai timing normal (preview boleh dipercepat secara terpisah);
- distraction dapat memakai karakter terpilih dan pulih benar saat overlay berakhir;
- Reduce Motion, pause, pergantian sesi, dan reset distraction tidak meninggalkan frame/efek dari karakter sebelumnya;
- tangkapan dekoratif companion tidak mengubah reward atau katalog kecuali memang dimaksudkan sebagai reward produk.

## Checklist sebelum selesai

- [ ] Identitas, siluet, aksesori, dan ekspresi konsisten di semua pose.
- [ ] Seluruh siklus sesi aktif tersedia, termasuk awal dan akhir aksi.
- [ ] Distraction menampilkan karakter yang sama dalam pose yang cocok.
- [ ] Pemilih mengubah companion di semua konteks yang mendukungnya.
- [ ] Tidak ada karakter/properti terpotong; titik kaki dan sambungan tali stabil.
- [ ] Preview runtime dilihat pada ukuran aplikasi dan latar terang serta gelap.
- [ ] Timing normal, Reduce Motion, pause, dan transisi distraction diperiksa.
- [ ] Build dan pemeriksaan terkait lulus; prompt, preview, dan catatan aset disimpan di `docs/companion/`.

## Batas keputusan

Tidak semua karakter perlu properti atau animasi yang sama. Buat aset tambahan hanya untuk gerakan yang benar-benar berbeda. Untuk langkah pertama, selesaikan siklus companion dan satu pose distraction; tambahkan variasi tangkapan atau reaksi hanya ketika konsepnya memerlukannya.
