# Update ke Versi 4: Merchant Coverage Map

Kerjakan berurutan.

## 1. Perbarui database DULU
1. Supabase → proyek Anda → **SQL Editor → New query**.
2. Buka `schema.sql` (versi baru), Ctrl+A, Ctrl+C, tempel, klik **Run**. Harus muncul **Success**.
   Aman dijalankan ulang. Data lama tidak hilang. Yang berubah:
   - Pengaturan baru `target_edc` (target harian EDC, bawaan 5) diizinkan. **Tanpa langkah ini, target EDC tidak bisa disimpan.**
   - View rekap: kolom `akuisisi_new_cif` dan `akuisisi_existing` dihapus karena status merchant tidak dipakai lagi.

## 2. Unggah ke GitHub
1. Repo → **Add file → Upload files**. Seret semua isi folder ini: `index.html`, `login-bg.jpg`, `icon-192.png`, `icon-512.png`, `manifest.webmanifest`, `sw.js`, `_headers`.
2. **JANGAN timpa `config.js`.** File itu tidak ikut di paket ini.
3. Hapus `login-tower.jpg` dari repo (sudah diganti `login-bg.jpg`).
4. **Commit changes**, tunggu 1-2 menit, lalu **Ctrl+F5** (di HP: tutup tab, buka lagi).

## 3. Yang berubah
- **Status merchant (New CIF / Existing) dihapus** dari form Tambah, edit merchant, filter, daftar, riwayat, dan ekspor CSV. Data lama di database tetap tersimpan, hanya tidak ditampilkan.
- **Status EDC hanya diisi saat Update Hasil Kunjungan.** Form Tambah merchant tidak lagi memuat EDC.
- **Status Sudah EDC / Belum EDC** (baru), aturan sama dengan LVM:
  Akuisisi dan Existing = **Sudah**; Follow up dan Reject = **Belum**. Dihitung dari hasil kunjungan terakhir masing-masing (LVM dari hasil Livin Merchant, EDC dari hasil EDC). Merchant tanpa hasil EDC = Belum EDC.
  Muncul di filter, daftar, detail, warna pin peta (pilihan "Status LVM / Status EDC / Hasil EDC"), dan ekspor CSV.
- **Akun hanya lewat Profil.** Ikon profil → **Akun saya** (ubah nama, ganti kata sandi, keluar). Tab **Data** kini hanya berisi titik cabang, ekspor/cadangan/impor, dan sinkronisasi.
- **Target dipisah.** Dashboard → Pengaturan target: kartu **Livin Merchant** dan kartu **EDC (new merchant)**, masing-masing target harian sendiri. Libur/cuti bulan ini berlaku untuk keduanya.
- **Dashboard EDC hanya menghitung new merchant EDC** (hasil EDC = Akuisisi), dibandingkan dengan target EDC (harian, bulanan, dan grafik 14 hari). Header atas menampilkan "LVM hari ini" dan "EDC baru hari ini".
- **Halaman login**: kotak dibuat transparan, foto diganti foto tower Kopra by Mandiri x Livin.

## Kalau macet
- Target EDC tidak tersimpan / muncul "perubahan ditolak server": langkah 1 belum dijalankan.
- Foto login lama masih muncul: Ctrl+F5 atau buka lewat tab penyamaran.
- Foto login terlihat agak lembut di layar besar: sumbernya hanya 1024 px. Ganti file `login-bg.jpg` dengan foto asli lebih besar (lebar 2000 px ke atas, nama file tetap sama).
