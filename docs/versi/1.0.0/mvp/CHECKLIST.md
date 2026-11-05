# Checklist — Ghostwriter v1.0.0

Satu-satunya daftar centang untuk semua versi, dari setup sampai rilis. Rincian desain ada di dokumen yang ditautkan. Setiap kali satu versi selesai, catat perubahannya di `CHANGELOG.md` dan buat git tag (lihat [konvensi](../../../panduan/konvensi.md)).

## Setup (sebelum 0.1.0)

- [ ] Install Godot 4.7.1 (sama dengan versi yang didukung plugin godot-sqlite v4.9)
- [ ] Pasang plugin **godot-sqlite** (AssetLib atau rilis GitHub) ke `res://addons/godot-sqlite/`, lalu restart editor
- [ ] Buat project baru, renderer **Mobile** atau **Compatibility** (Compatibility lebih aman untuk HP kelas bawah)
- [ ] Project Settings → Display → Window: viewport 720×1280, orientation `portrait`, stretch mode `canvas_items`, aspect `expand`
- [ ] Buat struktur folder seperti di bagian 3
- [ ] Inisialisasi git + repo GitHub (commit kecil tiap hari)
- [ ] Siapkan Android export: Android SDK, JDK 17, export template, keystore debug
- [ ] Uji coba: buka `user://ghostwriter.db`, buat satu tabel, simpan satu baris, lalu cek di HP Android. Pastikan plugin jalan di Android sejak awal
- [ ] Ekspor scene kosong ke HP sendiri — pastikan jalan sekarang, bukan di minggu ke-11

## 0.1.0 — Prototipe

Semua pakai kotak abu-abu dan teks polos. **Jangan sentuh art.**

**Hari 1–2: meracik headline**

- [ ] `DataDB` memuat `words.json` dan `templates.json`
- [ ] `WordCard.tscn`: tombol berisi teks kata + ikon emosi sederhana
- [ ] `Hand.tscn`: menampilkan kartu yang dimiliki pemain
- [ ] `Desk.tscn`: menampilkan template dengan slot; tap kartu → mengisi slot sesuai kategorinya
- [ ] Tombol **KIRIM** aktif jika semua slot terisi
- [ ] `RumorScorer.gd`: hitung viral & dipercaya, tampilkan angkanya di layar (debug)

**Hari 3–4: kota & penyebaran**

- [ ] `City.tscn`: 3 distrik berupa kotak berwarna, warga berupa titik (`ColorRect` kecil atau digambar di `_draw()`)
- [ ] `SpreadSim.gd`: tiap tick (misalnya 0,2 detik) warga yang percaya mencoba menulari tetangga terdekat
- [ ] Warna titik sesuai status: abu (belum dengar), merah (percaya), kuning (ragu)
- [ ] Rumor dimulai dari 1–3 warga acak di distrik tujuan
- [ ] Penyebaran berhenti otomatis setelah N detik atau saat tidak ada yang baru tertular

**Hari 5: uang & upgrade pertama**

- [ ] Tiap warga yang percaya memberi uang
- [ ] `Shop.tscn` sederhana: beli 3–5 kata baru dan 1 template baru
- [ ] HUD menampilkan uang

**Hari 6–7: mainkan dan putuskan**

