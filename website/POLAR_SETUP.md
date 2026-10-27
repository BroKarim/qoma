# Setup Polar dan secret entitlement Qyube

Diperiksa terhadap dokumentasi resmi Polar pada 26 Oktober 2026. Mulai dari sandbox. Semua nilai berikut diisi di `website/.env` untuk lokal atau environment service website pada Dokploy. Jangan memakai awalan `NEXT_PUBLIC_` untuk secret.

## 1. Buat organisasi sandbox

1. Buka [sandbox.polar.sh](https://sandbox.polar.sh), lalu buat akun dan organisasi sandbox Qyube. Bisa juga melalui **Go to sandbox** pada organization switcher.
2. Set currency utama organisasi ke USD.
3. Isi branding dan informasi produk Qyube. Untuk production nanti, selesaikan onboarding/review merchant serta payout yang diminta Polar.
4. Isi `POLAR_ENVIRONMENT=sandbox`.

Sandbox memiliki akun, token, produk dan webhook sendiri; nilai production tidak dapat dipakai di sana. Kode memakai SDK Polar versi API `2026-10` dengan pilihan environment tersebut. [Dokumentasi sandbox](https://polar.sh/docs/integrate/sandbox).

## 2. Buat tiga produk berbayar

Buka **Products**, buat produk satu per satu dengan fixed price dalam USD:

| Nama yang disarankan | Billing cycle | Harga | Environment variable | Plan internal |
|---|---|---|---|
| Qyube Monthly — macOS | Recurring, setiap 1 month | $3.99 | `POLAR_MONTHLY_PRODUCT_ID` | `monthly` |
| Qyube Annual — macOS | Recurring, setiap 1 year | $29.00 | `POLAR_ANNUAL_PRODUCT_ID` | `annual` |
| Qyube Lifetime — macOS only | One-time purchase | $49.00 | `POLAR_LIFETIME_PRODUCT_ID` | `lifetime` |

Nama produk boleh berorientasi pelanggan seperti tabel ini. Backend tidak membaca nama produk untuk menentukan akses: setiap **Product ID** harus dipasang ke env var yang sesuai, lalu dipetakan menjadi plan internal pada kolom terakhir. Jangan mengganti nilai plan internal dengan nama produk atau slug metadata.

1. Isi nama, checkout description, fixed price dan billing cycle. Jelaskan cakupan macOS pada ketiga paket; lifetime secara eksplisit tidak mencakup app iOS mendatang.
2. Matikan trial pada produk recurring. Trial tujuh hari Qyube sudah dihitung server setelah login native; tidak ada produk trial atau checkout trial.
3. Gunakan harga USD saja untuk MVP ini. Backend checkout saat ini mengirim `currency: "usd"`; ledger juga membatasi USD. Menambahkan currency di dashboard saja belum membuat kode mendukungnya.
4. Tambahkan metadata berikut pada **masing-masing produk**. Metadata membantu manusia dan tooling mengenali mapping, tetapi kode saat ini tetap menentukan plan dari env var Product ID; metadata tidak memberi akses.

   | Produk | Metadata |
   |---|---|
   | Monthly | `app: qyube`, `plan: monthly`, `entitlement: qyube_pro`, `scope: macos`, `billing_interval: month` |
   | Annual | `app: qyube`, `plan: annual`, `entitlement: qyube_pro`, `scope: macos`, `billing_interval: year` |
   | Lifetime | `app: qyube`, `plan: lifetime`, `entitlement: qyube_pro`, `scope: macos`, `billing_interval: once` |

   `qyube_pro` adalah label metadata produk, bukan entitlement key yang dicek oleh backend. Entitlement efektif Qyube dihitung di server sebagai plan `trial`, `monthly`, `annual`, atau `lifetime` dengan scope `macos`.

5. Buat **satu benefit bersama** dengan pengaturan berikut, lalu pasangkan ke ketiga produk berbayar:

   - Type: **Custom**
   - Description: `Qyube account access for macOS`
   - Visibility: **Visible**
   - Private note:

     > Sign in to Qyube on your Mac using the same email address you used at checkout. Your purchase is linked to your Qyube account—no license key is needed. Access activates after Polar confirms your payment.

   - Benefit metadata (opsional): `app: qyube`, `scope: macos`

   Custom benefit ini hanya menampilkan petunjuk aktivasi kepada pelanggan. **Jangan pilih License Keys**: Qyube tidak mengirim atau memvalidasi license key. Pembeli login dengan akun Qyube; backend memberikan akses setelah pembayaran dikonfirmasi lewat webhook Polar.

6. Simpan produk, buka detailnya, salin **Product ID** melalui aksi copy ID yang tersedia. Jika ID tidak terlihat, gunakan daftar/detail produk API Polar dari dashboard API tester. Ambil `id` produk, bukan ID harga atau URL checkout.
7. Tempel ketiga ID yang berbeda ke env yang sesuai. Pastikan tiap ID menunjuk ke paket, harga, dan billing cycle yang benar.

Polar mengunci billing cycle saat produk dibuat. Bila salah memilih monthly/yearly/one-time, buat produk pengganti. [Dokumentasi produk](https://polar.sh/docs/features/products).

## 3. Ambil `POLAR_ACCESS_TOKEN`

Buka **Organization Settings → Developers → New Token**. Beri nama `Qyube website sandbox`, tentukan masa berlaku, dan pilih scope yang dibutuhkan. Simpan token yang ditampilkan ke password manager dan `POLAR_ACCESS_TOKEN`; expiry token perlu dicatat untuk rotasi. [Petunjuk Organization Access Token](https://polar.sh/docs/integrate/oat).

Scope berikut sesuai pemanggilan SDK dalam kode Qyube:

| Scope | Pemakaian |
|---|---|
| `checkouts:write` | Membuat checkout |
| `checkouts:read` | Memeriksa checkout sebelumnya |
| `discounts:write` | Membuat kredit upgrade lifetime sekali pakai |
| `subscriptions:read` | Membaca periode subscription saat webhook perlu data tambahan |
| `subscriptions:write` | Membatalkan renewal subscription setelah lifetime terbayar |
| `customer_sessions:write` | Membuka portal invoice dan pengelolaan subscription |

Anda tidak perlu scope write produk atau webhook untuk token runtime jika keduanya dibuat lewat dashboard. Scope API dapat dicek pada dokumentasi [checkout](https://polar.sh/docs/api-reference/checkouts/create-session), [subscription](https://polar.sh/docs/api-reference/subscriptions/update), [discount](https://polar.sh/docs/api-reference/discounts/create), dan [customer session](https://polar.sh/docs/api-reference/customer-portal/sessions/create).

## 4. Ambil `POLAR_WEBHOOK_SECRET`

1. Siapkan website staging HTTPS yang dapat menerima request Polar. `localhost` tidak dapat dicapai langsung; gunakan staging URL atau forwarding melalui Polar CLI sesuai dokumentasinya.
2. Pada organisasi **sandbox**, buka settings webhook lalu **Add Endpoint**.
3. Masukkan `https://HOST_STAGING_ANDA/api/billing/webhook/polar`. Untuk production nanti gunakan `https://qyube.brokarim.com/api/billing/webhook/polar`.
4. Pilih format **Raw**, generate secret pada form, lalu salin nilainya utuh ke `POLAR_WEBHOOK_SECRET` pada server tujuan. Token API dan secret webhook adalah nilai berbeda.
5. Pilih `order.paid`, `order.refunded`, dan seluruh event `subscription.*` yang tersedia. Termasuk created, updated, active, canceled, uncanceled, past_due, revoked bila tersedia dalam daftar.
6. Simpan endpoint dan redeploy/restart website setelah env berubah. Cek delivery lewat transaksi sandbox yang benar; request buatan tanpa signature akan ditolak.

Qyube memverifikasi signature sebelum menyimpan event. Return URL checkout hanya mengarahkan pengguna kembali; akses diperbarui setelah event pembayaran diproses. [Setup webhook resmi](https://polar.sh/docs/integrate/webhooks/endpoints).

## 5. Buat `BILLING_JOB_TOKEN` sendiri

Nilai ini bukan dari Polar. Buat token acak dengan:

```sh
openssl rand -hex 32
```

Salin hasilnya ke `BILLING_JOB_TOKEN`. Konfigurasikan scheduled job Dokploy setiap sekitar lima menit untuk request:

```text
POST https://qyube.brokarim.com/api/internal/billing/retry
Authorization: Bearer <nilai BILLING_JOB_TOKEN>
```

Gunakan domain staging untuk sandbox. Simpan header token pada pengaturan secret job dan hindari mencetaknya ke log. Endpoint ini mencoba ulang pembatalan subscription lama setelah pembelian lifetime; webhook tetap harus aktif.

## 6. Buat kunci entitlement sendiri

Kedua nilai ini juga bukan dari Polar. Dari folder `website/`, jalankan satu kali untuk environment yang sedang disiapkan:

```sh
bun run entitlement:keys
```

Perintah menghasilkan pasangan Ed25519 dan menampilkan dua baris env. Salin ke tempat aman; output mencakup private key. Jangan menempelkan output tersebut ke issue, chat atau Git.

- `ENTITLEMENT_SIGNING_PRIVATE_KEY`: private PEM dengan newline sebagai `\n`, disimpan hanya pada server. Penandatangan sudah menangani format ini.
- `ENTITLEMENT_SIGNING_PUBLIC_KEY`: raw public key 32 byte dalam Base64. Boleh berada di app; nilai env ini dipakai sebagai referensi deployment, bukan dibaca otomatis oleh Mac.
- Salin nilai **public** yang sama ke `QyubeEntitlementPublicKey` pada `Qoma/Info.plist`, lalu rebuild app. Private key tidak masuk ke Xcode atau bundle app.

Simpan pasangan ini agar tidak berubah setiap deploy. Bila diganti, app lama perlu strategi rotasi kunci; jangan generate ulang untuk memperbaiki kesalahan env biasa. Untuk sandbox gunakan build Debug dengan public key sandbox dan API URL staging; app production harus memakai public key dan API production yang cocok.

## 7. Isi env dan uji alurnya

```dotenv
POLAR_ACCESS_TOKEN=<token organisasi sandbox>
POLAR_ENVIRONMENT=sandbox
POLAR_WEBHOOK_SECRET=<secret endpoint sandbox>
BILLING_JOB_TOKEN=<hasil token acak>
POLAR_MONTHLY_PRODUCT_ID=<id produk monthly sandbox>
POLAR_ANNUAL_PRODUCT_ID=<id produk annual sandbox>
POLAR_LIFETIME_PRODUCT_ID=<id produk lifetime sandbox>
ENTITLEMENT_SIGNING_PRIVATE_KEY=<private PEM satu baris dengan literal \n>
ENTITLEMENT_SIGNING_PUBLIC_KEY=<raw public key Base64>
```

1. Selesaikan [setup database](SUPABASE_SETUP.md), Google OAuth dan Resend, lalu deploy website dengan env tersebut.
2. Login dari app Mac: trial harus aktif tanpa kartu. Buka pricing dari akun untuk membeli selama trial atau setelah trial selesai.
3. Pada checkout **sandbox saja**, gunakan kartu uji `4242 4242 4242 4242`, expiry masa depan dan CVC uji. Periksa delivery webhook dan perubahan `entitlements` akun itu.
4. Uji monthly, annual, lifetime, cancel, refund, dan replay delivery. Setelah membeli lifetime dari subscription aktif, cek diskon upgrade dan subscription lama menjadi cancel-at-period-end.
5. Uji kegagalan pembatalan lalu jalankan billing job; akses lifetime tetap ada dan job dapat mencoba lagi.

Sandbox membatasi email customer Polar ke anggota organisasi, sehingga gunakan alamat anggota organisasi untuk menguji invoice. Invoice/struk berasal dari Polar; OTP aplikasi berasal dari Resend. [Batasan dan kartu sandbox](https://polar.sh/docs/integrate/sandbox).

## 8. Pindah ke production

Buat tiga produk, OAT dan endpoint webhook lagi pada organisasi production. Set `POLAR_ENVIRONMENT=production`, ganti ketiga product ID, token serta webhook secret secara bersama. Gunakan database production dan pasangan entitlement key production; pastikan public key sudah terpasang di build rilis. Billing job harus mengarah ke server production. Verifikasi nominal akhir/pajak pada checkout dan jangan menganggap hasil sandbox sebagai transaksi production.

Detail lain yang masih diperlukan sebelum flow penuh bekerja: `DATABASE_URL`, `BETTER_AUTH_SECRET`, Google OAuth, Resend domain/API key, website HTTPS, dan konfigurasi public key Mac. Nilai tersebut tidak dibuat oleh Polar. Panduan ini tidak membuat produk atau mengisi secret akun Anda secara otomatis.
