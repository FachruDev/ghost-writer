# Suara (SFX) — Ghostwriter v1.0.0

SFX pendek disimpan di `res://assets/sfx/` sebagai `.wav` (latensi rendah). Semua diputar lewat bus **SFX**. Prioritas MVP: suara yang terdengar setiap putaran (mengetik, kartu, kirim, uang).

| ID | Kapan diputar | Catatan | Versi | Sumber / lisensi | Status |
| --- | --- | --- | --- | --- | --- |
| sfx_type_key_1..3 | Tiap huruf headline diketik | 3 variasi diacak supaya tidak monoton; pitch ±5% | 0.2.0 | OpenGameArt typewriter-sounds (Cassie-OrbitGames), CC0, sementara | Selesai |
| sfx_type_bell | Headline selesai diketik | Bel mesin tik | 0.2.0 | OpenGameArt SoundPack01 Coin01 (wobbleboxx), CC0, sementara | Selesai |
| sfx_card_pick | Kartu diambil dari tangan | Gesekan kertas pendek | 0.2.0 | Kenney RPG sounds bookFlip1, CC0, sementara | Selesai |
| sfx_card_place | Kartu masuk ke slot | Bunyi "tak" ringan | 0.2.0 | Kenney RPG sounds bookPlace1, CC0, sementara | Selesai |
| sfx_send | Tombol KIRIM | Kertas dilipat / sayap merpati | 0.2.0 | Kenney RPG sounds cloth1, CC0, sementara | Selesai |
| sfx_coin | Uang masuk | Volume kecil, dibatasi maks 4 per detik | 0.2.0 | Kenney RPG sounds handleCoins, CC0, sementara | Selesai |
| sfx_debunk_stamp | Pembongkar fakta mengecap HOAKS | Stempel keras | 0.2.0 | Kenney RPG sounds chop, CC0, sementara | Selesai |
| sfx_event_alert | Banner event muncul | Beda nada untuk modifier vs ancaman | 0.2.0 | OpenGameArt SoundPack01 Rise01 / Alarm (wobbleboxx), CC0, sementara | Selesai |
| sfx_ui_click | Tombol UI umum | | 0.2.0 | Kenney UI SFX click3, CC0, sementara | Selesai |
| sfx_carriage_return | Ganti template / reset meja | | 0.3.0 | Kenney RPG sounds metalLatch, CC0, sementara | Selesai |
| sfx_follower_up | Pengikut naik milestone | | 0.3.0 | OpenGameArt SoundPack01 Rise03 (wobbleboxx), CC0, sementara | Selesai |
| sfx_buy | Beli di toko | | 0.3.0 | Kenney RPG sounds handleCoins2, CC0, sementara | Selesai |
| sfx_error | Aksi tidak bisa (uang kurang, slot kosong) | | 0.3.0 | Kenney RPG sounds metalClick, CC0, sementara | Selesai |
| sfx_dilemma_choice | Memilih opsi event dilema | | 0.3.0 | Kenney UI SFX switch3, CC0, sementara | Selesai |
| sfx_phone_ring | Event wartawan (era kantor) | | 0.3.0 | | Belum |
| sfx_modem / sfx_notif | Saluran medsos (era gedung) | | 0.4.0 | | Belum |
| sfx_server_hum | Ambience era server | Loop pelan | 0.5.0 | | Belum |
| sfx_era_up | Naik era | Stinger 2–3 detik | 0.5.0 | | Belum |

**Aturan**

- Sumber aman: buat sendiri, atau aset berlisensi **CC0** / lisensi komersial yang jelas. Isi kolom sumber untuk setiap file.
- Normalisasi volume semua SFX ke level yang mirip sebelum dimasukkan.
- Opsi matikan suara dan getar wajib ada di pengaturan (0.9.0).