- [ ] Main sendiri minimal 3 sesi × 10 menit
- [ ] Catat: kapan mulai bosan? Kombinasi mana yang terasa lucu? Apakah melihat rumor menjalar itu memuaskan?
- [ ] Ubah angka di `Balance.gd`, coba lagi
- [ ] Putuskan lanjut / ubah / buang sesuai [gerbang keputusan](mvp-v1.md#gerbang-keputusan-prototipe)

## 0.2.0 — MVP

**Konten**

- [ ] ±40 kata (10 per kategori)
- [ ] 3 template
- [ ] 3 distrik (Pasar Lama, Kompleks Hijau, Gang Sempit)
- [ ] 2 saluran: Merpati dan Koran

**Sistem**

- [ ] Kredibilitas (0–100) dan heat (0–100)
- [ ] Status warga **kebal** (biru)
- [ ] Mutasi rumor (satu kata berganti saat menyebar)
- [ ] Feed headline yang sedang beredar
- [ ] Pengikut sebagai mata uang kedua
- [ ] Misi sederhana (minimal 5 misi berurutan)

**Event** (lihat [EVENT.md](../event/EVENT.md))

- [ ] `EventSystem.gd` + `events.json`
- [ ] Banner event di atas peta
- [ ] E01 Hari Pasar
- [ ] E02 Ronda Malam
- [ ] E03 Pembongkar Fakta

**Suara dasar** (lihat [suara.md](../aset/suara.md))

- [ ] Bus audio: Master, Music, SFX
- [ ] Tombol ketik mesin tik + bel akhir baris
- [ ] Ambil & taruh kartu
- [ ] Kirim rumor
- [ ] Dapat uang
- [ ] Stempel HOAKS (pembongkar fakta)
- [ ] Alert event
- [ ] 1 musik latar loop (era kamar)

**Animasi dasar** (lihat [animasi.md](../aset/animasi.md))

- [ ] Mesin tik mengetik headline per huruf
- [ ] Kartu terbang ke slot
- [ ] Titik warga berdenyut saat tertular
- [ ] Angka uang melayang
- [ ] Banner event masuk/keluar

**Uji**

- [ ] Build APK debug terpasang di HP sendiri
- [ ] 3–5 teman main tanpa penjelasan
- [ ] 3 hal paling membingungkan sudah diperbaiki
- [ ] Mulai kumpulkan calon tester closed testing (target 15–25 orang)

**Definisi selesai 0.2.0**

- [ ] Satu sesi 15 menit bisa dimainkan dari awal sampai misi terakhir
- [ ] Minimal 2 event muncul dalam satu sesi
- [ ] Tidak ada crash di HP sendiri
- [ ] Semua perubahan tercatat di `CHANGELOG.md` bagian `[0.2.0]`

## 0.3.0 — Era kantor

- [ ] Era 2: latar meja kantor, terbuka saat syarat pengikut tercapai
- [ ] Saluran radio
- [ ] Staf otomatis pertama
- [ ] ±80 kata, 6 template
- [ ] Sistem event dilema (pilihan A/B, waktu dijeda)
- [ ] Event E04 Pemilihan Ketua RT, E05 Wartawan Penasaran, E06 Festival Kampung
- [ ] SFX: carriage return, pengikut naik, beli, error, pilih dilema, telepon
- [ ] Musik era 2
- [ ] Animasi: kirim kertas, mutasi headline, buka toko, umpan balik tombol
- [ ] Art pertama: kartu, slot, kertas, meja era 1–2, peta, distrik 1–3, panel UI, stempel HOAKS
- [ ] Ikon radio dan staf

## 0.4.0 — Era gedung media

- [ ] Era 3 dan saluran medsos
- [ ] Kampanye multi-distrik
- [ ] Distrik 4–6, ±120 kata, 9 template
- [ ] Event E07 Dokumen Bocor, E08 Viral Challenge, E09 Razia Hoaks
- [ ] SFX notifikasi medsos, musik era 3, lapisan musik ancaman
- [ ] Animasi staf bekerja
- [ ] Art meja era 3, distrik 4–6, ikon medsos

## 0.5.0 — Era server

- [ ] Era 4 dan saluran server
- [ ] Tokoh fiktif target besar dengan pertahanan masing-masing
- [ ] Distrik 7–8, ±150 kata, 12 template
- [ ] Event E10 Rumor Tandingan, E11 Server Down
- [ ] Ambience server, stinger naik era, musik era 4
- [ ] Animasi transisi era
- [ ] Art meja era 4, distrik 7–8, ikon server

## 0.6.0 — Ending & balancing

- [ ] Kampanye akhir dan layar ending
- [ ] Event E12 Kota Tak Percaya Lagi
- [ ] Penghasilan offline ringan
- [ ] Semua harga dan pengali dipindah ke spreadsheet, diekspor ke JSON
- [ ] Ritme unlock: hal baru tiap 3–5 menit di awal, 10–15 menit di akhir
- [ ] Musik ending, animasi ending, art ending
- [ ] Satu perjalanan penuh kamar → ending dimainkan tanpa macet

## 0.9.0 — Beta & polish

**Save**

- [ ] `SaveSystem` dengan SQLite sesuai [skema](../../../panduan/struktur-project.md#database-save-sqlite): simpan dalam satu transaksi
- [ ] Autosave tiap 30 detik dan saat aplikasi dijeda (`NOTIFICATION_APPLICATION_PAUSED`)
- [ ] Migrasi skema lewat `PRAGMA user_version` supaya update berikutnya tidak merusak save lama
- [ ] Pengaturan disimpan terpisah di `user://settings.cfg`
- [ ] Uji: tutup paksa aplikasi saat autosave, buka lagi, progres tetap utuh
- [ ] Tombol reset progres di pengaturan

**Onboarding**

- [ ] Tutorial 3 langkah yang dimainkan, bukan dibaca: isi slot → kirim → beli kata
- [ ] Tooltip singkat saat sistem baru terbuka (kredibilitas, saluran, staf)

**Juice & aset**

- [ ] Angka uang melayang dari titik warga
- [ ] Getar ringan (haptic) saat headline dikirim
- [ ] Musik menu (`mus_menu`) dan kredit musik di layar Tentang
- [ ] Rapikan semua art: satu palet, font utama + font mesin tik
- [ ] Ikon aplikasi final (adaptive + monochrome), layar judul, splash

**Teknis**

- [ ] Uji di minimal 2 HP berbeda (satu kelas bawah)
- [ ] Batasi jumlah titik warga yang digambar; pakai `_draw()` satu node per distrik, bukan satu node per warga, jika mulai lag
- [ ] Pengaturan: suara, musik, getar, bahasa (Indonesia saja dulu)
- [ ] Safe area untuk notch: beri margin atas di HUD

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
