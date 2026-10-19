# Merchant Coverage Map V4: Panduan Lengkap

Aplikasi web untuk memetakan dan mencatat kunjungan merchant (Livin Merchant dan EDC). Berjalan di GitHub Pages dengan database Supabase. Semua gratis untuk pemakaian tim kecil.

## Isi paket
| File | Fungsi |
|---|---|
| `index.html` | Aplikasi (wajib) |
| `config.js` | Alamat dan kunci Supabase Anda (**wajib diisi**) |
| `login-bg.jpg`, `icon-192.png`, `icon-512.png`, `manifest.webmanifest`, `sw.js` | Foto login, ikon, dan pemasangan sebagai aplikasi HP (wajib) |
| `schema.sql` | Dijalankan sekali di Supabase (tabel dan keamanan) |
| `hapus-data-contoh.sql` | Opsional: membersihkan data contoh |
| `_headers` | Hanya dipakai Netlify/Cloudflare. GitHub Pages mengabaikannya, boleh dihapus |

---

## A. Pasang dari nol

### 1. Siapkan Supabase (sekali saja)
1. Buka supabase.com, masuk, lalu **New project**. Catat kata sandi database, lalu tunggu proyek selesai dibuat.
2. Buka **SQL Editor → New query**. Buka `schema.sql`, Ctrl+A, Ctrl+C, tempel, klik **Run**. Harus muncul **Success**. Aman dijalankan ulang.
3. Buat akun petugas: **Authentication → Users → Add user → Create new user**. Isi email dan kata sandi (minimal 8 karakter), centang konfirmasi otomatis bila ada. Ulangi untuk tiap petugas.
4. Ambil dua nilai dari **Project Settings → API** (nama menu bisa sedikit berbeda):
   - **Project URL**, bentuknya `https://xxxx.supabase.co`
   - **Publishable key** (atau **anon public**). Jangan pakai `service_role` atau `secret`.
5. Disarankan: matikan pendaftaran mandiri di **Authentication → Sign In / Providers** (nonaktifkan "Allow new users to sign up"), supaya hanya akun buatan Anda yang bisa masuk.
6. Opsional, menjadikan pimpinan sebagai admin: jalankan perintah di bagian 8 paling bawah `schema.sql` (ganti emailnya).

### 2. Isi `config.js`
Buka `config.js`, ganti dua nilainya:
```
window.APP_CONFIG={url:'https://xxxx.supabase.co',key:'KUNCI-PUBLISHABLE-ANDA'};
```
Aturan: `url` berhenti di `.supabase.co`, tanpa garis miring atau jalur tambahan. Kunci ditulis utuh di dalam tanda kutip.

### 3. Unggah ke GitHub
1. Buat repositori baru di github.com (Public).
2. **Add file → Upload files**, seret **semua file** dari folder ini (termasuk `config.js` yang sudah diisi), lalu **Commit changes**.
3. **Settings → Pages → Build and deployment**: Source = **Deploy from a branch**, Branch = **main**, folder **/(root)**, klik **Save**.
4. Tunggu 1-2 menit. Alamat aplikasi: `https://NAMA-GITHUB.github.io/NAMA-REPO/`.

### 4. Pertama kali dipakai
1. Buka alamat tadi, tekan **Ctrl+F5**, lalu masuk dengan email dan kata sandi dari langkah 1.3.
2. Tab **Data → Titik cabang → Pindahkan**, lalu ketuk lokasi branch sebenarnya di peta. Titik bawaan hanya contoh.
3. Di HP: buka lewat Chrome/Safari, pilih **Tambahkan ke layar utama** supaya terpasang seperti aplikasi.

---

## B. Jika repo Anda sudah berisi versi lama
1. Ganti `index.html`, `sw.js`, dan `login-bg.jpg` dengan yang baru.
2. Pastikan `config.js` **ada** di repo. Kalau belum, buat dari template di paket ini dan isi.
3. Jalankan `schema.sql` terbaru di Supabase (wajib agar target EDC bisa disimpan).
4. Hapus file yang tidak dipakai: `UPDATE-V4.md`, `_headers`, `login-tower.jpg` (bila ada). Cara cepat menghapus banyak file: buka repo, tekan tombol `.` (titik), pilih file dengan Ctrl+klik, Delete, lalu Commit di panel Source Control.
5. Tunggu 1-2 menit, lalu Ctrl+F5. Jangan pernah menimpa `config.js` Anda dengan template kosong.

