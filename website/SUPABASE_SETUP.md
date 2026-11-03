# Setup Supabase + Drizzle untuk Qyube

Diperbarui 26 Oktober 2026. Website tetap dijalankan di Dokploy; database memakai Supabase managed PostgreSQL. Better Auth tetap mengurus Google/email OTP. Supabase Auth dan Supabase SDK tidak diperlukan untuk alur ini.

```text
Mac → HTTPS API website di Dokploy → Drizzle / pg → Supabase PostgreSQL
Browser → Better Auth pada website → database yang sama
Polar → webhook website → ledger billing → entitlements → signed API → Mac
```

## 1. Buat project

1. Buka [Supabase Dashboard](https://supabase.com/dashboard) dan buat project khusus Qyube, terpisah dari aplikasi lain.
2. Pilih region dekat VPS website. Simpan database password di password manager.
3. Gunakan project berbeda untuk pengujian dan production agar akun serta pembayaran sandbox terpisah.
4. Karena seluruh akses melewati backend, buka **Integrations → Data API** lalu matikan **Enable Data API**. Tidak ada browser atau app Mac yang perlu mengakses tabel melalui Supabase REST/GraphQL. Jangan menambahkan policy publik untuk tabel billing atau Better Auth. [Petunjuk resmi](https://supabase.com/docs/guides/api/securing-your-api).

## 2. Ambil connection string

Klik **Connect** di dashboard. Untuk container Dokploy yang berjalan terus dan menggunakan IPv4, pilih **Session pooler**, port **5432**. Salin URI dari dashboard, ganti placeholder password, dan URL-encode karakter khusus pada password. Gunakan TLS; URI dapat memakai `sslmode=require`. Untuk verifikasi sertifikat server penuh, ambil root certificate dari Database settings dan konfigurasi `sslmode=verify-full` beserta `sslrootcert` yang menunjuk file sertifikat pada container.

```dotenv
# Contoh struktur saja. Host dan username harus disalin dari dashboard.
DATABASE_URL=postgresql://postgres.PROJECT_REF:PASSWORD@POOLER_HOST:5432/postgres?sslmode=require
DATABASE_MIGRATION_URL=
```

`DATABASE_MIGRATION_URL` opsional; jika kosong, migrator memakai `DATABASE_URL`. Jika VPS mendukung IPv6, direct connection cocok untuk migrasi. Session pooler menjadi pilihan IPv4. Jangan memakai transaction pooler port 6543 untuk migrator ini karena ia memakai session advisory lock.

Pool runtime dibatasi lima koneksi per proses; beberapa replica mengalikan jumlah itu. Database password hanya berada di environment server. Qyube tidak memerlukan `SUPABASE_ANON_KEY` atau `SUPABASE_SERVICE_ROLE_KEY` karena memakai koneksi PostgreSQL langsung. [Referensi koneksi Supabase](https://supabase.com/docs/guides/database/connecting-to-postgres).

## 3. Isi environment dan migrasikan

Di mesin lokal, isi `website/.env` yang diabaikan Git. Di Dokploy, isi environment service website. Selain koneksi database, isi `BETTER_AUTH_URL` dan `BETTER_AUTH_SECRET` sebelum menjalankan CLI auth. Jangan menyalin atau menimpa `.env` yang sudah berisi konfigurasi.

Dari folder `website/`:

```sh
bun install --frozen-lockfile
bun run auth:migrate
bun run db:migrate
bun run db:check
```

`auth:migrate` membuat tabel versi Better Auth terpasang lalu mengaktifkan RLS pada tabel auth. `db:migrate` memakai migrator Drizzle dan mencatat riwayat di `drizzle.__drizzle_migrations`. Baseline domain mengaktifkan RLS pada 14 tabel, tanpa policy untuk anon/authenticated. Gunakan koneksi server sebagai pemilik tabel atau role yang memang memiliki BYPASSRLS; role browser Supabase tidak cocok untuk backend ini. Semua pembatasan akun tetap diperiksa API Qyube.

Urutan perintah di atas juga berlaku saat menyiapkan database baru. Setelahnya jalankan website dan uji login, trial, serta webhook sandbox. Migrasi tidak mengisi token Polar atau membuat produk.

## 4. Database lama dan perubahan schema berikutnya

Baseline Drizzle memuat DDL idempotent dari migrasi `001`–`006`. Jika diterapkan pada database lama yang sudah memakai schema tersebut, baris akun, trial, entitlement dan billing tetap disimpan. File SQL lama dipertahankan sebagai dokumentasi; runtime migrator sekarang membaca `db/drizzle/` saja.

Jika database VPS sudah berisi data nyata, mengganti URL saja tidak memindahkannya. Backup dan pindahkan tabel Qyube serta Better Auth ke project Supabase terlebih dahulu, termasuk sequence dan riwayat migrasinya, lalu jalankan migrator pada salinan itu. Hentikan write selama cutover agar pembayaran tidak masuk ke database lama. Database kosong yang terlanjur dipakai akan kehilangan kontinuitas akun/trial meskipun database lama masih utuh.

Untuk perubahan domain berikutnya:

1. Ubah `db/schema.ts`.
2. Jalankan `bun run db:generate --name=nama_perubahan`.
3. Review SQL di `db/drizzle/`, lalu uji pada database lokal dan salinan staging.
4. Jalankan `bun run db:migrate` saat deployment sebelum traffic memakai schema baru.

Jangan menjalankan `drizzle-kit push` untuk project ini: tabel Better Auth dikelola CLI auth dan tidak ada dalam schema domain Drizzle. Jangan mengubah migration baseline yang sudah diterapkan; buat migration baru. Query SQL yang memakai lock/transaksi tetap berbagi pool dengan Drizzle. [Referensi Drizzle](https://orm.drizzle.team/docs/connect-supabase).

## 5. Verifikasi sebelum mengalihkan traffic

- Tabel auth dan domain ada, RLS aktif, dan Data API project sudah dinonaktifkan.
- Login Google/OTP berhasil dari website; app Mac memperoleh grant dari API website.
- Trial lama tidak diulang, batas dua perangkat berlaku, webhook mengubah entitlement akun yang benar.
- Backup dan restore diuji sesuai fasilitas paket Supabase yang dipilih.
- Tidak ada database URL, password atau private key di Swift, bundle web publik, atau Git.

Kredensial Supabase belum diisi oleh perubahan kode ini; koneksi ke project Supabase nyata perlu diuji setelah Anda menyiapkannya.
