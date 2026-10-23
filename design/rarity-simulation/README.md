# Simulasi rarity dan koleksi — 23 Oktober 2026

Roster production memakai 96 item dengan artwork terintegrasi. Setiap kandidat memakai 10.000 pemain, seed 20261022, Bun 1.3.10. Semua pemain disimulasikan sampai lengkap, tanpa censoring. Hasil ini mengukur roster saat ini; belum ada penyesuaian parameter untuk mengejar target 300 jam.

Satu catch memakai interval uniform 50–70 detik yang benar-benar dijumlahkan. Hanya jam fokus aktif; semua hasil dianggap banked, tanpa kehilangan provisional. Tidak ada bantuan item baru. Pity hanya menjamin tier.

P10 berarti 10% pemain mencapai milestone sebelum waktu itu; P90 berarti 90% sudah mencapainya. Quantile menggunakan interpolasi linear pada posisi (n−1) × p.

## Perbandingan penyelesaian 100%

| Kandidat | Item | P10 jam | Median jam | P90 jam | Mean duplikat |
|---|---:|---:|---:|---:|---:|
| baseline-100 | 100 | 11.61 | 17.92 | 32.56 | 1128.03 |
| bottleneck-150 | 150 | 54.27 | 283.50 | 946.26 | 24594.67 |
| spread-150 | 150 | 264.43 | 410.07 | 665.79 | 26453.55 |
| tuned-spread-150 | 150 | 192.10 | 300.57 | 487.72 | 19297.71 |
| progressive-150 | 150 | 206.61 | 292.56 | 438.74 | 18480.32 |
| artwork-backed-96 | 96 | 206.61 | 292.56 | 438.74 | 18534.28 |

## Konfigurasi produksi yang disetujui

**artwork-backed-96**: 8 Common, 35 Uncommon, 23 Rare, 30 Legendary. Angka mengikuti roster artwork aktif dan dapat berubah saat aset baru disetujui.

Peluang dasar C/U/R/L: **70,1% / 24% / 5,5% / 0,4%**. Rare+ soft/hard **30/60**, Legendary **220/440**. Bobot C/U/R berulang **1,2,3** menurut urutan item aktif; bobot Legendary **1 + indeks × 0,01**. Roster produksi memakai ID stabil yang sudah dipetakan ke artwork.

Ini tetap memiliki ekor panjang: banyak duplikat dan sebagian besar jam akhir mengejar Legendary tersisa. Pity tidak membatasi waktu menuju spesies baru; tidak ada jaminan 100% katalog selesai pada jam tertentu.

## Kebijakan pity yang diterapkan

Counter adalah kegagalan sebelum undian. Formula ramp mengikuti pengguna. Rare+ menghitung target peluang gabungan Rare+Legendary; Rare mereset counter Rare+ saja, Legendary mereset keduanya. Peluang Legendary soft dibatasi 1−baseRare, lalu Rare=max(baseRare,targetRarePlus−Legendary). Sisa peluang dibagi Common/Uncommon secara proporsional. Hard Legendary menang dan menetapkan Legendary=1, Rare=0 sebagai pengecualian eksplisit. Hard Rare+ dipenuhi oleh Rare atau Legendary.

## Hasil lengkap setiap kandidat

### baseline-100

Jumlah C/U/R/L: 60 / 25 / 12 / 3. Base (%): 70.00 / 24.00 / 5.50 / 0.50. Pity Rare+ 30/60 dan Legendary 180/360.

| Koleksi | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|
| 25% | 0.44 | 0.49 | 0.55 |
| 50% | 1.12 | 1.25 | 1.41 |
| 75% | 2.41 | 2.78 | 3.22 |
| 90% | 4.37 | 5.24 | 6.35 |
| 100% | 11.61 | 17.92 | 32.56 |

| Tier lengkap | Mean jam dari awal |
|---|---:|
| common | 10.49 |
| uncommon | 9.99 |
| rare | 14.54 |
| legendary | 15.24 |

