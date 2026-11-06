# Changelog — Ghostwriter

Semua perubahan penting dicatat di sini, versi terbaru di atas. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/) dan penomoran [Semantic Versioning](https://semver.org/lang/id/).

Kategori yang dipakai:

- **Ditambah** — fitur, event, konten, atau aset baru
- **Diubah** — perubahan pada yang sudah ada (termasuk balancing angka)
- **Diperbaiki** — perbaikan bug
- **Dihapus** — fitur atau konten yang dibuang

Rencana per versi ada di [`docs/versi/1.0.0/README.md`](docs/versi/1.0.0/README.md).

## [Belum dirilis]

Berisi sisa 0.2.0 (MVP; masih kurang uji di HP dan uji dengan 3–5 teman) dan isi 0.3.0 yang sudah dikerjakan paralel.

### Ditambah

- Era 2 (kantor, 0.3.0): tombol Sewa Kantor di toko (200 pengikut, 400 uang), warna meja kantor sementara, musik era 2
- Saluran Radio: siaran 10 detik, tiap 2 detik satu warga di setiap distrik langsung percaya (60 uang, heat ×1,2)
- Staf otomatis: rumor abstrak tiap 40 detik dari kartu milik pemain, hasil di feed
- Event dilema dengan tombol pilihan yang menjeda waktu; E04 Pemilihan Ketua RT (kartu calon fiktif, uang ×2), E05 Wartawan Penasaran, E06 Festival Kampung
- 40 kata era 2, 2 kartu calon RT, template EKSKLUSIF; 5 SFX dan musik era 2 (placeholder CC0)
- gdUnit4 v6.2.3 dan tes otomatis di `tests/`; bot balancing `tools/sesi_bot.gd`
- Era 3 (gedung media, 0.4.0): upgrade Gedung Media (350 pengikut, 1.200 uang), peta meluas ke 6 distrik (Perumahan Elit, Kampus, Pelabuhan) dengan status warga dipertahankan
- Saluran Medsos: tiap penular juga menulari 2 "teman online" acak se-kota, sehingga rumor melompat antar distrik
- Kontrak kampanye: tawaran klien fiktif (yakinkan 50% warga di 2 distrik dalam 3 menit), progres di HUD
- E07 Dokumen Bocor (kartu sementara 3 rumor), E08 Viral Challenge, E09 Razia Hoaks (medsos dikunci, pengikut −5%)
- 40 kata era 3, 3 template (UTAS, podcast, KLARIFIKASI); notifikasi medsos dan musik era 3 (placeholder CC0)
- Bot balancing bisa "tiarap" saat heat tinggi dan memainkan era 2–4
- Era 4 (menara server, 0.5.0): upgrade Menara Server (ambang sementara 450 pengikut, 1.600 uang), peta 8 distrik dengan Pusat Kota dan Kawasan Industri
- Saluran Server (jaringan bot): 15 detik, tiap detik satu warga acak se-kota langsung percaya, plus lompatan
- Tiga tokoh fiktif target (Pak Hartono, Bu Sasmita, Juragan Bramantyo) dengan reputasi 100 dan pertahanan Pengacara, Humas, Media sendiri; progres di HUD
- E10 Rumor Tandingan (pemercaya jadi ragu), E11 Server Down (staf dan server mati 120 detik)
- 30 kata era 4, 3 template (TRENDING, INVESTIGASI, VIDEO BEREDAR); musik era 4, stinger naik era, dengung server
- Konsekuensi: heat per rumor yang turun pelan, peluang rumor dibongkar, kredibilitas sebagai pengali "dipercaya", warga kebal (biru) yang pulih perlahan, stempel HOAKS
- Saluran Merpati (gratis, satu distrik) dan Koran (30 uang, semua distrik, terbuka di 100 pengikut)
- Pengikut sebagai mata uang ambang (+1 per 5 warga dari rumor yang tidak dibongkar, +3 per mutasi)
- Lima misi berurutan dengan hadiah uang, tampil di HUD
- Mutasi rumor (2% per warga tertular) dan feed headline di atas peta
- Event E01 Hari Pasar, E02 Ronda Malam, E03 Pembongkar Fakta dengan banner dan sisa waktu
- Save `user://save.json` dengan tulis atomik (`.tmp` → `.bak`), versi skema, autosave 30 detik dan saat aplikasi dijeda; rumor yang sedang menjalar disimpan sebagai proyeksi
- Animasi: mesin tik mengetik, kartu terbang ke slot, kartu ditekan, denyut warga, uang melayang, banner event, stempel HOAKS dengan getar peta
- Suara: bus Music dan SFX, 12 SFX dan musik latar era 1 (placeholder CC0 dari OpenGameArt, lihat `assets/LISENSI_AUDIO.md`)
- Konten jadi 40 kata (10 per slot)
- Export preset Android dan APK debug (`build/ghostwriter-debug.apk`)

### Diubah

- Sinyal reputasi hanya dipancarkan saat angka heat/kredibilitas yang tampil berubah (sebelumnya tiap tick, HUD diformat ulang 5 kali per detik)
- Headline panjang di meja mengecil otomatis supaya muat
- Pemilih saluran memendekkan label dan menyembunyikan saluran era berikutnya (sebelumnya 4 tombol mendorong layout melebihi lebar layar)
- Kompresi tekstur ETC2/ASTC diaktifkan (wajib untuk ekspor Android)
- Balancing dari simulasi 8 sesi × 15 menit: heat turun 0,1 → 0,3/detik, jeda Pembongkar Fakta 60 → 120 detik, jeda event acak 90 → 180 detik, pengikut per 5 → per 12 warga, uang per warga 5 → 2

### Diperbaiki

- Bot balancing crash (antrean pesan penuh) saat menjalankan banyak sesi panjang dalam satu frame
- Ancaman (Pembongkar Fakta) menimpa event acak yang sedang aktif dan mereset jedanya, sehingga event acak hampir tidak muncul

## [0.1.0] - 2026-11-05

Prototipe lolos gerbang keputusan: seru dimainkan tanpa art.

### Ditambah

- ADR-0001 sampai ADR-0004: renderer Compatibility, save JSON atomik, model waktu GameClock, lokalisasi Indonesia–Inggris
- Konfigurasi engine Godot 4.7.2 (`CLAUDE.md`, `project.yaml`) dan referensi engine bersumber resmi di `docs/engine-reference/godot/`
- Prototipe: racik headline dari kartu kata ke template, skor viral dan dipercaya, penyebaran rumor di 3 distrik, uang, toko kata dan template, HUD
- Data dua bahasa: 30 kata, 5 template, 3 distrik, teks UI di `localization/ui.csv`
- Aturan desain: rumus konsekuensi, status warga, emosi dominan
- README project dan dokumentasi di `docs/`

### Diubah

- Renderer Mobile → Compatibility; layar portrait 720×1280 (ADR-0001)
- Nama file script dan scene PascalCase → snake_case; aturan kode modular ±300 baris per file
- Angka penyebaran disetel lewat simulasi Monte Carlo; warga yang ragu ikut bercerita 1 detik (usulan prototipe)
- Bahasa Inggris masuk v1 (sebelumnya di daftar ide 2.0.0)

### Dihapus

- Rancangan save SQLite dengan plugin godot-sqlite, diganti JSON (ADR-0002)

<!--
Contoh entri saat versi selesai:

## [0.2.0] - 2026-12-01

### Ditambah
- Event E01 Hari Pasar, E02 Ronda Malam, E03 Pembongkar Fakta
- SFX mesin tik, kartu, kirim, uang
- Animasi mesin tik mengetik headline

### Diubah
- Peluang tular dasar 0,02 → 0,015 (penyebaran terlalu cepat)

### Diperbaiki
- Kartu bisa masuk ke slot kategori yang salah
-->
