# Musik — Ghostwriter v1.0.0

Musik disimpan di `res://assets/music/` sebagai `.ogg` dengan **loop aktif** di pengaturan import. Diputar lewat bus **Music**. Tiap era punya suasana sendiri supaya kenaikan era terasa.

| ID | Dipakai di | Suasana | Durasi loop | Versi | Sumber / lisensi | Status |
| --- | --- | --- | --- | --- | --- | --- |
| mus_era1_kamar | Era 1 (kamar) | Lo-fi jazz tenang, piano + ketukan pelan | 1–2 menit | 0.2.0 | OpenGameArt chill-lofi-inspired (omfgdude), CC0, sementara | Selesai |
| mus_era2_kantor | Era 2 (kantor kecil) | Jazz lebih sibuk, sedikit tegang | 1–2 menit | 0.3.0 | | Belum |
| mus_era3_gedung | Era 3 (gedung media) | Elektronik ringan, ritme cepat | 1–2 menit | 0.4.0 | | Belum |
| mus_era4_server | Era 4 (menara server) | Synth dingin, megah, sedikit gelap | 1–2 menit | 0.5.0 | | Belum |
| mus_threat | Saat ancaman besar aktif | Lapisan tegang di atas musik era | 30–60 detik | 0.4.0 | | Belum |
| mus_ending | Layar ending | Sepi dan satir | 1 menit, tidak loop | 0.6.0 | | Belum |
| mus_menu | Menu utama | Versi pelan dari tema era 1 | 1 menit | 0.9.0 | | Belum |

**Aturan**

- Pergantian musik pakai crossfade 1–2 detik (Tween pada volume bus atau dua `AudioStreamPlayer`).
- Musik default lebih pelan dari SFX (misalnya −8 dB).
- Catat lisensi tiap lagu; kredit komposer di layar Tentang (0.9.0).
