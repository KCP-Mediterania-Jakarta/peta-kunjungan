-- =====================================================================
-- Merchant Coverage Map - skema database v3 (Supabase / PostgreSQL)
-- v3: hasil kunjungan 4 pilihan (Follow up, Akuisisi, Reject, Existing) untuk Livin Merchant dan EDC secara terpisah,
--     kategori UREG/USAC bila Existing, data lama dimigrasi otomatis, view rekap diperbarui.
-- Cara pakai: Supabase > SQL Editor > New query > tempel SEMUA isi file ini > Run.
-- Aman dijalankan ulang (idempotent) dan aman ditimpa di atas skema lama.
-- =====================================================================

-- ---------- 1. Profil petugas (nama + peran) ----------
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  nama       text not null default '',
  role       text not null default 'petugas' check (role in ('petugas','admin')),
  created_at timestamptz not null default now()
);

-- Profil dibuat otomatis saat akun baru dibuat di Authentication > Users
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nama)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'nama',''), split_part(new.email,'@',1)))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Isi profil untuk akun yang sudah ada sebelum skema ini dijalankan
insert into public.profiles (id, nama)
select id, split_part(email,'@',1) from auth.users
on conflict (id) do nothing;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- Fungsi internal tidak boleh dipanggil lewat API publik
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.is_admin()        from public, anon;
grant  execute on function public.is_admin()        to authenticated;

-- ---------- 2. Usaha ----------
create table if not exists public.businesses (
  id              text primary key,                -- dibuat di aplikasi (bisa offline)
  nama            text not null,
  jenis           text not null default '',        -- teks bebas
  status_merchant text not null default '' check (status_merchant in ('','New CIF','Existing')),
  lat             double precision not null check (lat between -90 and 90),
  lng             double precision not null check (lng between -180 and 180),
  catatan         text not null default '',
  dibuat          date,
  diverifikasi    date,
  s0              text not null default 'belum' check (s0 in ('belum','sudah')), -- status dasar bila belum ada kunjungan
  created_by      uuid default auth.uid() references auth.users(id) on delete set null,
  updated_by      uuid,
  updated_at      timestamptz not null default now()
);

alter table public.businesses drop constraint if exists businesses_len_chk;
alter table public.businesses add  constraint businesses_len_chk
  check (char_length(nama) between 1 and 200 and char_length(jenis) <= 100 and char_length(catatan) <= 2000) not valid;

create index if not exists businesses_created_by_idx on public.businesses (created_by);

-- Saat diubah: catat waktu/pengubah, dan cegah pergantian pembuat/id
create or replace function public.touch_businesses()
returns trigger language plpgsql as $$
begin
  new.id         := old.id;
  new.created_by := old.created_by;
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;

drop trigger if exists trg_touch_businesses on public.businesses;
create trigger trg_touch_businesses
  before update on public.businesses
  for each row execute function public.touch_businesses();

-- ---------- 3. Riwayat kunjungan ----------
-- business_id sengaja TANPA foreign key: riwayat tetap ada walau usaha dihapus.
create table if not exists public.visits (
  id              text primary key,
  business_id     text not null,
  nama_usaha      text not null default '',        -- salinan saat kunjungan
  jenis           text not null default '',
  status_merchant text not null default '' check (status_merchant in ('','New CIF','Existing')),
  tanggal         date not null,
  ts              timestamptz,
  hasil           text not null default '',        -- hasil Livin Merchant: '', Follow up, Akuisisi, Reject, Existing
  catatan         text not null default '',
  petugas         text not null default '',
  user_id         uuid default auth.uid() references auth.users(id) on delete set null,
  created_at      timestamptz not null default now()
);
alter table public.visits drop constraint if exists visits_len_chk;
alter table public.visits add  constraint visits_len_chk
  check (char_length(catatan) <= 2000 and char_length(nama_usaha) <= 200) not valid;

create index if not exists visits_tanggal_idx  on public.visits (tanggal);
create index if not exists visits_business_idx on public.visits (business_id);
create index if not exists visits_petugas_idx  on public.visits (petugas);
create index if not exists visits_user_idx     on public.visits (user_id);

-- ---------- 3b. Tracking EDC ----------
-- Status EDC per usaha: '' (belum didata), belum, bank_lain, prospek, proses, terpasang, menolak
alter table public.businesses add column if not exists edc_status text not null default '';
alter table public.businesses add column if not exists edc_tid    text not null default '';   -- Terminal ID (opsional)
alter table public.businesses add column if not exists edc_tgl    date;                        -- tanggal status terakhir diubah
alter table public.visits     add column if not exists edc        text not null default '';    -- status EDC saat kunjungan

-- v3: pilihan hasil diseragamkan: '', 'Follow up', 'Akuisisi', 'Reject', 'Existing' (+ kategori UREG/USAC untuk Existing)
alter table public.businesses add column if not exists edc_sub text not null default '';   -- UREG / USAC bila edc_status = Existing
alter table public.visits     add column if not exists hasil_sub text not null default ''; -- UREG / USAC bila hasil = Existing
alter table public.visits     add column if not exists edc_sub    text not null default ''; -- UREG / USAC bila edc = Existing

