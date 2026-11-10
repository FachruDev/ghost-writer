# Checklist — Ghostwriter v1.0.0

Satu-satunya daftar centang untuk semua versi, dari setup sampai rilis. Rincian desain ada di dokumen yang ditautkan. Setiap kali satu versi selesai, catat perubahannya di `CHANGELOG.md` dan buat git tag (lihat [konvensi](../../../panduan/konvensi.md)).

## Setup (sebelum 0.1.0)

- [x] Install Godot 4.7.2
- [x] Project dengan renderer **Compatibility** ([ADR-0001](../../../architecture/adr-0001-renderer.md))
- [x] Project Settings → Display → Window: viewport 720×1280, orientation `portrait`, stretch mode `canvas_items`, aspect `expand`
- [x] Localization: fallback locale `id` ([ADR-0004](../../../architecture/adr-0004-lokalisasi.md))
- [x] Buat struktur folder seperti di [struktur-project.md](../../../panduan/struktur-project.md)
- [x] Inisialisasi git (commit kecil tiap hari)
- [x] Siapkan Android export: Android SDK, JDK 17+, export template, keystore debug, Android Build Template (Gradle, untuk AAB). Tambahkan filter `data/*.json` ke "Filters to export non-resource files" supaya konten JSON ikut terekspor
- [x] Pasang gdUnit4 v6.2.3 (jalan di Godot 4.7.2); tes di `tests/`, bot balancing di `tools/sesi_bot.gd`
- [ ] Uji coba: tulis dan baca `user://save.json` di HP Android
- [ ] Ekspor scene kosong ke HP sendiri — pastikan jalan sekarang, bukan di minggu ke-11

## 0.1.0 — Prototipe

Semua pakai kotak abu-abu dan teks polos. **Jangan sentuh art.**

**Hari 1–2: meracik headline**

- [x] `DataDB` memuat `words.json` dan `templates.json` (teks per bahasa, [ADR-0004](../../../architecture/adr-0004-lokalisasi.md))
- [x] `Bahasa` autoload + `headline_builder.gd`; teks UI lewat `localization/ui.csv`
- [x] `word_card.tscn`: tombol berisi teks kata + ikon emosi sederhana
- [x] `hand.tscn`: menampilkan kartu yang dimiliki pemain
- [x] `desk.tscn`: menampilkan template dengan slot; tap kartu → mengisi slot sesuai kategorinya
- [x] Tombol **KIRIM** aktif jika semua slot terisi
- [x] `rumor_scorer.gd`: hitung viral & dipercaya, tampilkan angkanya di layar (debug)

**Hari 3–4: kota & penyebaran**

- [x] `city.tscn`: 3 distrik berupa kotak berwarna, warga berupa titik (`ColorRect` kecil atau digambar di `_draw()`)
- [x] `GameClock` autoload: tick tetap 0,2 detik, jeda bernama, RNG berseed ([ADR-0003](../../../architecture/adr-0003-model-waktu.md))
- [x] `spread_sim.gd`: tiap `GameClock.tick` warga yang percaya (dan sebentar yang ragu) mencoba menulari tetangga terdekat
- [x] Warna titik sesuai status: abu (belum dengar), merah (percaya), kuning (ragu)
- [x] Rumor dimulai dari 1–3 warga acak di distrik tujuan
- [x] Penyebaran berhenti otomatis setelah N detik atau saat tidak ada yang baru tertular

**Hari 5: uang & upgrade pertama**

- [x] Tiap warga yang percaya memberi uang
- [x] `shop.tscn` sederhana: beli 3–5 kata baru dan 1 template baru
- [x] HUD menampilkan uang

**Hari 6–7: mainkan dan putuskan**

