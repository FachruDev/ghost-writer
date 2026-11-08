# Struktur Project Godot — Ghostwriter

Pisahkan data, logika, dan tampilan sejak awal: konten di JSON, aturan di script sistem tanpa node, scene hanya menampilkan. Menambah kata atau menyeimbangkan angka tidak perlu menyentuh scene.

Keputusan yang mengikat struktur ini ada di [`docs/architecture/`](../architecture/): renderer ([ADR-0001](../architecture/adr-0001-renderer.md)), save ([ADR-0002](../architecture/adr-0002-backend-save.md)), waktu simulasi ([ADR-0003](../architecture/adr-0003-model-waktu.md)), dan bahasa ([ADR-0004](../architecture/adr-0004-lokalisasi.md)).

```
res://
  data/
    words.json        # semua kartu kata (teks per bahasa)
    templates.json    # pola headline per bahasa
    districts.json    # distrik, profil emosi, area per era (area_era)
    upgrades.json     # saluran (Merpati, Koran, Radio), Sewa Kantor (era), staf
    missions.json     # misi berurutan
    tokoh.json        # tokoh fiktif target besar (era 4)
    endings.json      # dua ending: judul + epilog
    balance.json      # dibuat dari balancing/angka.csv; jangan diedit langsung
    events.json       # event (lihat EVENT.md)
  localization/
    ui.csv            # teks UI: keys,id,en
  scenes/
    main/main.tscn          # layout portrait: HUD, peta, meja (kertas + tangan + saluran/KIRIM)
    main/rumor_controller.gd    # alur satu rumor: kirim, menjalar, mutasi, konsekuensi
    main/event_controller.gd    # event kota (EVENT.md)
    main/mission_controller.gd  # misi berurutan
    main/staff_controller.gd    # staf otomatis era 2
    main/campaign_controller.gd # kontrak kampanye era 3
    main/tokoh_controller.gd    # tokoh target dan pertahanannya (era 4)
    main/final_controller.gd    # kampanye akhir + E12
    main/tutorial_controller.gd # tutorial 3 langkah: sasaran yang ditunjuk UI
    main/petunjuk_controller.gd # petunjuk singkat saat sistem baru terbuka
    city/city.tscn          # peta: feed, banner, stempel HOAKS, uang melayang
    city/peta_jaringan.gd   # warga = wajah, tetangga = garis (Konsep A "Jaringan Gosip")
    city/feed.tscn          # feed kabar satu baris, ketuk untuk 5 terakhir
    city/event_banner.tscn  # banner modifier/peluang/ancaman
    desk/desk.tscn          # meja: kertas headline, tangan, saluran + KIRIM
    desk/kertas_headline.gd # kalimat dengan chip slot, skor, animasi mesin tik
    desk/saluran_sheet.gd   # lembar Pilih Saluran
    hand/hand.tscn          # deretan kartu untuk slot aktif
    card/word_card.tscn     # kartu kata (pita emosi, varian tokoh/calon/sementara)
    ui/judul.tscn           # layar judul (main scene)
    ui/hud.tscn             # menu hantu, era, uang, pengikut, toko, meter, strip kontrak
    ui/hud_strip.gd         # strip utama HUD: misi / tokoh / kampanye akhir
    ui/shop.tscn            # toko layar penuh: Kata, Template, Kantor & staf (toko_kantor.gd)
    ui/ending.tscn          # ending menang/kalah
    ui/lembar.gd            # dasar lembar bawah/layar penuh
    ui/dilema_sheet.gd, tokoh_sheet.gd, final_sheet.gd, naik_era.gd,
    ui/offline_sheet.gd, pengaturan_layar.gd   # lapisan lain (kanvas papan 10–20)
    ui/hantu.gd             # maskot Si Hantu Penulis (digambar, 4 suasana)
    ui/tutorial_lapisan.gd  # lapisan tutorial (CanvasLayer): tangan_tunjuk.gd, tutorial_gelembung.gd,
    ui/tutorial_sasaran.gd  #   dan pencari node sasaran lewat grup
    ui/petunjuk_lapisan.gd  # kartu petunjuk sistem baru (petunjuk_kartu.gd) + ekor ke sasaran
  scripts/
    autoload/game_state.gd   # uang, pengikut, kredibilitas, kartu dimiliki
    autoload/data_db.gd      # memuat semua JSON saat start
    autoload/events.gd       # sinyal global
    autoload/game_clock.gd   # tick simulasi tetap 0,2 detik (ADR-0003)
    autoload/save_system.gd  # simpan/muat user://save.json (ADR-0002)
    autoload/bahasa.gd       # bahasa aktif, teks konten, format angka (ADR-0004)
    autoload/pengaturan.gd   # volume musik/SFX, getar di user://settings.cfg
    autoload/suara.gd        # bus audio, musik era, lapisan ancaman, SFX
    autoload/getar.gd        # getar ringan di HP (kirim, HOAKS)
    systems/balance.gd       # Balance.X: angka dari data/balance.json + konstanta teknis
    systems/state_serial.gd  # GameState <-> dictionary save
    systems/rumor_scorer.gd  # hitung viral & dipercaya
    systems/spread_sim.gd    # simulasi penyebaran per tick
    systems/economy.gd       # pendapatan, harga, upgrade
    systems/konsekuensi.gd   # heat, pembongkaran, kredibilitas, pengikut
    systems/mutasi.gd        # ganti satu kata saat menyebar
    systems/staf.gd          # rumus rumor abstrak staf (juga untuk offline)
    ui/palet.gd              # warna "Kota Gosip Malam" + StyleBox tombol tebal
    ui/tema.gd               # Theme global + font (Lilita One, Fredoka, Courier Prime)
    ui/ui_kit.gd             # pembuat label, tombol, pil, bar, ikon
    ui/gambar_wajah.gd       # menggambar wajah warga per status
    systems/headline_builder.gd  # susun headline dari template_id + kata_ids
  tests/                     # tes gdUnit4
  tools/sesi_bot.gd          # bot balancing: simulasi sesi headless
  tools/uji_tutup_paksa.gd   # uji tutup paksa saat autosave (desktop)
  addons/gdUnit4/            # framework tes (tidak ikut diekspor)
  assets/
    fonts/  sfx/  music/  ui/ikon/   # font OFL + lisensi, ikon SVG garis
```

