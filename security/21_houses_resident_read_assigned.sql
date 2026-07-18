-- BUG (ditemukan 17/07, kena PHH *dan* HCA):
-- Resident ditautkan ke rumah lewat `profiles.house_id` (itulah yang dipakai
-- admin lewat "Assign to House"), TAPI policy SELECT di `houses` hanya
-- mengizinkan baca kalau `houses.owner_id = auth.uid()`.
-- Akibatnya resident yang di-assign tapi bukan owner_id TIDAK bisa membaca
-- rumahnya sendiri → halaman Profile menampilkan "House Address: Not assigned",
-- dan getHouseById() melempar 406 (PGRST116: 0 rows).
-- Paling sering terjadi saat dua resident berbagi satu rumah (hanya satu yang
-- bisa jadi owner_id).
--
-- Perbaikan: resident boleh membaca rumah yang ditunjuk profilnya sendiri.
-- JALANKAN DI KEDUA DATABASE (PHH dan HCA).

DROP POLICY IF EXISTS resident_read_own ON public.houses;

CREATE POLICY resident_read_own ON public.houses
  FOR SELECT
  USING (
    owner_id = auth.uid()
    OR id = (SELECT p.house_id FROM public.profiles p WHERE p.id = auth.uid())
  );
