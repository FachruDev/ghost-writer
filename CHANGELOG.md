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

- Desain UI "Kota Gosip Malam" (kanvas desain, papan 01–20): tema gelap, tombol tebal, font OFL Lilita One, Fredoka, Courier Prime di `assets/fonts/`, ikon SVG garis di `assets/ui/ikon/`
- Peta "Jaringan Gosip": tiap warga digambar sebagai wajah (ekspresi + cincin status + gelembung !/?), garis tetangga, titik pink merambat saat menular, gugus distrik bercahaya warna emosi, label persen percaya, cincin TARGET
- Maskot Si Hantu Penulis (4 suasana) di HUD, judul, naik era, kampanye akhir, ending
- Layar judul sebagai main scene: LANJUTKAN/MAIN, Main baru (tekan dua kali), Pengaturan, bahasa
- Meja baru: kertas headline dengan chip slot yang bisa diketuk, pengganti template, skor emosi/viral/dipercaya; tangan kartu per slot yang bisa digeser; kartu tokoh/calon/sementara; tombol saluran + KIRIM!
- Lapisan: Pilih Saluran, toko layar penuh (Kata, Template, Kantor & staf), banner event, lembar Dilema dan Tawaran Kontrak, Tokoh Target, Kampanye Akhir, Naik Era, Selamat Datang Kembali (offline), Pengaturan (musik, efek suara, getar, bahasa, hapus progres), ending menang/kalah dengan 6 statistik
- HUD: era, uang, pengikut, bar kredibilitas & panas, cincin staf, strip misi/tokoh/kampanye akhir dan strip kontrak
- Sinyal tampilan `layar_diminta`, `kontrak_progres`, `final_data`, `staf_hitung`, `slot_aktif`; deskripsi saluran (`info`) di `data/upgrades.json`; 120-an kunci teks UI baru (id + en)
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
- Kampanye akhir (0.6.0): tombol Kampanye Akhir setelah ketiga tokoh jatuh; E12 Kota Tak Percaya Lagi (semua warga ragu, kebal menular ke tetangga tiap 10 detik dan tidak pulih); menang 60% warga percaya, kalah 50% kebal atau 5 menit habis; progres di HUD
- Layar ending: Imperium Kabar Burung (menang) dan Kota Mati Rasa (kalah) dengan epilog satir dua bahasa, statistik (rumor, uang, tokoh jatuh, dibongkar, waktu main, rumor terbaik), Mulai Baru (tekan dua kali) dan Lanjut Bermain; musik ending (placeholder CC0)
- Penghasilan offline dari staf saat memuat save (maks 8 jam × 0,5, ADR-0003), tampil di feed
- Spreadsheet balancing: `balancing/angka.csv` dan `balancing/harga.csv`, diterapkan ke `data/balance.json` dan harga di `data/*.json` oleh `tools/terapkan_balancing.gd`; tes memastikan keduanya sinkron
- Tes ketahanan save (0.9.0): save rusak dimuat dari `.bak`, save 0.2.0 tetap termuat, urutan migrasi, waktu proyeksi save (8 ms di desktop untuk kota 260 warga)
- Autoload `Pengaturan` (volume musik dan SFX, getar) di `user://settings.cfg`, tidak ikut terhapus saat reset progres; layarnya menyusul bersama desain UI
- Getar ringan saat headline dikirim dan saat rumor dibongkar (izin VIBRATE di preset Android)
- Lapisan musik ancaman yang masuk/keluar pelan selama ancaman dan E12 (placeholder CC0); dering telepon untuk E05 Wartawan (dibuat prosedural)
- Tes wajib: semua teks konten dan UI punya bahasa Indonesia dan Inggris
- Bot balancing memainkan kampanye akhir, menimbang pertahanan Pengacara dengan tepat (varian rumor dengan/tanpa tokoh), mencatat jejak per 5 menit, dan punya mode `-- final` untuk menguji balapan saja; 25 tes baru (77 total)
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
- Uji tutup paksa saat autosave (`tools/uji_tutup_paksa.gd`): proses anak dibunuh di titik acak selagi menyimpan, dan tiap putaran harus memuat save yang utuh tanpa uang mundur. Save pemain dicadangkan lalu dikembalikan. Di desktop lolos 30 kali; save yang ditulis tanpa `.tmp` gagal di uji ini
- Data kredit aset untuk layar Tentang (`data/kredit.json`, dibaca `DataDB.kredit`): 3 font OFL, 7 musik dan 19 efek suara CC0 dengan pembuat dan sumbernya, plus kunci teks `UI_KREDIT_*`. Tes memastikan setiap file di `assets/fonts`, `assets/music`, dan `assets/sfx` tercatat. Teks lisensi OFL (`assets/fonts/OFL-*.txt`) kini ikut diekspor ke APK, sesuai syarat SIL OFL 1.1
- Ikon aplikasi dan splash (kanvas desain papan 21–22, halaman "Ikon & Splash"): Si Hantu Penulis bertopi di langit malam. Adaptive icon Android (lapisan depan, belakang, monokrom untuk themed icon), ikon utama 192 px (juga ikon jendela desktop) dan ikon Play Store 512 px, semua dari SVG di `assets/ikon_app/`. Boot splash 1080×1920 (logo + hantu di tengah, latar = `boot_splash/bg_color`) dirender Godot dengan font dan gambar hantu yang sama dengan game; hantu berada di tengah seperti di splash sistem Android 12+. PNG dibuat ulang dengan `tools/buat_ikon_splash.gd`. Ikon bawaan Godot (`icon.svg`) dihapus; sumber SVG dan ikon Play Store tidak ikut diekspor
- Layar Tentang & kredit (`scenes/ui/tentang_layar.gd` + `kredit_baris.gd`), dibuka dari tombol baru di Pengaturan (layar judul dan dalam permainan): Si Hantu, logo, slogan, ringkasan game, dan versi, lalu kredit dari `data/kredit.json` per kelompok (huruf, musik, efek suara; aset buatan sendiri tidak ditampilkan) dan Godot Engine. Teks lisensi OFL tiap font dan lisensi Godot beserta daftar komponen pihak ketiganya (`Engine.get_copyright_info()`/`get_license_info()`) dibuka per baris; baris yang dipatah tiap ±80 huruf disambung supaya mengalir di layar sempit. Ikut ganti bahasa; Back menutup Tentang lebih dulu
- Logika petunjuk singkat saat sistem baru terbuka (`scenes/main/petunjuk_controller.gd`): kredibilitas & panas setelah rumor pertama selesai, tiap saluran baru (Koran, Radio, Medsos, Server), dan staf. Diumumkan satu per satu lewat `petunjuk_tampil` setelah tutorial selesai, saat waktu tidak dijeda, dan 3 detik setelah pemicu atau petunjuk sebelumnya ditutup (`petunjuk_ditutup`). Tiap petunjuk tampil sekali per progres (`statistik.petunjuk`)
- Lapisan petunjuk (`scenes/ui/petunjuk_lapisan.gd` + `petunjuk_kartu.gd`): kartu bergaris cyan (beda dari tutorial yang kuning) dengan ubin ikon sistem, teks, dan tombol Oke, plus ekor dan cincin sorot cyan ke sasarannya: bar kredibilitas & panas, tombol saluran di meja, atau cincin staf. Kartu diletakkan di sisi sasaran yang lebih lega dan menunggu sampai lembar yang terbuka (Naik Era, lembar saluran) ditutup. Oke memancarkan `petunjuk_ditutup`. Teks ikut ganti bahasa; lapisan yang dibuat belakangan membaca petunjuk yang sedang aktif. Grup baru di HUD: `petunjuk_kredibilitas` dan `petunjuk_staf`
- Musik menu `mus_menu` di layar judul (placeholder CC0: Lofi again, omfgdude). `Suara` mengganti musik mengikuti root scene yang masuk: judul → musik menu, permainan → musik era tanpa stinger naik era (juga setelah reset progres)
- Logika tutorial 3 langkah (isi slot → kirim → beli kata) di `scenes/main/tutorial_controller.gd`: menentukan sasaran yang perlu ditunjuk (kartu, distrik, saluran, KIRIM!, toko, kartu toko termurah) lewat sinyal `tutorial_langkah`, sembunyi saat lembar lain terbuka atau uang belum cukup, dan selesai saat kata pertama dibeli, era naik, atau pemain menekan Lewati (`tutorial_dilewati`, tersimpan di `statistik.tutorial_lewat`). Meja memancarkan `meja_berubah`, `GameClock` memancarkan `jeda_berubah`
- Lapisan tutorial (`scenes/ui/tutorial_lapisan.gd`): tangan kartun yang mengetuk sasaran, cincin sorot kuning, dan gelembung Si Hantu berisi LANGKAH n/3, teks petunjuk, dan Lewati; Hantu girang sebentar saat tutorial selesai. Lapisan ini CanvasLayer, jadi tetap di atas toko, tetapi ketukan tembus kecuali Lewati. Sembunyi saat lembar lain menutupi sasaran. Node sasaran dicari lewat grup (`TutorialSasaran`): kartu paling kiri di tangan, distrik pertama, pilihan di lembar saluran, dan di toko cadangan ke filter "Semua" atau tab Kata. Teks ikut ganti bahasa; kunci baru `UI_TUT_SELESAI`