-- lepas aturan lama sebelum data dimigrasi
alter table public.businesses drop constraint if exists businesses_edc_chk;
alter table public.visits drop constraint if exists visits_edc_chk;
alter table public.visits drop constraint if exists visits_hasil_check;
alter table public.visits drop constraint if exists visits_hasil_chk;
alter table public.visits alter column hasil set default '';

-- migrasi data lama (aman dijalankan ulang)
update public.visits set hasil = case hasil when 'Sudah' then 'Existing' when 'Berhasil' then 'Akuisisi' when 'Menolak' then 'Reject' else hasil end
 where hasil in ('Sudah','Berhasil','Menolak');
update public.visits set edc = case edc when 'prospek' then 'Follow up' when 'proses' then 'Follow up' when 'terpasang' then 'Akuisisi'
 when 'menolak' then 'Reject' when 'bank_lain' then 'Reject' when 'belum' then '' else edc end
 where edc in ('belum','bank_lain','prospek','proses','terpasang','menolak');
update public.businesses set edc_status = case edc_status when 'prospek' then 'Follow up' when 'proses' then 'Follow up' when 'terpasang' then 'Akuisisi'
 when 'menolak' then 'Reject' when 'bank_lain' then 'Reject' when 'belum' then '' else edc_status end
 where edc_status in ('belum','bank_lain','prospek','proses','terpasang','menolak');

-- aturan baru
alter table public.visits add constraint visits_hasil_chk
  check (hasil in ('','Follow up','Akuisisi','Reject','Existing') and hasil_sub in ('','UREG','USAC'));
alter table public.visits add constraint visits_edc_chk
  check (edc in ('','Follow up','Akuisisi','Reject','Existing') and edc_sub in ('','UREG','USAC'));
alter table public.businesses add constraint businesses_edc_chk
  check (edc_status in ('','Follow up','Akuisisi','Reject','Existing') and edc_sub in ('','UREG','USAC') and char_length(edc_tid) <= 30);

create index if not exists businesses_edc_idx on public.businesses (edc_status);

-- ---------- 4. Pengaturan bersama (titik cabang, target harian, libur bulanan, buffer menit per merchant) ----------
create table if not exists public.app_settings (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);

create or replace function public.touch_settings()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_touch_settings on public.app_settings;
create trigger trg_touch_settings
  before update on public.app_settings
  for each row execute function public.touch_settings();

insert into public.app_settings (key, value)
values ('branch', jsonb_build_object('lat', -6.1760, 'lng', 106.7890, 'name', 'Branch Mediterania'))
on conflict (key) do nothing;

-- v3: nama penanda cabang di peta
update public.app_settings set value = value || jsonb_build_object('name','Branch Mediterania') where key = 'branch';

insert into public.app_settings (key, value)
values ('target', to_jsonb(5))
on conflict (key) do nothing;

-- ---------- 5. Keamanan: Row Level Security ----------
alter table public.profiles     enable row level security;
alter table public.businesses   enable row level security;
alter table public.visits       enable row level security;
alter table public.app_settings enable row level security;

-- Pengunjung tanpa login (anon) tidak boleh mengakses apa pun
revoke all on public.profiles, public.businesses, public.visits, public.app_settings from anon;
grant usage on schema public to authenticated;

-- profiles: petugas hanya boleh mengubah kolom NAMA. Peran (role) hanya bisa diubah
-- lewat SQL Editor oleh pemilik proyek (lihat bagian 8) sehingga tidak bisa dinaikkan sendiri.
revoke all on public.profiles from authenticated;
grant select         on public.profiles to authenticated;
grant update (nama)  on public.profiles to authenticated;

grant select, insert, update, delete on public.businesses   to authenticated;
grant select, insert, update, delete on public.visits       to authenticated;
grant select, insert, update         on public.app_settings to authenticated;

-- profiles: semua petugas boleh melihat; ubah nama sendiri (admin boleh semua)
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated using (true);
drop policy if exists profiles_update_admin on public.profiles;
drop policy if exists profiles_update_self  on public.profiles;
create policy profiles_update_self on public.profiles for update to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

-- businesses: data bersama tim. Semua petugas boleh lihat, tambah, dan ubah
-- (supaya kunjungan petugas lain bisa memperbarui jenis/verifikasi).
-- Hapus hanya oleh pembuat usaha atau admin.
drop policy if exists biz_select on public.businesses;
create policy biz_select on public.businesses for select to authenticated using (true);
drop policy if exists biz_insert on public.businesses;
create policy biz_insert on public.businesses for insert to authenticated with check (created_by = auth.uid());
drop policy if exists biz_update on public.businesses;
create policy biz_update on public.businesses for update to authenticated using (true) with check (true);
drop policy if exists biz_delete on public.businesses;
create policy biz_delete on public.businesses for delete to authenticated
  using (created_by = auth.uid() or public.is_admin());

