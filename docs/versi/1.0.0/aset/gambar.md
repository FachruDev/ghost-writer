# Gambar & Art — Ghostwriter v1.0.0

Gaya visual: **2D flat dan minimal**, satu palet warna, garis bersih. Sampai 0.2.0 semua boleh kotak abu-abu; art final masuk bertahap mulai 0.3.0 dan dirapikan di 0.9.0. Simpan di `res://assets/ui/` dan `res://assets/art/`, format `.png` (atau `.svg` untuk bentuk sederhana).

## Panduan gaya

| Hal | Keputusan |
| --- | --- |
| Resolusi acuan | 720×1280 (portrait) |
| Palet | Maks 8 warna utama + 4 warna status warga (abu, merah, kuning, biru) |
| Font utama | Sans-serif yang mudah dibaca di HP (lisensi OFL) |
| Font mesin tik | Monospace bergaya mesin tik (lisensi OFL) |
| Sudut | Membulat kecil, konsisten di kartu dan panel |

Palet "Kota Gosip Malam" (`scripts/ui/palet.gd`): malam #1A1530, panel #2A2350, pink #FF3D7F, kuning #FFC93C, cyan #3DD9EB, hijau #34D399. Font (semua SIL OFL): Fredoka untuk UI, Lilita One untuk judul, Courier Prime untuk mesin tik. Hampir semua art digambar kode (`_draw()`, StyleBox) supaya tajam di semua layar; desain di kanvas papan 01–26.

## Daftar

| ID | Isi | Ukuran kira-kira | Versi | Sumber / lisensi | Status |
| --- | --- | --- | --- | --- | --- |
| art_card_frame | Bingkai kartu kata (4 warna kategori) | 160×96 | 0.3.0 | digambar kode: `scenes/card/word_card.gd` (papan 02) | Selesai |
| art_slot | Slot kosong di template | 160×56 | 0.3.0 | digambar kode: chip slot di `kertas_headline.gd` | Selesai |
| art_paper | Tekstur kertas di bawah headline | 680×220 | 0.3.0 | digambar kode: kertas krem di `kertas_headline.gd` | Selesai |
| art_desk_era1 | Meja kamar + mesin tik tua + lampu | 720×300 | 0.3.0 | digambar kode: `scenes/desk/meja_era.gd` (papan 23) | Selesai |
| art_map_base | Latar peta kota (sungai, jalan) | 720×580 | 0.3.0 | digambar kode: `peta_latar.gd` (papan 03) | Selesai |
| art_district_1..3 | Bentuk distrik awal | sesuai peta | 0.3.0 | digambar kode: gugus wajah di `peta_jaringan.gd` | Selesai |
| art_panel_ui | Panel toko, banner event, dialog | 9-patch | 0.3.0 | digambar kode: `scripts/ui/tema.gd`, `palet.gd`, `ui_kit.gd` | Selesai |
| art_debunk_stamp | Stempel HOAKS | 200×120 | 0.3.0 | digambar kode: stempel di `scenes/city/city.gd` | Selesai |
| art_desk_era2 | Meja kantor + komputer tabung + telepon | 720×300 | 0.3.0 | digambar kode: `meja_era.gd` (papan 23) | Selesai |
| art_district_4..6 | Distrik tambahan | sesuai peta | 0.4.0 | digambar kode: `peta_jaringan.gd` (papan 09) | Selesai |
| art_desk_era3 | Ruang media + banyak layar | 720×300 | 0.4.0 | digambar kode: `meja_era.gd` (papan 23) | Selesai |
| art_desk_era4 | Konsol rak server berkilau | 720×300 | 0.5.0 | digambar kode: `meja_era.gd` (papan 23) | Selesai |
| art_district_7..8 | Distrik akhir | sesuai peta | 0.5.0 | digambar kode: `peta_jaringan.gd` (papan 09) | Selesai |
| art_ending | Ilustrasi layar ending | 720×1280 | 0.6.0 | digambar kode: `ilustrasi_ending.gd` (papan 17/18, 26) | Selesai |
| art_title | Layar judul / menu | 720×1280 | 0.9.0 | digambar kode: `scenes/ui/judul.gd` (papan 01) | Selesai |
| art_splash | Boot splash: logo + Si Hantu di tengah, latar malam polos (`assets/ikon_app/splash.png`, 1080×1920, dibuat `tools/buat_ikon_splash.gd`; kanvas papan 22) | 720×1280 | 0.9.0 | | Selesai |

## Aset Play Store (1.0.0)

| ID | Isi | Ukuran | Status |
| --- | --- | --- | --- |
| store_feature | Feature graphic | 1024×500 | Belum |
| store_shot_1..4 | Screenshot portrait (racik, peta menyebar, event, era server) | ukuran layar HP | Belum |