Nama file dan scene memakai `snake_case`; nama class dan autoload tetap `PascalCase`. Satu tanggung jawab per script, dengan batas lunak ±300 baris; kalau lewat, pecah ke file baru (lihat [konvensi](konvensi.md)).

| Autoload | Tugas |
| --- | --- |
| `DataDB` | Membaca file di `data/` dengan `JSON.parse_string`, menyediakan `get_word(id)`, `get_template(id)` |
| `GameState` | Satu-satunya tempat angka pemain disimpan; scene membaca dari sini |
| `Events` | Sinyal seperti `rumor_published`, `citizen_converted`, `money_changed` supaya scene tidak saling memanggil langsung |
| `GameClock` | Satu-satunya sumber waktu simulasi: sinyal `tick`, jeda bernama, RNG berseed |
| `SaveSystem` | Menyimpan dan memuat `GameState` ke `user://save.json` dengan tulis atomik dan migrasi skema |
| `Bahasa` | Bahasa aktif, `teks()` untuk konten per bahasa, `angka()` untuk format angka |

### Layout layar (portrait)

```
┌───────────────────┐
│  Uang · Pengikut  │  ← HUD tipis
├───────────────────┤
│                   │
│   PETA KOTA       │  ← rumor menjalar, warga bereaksi
│   (3 distrik)     │
│                   │
├───────────────────┤
│  MESIN TIK        │  ← template headline + slot,
│  [SUBJEK] ketahuan│     lalu animasi mengetik
│  [AKSI] di [...]  │
├───────────────────┤
│ [kartu][kartu]... │  ← tangan kartu kata, zona jempol
└───────────────────┘
```

Susun dengan `VBoxContainer` di root `main.tscn`, dan beri `size_flags_stretch_ratio` (misalnya 0.08 / 0.45 / 0.22 / 0.25) supaya proporsinya ikut menyesuaikan rasio layar HP.

### Contoh data (cukup 30 kata dan 5 template untuk prototipe)

Setiap teks yang tampil ke pemain berupa dictionary per bahasa. Field `en` boleh kosong sampai 0.9.0; teks Indonesia dipakai sebagai cadangan.

`words.json`

