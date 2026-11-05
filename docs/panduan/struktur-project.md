# Struktur Project Godot — Ghostwriter

Pisahkan data, logika, dan tampilan sejak awal: konten di JSON, aturan di script sistem tanpa node, scene hanya menampilkan. Menambah kata atau menyeimbangkan angka tidak perlu menyentuh scene.

```
res://
  addons/
    godot-sqlite/     # plugin GDExtension SQLite
  data/
    words.json        # semua kartu kata
    templates.json    # pola headline
    districts.json    # distrik dan profil emosi
    upgrades.json     # saluran, staf, era
  scenes/
    main/Main.tscn          # layout portrait: HUD, kota, meja, tangan
    city/City.tscn          # peta + titik warga
    city/District.tscn
    desk/Desk.tscn          # mesin tik + slot template
    hand/Hand.tscn          # deretan kartu
    card/WordCard.tscn
    ui/HUD.tscn
    ui/Shop.tscn
  scripts/
    autoload/GameState.gd   # uang, pengikut, kredibilitas, kartu dimiliki
    autoload/DataDB.gd      # memuat semua JSON saat start
    autoload/Events.gd      # sinyal global
    autoload/SaveSystem.gd  # simpan/muat progres ke SQLite di user://
    systems/Balance.gd      # semua konstanta balancing
    systems/RumorScorer.gd  # hitung viral & dipercaya
    systems/SpreadSim.gd    # simulasi penyebaran per tick
    systems/Economy.gd      # pendapatan, harga, upgrade
  assets/
    fonts/  sfx/  ui/
```

| Autoload | Tugas |
| --- | --- |
| `DataDB` | Membaca file di `data/` dengan `JSON.parse_string`, menyediakan `get_word(id)`, `get_template(id)` |
| `GameState` | Satu-satunya tempat angka pemain disimpan; scene membaca dari sini |
| `Events` | Sinyal seperti `rumor_published`, `citizen_converted`, `money_changed` supaya scene tidak saling memanggil langsung |
| `SaveSystem` | Membuka `user://ghostwriter.db`, menjalankan migrasi, menyimpan dan memuat `GameState`, mencatat riwayat rumor dan event |

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

Susun dengan `VBoxContainer` di root `Main.tscn`, dan beri `size_flags_stretch_ratio` (misalnya 0.08 / 0.45 / 0.22 / 0.25) supaya proporsinya ikut menyesuaikan rasio layar HP.

### Contoh data (cukup 30 kata dan 5 template untuk prototipe)

`words.json`

```json
[
  {"id": "pak_rt", "text": "Pak RT", "slot": "subjek", "emosi": "lucu", "heboh": 1, "kred": 2, "harga": 0},
  {"id": "menari_malam", "text": "menari tengah malam", "slot": "aksi", "emosi": "lucu", "heboh": 2, "kred": 1, "harga": 0},
  {"id": "pasar", "text": "pasar", "slot": "tempat", "emosi": "netral", "heboh": 0, "kred": 2, "harga": 0},
  {"id": "tetangga", "text": "tetangga", "slot": "sumber", "emosi": "netral", "heboh": 0, "kred": 1, "harga": 0}
]
```

`templates.json`

```json
[
  {
    "id": "t_dasar",
    "pola": "{subjek} ketahuan {aksi} di {tempat}, kata {sumber}!",
    "slot": ["subjek", "aksi", "tempat", "sumber"],
    "pengali_heboh": 1.0,
    "unlock": 0
  }
]
```

`districts.json`

```json
[
  {"id": "pasar_lama", "nama": "Pasar Lama", "emosi_favorit": "lucu", "kerentanan": 1.2, "warga": 40},
  {"id": "kompleks_hijau", "nama": "Kompleks Hijau", "emosi_favorit": "iri", "kerentanan": 0.9, "warga": 30},
  {"id": "gang_sempit", "nama": "Gang Sempit", "emosi_favorit": "takut", "kerentanan": 1.0, "warga": 35}
]
```

Pola template diisi dengan `pola.format({"subjek": "Pak RT", ...})` milik GDScript.

## Database save (SQLite)

Pembagian data:

| Data | Disimpan di | Alasan |
| --- | --- | --- |
| Konten (kata, template, distrik, event, upgrade) | JSON di `res://data/` | Dibuat developer, tidak berubah saat main, mudah diedit dan dibaca di git |
| Progres pemain, riwayat, statistik | SQLite di `user://ghostwriter.db` | Berubah terus; butuh simpan aman (transaksi), query, dan migrasi versi |
| Pengaturan (suara, musik, getar) | `user://settings.cfg` (`ConfigFile`) | Tetap ada walaupun progres di-reset |

Tabel SQLite hanya menyimpan **ID** konten (misalnya `pak_rt`, `t_dasar`), bukan isinya. Isi kata dan template selalu dibaca dari JSON, jadi memperbaiki typo di JSON langsung berlaku untuk save lama.

### Skema awal (versi skema 1)

