-- =====================================================================
-- Hapus data contoh / dummy dari database Merchant Coverage Map
-- Jalankan di Supabase > SQL Editor. Kerjakan BAGIAN A dulu (hanya melihat),
-- lalu pilih SATU opsi di bagian B. Skrip B berakhir dengan ROLLBACK
-- (tidak ada yang terhapus) sampai Anda mengganti ROLLBACK menjadi COMMIT.
-- Penghapusan tidak bisa dibatalkan setelah COMMIT. Ekspor cadangan JSON dulu
-- dari tab Data di aplikasi.
-- =====================================================================

-- ---------- A. LIHAT DULU (aman, tidak mengubah apa pun) ----------
-- A1. Siapa yang membuat usaha, berapa banyak, kapan
select u.email, count(*) as jumlah_usaha, min(b.dibuat) as pertama, max(b.dibuat) as terakhir
from public.businesses b left join auth.users u on u.id = b.created_by
group by u.email order by jumlah_usaha desc;

-- A2. Daftar usaha (cek mana yang dummy)
select id, nama, jenis, dibuat, created_by from public.businesses order by dibuat, nama;

-- A3. Kunjungan per petugas
select petugas, count(*) as jumlah_kunjungan, min(tanggal) as pertama, max(tanggal) as terakhir
from public.visits group by petugas order by jumlah_kunjungan desc;

-- ---------- B. HAPUS (pilih SATU opsi, hapus tanda -- pada barisnya) ----------
begin;

-- OPSI 1: hapus berdasarkan akun pembuat (ganti emailnya, mis. akun uji coba)
-- delete from public.visits     where business_id in (select id from public.businesses where created_by = (select id from auth.users where email = 'akun-uji@contoh.com'));
-- delete from public.businesses where created_by = (select id from auth.users where email = 'akun-uji@contoh.com');

-- OPSI 2: hapus berdasarkan id usaha (salin id dari hasil A2)
-- delete from public.visits     where business_id in ('b1abc','b2def');
-- delete from public.businesses where id in ('b1abc','b2def');

-- OPSI 3: hapus SEMUA usaha dan kunjungan (mulai dari nol; pengaturan target/branch tetap)
-- delete from public.visits;
-- delete from public.businesses;

-- Periksa hasilnya sebelum memutuskan
select (select count(*) from public.businesses) as sisa_usaha, (select count(*) from public.visits) as sisa_kunjungan;

rollback;   -- ganti menjadi: commit;   kalau hasilnya sudah benar
