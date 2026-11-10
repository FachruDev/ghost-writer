# ADR-0002: Backend Save JSON dengan Tulis Atomik

## Status
Accepted

## Date
2026-11-05

## Last Verified
2026-11-05

## Decision Makers
Pengembang (FchDxCode), dengan Claude

## Summary
Progres pemain perlu disimpan aman di Android tanpa dependensi native yang berisiko di Google Play. Diputuskan: satu file **JSON di `user://save.json`** dengan tulis atomik (`.tmp` → `.bak`), versi skema plus migrasi berurutan, dan `SaveSystem` mulai dibuat di 0.2.0. Ini menggantikan rencana SQLite via godot-sqlite.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | MEDIUM — `docs/engine-reference/` belum ada; API yang dipakai (`FileAccess`, `DirAccess`, `JSON`) stabil sejak Godot 4.0 |
| **References Consulted** | Tidak ada engine-reference lokal; pencarian web tentang godot-sqlite dan syarat 16 KB Google Play |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | `DirAccess.rename_absolute` di Android menimpa/mengganti file dengan benar; save utuh setelah aplikasi ditutup paksa saat autosave |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0003 (model waktu simulasi): proyeksi rumor yang sedang menjalar dan penghasilan offline |
| **Blocks** | `SaveSystem` dan serialisasi `GameState` (0.2.0) |
| **Ordering Note** | Dibuat di 0.2.0, bukan 0.9.0, supaya tester MVP tidak kehilangan progres dan skema ikut tumbuh bersama `GameState` |

## Context

### Problem Statement
`struktur-project.md` merencanakan SQLite lewat plugin godot-sqlite (GDExtension). Plugin itu membawa library native `.so` ke dalam AAB. Google Play mewajibkan library native selaras 16 KB untuk app yang menargetkan Android 15+, dan Ghostwriter menargetkan API 36. Belum ada bukti plugin memenuhinya. Repo-nya terakhir di-push sekitar Maret 2025, dan setiap rilis plugin terikat ke versi Godot tertentu. Sementara itu, datanya kecil: satu baris pemain, beberapa daftar ID, dan riwayat terbatas.

### Constraints
- Android, target API 36; harus lolos review Play Store
- Solo paruh waktu: tidak ada waktu untuk memelihara atau mengompilasi ulang plugin native
- Tester mulai bermain di 0.2.0

### Requirements
- Save tidak boleh rusak saat aplikasi ditutup paksa di tengah penyimpanan
- Update game tidak boleh merusak save lama (migrasi skema)
- Save hanya menyimpan ID konten; isi kata dan template selalu dibaca dari JSON di `res://data/`
- Reset progres tidak menghapus pengaturan

## Decision

Progres disimpan dalam **satu file JSON** di `user://save.json`. Pengaturan tetap di `user://settings.cfg` (`ConfigFile`). Konten game tetap di `res://data/*.json`.

### Format file (skema versi 1)

```json
{
  "versi_skema": 1,
  "versi_game": "0.2.0",
  "disimpan_pada": "2026-11-05T10:00:00",
  "disimpan_unix": 1793872800,
  "pemain": {"uang": 0, "pengikut": 0, "kredibilitas": 50, "heat": 0, "era": 1, "waktu_main_detik": 0},
  "kartu_dimiliki": ["pak_rt", "pasar"],
  "template_dimiliki": ["t_dasar"],
  "upgrade_dimiliki": {"merpati": 1},
  "misi": {"m_01": "selesai", "m_02": "aktif"},
  "distrik_status": {"pasar_lama": {"terbuka": true, "percaya": 0, "ragu": 0, "kebal": 0}},
  "riwayat_rumor": [],
  "riwayat_event": [],
  "statistik": {"total_rumor": 0, "total_uang": 0, "total_dibongkar": 0, "rumor_terbaik": null}
}
```

Isi `riwayat_rumor` mengikuti kolom tabel `riwayat_rumor` di `struktur-project.md` **tanpa kolom `headline`**: entri menyimpan `template_id` dan `kata_ids` (termasuk hasil mutasi), dan headline disusun saat ditampilkan (ADR-0004). Riwayat dibatasi **200 entri terakhir**. `riwayat_event` juga dibatasi 200. Angka sepanjang permainan dicatat di `statistik` supaya tetap ada walaupun riwayat dipotong.

