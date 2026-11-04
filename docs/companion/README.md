# Panduan berkas companion

Gunakan indeks ini untuk memilih referensi yang tepat saat membuat atau memperbaiki karakter companion. Prompt aksi yang ada dibuat untuk penguin duduk; jadikan acuan gaya dan urutan kerja, lalu sesuaikan pose, proporsi, serta properti untuk karakter baru.

## Panduan dan catatan implementasi

| Berkas | Gunakan saat |
|---|---|
| [new-character-guide.md](new-character-guide.md) | Memulai karakter baru. Berisi daftar aset yang dibutuhkan, alur animasi lengkap, panduan prompt imagegen, integrasi, dan checklist. |
| [full-cycle-v4.md](full-cycle-v4.md) | Memahami contoh implementasi memancing lengkap: masuk, lempar, menunggu, gigitan, menarik tangkapan, memasukkannya ke ember, lalu mengulang. Ini referensi runtime terbaru. |
| [smooth-distraction-v3.md](smooth-distraction-v3.md) | Membuat atau menyesuaikan animasi karakter pada overlay distraction: menekan sakelar, melompat di es, atau meniup salju. |
| [watercolor-v2.md](watercolor-v2.md) | Melihat asal gaya visual, pembagian layer, ukuran runtime, dan prompt awal untuk pose, tangkapan, serta latar es-air. Catatan ini menjelaskan versi awal, jadi gunakan `full-cycle-v4.md` untuk perilaku siklus terbaru. |
| [character-prototypes/README.md](character-prototypes/README.md) | Membandingkan tiga konsep berdiri yang sudah dibuat dan memakai prompt konsepnya sebagai titik awal untuk variasi aksesori atau pancing. |

## Prompt imagegen

Prompt ini spesifik untuk aksi atau aset tertentu. Salin hanya setelah mengganti detail pose dan identitas sesuai karakter yang sedang dibuat.

| Berkas | Gunakan saat |
|---|---|
| [smooth-catch-prompt.txt](smooth-catch-prompt.txt) | Membuat 12 frame gigitan dan tarikan, dengan perubahan pose bertahap serta kaki yang stabil. |
| [cast-v4-prompt.txt](cast-v4-prompt.txt) | Membuat 12 frame gerakan melempar pancing. Prompt mengatur urutan gerak, bentuk atlas, transparansi, dan ciri penguin watercolor. |
| [deposit-v4-prompt.txt](deposit-v4-prompt.txt) | Membuat 12 frame saat karakter mengarahkan tangkapan ke ember dan kembali ke posisi memancing. Ember dan tangkapan digambar sebagai layer terpisah. |
| [deposit-v4-layout-prompt.txt](deposit-v4-layout-prompt.txt) | Memperbaiki atlas deposit yang keluar batas sel atau memiliki ukuran dan baseline karakter yang tidak konsisten. Ini prompt koreksi layout, bukan prompt aksi baru. |
| [ice-water-v2-prompt.txt](ice-water-v2-prompt.txt) | Membuat ulang latar gabungan es dan air. Tidak perlu dijalankan untuk karakter baru jika latar yang sama tetap digunakan. |

## Preview visual

| Berkas | Gunakan saat |
|---|---|
| [full-cycle-v4.gif](full-cycle-v4.gif) | Melihat siklus memancing berulang pada tampilan terang dan gelap. |
| [full-cycle-v4.mp4](full-cycle-v4.mp4) | Meninjau siklus memancing pada video 30 FPS. |
| [distraction-lights-v3.gif](distraction-lights-v3.gif) | Melihat gerakan karakter saat menekan kontrol lampu. |
| [distraction-ice-v3.gif](distraction-ice-v3.gif) | Melihat lompatan dan pendaratan karakter di es. |
| [distraction-snow-v3.gif](distraction-snow-v3.gif) | Melihat aksi karakter meniup salju. |
| [runtime-preview.png](runtime-preview.png) | Memeriksa tampilan companion di aplikasi pada ukuran runtime. |
| [ice-water-runtime.png](ice-water-runtime.png) | Memeriksa skala dan posisi latar es-air bersama karakter di runtime. |

## File konsep karakter

Semua gambar berikut adalah konsep diam, bukan frame animasi atau aset yang siap dipasang ke runtime.

| Berkas | Konsep |
|---|---|
| [round-black-glasses-v1.png](character-prototypes/round-black-glasses-v1.png) | Penguin berkacamata hitam bulat, bandana merah bata, dan pancing biru modern. |
| [christmas-v1.png](character-prototypes/christmas-v1.png) | Penguin bertopi Santa dan bersyal hijau dengan pancing merah-putih. |
| [explorer-v1.png](character-prototypes/explorer-v1.png) | Penguin penjelajah bertopi ochre dan bersyal sage dengan pancing bambu. |

## Alur singkat

1. Buka `new-character-guide.md` untuk menentukan paket karakter dan cakupannya.
2. Gunakan `character-prototypes/README.md` untuk contoh identitas atau buat desain dasar baru.
3. Buat prompt atlas per aksi dengan mengadaptasi `smooth-catch-prompt.txt`, `cast-v4-prompt.txt`, dan `deposit-v4-prompt.txt` sesuai kebutuhan karakter.
4. Jika karakter tampil saat aplikasi terblokir, lihat `smooth-distraction-v3.md` dan siapkan pose atau animasi distraction yang sesuai.
5. Bandingkan hasil runtime dengan preview `full-cycle-v4` dan catatan implementasinya.