| Legendary pertama | Mean jam | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|---:|
| withPity | 2.10 | 0.35 | 2.35 | 3.37 |
| withoutPity | 3.36 | 0.35 | 2.35 | 7.76 |

Mean duplikat: **1128.03**. Censored: **0**. Frekuensi tier efektif sepanjang simulasi (% C/U/R/L): **69.33 / 23.78 / 6.11 / 0.78**. Frekuensi ini mencakup penghentian pemain saat lengkap, bukan estimasi steady-state tanpa batas.

### bottleneck-150

Jumlah C/U/R/L: 90 / 36 / 18 / 6. Base (%): 70.00 / 24.00 / 5.50 / 0.50. Pity Rare+ 30/60 dan Legendary 180/360.

| Koleksi | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|
| 25% | 0.69 | 0.75 | 0.83 |
| 50% | 1.72 | 1.89 | 2.10 |
| 75% | 3.79 | 4.28 | 4.83 |
| 90% | 7.10 | 8.29 | 9.71 |
| 100% | 54.27 | 283.50 | 946.26 |

| Tier lengkap | Mean jam dari awal |
|---|---:|
| common | 17.47 |
| uncommon | 15.99 |
| rare | 25.18 |
| legendary | 412.08 |

| Legendary pertama | Mean jam | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|---:|
| withPity | 2.10 | 0.35 | 2.35 | 3.37 |
| withoutPity | 3.36 | 0.35 | 2.35 | 7.76 |

Mean duplikat: **24594.67**. Censored: **0**. Frekuensi tier efektif sepanjang simulasi (% C/U/R/L): **69.33 / 23.77 / 6.10 / 0.80**. Frekuensi ini mencakup penghentian pemain saat lengkap, bukan estimasi steady-state tanpa batas.

### spread-150

Jumlah C/U/R/L: 84 / 36 / 18 / 12. Base (%): 70.42 / 24.00 / 5.50 / 0.08. Pity Rare+ 30/60 dan Legendary 1000/2000.

| Koleksi | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|
| 25% | 0.70 | 0.76 | 0.84 |
| 50% | 1.78 | 1.96 | 2.19 |
| 75% | 4.24 | 4.82 | 5.53 |
| 90% | 10.34 | 12.96 | 16.65 |
| 100% | 264.43 | 410.07 | 665.79 |

| Tier lengkap | Mean jam dari awal |
|---|---:|
| common | 15.89 |
| uncommon | 15.93 |
| rare | 24.66 |
| legendary | 443.38 |

| Legendary pertama | Mean jam | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|---:|
| withPity | 11.78 | 2.19 | 14.53 | 17.58 |
| withoutPity | 21.04 | 2.19 | 14.53 | 49.04 |

Mean duplikat: **26453.55**. Censored: **0**. Frekuensi tier efektif sepanjang simulasi (% C/U/R/L): **69.83 / 23.80 / 6.23 / 0.14**. Frekuensi ini mencakup penghentian pemain saat lengkap, bukan estimasi steady-state tanpa batas.

### tuned-spread-150

Jumlah C/U/R/L: 84 / 36 / 18 / 12. Base (%): 70.39 / 24.00 / 5.50 / 0.11. Pity Rare+ 30/60 dan Legendary 730/1460.

| Koleksi | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|
| 25% | 0.70 | 0.76 | 0.84 |
| 50% | 1.78 | 1.96 | 2.19 |
| 75% | 4.23 | 4.81 | 5.52 |
| 90% | 10.17 | 12.56 | 15.24 |
| 100% | 192.10 | 300.57 | 487.72 |

| Tier lengkap | Mean jam dari awal |
|---|---:|
| common | 15.89 |
| uncommon | 15.93 |
| rare | 24.67 |
| legendary | 324.12 |

| Legendary pertama | Mean jam | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|---:|
| withPity | 8.61 | 1.57 | 10.55 | 12.96 |
| withoutPity | 15.15 | 1.57 | 10.55 | 35.22 |