### Alur simpan dan muat

```
simpan():
  GameState.ke_dict() ──► JSON.stringify ──► tulis user://save.tmp
                                               │ (gagal → batal, save lama utuh)
  hapus save.bak ◄── rename save.json → save.bak
  rename save.tmp → save.json

muat():
  coba save.tmp ──gagal──► coba save.json ──gagal──► coba save.bak ──gagal──► game baru
       │ berhasil     (tmp terpotong dilewati diam-diam; json/bak rusak disalin ke save.rusak)
       ▼
  migrasi(versi_skema → terbaru) ──► GameState.dari_dict()
```

Amandemen 2026-11-07: urutan muat semula `save.json → save.bak → save.tmp`. `save.tmp` hanya tertinggal kalau proses mati di tengah `simpan()`, dan kalau isinya JSON utuh berarti sudah ditulis penuh sebelum ganti nama, jadi selalu data terbaru. Dengan urutan lama, mati di antara dua ganti nama (sering terjadi di Windows saat `tools/uji_tutup_paksa.gd`) memuat `save.bak` dan satu autosave hilang. Tes: `test_save.gd` (`test_mati_*`, `test_tmp_terpotong_*`).

### Key Interfaces

```gdscript
# scripts/autoload/save_system.gd
func simpan() -> Error
func muat() -> bool                # false = tidak ada save valid, mulai game baru
func reset_progres() -> void       # hapus save.json/.bak/.tmp; settings.cfg tidak disentuh

# scripts/autoload/game_state.gd
func ke_dict() -> Dictionary
func dari_dict(data: Dictionary) -> void

# scripts/systems/balance.gd
const AUTOSAVE_DETIK := 30.0
const BATAS_RIWAYAT := 200
```

Migrasi berupa daftar fungsi berurutan di `save_system.gd`. `MIGRASI[i]` mengubah dictionary dari versi `i + 1` ke versi `i + 2`.

### Implementation Guidelines
- Penulisan **must** selalu lewat `save.tmp` lalu rename; **must never** menulis langsung ke `save.json`.
- Kalau penulisan `save.tmp` gagal (`FileAccess.get_open_error()` atau error saat menulis), `simpan()` **must** berhenti tanpa menyentuh `save.json` dan `save.bak`.
- `muat()` **must** memeriksa hasil `JSON.parse_string` (bisa `null`) dan tipe setiap field sebelum dipakai.
- Angka dari JSON terbaca sebagai `float`; field bilangan bulat **must** di-cast dengan `int()` di `dari_dict()`.
- Setiap perubahan skema **must** menaikkan `versi_skema` dan menambah satu fungsi migrasi di akhir; migrasi lama **must never** diubah.
- Save **must** hanya berisi ID konten. ID yang tidak lagi ada di `res://data/` **must** diabaikan saat memuat, bukan membuat crash.
- Autosave **must** berjalan tiap `AUTOSAVE_DETIK`, pada `NOTIFICATION_APPLICATION_PAUSED`, dan pada `NOTIFICATION_WM_CLOSE_REQUEST`.
- Posisi titik warga **must never** disimpan; warga dibangkitkan ulang dari `distrik_status`.
- `disimpan_unix` (`Time.get_unix_time_from_system()`) **must** diisi setiap simpan; `disimpan_pada` hanya untuk dibaca manusia karena tidak punya zona waktu.
- Rumor yang sedang menjalar **must** disimpan sebagai hasil proyeksi sesuai ADR-0003.
- Hanya `SaveSystem` yang **must** menyentuh file save; scene lain membaca dan menulis lewat `GameState`.

## Alternatives Considered

- **SQLite via godot-sqlite** — query dan transaksi bawaan. Ditolak: library native perlu dibuktikan selaras 16 KB, terikat ke versi Godot, dan terlalu besar untuk data sekecil ini. Statistik cukup dihitung dari array di memori.
- **Resource `.tres` via `ResourceSaver`** — terintegrasi dengan editor. Ditolak: mengganti nama class merusak save lama. Risiko script tertanam saat memuat Resource dari `user://` sering disebut komunitas, tapi **belum terverifikasi**: halaman `ResourceLoader` di dokumentasi 4.7 tidak menyebutnya.
- **`ConfigFile` untuk semuanya** — sudah dipakai untuk pengaturan. Ditolak: kurang nyaman untuk daftar bertingkat dan riwayat.

