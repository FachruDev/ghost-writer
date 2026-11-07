# Konsep Game — Ghostwriter

Acuan desain: apa game-nya dan bagaimana sistemnya bekerja. Urutan pengerjaan ada di [roadmap](../versi/1.0.0/mvp/mvp-v1.md).

## Ringkasan & keputusan teknis

Ghostwriter adalah game satir portrait untuk Android: pemain meracik rumor dari kartu kata, melihatnya menyebar di kota fiktif, lalu tumbuh dari mesin tik tua menjadi imperium media. Target realistis untuk dikerjakan solo paruh waktu: **v1 bisa dimainkan dan siap rilis dalam sekitar 12 minggu** (perkiraan, bisa lebih cepat atau lambat).

| Hal | Keputusan |
| --- | --- |
| Engine | Godot 4.7.2, GDScript, renderer Compatibility ([ADR-0001](../architecture/adr-0001-renderer.md)) |
| Orientasi | Portrait, resolusi dasar 720×1280, stretch mode `canvas_items`, aspect `expand` |
| Platform | Android dulu; PC menyusul jika v1 berhasil |
| Gaya visual | 2D flat dan minimal: ikon, kartu, titik warga. Art bukan prioritas sampai Fase 4 |
| Input | Tap kartu kata untuk mengisi slot template (drag opsional) |
| Bahasa | Indonesia dan Inggris; teks UI di CSV, teks konten di JSON per bahasa ([ADR-0004](../architecture/adr-0004-lokalisasi.md)) |
| Data konten | File JSON di `res://data/` |
| Save | JSON di `user://save.json` dengan tulis atomik ([ADR-0002](../architecture/adr-0002-backend-save.md)); konten game tetap JSON. Detail di [struktur-project.md](struktur-project.md#save-json) |
| Pengaturan | `ConfigFile` di `user://settings.cfg`, terpisah dari save supaya tidak ikut terhapus saat reset progres |
| Judul | Ghostwriter |

Dua prinsip yang dipegang sejak hari pertama:

- **Semua kota, tokoh, dan partai fiktif.** Tidak menyindir orang atau partai nyata.
- **Setiap rumor punya konsekuensi** (kredibilitas turun, pembongkar fakta muncul). Ini yang membuatnya satir, bukan tutorial jadi buzzer.

## Core loop & sistem inti

Satu putaran permainan berlangsung 30–60 detik:

```
Racik headline (kartu kata → slot template)
        ↓
Kirim lewat saluran (merpati / koran / ...)
        ↓
Rumor menjalar di peta kota, bisa bermutasi
        ↓
Panen uang + pengikut  (kredibilitas & heat ikut berubah)
        ↓
Beli kata / template / saluran / upgrade baru
        ↓
(kembali ke atas)
```

| Sistem | Isi | Mulai di |
| --- | --- | --- |
| Kartu kata | Kategori SUBJEK, AKSI, TEMPAT, SUMBER. Atribut: emosi (lucu, takut, marah, iri), heboh 0–3, kredibilitas 0–3, harga | Prototipe |
| Template headline | Kalimat dengan slot, misalnya `"{subjek} ketahuan {aksi} di {tempat}, kata {sumber}!"`. Tiap template punya pengali heboh | Prototipe |
| Skor rumor | Viral = total heboh × kecocokan emosi dengan distrik. Dipercaya = rata-rata kredibilitas, dikurangi jika terlalu heboh | Prototipe |
| Kota & warga | Distrik dengan profil emosi. Warga berupa titik dengan status: belum dengar, percaya, ragu, kebal | Prototipe |
| Penyebaran | Tiap tick, warga yang percaya menular ke tetangga dengan peluang dari skor viral dan kerentanan distrik | Prototipe |
| Mutasi | Saat menyebar, ada peluang kecil satu kata diganti kata sejenis. Headline yang berubah tampil di feed | MVP |
| Ekonomi | Uang dari warga yang percaya; pengikut sebagai mata uang progresi | Prototipe (uang), MVP (pengikut) |
| Kredibilitas & heat | Heat naik dari rumor yang heboh dan sulit dipercaya, lalu turun pelan. Rumor bisa dibongkar: kredibilitas turun, sebagian warga jadi kebal. Kredibilitas mengalikan seberapa dipercaya rumor berikutnya. Rumus di bawah | MVP |
| Saluran | Merpati → koran → radio → medsos → server. Menentukan jangkauan awal dan distrik tujuan | MVP (2 saluran), Fase 3 (sisanya) |
| Staf otomatis | Menulis rumor kecil sendiri supaya pemain fokus ke kampanye besar | Fase 3 |
| Era | Kamar → kantor → gedung media → menara server. Mengubah latar meja dan membuka konten | Fase 3 |

### Rumus awal (untuk dicoba, nanti diseimbangkan)

```
heboh_total   = (jumlah heboh semua kartu) × pengali_heboh_template
kred_rata     = rata-rata kred semua kartu
cocok_emosi   = 1.5 jika emosi dominan = emosi favorit distrik
                1.0 jika headline netral
                0.9 jika berbeda
                0.6 jika berlawanan

viral         = heboh_total × cocok_emosi
dipercaya     = clamp(kred_rata / 3.0 - max(0, heboh_total - 6) × 0.05, 0.1, 1.0)
dipercaya_akhir = clamp(dipercaya × (0.5 + kredibilitas / 100), 0.1, 1.0)

peluang_tular (per tetangga, per tick) = viral × kerentanan_distrik × 0.02
peluang_percaya (saat tertular)        = dipercaya_akhir        (× 0.5 jika warga sedang ragu)
```

**Emosi dominan.** Hitung emosi semua kartu kecuali netral; emosi terbanyak menang. Kalau seri, ambil emosi kartu dengan heboh tertinggi; kalau masih seri, kartu yang slotnya paling awal (subjek → aksi → tempat → sumber). Kalau semua kartu netral, headline netral.

**Pasangan emosi berlawanan** (usulan awal, ubah saat playtest): lucu ↔ takut, marah ↔ iri.

### Status warga

| Status | Arti | Berubah menjadi |
| --- | --- | --- |
| Belum dengar | Bisa tertular | Percaya (peluang `dipercaya_akhir`) atau ragu |
| Percaya | Menularkan rumor selama 1,2 detik, memberi uang | Kebal kalau rumornya dibongkar (50%) |
| Ragu | Tertular tapi tidak percaya; ikut bercerita selama 1 detik ("eh, katanya sih..."); bisa tertular rumor baru dengan peluang percaya separuh | Belum dengar, peluang 1/60 per detik simulasi (±1 menit) |
| Kebal | Tidak bisa tertular | Belum dengar, peluang 1/180 per detik simulasi (±3 menit); berhenti total saat E12 |

**Usulan prototipe: warga ragu ikut menyebar.** Kalau hanya warga yang percaya yang menularkan, `dipercaya` menentukan dua hal sekaligus (berapa yang yakin *dan* seberapa jauh rumor menjalar), sehingga rumor kredibel dengan heboh rendah selalu menang. Dengan warga ragu ikut bercerita sebentar, jangkauan ditentukan viral dan jumlah yang yakin ditentukan dipercaya. Simulasi Monte Carlo (300 rumor di Pasar Lama, kredibilitas 50) dengan angka di `balance.gd` saat ini:

| Headline | Viral | Dipercaya | Warga percaya (rata-rata) | Lama |
| --- | --- | --- | --- | --- |
| Awal: Pak RT · menari tengah malam · pasar · tetangga | 4,5 | 50% | 24 | 7 detik |
| Kredibel: Bu Lurah · beli mobil · warung kopi · tukang sayur | 1,8 | 75% | 18 | 6 detik |
| Ekstrem: kucing oren · curhat ke ayam · lapangan voli · burung beo | 13,5 | 10% | 11 | 8 detik |

Dimatikan dengan `DURASI_MENULAR_RAGU_DETIK = 0.0`. Diputuskan di gerbang prototipe.

### Konsekuensi (MVP)

```
Saat rumor dikirim:
  heat += heboh_total × (1.5 − dipercaya_akhir)
Setiap detik simulasi:
  heat −= 0.3                                   (±18 per menit)

Saat rumor selesai menyebar:
  peluang_bongkar = (1 − dipercaya_akhir) × (0.3 + heat / 100 × 0.7)

  Kalau dibongkar:
    kredibilitas −= 5 + heboh_total × 0,5
    50% warga yang percaya rumor itu → kebal
    heat += 10
    stempel HOAKS di feed; uang yang sudah didapat tetap
  Kalau tidak dibongkar dan dipercaya (dasar, dari kartu) ≥ 0.7:
    kredibilitas += 1
Setiap detik simulasi, kalau kredibilitas < 50:
  kredibilitas += 0,1   ("orang lupa", ±6 per menit)
```

**Disetel di 0.6.0.** Dengan aturan lama (+1 hanya kalau `dipercaya_akhir` ≥ 0,7, dibongkar −5 − heboh_total), kredibilitas yang sudah 0 tidak bisa naik lagi: `dipercaya_akhir` tertahan di ≤ 0,5 sehingga syarat +1 mustahil, sementara pembongkaran terus memotong. Bot balancing terjebak di kredibilitas 0 sejak menit 10–15 di separuh sesi. Sekarang +1 dihitung dari dipercaya dasar (rumor dari kartu kredibel memulihkan nama baik), hukuman heboh dikali 0,5, dan kredibilitas di bawah 50 pulih pelan sendiri.

Heat dan kredibilitas berada di 0–100; kredibilitas mulai di 50. Ambang event: E05 Wartawan di heat ≥ 40, E03 Pembongkar Fakta di heat ≥ 70, E09 Razia Hoaks di kredibilitas < 30 (lihat [EVENT.md](../versi/1.0.0/event/EVENT.md)).

Contoh: headline heboh 8 dengan `dipercaya_akhir` 0,4 menambah heat ±9 dan punya peluang bongkar ±0,26 saat heat 20. Headline heboh 3 dengan `dipercaya_akhir` 0,9 hanya menambah ±2 dengan peluang bongkar ±0,04. Rumor heboh menyebar cepat tapi mahal; rumor kredibel lambat tapi aman.

### Saluran, pengikut, misi, mutasi (MVP)

| Sistem | Aturan |
| --- | --- |
| Merpati | Gratis. Satu distrik pilihan, 1–3 warga awal |
| Koran | 30 uang per kiriman. Semua distrik sekaligus, 2 warga awal per distrik, heat ×1,3. Terbuka di 100 pengikut |
| Pengikut | +1 per 12 warga percaya dari rumor yang **tidak** dibongkar; +3 per mutasi. Tidak dibelanjakan: mencapai ambang membuka hal baru (100 → Koran, 300 → E04 di 0.3.0) |
| Misi | Lima misi berurutan, sekaligus tutorial ringan: kirim rumor pertama (+20 uang), yakinkan 20 warga sekaligus (+30), beli 2 kata (+30), kirim rumor *takut* ke Gang Sempit (+40), capai 100 pengikut (+50, Koran terbuka). Isi di `data/missions.json` |
| Mutasi | Setiap warga yang tertular punya peluang 2% memicu mutasi: satu kata diganti kata lain dari slot yang sama (dari semua kata). Versi mutasi tampil di feed dan memberi +3 pengikut; skor rumor tidak berubah |

### Era 2: kantor (0.3.0)

| Sistem | Aturan |
| --- | --- |
| Naik era | Tombol **Sewa Kantor** di toko muncul setelah 180 pengikut; harga 350 uang (0.6.0; awalnya 200/400), sekali beli. Efek: era = 2, latar meja kantor, dan isi era 2 terbuka (radio, staf, kata dan template baru, event era 2) |
| Radio | 60 uang per kiriman, terbuka di era 2, heat ×1,2. Siaran 10 detik: tiap 2 detik satu warga di setiap distrik langsung mendengar (total 5 × 3 = 15 warga awal), jadi rumor sulit padam |
| Staf otomatis | Rekrut 250 uang di era 2, maksimal 1 staf di 0.3.0. Tiap 40 detik staf mengirim rumor kecil dari kartu milik pemain secara acak lewat Merpati. Rumor ini **tidak** disimulasikan di peta: warga percaya ≈ 8 × dipercaya × cocok_emosi, lalu uang, heat (×0,7), dan peluang dibongkar dihitung seperti biasa; hasilnya tampil di feed sebagai "Staf: …". Rumus tertutup yang sama dipakai untuk penghasilan offline (0.6.0) |
| Event dilema | Banner berisi dua pilihan; `GameClock.jeda(&"dilema")` sampai pemain memilih (ADR-0003) |

### Era 3: gedung media (0.4.0)

| Sistem | Aturan |
| --- | --- |
| Naik era | Upgrade **Gedung Media** di toko: 400 pengikut, 1.800 uang (disetel ulang di 0.6.0 untuk target Era 3 ±menit 18). Membuka medsos, kontrak kampanye, kata dan template era 3, serta 3 distrik baru |
| Peta meluas | Peta tetap satu layar, 3 → 6 distrik (2 kolom × 3 baris): Perumahan Elit (iri), Kampus (lucu), Pelabuhan (takut). Warga ±105 → ±200. Status warga lama dipertahankan saat peta ditata ulang |
| Medsos | 100 uang per kiriman, heat ×1,5, 2 warga awal di satu distrik pilihan. Selama rumor medsos aktif, tiap penular juga mencoba menulari 2 "teman online" acak di mana pun di kota, sehingga rumor melompat antar distrik |
| Kontrak kampanye | Tawaran klien fiktif tiap ±4 menit (bisa ditolak; waktu dijeda selama tawaran tampil): yakinkan 50% warga di 2 distrik dalam 3 menit. Berhasil: +600 uang, +60 pengikut. Gagal: kredibilitas −10. Maksimal satu kontrak aktif |
| E07 Dokumen Bocor | Kartu SUMBER "dokumen bocor" (kred 3) masuk ke tangan untuk 3 rumor, lalu hilang |
| E08 Viral Challenge | Headline beremosi lucu viral ×2 di semua distrik, tapi kredibilitas setiap kartu −1 selama event |
| E09 Razia Hoaks | Ancaman saat kredibilitas < 30: medsos dikunci 90 detik, pengikut −5% |

### Era 4: menara server (0.5.0)

| Sistem | Aturan |
| --- | --- |
| Naik era | Upgrade **Menara Server**: 700 pengikut, 2.200 uang (disetel ulang di 0.6.0 untuk target Era 4 ±menit 30). Membuka saluran server, tokoh target, kata dan template era 4, serta 2 distrik baru |
| Peta meluas | 6 → 8 distrik (2 kolom × 4 baris): Pusat Kota dan Kawasan Industri, keduanya beremosi marah (emosi yang belum punya distrik). Warga ±260 |
| Server (jaringan bot) | 200 uang per kiriman, heat ×2, terbuka di Era 4. Selama 15 detik, tiap detik satu warga acak di mana pun di kota langsung percaya (15 total), ditambah lompatan 2 seperti Medsos |
| Tokoh target | Tiga tokoh fiktif masuk ke tangan sebagai kartu SUBJEK khusus saat Era 4 dimulai. Masing-masing punya reputasi 1.000 (0.6.0; dengan 100, satu rumor server menjatuhkan satu tokoh); tiap rumor tentang tokoh yang **tidak** dibongkar mengurangi reputasinya sebanyak warga yang percaya. Di 0 tokoh jatuh: +2.000 uang, +200 pengikut. Ketiganya jatuh = syarat kampanye akhir (0.6.0). Staf tidak memakai kartu tokoh |
| Pertahanan tokoh | **Pak Hartono** (wali kota fiktif) — *Pengacara*: rumor tentang dia dengan dipercaya < 60% otomatis dibongkar. **Bu Sasmita** (direktur bank fiktif) — *Humas*: heat ×2 untuk rumor tentang dia. **Juragan Bramantyo** (raja media fiktif) — *Media sendiri*: setiap rumor tentang dia memicu E10 Rumor Tandingan |
| E10 Rumor Tandingan | Ancaman acak (Era 3+): media saingan membuat 40% warga yang percaya di distrik dengan pemercaya terbanyak menjadi ragu |
| E11 Server Down | Dilema acak (Era 4): bayar perbaikan cepat (400 uang), atau biarkan sehingga staf otomatis dan saluran server mati 120 detik |

Peluang "per detik simulasi" dihitung per tick sebagai `peluang × SIM_TICK` ([ADR-0003](../architecture/adr-0003-model-waktu.md)).

### Kampanye akhir dan ending (0.6.0)

| Sistem | Aturan |
| --- | --- |
| Syarat | Setelah ketiga tokoh jatuh, tombol **Kampanye Akhir** muncul di HUD. Pemain sendiri yang menekannya (tidak bisa saat waktu dijeda) |
| E12 Kota Tak Percaya Lagi | Saat mulai, kota diseragamkan: semua warga jadi ragu, lalu 5% warga acak langsung kebal. Jadi tiap balapan mulai dari kondisi yang sama, berapa pun pemercaya sebelumnya (kalau hanya pemercaya yang jadi ragu, pemain yang sudah meyakinkan banyak warga justru dapat balapan lebih sulit). Selama balapan peluang percaya dikali 0,75, kebal tidak pulih, dan tiap 10 detik tiap warga kebal menulari satu tetangga acak (peluang 50%) yang belum dengar atau ragu; pemercaya tidak bisa ditulari |
| Menang / kalah | Menang: 60% warga kota percaya sekaligus. Kalah: 5 menit habis, atau 50% warga kebal |
| Selama balapan | Event acak, ancaman, dan kontrak berhenti; kontrak yang berjalan batal. Staf tetap bekerja. Progres di HUD: percaya %, kebal %, sisa waktu |
| Ending | Menang: **Imperium Kabar Burung**. Kalah: **Kota Mati Rasa**. Layar berisi epilog satir (`data/endings.json`) dan statistik (rumor, uang, tokoh jatuh, dibongkar, waktu main, rumor terbaik), lalu [Mulai Baru] (tekan dua kali; menghapus progres) atau [Lanjut Bermain]. Waktu dijeda selama layar tampil |
| Setelah ending | Lanjut bermain bebas. Setelah kalah, kampanye akhir bisa dicoba lagi dan mulai dari kondisi yang sama. Setelah menang, tombolnya hilang |
| Simpan | Hasil terakhir (`hasil_akhir`) disimpan; balapan yang sedang berjalan tidak (seperti kontrak, ADR-0003). Kalau aplikasi tertutup di tengah balapan, tombol muncul lagi |

### Penghasilan offline (0.6.0)

Saat memuat save, staf dianggap bekerja selama aplikasi tertutup ([ADR-0003](../architecture/adr-0003-model-waktu.md)):

```
laju (uang/detik) = warga_dasar_staf × 0,6 × UANG_PER_WARGA / jeda_staf     (0 tanpa staf)
detik_offline     = clamp(sekarang − disimpan_unix, 0, 28.800)                (maks 8 jam)
uang_offline      = floor(laju × detik_offline × 0,5)
```

Dengan staf awal (8 warga, 40 detik) lajunya ±0,24 uang/detik: pergi 1 jam memberi ±430 uang, 8 jam atau lebih ±3.450. Heat, kredibilitas, dan pengikut tidak berubah. Hasilnya tampil sekali di feed.

### Ritme dan spreadsheet balancing (0.6.0)

Target satu perjalanan penuh ±60 menit: Era 2 ±menit 8, Era 3 ±18, Era 4 ±30, kampanye akhir ±50–60. Ritme diukur dengan bot `tools/sesi_bot.gd` (8 sesi × 70 menit waktu simulasi); hasil terakhir dicatat di CHANGELOG.

Semua angka balancing ada di `balancing/angka.csv` (kunci, nilai, catatan; pecahan seperti `1/60` boleh) dan harga di `balancing/harga.csv` (id, jenis, harga, pengikut_min, catatan). Kolom harga berarti harga beli untuk kata, template, dan upgrade, biaya kirim untuk saluran, dan reputasi awal untuk tokoh. Alurnya:

```
edit balancing/*.csv  →  godot --headless --path . -s res://tools/terapkan_balancing.gd
                      →  data/balance.json + harga di data/*.json  →  jalankan bot / tes
```

Kode tetap memakai `Balance.X`; nilainya dibaca dari `data/balance.json` saat class dimuat. Jangan ubah `data/balance.json` atau harga di `data/*.json` langsung: tes `test_final.gd` memeriksa keduanya sinkron dengan CSV.
