# Musik — Ghostwriter v1.0.0

Musik disimpan di `res://assets/music/` sebagai `.ogg` dengan **loop aktif** di pengaturan import. Diputar lewat bus **Music**. Tiap era punya suasana sendiri supaya kenaikan era terasa.

| ID | Dipakai di | Suasana | Durasi loop | Versi | Sumber / lisensi | Status |
| --- | --- | --- | --- | --- | --- | --- |
| mus_era1_kamar | Era 1 (kamar) | Lo-fi jazz tenang, piano + ketukan pelan | 1–2 menit | 0.2.0 | OpenGameArt chill-lofi-inspired (omfgdude), CC0, sementara | Selesai |
| mus_era2_kantor | Era 2 (kantor kecil) | Jazz lebih sibuk, sedikit tegang | 1–2 menit | 0.3.0 | OpenGameArt lofi-compilation Cue (TAD), CC0, sementara | Selesai |
| mus_era3_gedung | Era 3 (gedung media) | Elektronik ringan, ritme cepat | 1–2 menit | 0.4.0 | OpenGameArt Cyberpunk Moonlight Sonata v2 (Joth), CC0, sementara | Selesai |
| mus_era4_server | Era 4 (menara server) | Synth dingin, megah, sedikit gelap | 1–2 menit | 0.5.0 | OpenGameArt Calm Relax 1 Synthwave, lifewave (cynicmusic), CC0, sementara | Selesai |
| mus_threat | Saat ancaman aktif (termasuk E12) | Lapisan tegang di atas musik era, masuk/keluar pelan 1,5 detik | 24 detik | 0.4.0 | OpenGameArt Panic mode, panic.ogg (Bread), CC0, sementara; 372 KB | Selesai |
| mus_ending | Layar ending | Sepi dan satir | 1 menit, tidak loop | 0.6.0 | OpenGameArt 4 Music Box Tracks, musicbox3_sad_tune (Aureolus_Omicron), CC0, sementara; 2:36 | Selesai |
| mus_menu | Menu utama (layar judul) | Versi pelan dari tema era 1 | 1 menit | 0.9.0 | OpenGameArt Lofi again (omfgdude, komposer yang sama dengan era 1), CC0, sementara; ±80 detik, mono, 2,4 MB | Selesai |

**Aturan**

- Pergantian musik pakai crossfade 1–2 detik (Tween pada volume bus atau dua `AudioStreamPlayer`).
- Musik default lebih pelan dari SFX (misalnya −8 dB).
- Catat lisensi tiap lagu; kredit komposer di layar Tentang (0.9.0).