```json
[
  {"id": "pak_rt", "slot": "subjek", "emosi": "lucu", "heboh": 1, "kred": 2, "harga": 0,
   "text": {"id": "Pak RT", "en": "the Neighborhood Chief"}},
  {"id": "menari_malam", "slot": "aksi", "emosi": "lucu", "heboh": 2, "kred": 1, "harga": 0,
   "text": {"id": "menari tengah malam", "en": "dancing at midnight"}},
  {"id": "pasar", "slot": "tempat", "emosi": "netral", "heboh": 0, "kred": 2, "harga": 0,
   "text": {"id": "pasar", "en": "the market"}},
  {"id": "tetangga", "slot": "sumber", "emosi": "netral", "heboh": 0, "kred": 1, "harga": 0,
   "text": {"id": "tetangga", "en": "a neighbor"}}
]
```

`templates.json`

```json
[
  {
    "id": "t_dasar",
    "slot": ["subjek", "aksi", "tempat", "sumber"],
    "pengali_heboh": 1.0,
    "unlock": 0,
    "pola": {
      "id": "{subjek} ketahuan {aksi} di {tempat}, kata {sumber}!",
      "en": "{sumber} says {subjek} was caught {aksi} at {tempat}!"
    }
  }
]
```

`districts.json`

```json
[
  {"id": "pasar_lama", "nama": {"id": "Pasar Lama", "en": "Old Market"}, "emosi_favorit": "lucu", "kerentanan": 1.2, "warga": 40},
  {"id": "kompleks_hijau", "nama": {"id": "Kompleks Hijau", "en": "Green Estate"}, "emosi_favorit": "iri", "kerentanan": 0.9, "warga": 30},
  {"id": "gang_sempit", "nama": {"id": "Gang Sempit", "en": "Narrow Alley"}, "emosi_favorit": "takut", "kerentanan": 1.0, "warga": 35}
]
```

Headline disusun oleh `headline_builder.gd`: ambil pola bahasa aktif lewat `Bahasa.teks()`, lalu `pola.format({"subjek": ..., ...})` dengan teks kata dalam bahasa yang sama. Kata AKSI bahasa Inggris ditulis dalam bentuk yang pas dengan semua template EN.

`localization/ui.csv`

```csv
keys,id,en
UI_KIRIM,KIRIM,SEND
UI_TOKO,Toko,Shop
```

## Save (JSON)

Detail lengkap ada di [ADR-0002](../architecture/adr-0002-backend-save.md); ringkasnya:

| Data | Disimpan di | Alasan |
| --- | --- | --- |
| Konten (kata, template, distrik, event, upgrade) | JSON di `res://data/` | Dibuat developer, tidak berubah saat main, mudah diedit dan dibaca di git |
| Progres pemain, riwayat, statistik | `user://save.json` | Satu file kecil, tulis atomik, migrasi versi skema |
| Pengaturan (bahasa, suara, musik, getar) | `user://settings.cfg` (`ConfigFile`) | Tetap ada walaupun progres di-reset |

- Save hanya menyimpan **ID** konten (`pak_rt`, `t_dasar`), bukan isinya. Riwayat menyimpan `template_id` + `kata_ids`, dan headline disusun saat ditampilkan, jadi riwayat ikut berganti bahasa.
- Tulis atomik: tulis ke `save.tmp`, file lama jadi `save.bak`, lalu `save.tmp` di-rename jadi `save.json`. Saat memuat dicoba berurutan `save.tmp` (hanya ada kalau proses mati di tengah simpan; kalau utuh, itu yang terbaru) → `save.json` → `save.bak`.
- `versi_skema` di file; setiap perubahan skema = satu fungsi migrasi baru, migrasi lama tidak pernah diubah.
- Angka dari JSON terbaca sebagai float; cast `int()` saat memuat.
- Autosave tiap 30 detik (waktu nyata) dan saat `NOTIFICATION_APPLICATION_PAUSED`; di desktop juga saat `NOTIFICATION_WM_CLOSE_REQUEST`.
- Rumor yang sedang menjalar disimpan sebagai hasil proyeksi ([ADR-0003](../architecture/adr-0003-model-waktu.md)).
- Riwayat dibatasi 200 entri terakhir; total sepanjang permainan ada di `statistik`.
- Posisi titik warga tidak disimpan; warga dibangkitkan ulang dari jumlah `percaya`, `ragu`, `kebal` per distrik.
- Reset progres = menghapus `save.json`/`.bak`/`.tmp`; `settings.cfg` tidak disentuh.
