# Konvensi — Ghostwriter

Aturan penamaan dan pencatatan supaya dokumen, aset, dan kode tetap sinkron.

## Penomoran versi

Format `MAYOR.MINOR.PATCH` ([Semantic Versioning](https://semver.org/lang/id/)).

| Bagian | Naik saat | Contoh |
| --- | --- | --- |
| MAYOR | Rilis besar ke publik | 1.0.0, 2.0.0 |
| MINOR | Satu rilis rencana selesai (fitur/konten baru) | 0.2.0 → 0.3.0 |
| PATCH | Perbaikan bug tanpa fitur baru | 1.0.0 → 1.0.1 |

- Versi `0.x` = belum rilis publik.
- Set di **Project Settings → Application → Config → Version** dan di **Export → Android → Version Name**.
- **Version Code** Android naik +1 setiap kali build diunggah ke Play Console (termasuk build closed testing).

## Status di dokumen

Dipakai di kolom **Status** semua daftar aset dan event.

| Status | Arti |
| --- | --- |
| Belum | Direncanakan, belum dikerjakan |
| Proses | Sedang dikerjakan |
| Selesai | Sudah masuk game dan dicek |
| Batal | Tidak jadi; tulis alasannya singkat di kolom catatan |

## ID dan nama file

Semua ID dan nama file memakai huruf kecil, `snake_case`, tanpa spasi.

| Jenis | Awalan | Contoh | Folder |
| --- | --- | --- | --- |
| Suara (SFX) | `sfx_` | `sfx_type_bell.wav` | `res://assets/sfx/` |
| Musik | `mus_` | `mus_era1_kamar.ogg` | `res://assets/music/` |
| Animasi | `anim_` | `anim_card_to_slot` (nama Tween/animasi) | di scene terkait |
| Gambar & art | `art_` | `art_desk_era1.png` | `res://assets/art/` |
| Ikon | `ic_` | `ic_emo_lucu.svg` | `res://assets/icons/` |
| Event | `e_` (data), `E01` (dokumen) | `e_hari_pasar` | `res://data/events.json` |
| Kata | tanpa awalan | `pak_rt` | `res://data/words.json` |
| Template | `t_` | `t_dasar` | `res://data/templates.json` |
| Distrik | tanpa awalan | `pasar_lama` | `res://data/districts.json` |

Scene dan script memakai `PascalCase` sesuai kebiasaan Godot (`WordCard.tscn`, `RumorScorer.gd`).

## Git

- Commit kecil dan sering. Format pesan: `jenis: ringkasan`, jenis = `tambah`, `ubah`, `perbaiki`, `hapus`, `docs`.
  Contoh: `tambah: event hari pasar`, `ubah: peluang tular 0,02 jadi 0,015`.
- Setiap rilis diberi tag: `v0.1.0`, `v0.2.0`, dst.
- `main` selalu dalam keadaan bisa dijalankan.

## Alur saat menambah sesuatu

1. Tambah baris di dokumen aset/event terkait dengan versi tujuan dan status **Belum**.
2. Saat dikerjakan → **Proses**; saat sudah masuk game dan dicek → **Selesai**.
3. Catat di `CHANGELOG.md` bagian `[Belum dirilis]`.
4. Saat versi selesai: ganti `[Belum dirilis]` jadi `[x.y.z] - tanggal`, naikkan versi di Project Settings, buat git tag.
