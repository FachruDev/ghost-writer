# ADR-0004: Lokalisasi Indonesia dan Inggris

## Status
Accepted

## Date
2026-11-05

## Last Verified
2026-11-05

## Decision Makers
Pengembang (FchDxCode), dengan Claude

## Summary
Ghostwriter v1 harus tampil dalam bahasa Indonesia dan Inggris, dan format teks konten harus ditetapkan sebelum data prototipe ditulis. Diputuskan pendekatan **hibrida**: teks UI lewat CSV terjemahan Godot dan `tr()`, teks konten di JSON dengan field per bahasa (`{"id", "en"}`) dan pola template per bahasa. Save dan riwayat hanya menyimpan ID, dan headline disusun saat ditampilkan.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 |
| **Domain** | UI |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — Godot 4.7 di luar data latih yang andal; fakta di bawah diverifikasi dari dokumentasi 4.7 |
| **References Consulted** | [Internationalizing games](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html), [Localization using spreadsheets](https://docs.godotengine.org/en/4.7/tutorials/i18n/localization_using_spreadsheets.html), [TranslationServer](https://docs.godotengine.org/en/4.7/classes/class_translationserver.html), [Object](https://docs.godotengine.org/en/4.7/classes/class_object.html), [Node](https://docs.godotengine.org/en/4.7/classes/class_node.html) |
| **Post-Cutoff APIs Used** | Kolom `?plural` / baris `?pluralrule` di CSV (sejak 4.6) |
| **Verification Required** | CSV terdaftar di Project Settings > Localization > Translations dan termuat di build Android; `OS.get_locale_language()` mengembalikan `id` di HP berbahasa Indonesia |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (backend save): format riwayat diubah menjadi ID saja |
| **Enables** | None |
| **Blocks** | Penulisan `words.json`, `templates.json`, `districts.json` (0.1.0) dan `events.json` (0.2.0); semua teks UI |
| **Ordering Note** | Format dua bahasa dipakai sejak 0.1.0; teks EN boleh kosong sampai 0.9.0 |

## Context

### Problem Statement
Rencana awal hanya bahasa Indonesia, dengan bahasa Inggris di daftar ide 2.0. Sekarang bahasa Inggris masuk v1. Teks game terbagi dua jenis:
- **Teks UI** (tombol, label, menu): pendek dan tetap.
- **Teks konten** (±150 kata, 12 template, 12 event, distrik): bagian dari lelucon, punya atribut emosi/heboh/kredibilitas, dan template headline yang urutan katanya berbeda per bahasa.

`riwayat_rumor` di ADR-0002 juga masih menyimpan teks headline, sehingga riwayat lama tidak ikut berganti bahasa.

### Constraints
- Satire perlu dilokalkan, bukan diterjemahkan harfiah ("Pak RT", "ronda malam")
- Konten dan angka masih sering berubah selama prototipe dan MVP
- Dikerjakan solo; jumlah teks yang ditulis berlipat dua

### Requirements
- Pemain bisa berganti bahasa kapan saja tanpa merusak save
- Headline harus gramatikal di kedua bahasa
- Teks yang belum diterjemahkan tidak boleh membuat crash atau layar kosong
- Kartu dan banner harus muat untuk teks bahasa Inggris yang lebih panjang

## Decision

### Teks UI: CSV terjemahan Godot

`res://localization/ui.csv`, UTF-8 tanpa BOM:

```csv
keys,id,en
UI_KIRIM,KIRIM,SEND
UI_TOKO,Toko,Shop
?pluralrule,nplurals=1; plural=0;,nplurals=2; plural=(n != 1);
UI_PENGIKUT,%d pengikut,%d follower
?plural,,%d followers
```

- Didaftarkan di Project Settings > Localization > Translations.
- Label dan Button berisi kunci (`UI_KIRIM`) diterjemahkan otomatis.
- Teks dinamis memakai `tr()`; teks dengan jumlah memakai `tr_n()`. Terjemahan otomatis Control tidak mendukung bentuk jamak.
- `internationalization/locale/fallback` = `id`.

Catatan: format kolom `?plural` di atas mengikuti dokumen spreadsheet 4.7. Cek ulang di editor saat file pertama dibuat.

### Teks konten: JSON dengan field per bahasa

Setiap field teks yang tampil ke pemain berupa dictionary per bahasa. Atribut angka tetap satu.

```json
{"id": "pak_rt", "slot": "subjek", "emosi": "lucu", "heboh": 1, "kred": 2, "harga": 0,
 "text": {"id": "Pak RT", "en": "the Neighborhood Chief"}}
```

```json
{"id": "t_dasar", "slot": ["subjek", "aksi", "tempat", "sumber"], "pengali_heboh": 1.0, "unlock": 0,
 "pola": {"id": "{subjek} ketahuan {aksi} di {tempat}, kata {sumber}!",
          "en": "{sumber} says {subjek} was caught {aksi} at {tempat}!"}}
```

- Nama slot sama di semua bahasa; hanya pola dan urutannya yang berbeda.
- Event: `nama`, `teks`, dan `pilihan[].label` juga dictionary per bahasa. Distrik: `nama`.
- Kata AKSI bahasa Inggris ditulis dalam bentuk yang pas dengan semua template EN (misalnya frasa *-ing*: "dancing at midnight").

### Autoload `Bahasa`

```gdscript
# scripts/autoload/bahasa.gd  (autoload: Bahasa)
signal bahasa_berubah(kode: String)

const DIDUKUNG := ["id", "en"]
const CADANGAN := "id"

func kode() -> String                       # bahasa aktif
func atur(kode_baru: String) -> void        # TranslationServer.set_locale + simpan ke settings.cfg + emit
func teks(field: Variant) -> String         # Dictionary {"id","en"} → teks bahasa aktif, cadangan ke "id"
func angka(n: int) -> String                # pemisah ribuan: "1.000" (id) / "1,000" (en)
```

Penyusunan headline ada di script terpisah supaya `Bahasa` tetap kecil:

```gdscript
# scripts/systems/headline_builder.gd
static func susun(template_id: String, kata_ids: Dictionary) -> String
# kata_ids: {"subjek": "pak_rt", "aksi": "menari_malam", ...}
```

### Pemilihan bahasa

- Pertama kali dibuka: `OS.get_locale_language() == "id"` → `id`, selain itu → `en`.
- Pilihan disimpan di `user://settings.cfg` (kunci `bahasa`); reset progres tidak menghapusnya.
- Pengaturan bahasa ada di layar pengaturan; berlaku langsung tanpa restart.

### ID saja di save, riwayat, dan feed

- `riwayat_rumor` (ADR-0002) menyimpan `template_id` dan `kata_ids` saja; tidak ada kolom teks headline.
- Hasil mutasi menyimpan ID kata pengganti, sehingga tetap bisa ditampilkan di kedua bahasa.
- Feed dan layar ending menyusun headline lewat `headline_builder.susun()` saat ditampilkan.

### Implementation Guidelines
- Teks yang tampil ke pemain **must never** ditulis langsung di kode atau scene; UI lewat kunci CSV, konten lewat field per bahasa di JSON.
- Teks konten **must** diambil lewat `Bahasa.teks()`; **must never** membaca `field["id"]` atau `field["en"]` langsung.
- `Bahasa.teks()` **must** jatuh ke `id` kalau `en` kosong atau tidak ada, dan memberi `push_warning` di build debug.
- Field `id` **must** selalu terisi; field `en` boleh kosong sampai 0.9.0.
- Scene yang menampilkan teks konten **must** memperbarui teksnya saat `Bahasa.bahasa_berubah` (atau `NOTIFICATION_TRANSLATION_CHANGED` untuk Control).
- Save, riwayat, dan feed **must** menyimpan ID, **must never** teks yang sudah diterjemahkan.
- Angka uang dan pengikut **must** diformat lewat `Bahasa.angka()`.
- Teks dengan jumlah di UI **must** memakai `tr_n()`.
- Tes headless **must** memeriksa: setiap field teks punya `id` yang tidak kosong, setiap pola memakai slot yang sama dengan daftar `slot`-nya, dan jumlah field `en` yang kosong. Mulai 0.9.0, `en` kosong = tes gagal.

## Alternatives Considered

- **Semua teks di CSV Godot** — satu jalur terjemahan, pseudolokalisasi dan jamak bawaan. Ditolak: teks kata terpisah dari atribut emosi/heboh/kredibilitasnya, jadi penulis kehilangan konteks lelucon dan harus menyunting dua file untuk satu kartu.
- **File konten terpisah per bahasa** (`data/id/`, `data/en/`) — tiap file bersih satu bahasa. Ditolak: atribut angka terduplikasi di dua file dan bisa tidak sinkron saat balancing.

## Consequences

### Positive
- Ganti bahasa tidak menyentuh save; riwayat lama ikut berganti bahasa
- Penulis melihat teks kedua bahasa di samping atribut leluconnya
- UI memakai fitur bawaan Godot (terjemahan otomatis, jamak, pseudolokalisasi)
- Teks EN bisa ditunda tanpa membuat game rusak

### Negative
- Dua mekanisme terjemahan (CSV untuk UI, JSON untuk konten)
- Pekerjaan menulis berlipat dua: ±150 kata, 12 template, 12 event, teks UI
- Template EN dan kata AKSI EN harus saling cocok secara tata bahasa

## Risks
- **Lelucon tidak lucu dalam bahasa Inggris.** Mitigasi: lokalkan, jangan terjemahkan harfiah; minta 1–2 tester berbahasa Inggris di closed testing.
- **Teks EN lebih panjang dan tidak muat di kartu.** Mitigasi: aktifkan `internationalization/pseudolocalization/use_pseudolocalization` untuk UI; uji kartu dengan kata EN terpanjang.
- **Kata AKSI EN tidak cocok dengan salah satu template EN.** Mitigasi: setiap template EN memakai bentuk slot yang sama; tes headless menyusun semua kombinasi template × satu kata per slot dan mencatatnya untuk dibaca.
- **Beban menulis menekan jadwal Fase 3.** Mitigasi: EN ditulis setelah konten tiap versi stabil, lengkap di 0.9.0.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| konsep-game.md (belum ada GDD) | Semua teks di file data supaya mudah diterjemahkan | UI di CSV, konten di JSON per bahasa |
| konsep-game.md | Template headline dengan slot | Pola per bahasa, nama slot sama |
| konsep-game.md | Mutasi mengganti satu kata | Mutasi menyimpan ID kata, tampil di kedua bahasa |
| CHECKLIST.md 0.9.0 | Pengaturan bahasa | `Bahasa.atur()`, disimpan di `settings.cfg` |
| ADR-0002 | Save hanya menyimpan ID konten | Riwayat juga menyimpan ID, bukan teks headline |

## Performance Implications
- **CPU**: Headline disusun saat ditampilkan; satu `format()` per baris feed
- **Memory**: Teks dua bahasa di memori, dapat diabaikan
- **Load Time**: Satu CSV tambahan diimpor
- **Network**: Tidak berlaku

## Migration Plan
Belum ada kode. Saat ADR diterima, perbarui:
1. `struktur-project.md`: contoh `words.json`, `templates.json`, `districts.json` memakai field per bahasa; tambah `res://localization/`.
2. `EVENT.md`: format data event memakai field per bahasa.
3. `konsep-game.md`: baris Bahasa menjadi "Indonesia dan Inggris".
4. `mvp-v1.md` dan `IDE.md`: hapus "Bahasa selain Indonesia" / baris Bahasa Inggris dari daftar di luar scope.
5. `CHECKLIST.md` 0.9.0: "Pengaturan: bahasa (Indonesia, Inggris)" dan "Semua teks EN lengkap".

## Validation Criteria
- Ganti bahasa di pengaturan: semua UI, kartu, feed, dan riwayat berganti tanpa restart
- HP berbahasa Indonesia membuka game dalam bahasa Indonesia; HP berbahasa lain dalam bahasa Inggris
- Field `en` yang kosong menampilkan teks Indonesia, bukan kosong atau crash
- Tes headless lulus: semua `id` terisi, slot pola cocok; di 0.9.0 tidak ada `en` kosong
- Kata EN terpanjang muat di kartu pada layar 720×1280

## Related
- [ADR-0002: Backend save](adr-0002-backend-save.md) — riwayat menyimpan ID saja
- [ADR-0003: Model waktu](adr-0003-model-waktu.md) — tidak terkait langsung
- [konsep-game.md](../panduan/konsep-game.md), [struktur-project.md](../panduan/struktur-project.md), [EVENT.md](../versi/1.0.0/event/EVENT.md), [IDE.md](../versi/2.0.0/IDE.md)