```sql
-- Satu baris saja: keadaan pemain saat ini
CREATE TABLE pemain (
  id               INTEGER PRIMARY KEY CHECK (id = 1),
  uang             INTEGER NOT NULL DEFAULT 0,
  pengikut         INTEGER NOT NULL DEFAULT 0,
  kredibilitas     INTEGER NOT NULL DEFAULT 50,
  heat             INTEGER NOT NULL DEFAULT 0,
  era              INTEGER NOT NULL DEFAULT 1,
  waktu_main_detik INTEGER NOT NULL DEFAULT 0,
  terakhir_simpan  TEXT
);

-- Kepemilikan (ID mengacu ke JSON)
CREATE TABLE kartu_dimiliki    (kata_id TEXT PRIMARY KEY, didapat_pada TEXT);
CREATE TABLE template_dimiliki (template_id TEXT PRIMARY KEY);
CREATE TABLE upgrade_dimiliki  (upgrade_id TEXT PRIMARY KEY, level INTEGER NOT NULL DEFAULT 1);

-- Progres
CREATE TABLE misi (
  misi_id      TEXT PRIMARY KEY,
  status       TEXT NOT NULL CHECK (status IN ('aktif', 'selesai')),
  selesai_pada TEXT
);
CREATE TABLE distrik_status (
  distrik_id TEXT PRIMARY KEY,
  terbuka    INTEGER NOT NULL DEFAULT 0,
  percaya    INTEGER NOT NULL DEFAULT 0,
  ragu       INTEGER NOT NULL DEFAULT 0,
  kebal      INTEGER NOT NULL DEFAULT 0
);

-- Riwayat (bahan statistik dan layar ending)
CREATE TABLE riwayat_rumor (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  headline      TEXT NOT NULL,
  template_id   TEXT NOT NULL,
  kata_ids      TEXT NOT NULL,      -- array JSON, mis. ["pak_rt","menari_malam"]
  saluran_id    TEXT NOT NULL,
  distrik_id    TEXT NOT NULL,
  viral         REAL NOT NULL,
  dipercaya     REAL NOT NULL,
  warga_percaya INTEGER NOT NULL DEFAULT 0,
  uang_didapat  INTEGER NOT NULL DEFAULT 0,
  dibongkar     INTEGER NOT NULL DEFAULT 0,
  dibuat_pada   TEXT NOT NULL
);
CREATE TABLE riwayat_event (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id    TEXT NOT NULL,
  pilihan     TEXT,                 -- label pilihan untuk event dilema
  terjadi_pada TEXT NOT NULL
);
```

Posisi tiap titik warga **tidak** disimpan. Saat game dimuat, warga dibangkitkan ulang dari jumlah `percaya`, `ragu`, dan `kebal` per distrik.

### Aturan

- Semua penyimpanan dibungkus **satu transaksi** (`BEGIN` … `COMMIT`) supaya save tidak setengah jadi kalau aplikasi tertutup paksa.
- Autosave tiap 30 detik (atur di `Balance.gd`) dan saat aplikasi dijeda (`NOTIFICATION_APPLICATION_PAUSED`).
- Versi skema disimpan di `PRAGMA user_version`. Setiap perubahan skema = satu langkah migrasi baru di `SaveSystem.gd`; migrasi lama tidak pernah diubah.
- Selalu pakai query dengan parameter (`query_with_bindings`), jangan menyusun SQL dari gabungan string.
- `riwayat_rumor` dibatasi (misalnya 1.000 baris terakhir); statistik total disimpan terpisah bila perlu.
- Reset progres = mengosongkan tabel, bukan menghapus file.
- File database tidak pernah ditaruh di `res://`: setelah diekspor, `res://` hanya bisa dibaca.

### Contoh pemakaian

```gdscript
# SaveSystem.gd (ringkas)
extends Node

const DB_PATH := "user://ghostwriter.db"
const MIGRASI := [
    # indeks 0 -> skema versi 1; tambahkan langkah baru di akhir, jangan ubah yang lama
    ["CREATE TABLE pemain (...)", "CREATE TABLE kartu_dimiliki (...)"],
]

var db: SQLite

func _ready() -> void:
    db = SQLite.new()
    db.path = DB_PATH
    db.open_db()
    _migrasi()

func _migrasi() -> void:
    db.query("PRAGMA user_version;")
    var versi: int = db.query_result[0]["user_version"]
    while versi < MIGRASI.size():
        db.query("BEGIN;")
        for sql in MIGRASI[versi]:
            db.query(sql)
        versi += 1
        db.query("PRAGMA user_version = %d;" % versi)
        db.query("COMMIT;")

func catat_rumor(r: Dictionary) -> void:
    db.query_with_bindings(
        "INSERT INTO riwayat_rumor (headline, template_id, kata_ids, saluran_id, distrik_id, viral, dipercaya, dibuat_pada) VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
        [r.headline, r.template_id, JSON.stringify(r.kata_ids), r.saluran_id, r.distrik_id, r.viral, r.dipercaya, Time.get_datetime_string_from_system()]
    )
```