---

## C. Cara pakai singkat
- **Merchant**: daftar dan peta. Filter: Status LVM, Status EDC, Hasil EDC, jenis usaha, jarak dari branch. Centang merchant untuk menyusun rute (Google Maps).
- **Tambah**: catat merchant baru (nama, jenis, lokasi via GPS atau ketuk peta). **Tarik usaha sekitar branch** mengambil usaha dari OpenStreetMap dalam radius 1-5 km; centang yang mau disimpan. Data OpenStreetMap belum lengkap, terutama warung kecil.
- **Detail → Update Hasil Kunjungan**: isi hasil **Livin Merchant** dan/atau **EDC** (Follow up, Akuisisi, Reject, Existing; Existing wajib pilih UREG atau USAC). Di sinilah satu-satunya tempat mengisi status EDC.
- **Aturan status** (sama untuk LVM dan EDC): Akuisisi + Existing = **Sudah**; Follow up + Reject = **Belum**. Dihitung dari hasil kunjungan terakhir.
- **Riwayat**: filter tanggal dan hasil, ekspor CSV.
- **Dashboard**: target Livin Merchant (akuisisi) dan target EDC (hanya new merchant EDC = hasil EDC Akuisisi), harian dan bulanan. Target diatur di bagian bawah dashboard, terpisah untuk LVM dan EDC.
- **Data**: titik cabang, ekspor CSV dan cadangan JSON, impor, sinkronisasi.
- **Akun**: hanya lewat ikon profil (kanan atas) → **Akun saya**: ubah nama, ganti kata sandi, keluar.
- Tanpa sinyal, data disimpan di perangkat dan terkirim otomatis saat online. Ekspor cadangan secara berkala.

## D. Membersihkan data contoh
Paket tidak berisi data contoh. Bila database Anda berisi data uji, jalankan `hapus-data-contoh.sql` di SQL Editor: bagian A hanya melihat, bagian B menghapus dan berakhir dengan `rollback` (aman) sampai Anda menggantinya menjadi `commit`. Ekspor cadangan dulu. Setelah itu tekan **Sinkronkan sekarang** di tab Data.

---

## E. Masalah umum
| Gejala | Penyebab dan solusi |
|---|---|
| Konsol: `config.js 404`, atau pesan "Konfigurasi belum diisi" | `config.js` tidak ada di repo atau masih berisi `GANTI-...`. Buat/isi lalu commit |
| "Tidak bisa terhubung ke Supabase" atau "Invalid path specified" | `url` di `config.js` salah. Aplikasi V4 otomatis memotong jalur tambahan; bila masih gagal, periksa ejaan alamat proyek |
| "Email atau kata sandi salah" | Akun belum dibuat di Authentication → Users, atau kata sandi salah. Reset dari halaman Users |
| "Database belum siap atau belum diperbarui" | `schema.sql` belum dijalankan atau versi lama. Jalankan versi terbaru |
| Target EDC tidak tersimpan, "perubahan ditolak server" | `schema.sql` V4 belum dijalankan |
| Peta kosong | Butuh internet saat pertama dibuka (peta dan font dimuat dari internet) |
| Tarik usaha gagal | Server OpenStreetMap gratis kadang sibuk. Coba lagi beberapa menit, atau kecilkan radius |
| Tampilan lama masih muncul | Ctrl+F5; di HP tutup tab lalu buka lagi; atau buka lewat tab penyamaran |

## F. Keamanan
- Kunci **publishable** boleh terlihat publik; data dilindungi aturan keamanan (RLS) di `schema.sql`. **Jangan** pernah menaruh kunci `service_role` atau `secret` di `config.js`.
- Jangan mencatat data pribadi nasabah atau nomor kontak. Catat hanya data usaha.
- Hapus data hanya bisa dilakukan oleh pembuatnya atau admin.