### Diubah

- Kredibilitas di bawah 50 pulih 0,2 per detik (sebelumnya 0,1; ±12 per menit). Bot deterministik 32 sesi × 70 menit: sesi yang terjebak kredibilitas < 30 lebih dari 10 menit turun dari 8 ke 0, Era 4 tercapai di 31/32 sesi (sebelumnya 27/32, median menit 32), kampanye akhir di 22/32 (median menit 47; sebelumnya 24/32, median 45, selisih masih dalam batas acak). Tokoh ternyata bukan penghambat: sekali Era 4 tercapai dengan kredibilitas sehat, ketiganya jatuh dalam 3–9 menit
- Tes ending memeriksa 6 kotak statistik + kartu rumor terbaik (sebelumnya 12 label)
- `Balance.X` dibaca dari `data/balance.json` (static var); konstanta teknis tetap `const`
- Serialisasi save dipindah dari `game_state.gd` ke `scripts/systems/state_serial.gd` (game_state.gd 297 → ±250 baris); save menyimpan hasil kampanye akhir
- Kredibilitas bisa pulih: +1 dihitung dari dipercaya dasar kartu, dibongkar −(5 + heboh × 0,5), dan di bawah 50 pulih 0,1 per detik ("orang lupa")
- Ritme naik era untuk target ±60 menit: Sewa Kantor 180 pengikut/350 uang, Gedung Media 400/1.800, Menara Server 700/2.200, reputasi tokoh 100 → 1.000. Hasil bot (8 sesi × 70 menit): Era 2 median ±9 menit (7–25), Era 3 ±24 (17–51, 7/8 sesi), Era 4 ±34 (29–68, 6/8 sesi); kampanye akhir tercapai di 4/8 sesi pada menit 39–68 (median ±55), 2 menang setelah beberapa kali coba. Variasi antar-run besar; perlu konfirmasi playtest
- Pesan naik era tidak lagi selalu "Pindah ke kantor!"
- Sinyal reputasi hanya dipancarkan saat angka heat/kredibilitas yang tampil berubah (sebelumnya tiap tick, HUD diformat ulang 5 kali per detik)
- Headline panjang di meja mengecil otomatis supaya muat
- Pemilih saluran memendekkan label dan menyembunyikan saluran era berikutnya (sebelumnya 4 tombol mendorong layout melebihi lebar layar)
- Kompresi tekstur ETC2/ASTC diaktifkan (wajib untuk ekspor Android)
- Balancing dari simulasi 8 sesi × 15 menit: heat turun 0,1 → 0,3/detik, jeda Pembongkar Fakta 60 → 120 detik, jeda event acak 90 → 180 detik, pengikut per 5 → per 12 warga, uang per warga 5 → 2

