# Update ke Versi 3: Merchant Coverage Map

Kerjakan berurutan.

## 1. Perbarui database DULU
1. Supabase → proyek Anda → **SQL Editor → New query**.
2. Buka `schema.sql` (versi baru), Ctrl+A, Ctrl+C, tempel, klik **Run**. Harus muncul **Success**.
   Aman dijalankan ulang. Data lama tidak hilang dan otomatis dikonversi:
   - Hasil Livin Merchant: Sudah → **Existing**, Berhasil → **Akuisisi**, Menolak → **Reject**
   - Status EDC: prospek/proses → **Follow up**, terpasang → **Akuisisi**, menolak/bank lain → **Reject**, belum → kosong
   - Data lama yang berstatus Existing belum punya kategori UREG/USAC (kosong sampai diisi pada kunjungan berikutnya)

## 2. Unggah ke GitHub
1. Repo → **Add file → Upload files**. Seret semua isi folder ini: `index.html`, `login-tower.jpg`, `icon-192.png`, `icon-512.png`, `manifest.webmanifest`, `sw.js`, `_headers`.
2. **JANGAN timpa `config.js`.** File itu tidak ikut di paket ini supaya URL dan key Supabase Anda tidak hilang.
3. **Commit changes**, tunggu 1-2 menit, lalu tekan **Ctrl+F5** (di HP: tutup tab, buka lagi).

## 3. Yang berubah
- Hasil kunjungan kini dua dropdown terpisah: **Livin Merchant** dan **EDC**, masing-masing berisi Follow up, Akuisisi, Reject, Existing.
- Pilih **Existing** lalu muncul dropdown **UREG / USAC** (terpisah untuk Livin Merchant dan EDC).
- Status Livin: Akuisisi dan Existing = Sudah LVM; Follow up dan Reject = Belum LVM. Target harian menghitung **Akuisisi** Livin Merchant.
- Status EDC kini diubah lewat dropdown EDC di form kunjungan (tombol 7 status lama dihapus).
- "Riwayat Usaha" menjadi **Riwayat Merchant**; filter riwayat ada untuk hasil Livin dan hasil EDC.
- Pin KCP menjadi penanda **Branch Mediterania**.
- Ikon profil di kanan atas: Akun & Data, Ganti kata sandi (jendela tersendiri), Keluar. Pengaturan akun tetap ada di menu Data.
- Layar login memakai foto tower yang di-zoom dari bawah, nama aplikasi **Merchant Coverage Map**, dan kalimat sambutan baru.
- Tampilan baru: font Sora dan Plus Jakarta Sans, navigasi bawah di HP, pencarian merchant, filter yang bisa dilipat, kartu ringkasan hasil di Dashboard.

## Kalau macet
- Muncul "Database belum siap atau belum diperbarui": langkah 1 belum dijalankan. Data di perangkat tetap aman dan terkirim setelah skema diperbarui.
- Font tampak biasa: font diambil dari Google Fonts, butuh internet saat pertama kali dibuka.
- Tampilan lama masih muncul: Ctrl+F5 atau buka lewat tab penyamaran.