-- visits: semua petugas boleh melihat; hanya pemilik catatan (atau admin) boleh mengubah/menghapus
drop policy if exists visits_select on public.visits;
create policy visits_select on public.visits for select to authenticated using (true);
drop policy if exists visits_insert on public.visits;
create policy visits_insert on public.visits for insert to authenticated with check (user_id = auth.uid());
drop policy if exists visits_update on public.visits;
create policy visits_update on public.visits for update to authenticated
  using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());
drop policy if exists visits_delete on public.visits;
create policy visits_delete on public.visits for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- app_settings: semua petugas boleh baca; tulis hanya untuk kunci yang dikenal aplikasi
-- (branch, target, buffer, hol2026-10 dst) agar tidak bisa diisi sampah.
drop policy if exists settings_select on public.app_settings;
create policy settings_select on public.app_settings for select to authenticated using (true);
drop policy if exists settings_insert on public.app_settings;
create policy settings_insert on public.app_settings for insert to authenticated
  with check (key in ('branch','target','buffer') or key ~ '^hol[0-9]{4}-[0-9]{2}$');
drop policy if exists settings_update on public.app_settings;
create policy settings_update on public.app_settings for update to authenticated
  using (key in ('branch','target','buffer') or key ~ '^hol[0-9]{4}-[0-9]{2}$')
  with check (key in ('branch','target','buffer') or key ~ '^hol[0-9]{4}-[0-9]{2}$');

-- ---------- 6. Realtime: perubahan petugas lain muncul otomatis di peta ----------
do $$
declare t text;
begin
  foreach t in array array['businesses','visits','app_settings'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ---------- 7. Rekap untuk pimpinan (buka di Table Editor / SQL Editor) ----------
drop view if exists public.rekap_harian;
drop view if exists public.rekap_bulanan;
drop view if exists public.rekap_edc;

create view public.rekap_harian with (security_invoker = true) as
select
  tanggal,
  petugas,
  count(*) filter (where hasil = 'Akuisisi')  as livin_akuisisi,
  count(*) filter (where hasil = 'Follow up') as livin_follow_up,
  count(*) filter (where hasil = 'Reject')    as livin_reject,
  count(*) filter (where hasil = 'Existing' and hasil_sub = 'UREG') as livin_existing_ureg,
  count(*) filter (where hasil = 'Existing' and hasil_sub = 'USAC') as livin_existing_usac,
  count(*) filter (where edc = 'Akuisisi')    as edc_akuisisi,
  count(*) filter (where edc = 'Follow up')   as edc_follow_up,
  count(*) filter (where edc = 'Reject')      as edc_reject,
  count(*) filter (where edc = 'Existing' and edc_sub = 'UREG') as edc_existing_ureg,
  count(*) filter (where edc = 'Existing' and edc_sub = 'USAC') as edc_existing_usac,
  count(*) filter (where hasil = 'Akuisisi' and status_merchant = 'New CIF')  as akuisisi_new_cif,
  count(*) filter (where hasil = 'Akuisisi' and status_merchant = 'Existing') as akuisisi_existing
from public.visits
group by tanggal, petugas;

create view public.rekap_bulanan with (security_invoker = true) as
select
  to_char(tanggal, 'YYYY-MM') as bulan,
  petugas,
  count(*) filter (where hasil = 'Akuisisi')  as livin_akuisisi,
  count(*) filter (where hasil = 'Follow up') as livin_follow_up,
  count(*) filter (where hasil = 'Reject')    as livin_reject,
  count(*) filter (where hasil = 'Existing' and hasil_sub = 'UREG') as livin_existing_ureg,
  count(*) filter (where hasil = 'Existing' and hasil_sub = 'USAC') as livin_existing_usac,
  count(*) filter (where edc = 'Akuisisi')    as edc_akuisisi,
  count(*) filter (where edc = 'Follow up')   as edc_follow_up,
  count(*) filter (where edc = 'Reject')      as edc_reject,
  count(*) filter (where edc = 'Existing' and edc_sub = 'UREG') as edc_existing_ureg,
  count(*) filter (where edc = 'Existing' and edc_sub = 'USAC') as edc_existing_usac,
  count(*) filter (where hasil = 'Akuisisi' and status_merchant = 'New CIF')  as akuisisi_new_cif,
  count(*) filter (where hasil = 'Akuisisi' and status_merchant = 'Existing') as akuisisi_existing,
  count(distinct business_id) as merchant_dikunjungi
from public.visits
group by to_char(tanggal, 'YYYY-MM'), petugas;

create view public.rekap_edc with (security_invoker = true) as
select coalesce(nullif(edc_status,''),'belum_didata') as status_edc,
       coalesce(nullif(edc_sub,''),'-') as kategori,
       count(*) as jumlah
from public.businesses
group by 1, 2
order by 3 desc;

revoke all on public.rekap_harian, public.rekap_bulanan, public.rekap_edc from anon;
grant select on public.rekap_harian, public.rekap_bulanan, public.rekap_edc to authenticated;

-- ---------- 8. Menjadikan seseorang admin/pimpinan (jalankan manual, ganti emailnya) ----------
-- update public.profiles set role = 'admin', nama = 'Nama Pimpinan'
-- where id = (select id from auth.users where email = 'pimpinan@contoh.com');
