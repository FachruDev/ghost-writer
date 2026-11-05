# Ghostwriter — Roadmap v1.0.0

Per 5 November 2026 · Godot 4.7 · Android · Portrait

Roadmap ini menjawab *apa urutannya* dan *kapan lanjut*. Desain game ada di [konsep-game.md](../../../panduan/konsep-game.md), struktur kode di [struktur-project.md](../../../panduan/struktur-project.md), dan semua daftar centang di [CHECKLIST.md](CHECKLIST.md).

## Gambaran fase

| Fase | Versi | Minggu | Hasil | Gerbang untuk lanjut |
| --- | --- | --- | --- | --- |
| 0. Setup | — | 0 | Project kosong jalan di PC dan HP | Build debug terpasang di HP |
| 1. Prototipe | 0.1.0 | 1 | Racik headline + rumor menyebar di peta | Seru dimainkan 10 menit tanpa art? |
| 2. MVP | 0.2.0 | 2–4 | Core loop lengkap ±15 menit main, 3 event, suara & animasi dasar | 3–5 teman main sampai habis tanpa dijelaskan |
| 3. Konten & progresi | 0.3.0–0.6.0 | 5–8 | 4 era, ±150 kata, saluran lengkap, 12 event, ending | Satu sesi progresi penuh terasa tidak membosankan |
| 4. Save & polish | 0.9.0 | 9–10 | Save, tutorial, art & ikon final, opsi suara | Tidak ada bug fatal di 2+ HP berbeda |
| 5. Rilis v1 | 1.0.0 | 11–12+ | AAB di Play Store | Lolos closed testing & review |

Rincian per versi ada di [README.md](../README.md); perubahan yang sudah dikerjakan dicatat di `CHANGELOG.md` di root project.

## Gerbang keputusan prototipe

Dipakai di akhir 0.1.0. Ini keputusan terpenting di seluruh roadmap: jangan lanjut ke MVP kalau inti permainannya belum seru tanpa art.

| Hasil | Tindakan |
| --- | --- |
| Seru walau tanpa art | Lanjut ke Fase 2 |
| Lumayan, tapi ada yang kurang | Ubah 1 hal (misalnya tambah mutasi atau target misi), uji 2–3 hari lagi |
| Membosankan setelah 3 menit | Jangan dipaksa. Simpan, coba sudut lain dari konsep, atau ganti ide |

## Di luar scope v1

Semua ini dicatat di [daftar ide 2.0.0](../../2.0.0/IDE.md).

- Iklan dan pembelian dalam aplikasi
- Leaderboard online, cloud save, multiplayer
- Bahasa selain Indonesia dan Inggris
- Versi PC/Steam
- Konten yang menyinggung tokoh atau partai nyata (tidak akan pernah)

## Risiko

| Risiko | Tanda | Penanganan |
| --- | --- | --- |
| Scope membengkak | Menambah fitur sebelum yang lama selesai | Setiap ide baru masuk ke [IDE.md](../../2.0.0/IDE.md), bukan langsung dikerjakan |
| Core loop ternyata tidak seru | Bosan sendiri di prototipe | Gerbang keputusan Fase 1; berani ubah atau buang |
| Balancing berantakan | Pemain macet atau terlalu cepat kaya | Semua angka di `balance.gd`/spreadsheet; uji ritme unlock |
| Tema sensitif | Mirip tokoh atau isu nyata | Semua fiktif, nada satir, konsekuensi selalu ada |
| Motivasi turun | Berhari-hari tidak commit | Target kecil harian; tunjukkan progres ke teman tiap minggu |
| Terhambat closed testing | Tester kurang dari 12 | Kumpulkan tester sejak Fase 2 |

## Tips kerja

- Commit kecil setiap hari, meski hanya satu fungsi.
- Selesaikan satu fase sebelum menyentuh fase berikutnya.
- Rekam layar gameplay tiap minggu; berguna untuk motivasi dan nanti untuk promosi.
- Kalau ragu antara dua pilihan desain, buat versi tercepat dari keduanya dan mainkan.
