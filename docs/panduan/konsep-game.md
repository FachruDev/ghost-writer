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
  heat −= 0.1                                   (±6 per menit)

Saat rumor selesai menyebar:
  peluang_bongkar = (1 − dipercaya_akhir) × (0.3 + heat / 100 × 0.7)

  Kalau dibongkar:
    kredibilitas −= 5 + heboh_total
    50% warga yang percaya rumor itu → kebal
    heat += 10
    stempel HOAKS di feed; uang yang sudah didapat tetap
  Kalau tidak dibongkar dan dipercaya_akhir ≥ 0.7:
    kredibilitas += 1
```

Heat dan kredibilitas berada di 0–100; kredibilitas mulai di 50. Ambang event: E05 Wartawan di heat ≥ 40, E03 Pembongkar Fakta di heat ≥ 70, E09 Razia Hoaks di kredibilitas < 30 (lihat [EVENT.md](../versi/1.0.0/event/EVENT.md)).

Contoh: headline heboh 8 dengan `dipercaya_akhir` 0,4 menambah heat ±9 dan punya peluang bongkar ±0,26 saat heat 20. Headline heboh 3 dengan `dipercaya_akhir` 0,9 hanya menambah ±2 dengan peluang bongkar ±0,04. Rumor heboh menyebar cepat tapi mahal; rumor kredibel lambat tapi aman.

### Saluran, pengikut, misi, mutasi (MVP)

| Sistem | Aturan |
| --- | --- |
| Merpati | Gratis. Satu distrik pilihan, 1–3 warga awal |
| Koran | 30 uang per kiriman. Semua distrik sekaligus, 2 warga awal per distrik, heat ×1,3. Terbuka di 100 pengikut |
| Pengikut | +1 per 5 warga percaya dari rumor yang **tidak** dibongkar; +3 per mutasi. Tidak dibelanjakan: mencapai ambang membuka hal baru (100 → Koran, 300 → E04 di 0.3.0) |
| Misi | Lima misi berurutan, sekaligus tutorial ringan: kirim rumor pertama (+20 uang), yakinkan 20 warga sekaligus (+30), beli 2 kata (+30), kirim rumor *takut* ke Gang Sempit (+40), capai 100 pengikut (+50, Koran terbuka). Isi di `data/missions.json` |
| Mutasi | Setiap warga yang tertular punya peluang 2% memicu mutasi: satu kata diganti kata lain dari slot yang sama (dari semua kata). Versi mutasi tampil di feed dan memberi +3 pengikut; skor rumor tidak berubah |

Peluang "per detik simulasi" dihitung per tick sebagai `peluang × SIM_TICK` ([ADR-0003](../architecture/adr-0003-model-waktu.md)).

Angka-angka ini hanya titik awal. Taruh semuanya sebagai konstanta di satu file (`balance.gd`) supaya mudah diubah saat playtest.