- [x] Main sendiri minimal 3 sesi × 10 menit
- [x] Catat: kapan mulai bosan? Kombinasi mana yang terasa lucu? Apakah melihat rumor menjalar itu memuaskan? — catatan sesi tidak tersimpan di repo; hasilnya tercatat di `CHANGELOG.md` `[0.1.0]`
- [x] Ubah angka di `balancing/angka.csv`, coba lagi — angka penyebaran disetel lewat simulasi Monte Carlo; warga ragu ikut bercerita 1 detik (`DURASI_MENULAR_RAGU_DETIK`)
- [x] Putuskan lanjut / ubah / buang sesuai [gerbang keputusan](mvp-v1.md#gerbang-keputusan-prototipe) — **lanjut**: "seru dimainkan tanpa art" (`CHANGELOG.md` `[0.1.0]`, 2026-11-05); tag `v0.1.0` di commit prototipe `018df6e`

## 0.2.0 — MVP

**Konten**

- [x] ±40 kata (10 per kategori)
- [x] 3 template
- [x] 3 distrik (Pasar Lama, Kompleks Hijau, Gang Sempit)
- [x] 2 saluran: Merpati dan Koran

**Sistem**

- [x] Kredibilitas (0–100) dan heat (0–100)
- [x] Status warga **kebal** (biru)
- [x] Mutasi rumor (satu kata berganti saat menyebar)
- [x] Feed headline yang sedang beredar
- [x] Pengikut sebagai mata uang kedua
- [x] Misi sederhana (minimal 5 misi berurutan)

**Save dasar** (lihat [ADR-0002](../../../architecture/adr-0002-backend-save.md))

- [x] `SaveSystem`: `user://save.json` dengan tulis atomik (`.tmp` → `.bak`), `versi_skema`, migrasi
- [x] `GameState.ke_dict()` / `dari_dict()`; riwayat menyimpan `template_id` + `kata_ids`
- [x] Autosave tiap 30 detik dan saat aplikasi dijeda; rumor yang sedang menjalar disimpan sebagai proyeksi ([ADR-0003](../../../architecture/adr-0003-model-waktu.md))
- [x] Pengaturan (bahasa) di `user://settings.cfg`

**Event** (lihat [EVENT.md](../event/EVENT.md))

- [x] `event_controller.gd` + `events.json`
- [x] Banner event di atas peta
- [x] E01 Hari Pasar
- [x] E02 Ronda Malam
- [x] E03 Pembongkar Fakta

**Suara dasar** (lihat [suara.md](../aset/suara.md))

- [x] Bus audio: Master, Music, SFX
- [x] Tombol ketik mesin tik + bel akhir baris
- [x] Ambil & taruh kartu
- [x] Kirim rumor
- [x] Dapat uang
- [x] Stempel HOAKS (pembongkar fakta)
- [x] Alert event
- [x] 1 musik latar loop (era kamar)

**Animasi dasar** (lihat [animasi.md](../aset/animasi.md))

- [x] Mesin tik mengetik headline per huruf
- [x] Kartu terbang ke slot
- [x] Titik warga berdenyut saat tertular
- [x] Angka uang melayang
- [x] Banner event masuk/keluar

**Uji**

- [ ] Build APK debug terpasang di HP sendiri (APK sudah bisa dibangun: `build/ghostwriter-debug.apk`)
- [ ] 3–5 teman main tanpa penjelasan
- [ ] 3 hal paling membingungkan sudah diperbaiki
- [ ] Mulai kumpulkan calon tester closed testing (target 15–25 orang)

**Definisi selesai 0.2.0**

- [ ] Satu sesi 15 menit bisa dimainkan dari awal sampai misi terakhir — bot 2026-11-09 (32 sesi): misi ke-5 selesai di menit 4–10 (median ±7) di semua sesi; belum dimainkan manusia
- [ ] Minimal 2 event muncul dalam satu sesi — bot 2026-11-09 (32 sesi): 4–5 event dalam 15 menit pertama di semua sesi. Catatan: dulu Hari Pasar dan Ronda Malam bisa muncul sampai 3 kali dalam 15 menit; setelah E13 Arisan Kompleks dan E14 Mati Lampu ditambah, sesi dengan pengulangan 3 kali turun dari 10 ke 5 dari 32
- [ ] Tidak ada crash di HP sendiri
- [ ] Semua perubahan tercatat di `CHANGELOG.md` bagian `[0.2.0]`

## 0.3.0 — Era kantor

- [x] Era 2: tombol Sewa Kantor (200 pengikut, 400 uang); latar meja kantor sementara warna polos
- [x] Saluran radio (siaran 10 detik)
- [x] Staf otomatis pertama (rumor abstrak tiap 40 detik)
- [x] ±80 kata, 6 template (82 kata termasuk 2 calon RT dari E04)
- [x] Sistem event dilema (pilihan A/B, waktu dijeda)
- [x] Event E04 Pemilihan Ketua RT, E05 Wartawan Penasaran, E06 Festival Kampung
- [x] SFX: carriage return, pengikut naik, beli, error, pilih dilema (placeholder CC0); telepon dibuat prosedural
- [x] Musik era 2 (placeholder CC0)
- [x] Animasi: kirim kertas, mutasi headline, buka toko, umpan balik tombol — kertas terbang dari meja ke distrik benih (`kertas_terbang.gd`), baris feed mutasi berkedip lalu berganti, layar penuh meluncur naik (`Lembar`), semua tombol mengecil saat ditekan (`UmpanTekan`); kanvas papan 24
- [x] Art pertama: kartu, slot, kertas, meja era 1–2, peta, distrik 1–3, panel UI, stempel HOAKS — digambar kode dengan tema "Kota Gosip Malam" (kanvas papan 01–20); meja era 1–2 lewat `MejaEra` (papan 23)
- [x] Ikon radio dan staf

## 0.4.0 — Era gedung media

- [x] Era 3 (upgrade Gedung Media) dan saluran medsos (lompatan antar distrik)
- [x] Kampanye multi-distrik (kontrak klien fiktif)
- [x] Distrik 4–6 (peta 2×3, warga ±200), ±120 kata (123), 9 template
- [x] Event E07 Dokumen Bocor, E08 Viral Challenge, E09 Razia Hoaks
- [x] SFX notifikasi medsos dan musik era 3 (placeholder CC0); lapisan musik ancaman (Panic mode, CC0, 372 KB)
- [x] Animasi staf bekerja — titik mengetik di cincin staf (`cincin_staf.gd`); saat staf mengirim, cincin memantul dan kertas hijau terbang ke distrik
- [x] Art meja era 3, distrik 4–6, ikon medsos — meja studio (neon pink, meter suara bergerak), distrik di peta jaringan, `assets/ui/ikon/medsos.svg`

## 0.5.0 — Era server

- [x] Era 4 (upgrade Menara Server, ambang sementara 450/1.600) dan saluran server (jaringan bot)
- [x] Tokoh fiktif target besar dengan pertahanan masing-masing (Pengacara, Humas, Media sendiri)
- [x] Distrik 7–8 (peta 2×4, warga ±260), ±150 kata (156), 12 template
- [x] Event E10 Rumor Tandingan, E11 Server Down
- [x] Ambience server (dibuat prosedural), stinger naik era, musik era 4 (placeholder CC0)
- [x] Animasi transisi era — meja lama memudar ke meja baru sambil pita cahaya warna era naik (1,4 dtk), lalu lembar Naik Era dengan ilustrasi papan 11 (sinar, gedung tumbuh, hantu mendarat; `ilustrasi_era.gd`)
- [x] Art meja era 4, distrik 7–8, ikon server — meja server (sirkuit hijau, lampu berkedip), distrik di peta jaringan, `assets/ui/ikon/server.svg`

## 0.6.0 — Ending & balancing

- [x] Kampanye akhir dan layar ending (dua ending, statistik, Mulai Baru / Lanjut Bermain)
- [x] Event E12 Kota Tak Percaya Lagi
- [x] Penghasilan offline ringan (staf, maks 8 jam × 0,5)
- [x] Semua harga dan pengali dipindah ke spreadsheet (`balancing/*.csv`), diekspor ke JSON (`tools/terapkan_balancing.gd`)
- [ ] Ritme unlock: hal baru tiap 3–5 menit di awal, 10–15 menit di akhir — bot 2026-11-08 (32 sesi, median): 5 misi selesai menit 7, Era 2 menit 10, staf 12, Era 3 19, Era 4 31, kampanye akhir 45. Jarak awal 2–3 menit, akhir 12–14 menit; perlu dirasakan saat playtest
- [x] Musik ending (placeholder CC0), animasi ending, art ending — kota memudar titik demi titik 4 dtk (emas/kelabu, `kota_memudar.gd`), lalu art papan 17/18 (`ilustrasi_ending.gd`: hantu bermahkota + hujan koran / hantu kelabu + kucing oren), judul memantul, statistik bertahap
- [ ] Satu perjalanan penuh kamar → ending dimainkan tanpa macet — bot 2026-11-08 (32 sesi × 70 menit, deterministik, dengan tutorial dan petunjuk di main): tanpa crash/macet teknis; Era 4 27/32 sesi (median menit 31), kampanye akhir 24/32 (median menit 45, 19 menang). Tokoh bukan penghambat: sekali Era 4 tercapai dengan kredibilitas sehat, ketiganya jatuh dalam 3–9 menit. Yang menghambat: 8/32 sesi terjebak kredibilitas < 30 lebih dari 10 menit (dibongkar → kurang dipercaya → makin sering dibongkar), biasanya di Era 2–3. Setelah `KRED_PULIH_PER_DETIK` 0,1 → 0,2: 0/32 sesi terjebak, Era 4 31/32 (median menit 32), kampanye akhir 22/32 (median menit 47). Balapan akhir (2026-11-09): kebal menular tiap 20 detik (sebelumnya 10, hampir mustahil untuk pemain yang berpikir 10–20 detik per rumor); 16 dari 21 sesi kini menang di percobaan pertama. Perlu dimainkan manusia

## 0.9.0 — Beta & polish

**Save**

Save dasar sudah dibuat di 0.2.0 ([ADR-0002](../../../architecture/adr-0002-backend-save.md)). Di sini tinggal pengujian dan polish:

- [ ] Uji: tutup paksa aplikasi saat autosave 10 kali, buka lagi, progres tetap utuh — desktop lolos 30 kali (`tools/uji_tutup_paksa.gd`); tinggal diulang di HP
- [x] Uji: `save.json` dirusak manual → game memuat dari `save.bak` tanpa crash (tes headless `test_save.gd`)
- [x] Uji: save skema lama termuat setelah migrasi (tes headless: save 0.2.0 + urutan migrasi)
- [ ] Proyeksi rumor saat menyimpan < 50 ms di HP kelas bawah ([ADR-0003](../../../architecture/adr-0003-model-waktu.md)) — desktop 8 ms di kota terbesar; perlu diukur di HP
- [x] Tombol reset progres di pengaturan (`settings.cfg` tidak ikut terhapus)

**Onboarding**

- [x] Tutorial 3 langkah yang dimainkan, bukan dibaca: isi slot → kirim → beli kata — logika `TutorialController` (tes `test_tutorial.gd`) + lapisan UI tangan penunjuk, teks, dan Lewati (`tutorial_lapisan.gd`, tes `test_tutorial_lapisan.gd`); belum diuji di HP
- [x] Tooltip singkat saat sistem baru terbuka (kredibilitas, saluran, staf) — logika `PetunjukController` (tes `test_petunjuk.gd`) + kartu petunjuk berekor dengan tombol Oke (`petunjuk_lapisan.gd`, tes `test_petunjuk_lapisan.gd`); belum diuji di HP

**Juice & aset**

- [x] Angka uang melayang dari titik warga — dari warga yang paling baru percaya di distrik itu (`kiriman_animasi.gd`)
- [x] Getar ringan (haptic) saat headline dikirim (dan lebih kuat saat HOAKS; izin VIBRATE di preset Android)
- [x] Musik menu (`mus_menu`) dan kredit musik di layar Tentang — musik menu (placeholder CC0, diputar di layar judul); layar Tentang & kredit dari Pengaturan (`tentang_layar.gd`, data `data/kredit.json`, tes `test_kredit.gd` dan `test_tentang.gd`), termasuk lisensi OFL dan Godot Engine
- [x] Rapikan semua art: satu palet, font utama + font mesin tik — `Palet` + `Tema` (Fredoka, Lilita One, Courier Prime); semua art digambar kode atau SVG di `assets/ui/ikon`
- [x] Ikon aplikasi final (adaptive + monochrome), layar judul, splash — ikon Si Hantu Penulis (kanvas papan 21) dan boot splash (papan 22) dari `assets/ikon_app/`; ikon di APK debug sudah dicek. Belum dilihat di HP: warna latar splash sistem Android 12+ baru bisa diatur setelah Gradle build aktif

**Teknis**

- [ ] Uji di minimal 2 HP berbeda (satu kelas bawah)
- [x] Batasi jumlah titik warga yang digambar; pakai `_draw()` satu node per distrik, bukan satu node per warga, jika mulai lag — 2026-11-09: peta dulu digambar ulang penuh tiap frame selama rumor menjalar (Era 4: 32 ms/frame di desktop Intel UHD). Kini tiga lapisan (latar statis, wajah saat status berubah, animasi tiap frame) dan wajah dari atlas tekstur: Era 4 median 3,7 ms, p95 5,6 ms, draw call 2.615 → 470. Belum diukur di HP kelas bawah
- [x] Pengaturan: suara, musik, getar, bahasa (Indonesia, Inggris)
- [x] Semua teks EN lengkap: tes headless tidak menemukan field `en` kosong ([ADR-0004](../../../architecture/adr-0004-lokalisasi.md))
- [x] Kata EN terpanjang muat di kartu; uji UI dengan pseudolokalisasi — 312 dari 312 kartu (id + en) muat (`test_tata_letak.gd`). Pseudolokalisasi 2026-11-09 (teks UI +30%, ID dan EN, 15 layar di 720×1280): tidak ada teks UI yang di-hardcode; yang baru meluber hanya dengan +30%: judul GHOSTWRITER di layar judul dan Tentang, teks KIRIM "Ketuk distrik di peta" (+8 px), baris hadiah di lembar Tokoh EN (+6 px), dan grid statistik ending ID (+22 px). Dengan teks dan angka asli semuanya muat
- [x] Safe area untuk notch: beri margin atas di HUD (`UiKit.inset_aman`, juga tepi bawah lembar dan meja; belum diuji di HP bernotch)

## 1.0.0 — Rilis

Langkah lengkap ada di [panduan rilis Android](../../../panduan/rilis-android.md).

- [ ] Release keystore dibuat dan dicadangkan di dua tempat
- [ ] AAB dengan target API 36
- [ ] Aset Play Store lengkap (lihat [gambar.md](../aset/gambar.md) dan [ikon.md](../aset/ikon.md))
- [ ] Closed testing: minimal 12 tester selama 14 hari berturut-turut
- [ ] Akses produksi disetujui, aplikasi dikirim untuk review
- [ ] `CHANGELOG.md` bagian `[1.0.0]` lengkap, git tag `v1.0.0`

**v1 dianggap selesai jika**

- [ ] Satu perjalanan penuh kamar → menara server bisa dimainkan sampai ending
- [ ] Progres tersimpan dan aman saat aplikasi ditutup paksa
- [ ] Tidak ada crash di minimal 2 HP berbeda
- [ ] Orang baru bisa mulai main tanpa dijelaskan
- [ ] Lolos review dan tayang di Play Store
