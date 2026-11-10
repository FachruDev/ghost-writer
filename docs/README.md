# Dokumentasi — Ghostwriter

Game satir portrait untuk Android: racik rumor dari kartu kata, lihat rumornya menyebar di kota fiktif, lalu tumbuh dari mesin tik tua menjadi imperium media. Dibuat dengan Godot 4.7.

## Mulai dari mana

1. Pahami game-nya di [konsep-game.md](panduan/konsep-game.md).
2. Lihat urutan kerja di [roadmap v1.0.0](versi/1.0.0/mvp/mvp-v1.md).
3. Kerjakan [checklist](versi/1.0.0/mvp/CHECKLIST.md) versi yang sedang berjalan.
4. Catat yang sudah selesai di [CHANGELOG.md](../CHANGELOG.md).

## Isi

| Dokumen | Isi | Kapan dibuka |
| --- | --- | --- |
| [panduan/konsep-game.md](panduan/konsep-game.md) | Keputusan teknis, prinsip, core loop, sistem, rumus | Saat merancang atau ragu soal aturan game |
| [panduan/struktur-project.md](panduan/struktur-project.md) | Folder, autoload, layout layar, format data JSON | Saat menulis kode atau menambah data |
| [panduan/konvensi.md](panduan/konvensi.md) | Penomoran versi, ID aset, status, git | Saat menambah aset, event, atau merilis |
| [panduan/rilis-android.md](panduan/rilis-android.md) | Build AAB, Play Console, closed testing | Menjelang 1.0.0 (sebagian disiapkan lebih awal) |
| [versi/1.0.0/README.md](versi/1.0.0/README.md) | Isi setiap rilis 0.1.0 sampai 1.0.0 | Saat memulai versi baru |
| [versi/1.0.0/mvp/mvp-v1.md](versi/1.0.0/mvp/mvp-v1.md) | Fase, gerbang keputusan, scope, risiko | Saat menentukan lanjut atau tidak |
| [versi/1.0.0/mvp/CHECKLIST.md](versi/1.0.0/mvp/CHECKLIST.md) | Daftar centang semua versi | Setiap hari kerja |
| [versi/1.0.0/event/EVENT.md](versi/1.0.0/event/EVENT.md) | Sistem event dan 14 event v1 | Saat membuat atau menyeimbangkan event |
| [versi/1.0.0/aset/](versi/1.0.0/aset/) | Daftar suara, musik, animasi, gambar, ikon | Saat membuat atau mencari aset |
| [versi/2.0.0/IDE.md](versi/2.0.0/IDE.md) | Tempat parkir ide setelah v1 | Setiap muncul ide baru di tengah jalan |
| [../CHANGELOG.md](../CHANGELOG.md) | Apa yang benar-benar berubah per versi | Setiap selesai mengerjakan sesuatu |

## Aturan sederhana

- Setiap informasi hanya ditulis di satu tempat; dokumen lain cukup menautkannya.
- **Rencana** ada di `docs/versi/`, **yang sudah dikerjakan** ada di `CHANGELOG.md`.
- Ide baru tidak langsung dikerjakan: tulis dulu di `versi/2.0.0/IDE.md`.
