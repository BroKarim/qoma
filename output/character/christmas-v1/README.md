# Penguin Natal v1

## Revisi ekspresi dan preview

- `atlases/catch.png` direvisi dengan mata lelah, alis tegang, dan keringat; tiga atlas distraction mempertahankan ekspresi marah pada seluruh 12 frame.
- `preview.html` memakai salinan PNG es-air, ember, dan tangkapan proyek di `environment/`. Tali/kail digambar terpisah, mengikuti koordinat ujung pancing; kail masuk air saat menarik dan terlihat saat diangkat. Tangkapan menuju ember melalui jalur di atas topi.
- `registration.json` dan `registration.js` telah dihitung ulang untuk aset aktif, termasuk titik kaki, skala referensi per aksi, dan koordinat awal ujung pancing. Koordinat pancing masih perlu kalibrasi visual saat integrasi.
- Empat atlas sebelum revisi dan sumber preview sebelumnya disimpan di `archive/` sebagai riwayat. Gunakan preview utama untuk hasil sekarang.
- Prompt revisi built-in imagegen tersimpan sebagai `prompts/*-emotion-revision.txt`. Tidak ada perubahan kode atau asset catalog aplikasi.

Paket artwork animasi mandiri berdasarkan [prototipe Natal](reference.png): topi Santa, syal hijau, pancing merah-putih, watercolor hand-drawn, mata berupa garis, tanpa mulut/paruh. Posisi dasar berdiri mengikuti konsep yang dipilih. Dibuat dengan built-in imagegen; tidak diintegrasikan ke aplikasi.

Buka [preview.html](preview.html) di browser untuk memutar tiap atlas, mengatur kecepatan, dan mengganti latar. Ini preview urutan gambar, bukan renderer SpriteKit aplikasi. File prompt persis yang digunakan disimpan di `prompts/`.

Tujuh atlas masing-masing berukuran 1448 × 1086 px, dengan sel 362 × 362 px dan alpha transparan. Total 84 gambar. [registration.json](registration.json) berisi titik kaki awal yang diukur dari alpha per sel; `registration.js` memuat pengukuran yang sama untuk menyelaraskan kaki di preview. Metadata ini masih perlu peninjauan manual sebelum integrasi. Atlas lempar memakai hasil revisi layout; prompt revisinya ada di `prompts/cast-layout-revision.txt`.

## Isi paket

| Atlas | Fungsi dan urutan |
|---|---|
| [arrival-idle.png](atlases/arrival-idle.png) | Sambutan kecil, berdiri tegak, lalu bernapas dan tenang. Tidak memegang pancing. |
| [cast.png](atlases/cast.png) | Antisipasi, backswing, lempar, follow-through, lalu kembali memancing. |
| [catch.png](atlases/catch.png) | Gigitan, badan menahan tegangan, tarikan, lalu pose memperlihatkan hasil. |
| [deposit.png](atlases/deposit.png) | Pancing bergerak melewati atas kepala ke kanan untuk ember, melepas tangkapan, lalu kembali ke kiri. |
| [distraction-lights.png](atlases/distraction-lights.png) | Mengulurkan sirip, menekan sakelar imajiner, lalu menarik kembali. Target beat tekan: frame 6. |
| [distraction-ice.png](atlases/distraction-ice.png) | Antisipasi lompat, ekstensi, bersiap mendarat, squash, lalu pulih. Perpindahan vertikal perlu ditambahkan runtime. |
| [distraction-snow.png](atlases/distraction-snow.png) | Tarik napas, gestur meniup tanpa mulut, lalu pulih. Partikel salju ditambahkan terpisah. |

## Pemakaian berikutnya

Setiap atlas dirancang berisi 12 gambar dalam grid 4 kolom × 3 baris, dibaca kiri ke kanan kemudian atas ke bawah. Gunakan sekitar 10–12 gambar/detik sebagai titik awal; jangan menaikkan FPS untuk menutupi loncatan pose. Pompom dan syal mengikuti gerakan badan pada gambar penghubung.

Saat dipasang nanti, kalibrasi anchor kaki, skala badan, dan ujung pancing per frame. Target baseline prompt adalah 84% tinggi sel dan pusat kaki di 55% lebar sel; hasil generate tetap perlu diukur. Cocokkan pose akhir satu aksi dengan awal aksi berikutnya dan siapkan transisi mengambil pancing dari pose sambutan tanpa pancing.

Tali, tangkapan, ember, es-air, dan partikel tidak dilukis ke dalam atlas. Gerakkan elemen tersebut secara kontinu pada 30/60 FPS. Jalur tangkapan harus melewati atas topi dan pompom sebelum turun ke ember. Tambahkan fade/settle saat muncul, hold hasil tangkapan, serta Reduce Motion ketika integrasi dikerjakan.

## Batas hasil

Ini sumber artwork dan preview untuk peninjauan, belum paket runtime dengan metadata anchor yang dikalibrasi manual. Jumlah frame dan tekstur hasil imagegen tidak menjamin bebas flicker; periksa sambungan siluet, ukuran badan, dan perubahan rajutan pada kecepatan normal. Preview menggambarkan penempatan es, tali/kail dan tangkapan secara mandiri; sinkronisasi suara, sambungan seluruh siklus, dan perilaku interupsi aplikasi belum diperiksa. Pemeriksaan visual browser pada revisi ini terhalang kebijakan URL berkas lokal; grid, alpha, dan keberadaan 12 frame per atlas diperiksa langsung dari PNG.
