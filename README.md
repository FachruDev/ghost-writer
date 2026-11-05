# Ghostwriter

Game satir **portrait untuk Android** tentang kekuatan kabar burung. Kamu mulai sebagai penulis bayangan dengan mesin tik tua di kamar gelap, meracik rumor dari kartu kata, lalu melihatnya menjalar dan bermutasi di sebuah kota fiktif, hingga tumbuh menjadi imperium media dengan ruang server raksasa.

> Semua kota, tokoh, dan partai di game ini fiktif. Setiap rumor punya konsekuensi: kredibilitas turun, pembongkar fakta muncul, dan warga bisa kebal.

## Cara main (rencana)

1. **Racik headline**: isi slot template dengan kartu kata, misalnya *"[Pak RT] ketahuan [menari tengah malam] di [pasar], kata [tetangga]!"*
2. **Kirim** lewat saluran: merpati, koran, radio, medsos, hingga server.
3. **Lihat rumor menyebar** di peta kota. Warga bisa percaya, ragu, atau kebal.
4. **Panen** uang dan pengikut, lalu beli kata, template, dan upgrade baru.
5. Bertahan dari **event**: hari pasar, wartawan penasaran, razia hoaks, dan lainnya.

## Teknologi

| | |
| --- | --- |
| Engine | Godot 4.7, GDScript, renderer Mobile |
| Platform | Android (portrait 720×1280) |
| Konten | JSON di `res://data/` |
| Penyimpanan | SQLite (`user://ghostwriter.db`) via [godot-sqlite](https://github.com/2shady4u/godot-sqlite) |

## Status

Tahap perencanaan, menuju **0.1.0 (prototipe)**. Target rilis pertama di Google Play: **1.0.0**.

## Dokumentasi

Semua rencana dan panduan ada di [`docs/`](docs/README.md):

- [Konsep game](docs/panduan/konsep-game.md)
- [Struktur project & database](docs/panduan/struktur-project.md)
- [Roadmap v1.0.0](docs/versi/1.0.0/mvp/mvp-v1.md) dan [checklist](docs/versi/1.0.0/mvp/CHECKLIST.md)
- [Riwayat perubahan](CHANGELOG.md)
