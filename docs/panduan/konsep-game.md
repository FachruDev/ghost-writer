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
| Kredibilitas & heat | Rumor yang dibongkar menurunkan kredibilitas. Heat tinggi memunculkan pembongkar fakta yang membuat warga kebal | MVP |
| Saluran | Merpati → koran → radio → medsos → server. Menentukan jangkauan awal dan distrik tujuan | MVP (2 saluran), Fase 3 (sisanya) |
| Staf otomatis | Menulis rumor kecil sendiri supaya pemain fokus ke kampanye besar | Fase 3 |
| Era | Kamar → kantor → gedung media → menara server. Mengubah latar meja dan membuka konten | Fase 3 |

### Rumus awal (untuk dicoba, nanti diseimbangkan)

```
heboh_total   = (jumlah heboh semua kartu) × pengali_heboh_template
kred_rata     = rata-rata kred semua kartu
cocok_emosi   = 1.5 jika emosi dominan kartu = emosi favorit distrik, 1.0 jika netral, 0.6 jika bertentangan

viral         = heboh_total × cocok_emosi
dipercaya     = clamp(kred_rata / 3.0 - max(0, heboh_total - 6) × 0.05, 0.1, 1.0)

peluang_tular (per tetangga, per tick) = viral × kerentanan_distrik × 0.02
peluang_percaya (saat tertular)        = dipercaya
```

Angka-angka ini hanya titik awal. Taruh semuanya sebagai konstanta di satu file (`balance.gd`) supaya mudah diubah saat playtest.