## Consequences

### Positive
- Tidak ada library native tambahan; ekspor Android hanya bergantung pada Godot sendiri
- File save bisa dibaca dan diedit saat debug
- Ukuran kecil (±50 KB dengan 200 riwayat), cepat ditulis tiap 30 detik
- Tester sudah punya save sejak 0.2.0

### Negative
- Tidak ada query SQL; statistik dan filter riwayat ditulis manual di GDScript
- Seluruh file ditulis ulang setiap simpan
- Pemain dengan HP yang di-root bisa mengedit save (tidak masalah untuk game single-player)

## Risks
- **Rename di Android tidak menimpa file dengan benar.** Mitigasi: hapus file tujuan sebelum rename; uji tutup paksa di HP sungguhan sejak 0.2.0.
- **Penyimpanan HP penuh.** Mitigasi: `simpan()` gagal dengan aman dan save lama tetap utuh; tampilkan peringatan singkat.
- **Skema berubah sering selama 0.2–0.6.** Mitigasi: setiap perubahan menjadi satu langkah migrasi; tes headless memuat save versi lama.
- **Dokumen lain masih menyebut SQLite.** Mitigasi: setelah ADR ini diterima, perbarui `struktur-project.md`, `konsep-game.md`, `README.md`, dan `CHECKLIST.md`.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| struktur-project.md (belum ada GDD) | Save tidak setengah jadi saat ditutup paksa | Tulis ke `.tmp`, cadangan `.bak`, urutan muat json → bak → tmp |
| struktur-project.md | Migrasi versi skema; migrasi lama tidak diubah | `versi_skema` dan daftar fungsi `MIGRASI` |
| struktur-project.md | Save hanya menyimpan ID konten | Aturan ID saja; ID yang hilang diabaikan |
| struktur-project.md | Riwayat dibatasi | 200 entri terakhir + `statistik` total |
| CHECKLIST.md 0.9.0 | Pengaturan terpisah, reset tidak menghapus pengaturan | `settings.cfg` tidak disentuh `reset_progres()` |
| mvp-v1.md | Tester sejak Fase 2 | `SaveSystem` dibuat di 0.2.0 |

## Performance Implications
- **CPU**: Stringify ±50 KB tiap 30 detik; jauh di bawah satu frame
- **Memory**: Riwayat 200 entri di memori, dapat diabaikan
- **Load Time**: Parse satu file kecil saat start
- **Network**: Tidak berlaku

## Migration Plan
Belum ada kode. Saat ADR diterima:
1. Hapus langkah pemasangan godot-sqlite dan uji SQLite dari bagian Setup di `CHECKLIST.md`.
2. Pindahkan butir Save dasar dari 0.9.0 ke 0.2.0; sisakan uji tutup paksa, reset, dan polish di 0.9.0.
3. Ganti bagian "Database save (SQLite)" di `struktur-project.md` dengan format dan aturan di ADR ini.
4. Perbarui baris Save di `konsep-game.md` dan baris Penyimpanan di `README.md`.

## Validation Criteria
- Tutup paksa aplikasi saat autosave berjalan 10 kali di HP Android; setiap kali dibuka, progres utuh
- `save.json` dirusak manual → game memuat dari `save.bak` tanpa crash
- Save skema 1 tetap termuat setelah skema naik ke versi 2 (tes headless)
- Ekspor AAB tidak memuat library native selain milik Godot

## Related
- [ADR-0001: Renderer Compatibility](adr-0001-renderer.md) — tidak terkait langsung
- [ADR-0003: Model waktu simulasi](adr-0003-model-waktu.md) — memakai format save ini
- [ADR-0004: Lokalisasi](adr-0004-lokalisasi.md) — riwayat menyimpan ID, bukan teks headline
- [struktur-project.md](../panduan/struktur-project.md) — bagian Database save (digantikan oleh ADR ini)
- [CHECKLIST.md](../versi/1.0.0/mvp/CHECKLIST.md) — Setup, 0.2.0, 0.9.0
- [mvp-v1.md](../versi/1.0.0/mvp/mvp-v1.md) — risiko tester closed testing