Mean duplikat: **19297.71**. Censored: **0**. Frekuensi tier efektif sepanjang simulasi (% C/U/R/L): **69.79 / 23.80 / 6.22 / 0.19**. Frekuensi ini mencakup penghentian pemain saat lengkap, bukan estimasi steady-state tanpa batas.

### progressive-150

Jumlah C/U/R/L: 60 / 36 / 24 / 30. Base (%): 70.10 / 24.00 / 5.50 / 0.40. Pity Rare+ 30/60 dan Legendary 220/440.

| Koleksi | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|
| 25% | 0.73 | 0.81 | 0.91 |
| 50% | 2.10 | 2.38 | 2.72 |
| 75% | 7.45 | 8.88 | 10.71 |
| 90% | 41.31 | 52.26 | 65.10 |
| 100% | 206.61 | 292.56 | 438.74 |

| Tier lengkap | Mean jam dari awal |
|---|---:|
| common | 10.47 |
| uncommon | 15.98 |
| rare | 36.67 |
| legendary | 310.50 |

| Legendary pertama | Mean jam | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|---:|
| withPity | 2.57 | 0.43 | 2.93 | 4.08 |
| withoutPity | 4.18 | 0.43 | 2.93 | 9.74 |

Mean duplikat: **18480.32**. Censored: **0**. Frekuensi tier efektif sepanjang simulasi (% C/U/R/L): **69.44 / 23.78 / 6.13 / 0.65**. Frekuensi ini mencakup penghentian pemain saat lengkap, bukan estimasi steady-state tanpa batas.

### artwork-backed-96

Jumlah C/U/R/L: 8 / 35 / 23 / 30. Base (%): 70.10 / 24.00 / 5.50 / 0.40. Pity Rare+ 30/60 dan Legendary 220/440.

| Koleksi | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|
| 25% | 0.82 | 1.07 | 1.37 |
| 50% | 3.51 | 4.26 | 5.22 |
| 75% | 17.29 | 21.94 | 27.39 |
| 90% | 69.94 | 88.75 | 111.66 |
| 100% | 206.61 | 292.56 | 438.74 |

| Tier lengkap | Mean jam dari awal |
|---|---:|
| common | 0.71 |
| uncommon | 15.29 |
| rare | 34.20 |
| legendary | 310.50 |

| Legendary pertama | Mean jam | P10 jam | Median jam | P90 jam |
|---|---:|---:|---:|---:|
| withPity | 2.57 | 0.43 | 2.93 | 4.08 |
| withoutPity | 4.18 | 0.43 | 2.93 | 9.74 |

Mean duplikat: **18534.28**. Censored: **0**. Frekuensi tier efektif sepanjang simulasi (% C/U/R/L): **69.44 / 23.78 / 6.13 / 0.65**. Frekuensi ini mencakup penghentian pemain saat lengkap, bukan estimasi steady-state tanpa batas.

## Reproduksi dan validasi

`bun scripts/rarity-sim.ts --check` menjalankan assert checks. `bun scripts/rarity-sim.ts` menjalankan semua kandidat. `bun scripts/rarity-sim.ts --only=artwork-backed-96` menghitung ulang roster artwork aktif.

Jalankan dari root repository. PRNG Mulberry32 dengan stream terpisah interval/tier/item. Seed stream = seed XOR imul(player+1,0x9E3779B1) XOR imul(channel,0x85EBCA6B), channel 1/2/3. Pemain di setiap kandidat memakai seed yang sama. Perbandingan Legendary pertama memakai stream interval/tier sama dengan dan tanpa pity.

Seluruh bobot, parameter, hasil presisi penuh dan statistik disimpan di [results.json](results.json). [rarity-config.json](../../Qoma/Resources/rarity-config.json) menjadi sumber parameter untuk game, Help dan kandidat roster artwork aktif di simulator.
