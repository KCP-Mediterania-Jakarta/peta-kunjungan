# Panduan Peluncuran: Peta Potensi Cabang

Isi paket: `index.html` (aplikasi), `schema.sql` (database), `sw.js` + `manifest.webmanifest` + `icon-*.png` (bisa dipasang di layar HP dan tetap terbuka saat sinyal buruk), `_headers` (pengaman tambahan untuk Cloudflare/Netlify).

Alur: **(A) buat database → (B) hubungkan aplikasi → (C) hosting → (D) buat akun petugas**. Total sekitar 20 menit.

---

## A. Buat database di Supabase (gratis)

1. Buka https://supabase.com → **Start your project** → daftar → **New project**.
   - Name: `peta-potensi`, isi Database Password (simpan), Region: **Southeast Asia (Singapore)**.
2. Tunggu proyek siap (1–2 menit).
3. Menu kiri **SQL Editor → New query** → tempel **seluruh isi `schema.sql`** → **Run**. Harus muncul "Success".
4. **Tutup pendaftaran bebas** (WAJIB, supaya orang asing tidak bisa membuat akun dan melihat data):
   **Authentication → Sign In / Providers → Email** → matikan **Allow new users to sign up** → Save.
5. Ambil dua nilai untuk aplikasi di **Project Settings → API Keys** (atau **Data API**):
   - **Project URL** (contoh `https://abcdxyz.supabase.co`)
   - **Publishable key** / `anon` key (BUKAN `service_role` / secret key; key itu jangan pernah ditaruh di aplikasi)

## B. Hubungkan aplikasi

Buka `index.html` dengan Notepad/VS Code, cari dua baris di bagian atas skrip:

```js
var SB_URL='GANTI-DENGAN-PROJECT-URL';
var SB_KEY='GANTI-DENGAN-PUBLISHABLE-KEY';
```

Ganti dengan nilai dari langkah A5, simpan. Publishable/anon key memang boleh terlihat publik; data dilindungi aturan keamanan (RLS) di `schema.sql` sehingga hanya akun yang sudah login yang bisa membaca/menulis.

## C. Hosting (pilih salah satu)

**Opsi 1: Cloudflare Pages (disarankan: gratis, cepat, tanpa batas trafik)**
1. https://dash.cloudflare.com → **Workers & Pages → Create → Pages → Upload assets**.
2. Beri nama proyek (mis. `peta-potensi`), lalu seret **isi folder** (index.html, sw.js, manifest, icon, _headers) → **Deploy**.
3. Alamat jadi: `https://peta-potensi.pages.dev`.

**Opsi 2: Netlify (paling mudah)**: https://app.netlify.com/drop → seret folder → selesai. Alamat bisa diganti di Site settings.

**Opsi 3: GitHub Pages**: buat repo → unggah semua file → Settings → Pages → Deploy from branch `main` (folder `/root`). Catatan: file `_headers` tidak berlaku di GitHub Pages (aplikasi tetap jalan).

Wajib HTTPS (ketiganya otomatis). GPS dan "pasang ke layar utama" hanya bekerja di HTTPS.

Untuk update aplikasi nanti: ganti `index.html`, unggah ulang.

## D. Buat akun petugas dan pimpinan

Supabase **Authentication → Users → Add user → Create new user**:
- Email + password awal, centang **Auto Confirm User**.
- (Opsional) buka *User Metadata* dan isi `{"nama":"Nama Petugas"}`. Kalau kosong, nama diambil dari bagian depan email; petugas bisa menggantinya di tab **Data**.

Jadikan pimpinan admin (SQL Editor, ganti emailnya):

```sql
update public.profiles set role = 'admin', nama = 'Nama Pimpinan'
where id = (select id from auth.users where email = 'pimpinan@contoh.com');
```

Admin boleh menghapus usaha/kunjungan milik siapa pun. Petugas biasa hanya bisa menghapus miliknya sendiri; semua petugas bisa melihat dan memperbarui data tim.

Bagikan alamat hosting + email/password ke petugas. Di HP: buka alamat → menu browser → **Tambahkan ke layar utama**.

---

## Cara kerja setelah online

- Semua petugas melihat data yang sama; perubahan petugas lain muncul otomatis (realtime).
- Tanpa sinyal: tetap bisa mencatat; data masuk antrean di perangkat dan terkirim otomatis saat online (indikator di kanan atas header: *Tersinkron / n belum terkirim / Offline*). Login pertama butuh internet.
- Memindahkan data lama: di versi lama buka tab **Data → Cadangan JSON**, lalu di versi baru (sudah login) **Impor cadangan JSON**. Data lama otomatis terkirim ke server dan tercatat atas nama akun yang mengimpor, jadi cukup satu orang yang mengimpor tiap berkas.
- Rekap untuk pimpinan: Supabase **Table Editor → rekap_harian / rekap_bulanan**, atau tab Riwayat + Dashboard di aplikasi (ekspor CSV).
- Tombol "Muat data contoh" dan "Hapus semua data" sengaja dihapus karena sekarang data dipakai bersama.

## Catatan penting

- **Paket gratis Supabase menjeda proyek yang tidak dipakai 7 hari.** Untuk pemakaian rutin tim ini aman; kalau libur panjang, buka dashboard lalu klik Restore. Untuk produksi serius pertimbangkan paket Pro (ada backup harian otomatis).
- Cadangan: ekspor CSV/JSON berkala dari tab Data.
- Data usaha disimpan di layanan cloud pihak ketiga. Pastikan sesuai kebijakan keamanan data bank Anda sebelum dipakai resmi, dan jangan mengisi data pribadi nasabah (sesuai catatan di aplikasi).
- Lupa password petugas: Authentication → Users → klik user → Send password recovery, atau hapus lalu buat ulang.
- Kalau layar login muncul tulisan "Konfigurasi belum diisi", langkah B belum dilakukan atau file lama yang diunggah.
