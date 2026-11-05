# Ghostwriter v1.0.0 — Rencana per versi

Versi 1.0.0 dicapai lewat 7 rilis kecil. Setiap rilis punya cakupan tetap; ide baru di tengah jalan masuk ke rilis berikutnya atau ke [daftar ide 2.0.0](../2.0.0/IDE.md), bukan langsung dikerjakan.

| Versi | Fase | Mekanik & sistem | Event | Suara & musik | Animasi | Gambar & ikon |
| --- | --- | --- | --- | --- | --- | --- |
| 0.1.0 | Prototipe | Racik headline, skor rumor, 3 distrik, penyebaran, uang, toko sederhana | — | — | — | Kotak abu-abu |
| 0.2.0 | MVP | Kredibilitas, heat, kebal, mutasi, feed, pengikut, 2 saluran, misi | E01, E02, E03 | 9 SFX inti, musik era 1 | Mesin tik, kartu ke slot, denyut warga, uang melayang, banner, stempel | Ikon emosi, mata uang, saluran awal, ikon app sementara |
| 0.3.0 | Konten: era kantor | Era 2, radio, staf otomatis pertama, ±80 kata | E04, E05, E06 | SFX toko, error, telepon; musik era 2 | Kirim kertas, mutasi, toko, tombol | Art meja era 1–2, kartu, peta, panel UI |
| 0.4.0 | Konten: era gedung media | Era 3, medsos, kampanye multi-distrik, ±120 kata | E07, E08, E09 | SFX medsos; musik era 3 + lapisan ancaman | Staf bekerja | Art meja era 3, distrik 4–6 |
| 0.5.0 | Konten: era server | Era 4, server, tokoh fiktif target besar, ±150 kata | E10, E11 | Ambience server, stinger naik era; musik era 4 | Transisi era | Art meja era 4, distrik 7–8 |
| 0.6.0 | Ending & balancing | Kampanye akhir, ending, penghasilan offline, balancing via spreadsheet | E12 | Musik ending | Ending | Art ending |
| 0.9.0 | Beta & polish | Save/load, tutorial, pengaturan, safe area, uji 2+ HP | — | Musik menu, opsi suara/getar | Tangan tutorial, rapikan semua | Ikon app final, layar judul, splash |
| 1.0.0 | Rilis | AAB API 36, closed testing 14 hari, Play Store | — | — | — | Aset Play Store |

## Dokumen di folder ini

| File | Isi |
| --- | --- |
| [mvp/mvp-v1.md](mvp/mvp-v1.md) | Roadmap: fase, gerbang keputusan, scope, risiko |
| [mvp/CHECKLIST.md](mvp/CHECKLIST.md) | Checklist semua versi, dari setup sampai 1.0.0 |
| [event/EVENT.md](event/EVENT.md) | Sistem event dan 12 event v1 |
| [aset/suara.md](aset/suara.md) | Daftar SFX |
| [aset/musik.md](aset/musik.md) | Daftar musik |
| [aset/animasi.md](aset/animasi.md) | Daftar animasi |
| [aset/gambar.md](aset/gambar.md) | Panduan gaya, art, aset Play Store |
| [aset/ikon.md](aset/ikon.md) | Ikon aplikasi dan ikon dalam game |

Konsep game, struktur project, panduan rilis, dan konvensi penamaan ada di [`docs/panduan`](../../panduan/).

## Cara melacak perubahan

1. Rencana ada di tabel di atas dan di dokumen per kategori (kolom **Versi** + **Status**).
2. Yang **benar-benar** dikerjakan dicatat di [`CHANGELOG.md`](../../../CHANGELOG.md) di root project, per versi, dengan kategori Ditambah / Diubah / Diperbaiki / Dihapus.
3. Saat satu versi selesai: ubah `[Belum dirilis]` di CHANGELOG menjadi nomor versi + tanggal, naikkan `config/version` di Project Settings, dan buat git tag (misalnya `v0.2.0`).