### Dihapus

- `scenes/city/district.tscn` (kotak distrik + titik) diganti `peta_jaringan.gd`; `scenes/desk/channel_picker.tscn` diganti lembar Pilih Saluran

### Diperbaiki

- Bot balancing (`tools/sesi_bot.gd`) kini deterministik: `GameClock._process` dimatikan selama bot berjalan, karena di sela `await process_frame` ia menambah sampai 5 tick dari waktu nyata dan membuat seed yang sama memberi hasil berbeda tiap run. Hasil bot sebelum perbaikan ini bervariasi antar-run
- Pengaturan bisa digulir kalau layar terlalu pendek (jarak aman notch dan bar gestur), jadi tombol Tentang & kredit dan baris versi tidak terpotong; di 720×1280 tanpa notch tampilannya tetap sama
- Layar 16:9: kertas headline tidak lagi menggencet peta. Chip slot kembali ramping (60 px) dengan area ketuk tetap 88 px (`ChipSlot._has_point`), dan ukuran huruf kalimat mengikuti panjang kalimat yang tampil (kata terisi), bukan hanya pola. Peta tersisa di 720×1280 dengan template dan kata terpanjang: 19 px → 176 px (ID dan EN)
- Peta tidak menggambar warga saat tingginya di bawah tepi (dulu `sqrt` negatif → NaN dan ratusan peringatan "Vector2 cannot be normalized")
- HUD: nama era ("Menara Server", "Server Tower") tidak lagi terpotong elipsis di samping pil uang & pengikut. Angka di atas 100.000 diringkas ("995 rb"/"995K", "1,2 jt"/"1.2M", dibulatkan ke bawah, `UiKit.angka_ringkas`) dan huruf nama era mengecil 22 → 16 px kalau ruangnya sempit
- Tangan tutorial tidak lagi menutupi label tombol lebar (KIRIM!, "Beli · 40"): untuk sasaran selebar 200 px atau lebih, ujung jari digeser ke sisi tempat badan tangan menjulur; kartu dan ikon tetap ditunjuk di tengah
- Versi aplikasi Android mengikuti `application/config/version` (`version/name` di preset dikosongkan; sebelumnya tertinggal 0.2.0 sementara game 0.6.0). Tes `test_preset_android.gd` juga memastikan semua ikon dan boot splash menunjuk ke file yang ada
- Kartu kata: nama lebih dari 16 huruf memakai huruf kecil, jadi "the community hall" muat; semua 312 kartu ID + EN muat (`test_tata_letak.gd`)
- Save: kalau aplikasi mati di antara dua ganti nama saat autosave, `save.tmp` yang utuh (paling baru) kini dimuat lebih dulu daripada `save.bak`, jadi autosave terakhir tidak hilang. `save.tmp` yang terpotong dilewati tanpa disalin ke `save.rusak` ([ADR-0002](docs/architecture/adr-0002-backend-save.md), amandemen 2026-11-07)
- UI (hasil audit): lembar bawah tidak lagi kosong atau setinggi layar saat pertama dibuka (tinggi mengikuti isi, maks. 90% layar lalu digulir); banner event dan feed tidak menyempit; banner baru tidak ikut tersembunyi oleh pudar banner lama dan tidak menghalangi ketukan ke peta; Naik Era bisa digulir sehingga tombol tidak terpotong; toko menjeda waktu dan membangun ulang daftar paling banyak sekali per frame; peta hanya digambar ulang saat status warga berubah atau ada animasi; label HUD, meja, kertas, dan offline ikut ganti bahasa; pilihan dilema yang uangnya kurang dinonaktifkan dan lembar hanya ditutup oleh pengendali event
- Android: tombol Back menutup lapisan teratas lalu kembali ke layar judul (keluar dari judul), `quit_on_go_back=false`; jarak aman notch/bar gestur; area ketuk minimum 88 px (chip slot, panah template, strip HUD, toko, tombol bahasa); kartu tidak menahan geser tangan
- Teks "R", judul game, ID/EN, dan nama bahasa pindah ke `ui.csv`; saklar Getar memakai ikon besar sendiri

- Mulai Baru (ending) dan Hapus progres (pengaturan) membawa pemercaya lama ke game baru: pengendali scene lama sempat menulis ulang status distrik setelah reset. Reset kini diulang saat main baru dimulai (`SaveSystem.selesaikan_reset`)
- Pilihan dilema berbayar bisa dipilih walau uang kurang, sehingga uang jadi minus; kini ditolak (`aksi_gagal`) dan biaya tiap pilihan ikut di info event (`biaya`)
- Kartu kata membunyikan dua suara per ketuk (klik umum ikut terpasang karena grup `tanpa_klik` baru diisi di `_ready`)
- `final_data` dikirim tiap tick walau angkanya sama; kini hanya saat berubah
- Versi game belum diisi di `project.godot`, sehingga save tercatat 0.2.0 dan Pengaturan memakai angka cadangan
- Kredibilitas 0 tidak bisa naik lagi (syarat +1 mustahil saat dipercaya akhir tertahan ≤ 0,5)
- Statistik rumor terbaik tidak pernah diisi
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
