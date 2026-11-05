# ADR-0003: Model Waktu Simulasi (GameClock Fixed Timestep)

## Status
Accepted

## Date
2026-11-05

## Last Verified
2026-11-05

## Decision Makers
Pengembang (FchDxCode), dengan Claude

## Summary
Penyebaran rumor, event, ekonomi, staf otomatis, dan penghasilan offline semuanya bergantung pada waktu, dan semuanya harus bisa dijeda, diuji headless, dan dihitung ulang dengan cara yang sama. Diputuskan: satu autoload **GameClock** dengan fixed timestep 0,2 detik dan RNG berseed. Rumor yang sedang menjalar disimpan sebagai hasil proyeksi, dan penghasilan offline dihitung dengan rumus tertutup (maks 8 jam × 50%).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Core |
| **Layer** | Foundation |
| **Knowledge Risk** | MEDIUM — `docs/engine-reference/` belum ada; API yang dipakai (`_process`, sinyal, `RandomNumberGenerator`, `Time`, notifikasi aplikasi) stabil sejak Godot 4.0 |
| **References Consulted** | Tidak ada engine-reference lokal |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | `NOTIFICATION_APPLICATION_PAUSED` sempat menjalankan proyeksi dan menyimpan sebelum Android menghentikan proses; biaya proyeksi di HP kelas bawah |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (backend save): format save, `disimpan_unix`, alur `simpan()` |
| **Enables** | None |
| **Blocks** | `SpreadSim` dan `EventSystem` (0.1.0–0.2.0), staf otomatis (0.3.0), penghasilan offline (0.6.0) |
| **Ordering Note** | `GameClock` dibuat di 0.1.0 bersama `SpreadSim`; proyeksi save di 0.2.0 bersama `SaveSystem`; offline di 0.6.0 |

## Context

### Problem Statement
`SpreadSim` berjalan per tick (0,2 detik). Event punya durasi, jeda minimal 90 detik, dan dilema yang menjeda waktu. Staf otomatis bekerja di latar, dan 0.6.0 menambah penghasilan offline. Kalau tiap sistem memakai `Timer` atau `_process(delta)` sendiri, hasilnya tergantung frame rate. Menjeda satu hal bisa tidak menjeda yang lain, simulasi tidak bisa dijalankan headless untuk balancing, dan rumor yang sedang menjalar hilang saat Android menutup aplikasi.

### Constraints
- Simulasi ditulis di GDScript, HP kelas bawah ikut didukung (ADR-0001)
- Save hanya menyimpan jumlah warga per distrik, bukan posisi (ADR-0002)
- Balancing adalah risiko utama di roadmap; angka harus bisa diuji cepat

### Requirements
- Hasil simulasi tidak boleh bergantung pada frame rate
- Dilema, menu jeda, dan tutorial harus bisa menjeda tanpa saling mengganggu
- Simulasi harus bisa dijalankan tanpa scene untuk tes dan Monte Carlo
- Pemain tidak boleh kehilangan hasil rumor kalau aplikasi ditutup sistem

## Decision

### GameClock

Autoload `GameClock` mengumpulkan `delta` nyata di akumulator dan memancarkan `tick` dengan langkah tetap `SIM_TICK` (0,2 detik). Semua logika yang bergantung waktu hanya maju lewat sinyal ini.

```
_process(delta) ──► akumulator += delta × kecepatan
                         │  (kecepatan = 0 jika ada alasan jeda)
                         ▼
          selama akumulator ≥ SIM_TICK dan tick_frame < MAKS_TICK_PER_FRAME:
              tick.emit(SIM_TICK) ──► SpreadSim · EventSystem · Economy · Staf
              akumulator -= SIM_TICK
          (sisa di atas batas dibuang, supaya tidak menumpuk setelah lag)
```

Hal yang **tidak** memakai GameClock:
- Animasi dan Tween memakai waktu nyata dan bereaksi lewat sinyal `Events`
- Autosave memakai `Timer` waktu nyata (tetap menyimpan saat dilema menjeda permainan)
- `waktu_main_detik` dihitung dari waktu nyata

### Rumor yang sedang menjalar saat disimpan

Save adalah snapshot. Saat `SaveSystem.simpan()` berjalan dan ada rumor yang belum selesai:

1. `SpreadSim.duplikat()` membuat salinan keadaan simulasi, termasuk state RNG.
2. Salinan dijalankan sampai rumor selesai (`jalankan_sampai_selesai(BATAS_TICK_PROYEKSI)`).
3. Hasilnya (jumlah percaya/ragu/kebal per distrik, uang, entri riwayat) ditulis **hanya ke dictionary save**, tidak ke `GameState`.

Kalau aplikasi lanjut dari memori, simulasi asli berjalan biasa dan save berikutnya menimpa proyeksi. Jadi tidak ada hasil yang terhitung dua kali. Kalau aplikasi ditutup sistem, save sudah berisi rumor yang selesai.

### Penghasilan offline (0.6.0)

```
detik_offline = clamp(sekarang_unix - disimpan_unix, 0, OFFLINE_MAKS_DETIK)
penghasilan   = Economy.laju_pasif_per_detik() × detik_offline × OFFLINE_PENGALI
```

`laju_pasif_per_detik()` adalah rumus dari staf dan upgrade, bukan hasil menjalankan simulasi. Sebelum ada staf, nilainya 0. Jam HP yang dimundurkan menghasilkan selisih negatif, yang di-clamp ke 0.

### Key Interfaces

```gdscript
# scripts/autoload/game_clock.gd
signal tick(dt: float)                     # dt selalu SIM_TICK
var kecepatan: float = 1.0                 # pengali; hanya untuk debug/tes
func jeda(alasan: StringName) -> void      # mis. &"dilema", &"menu", &"tutorial"
func lanjut(alasan: StringName) -> void
func sedang_jeda() -> bool
func jalankan_tick(n: int) -> void         # tes headless, tanpa _process
var rng: RandomNumberGenerator             # satu sumber acak untuk simulasi

# scripts/systems/spread_sim.gd (RefCounted, tanpa node)
func langkah(dt: float) -> void
func duplikat() -> SpreadSim
func jalankan_sampai_selesai(batas_tick: int) -> Dictionary   # hasil akhir rumor
func ada_rumor_aktif() -> bool

# scripts/systems/economy.gd
func laju_pasif_per_detik() -> float

# scripts/systems/balance.gd
const SIM_TICK := 0.2
const MAKS_TICK_PER_FRAME := 5
const BATAS_TICK_PROYEKSI := 300           # 60 detik simulasi
const OFFLINE_MAKS_DETIK := 28800          # 8 jam
const OFFLINE_PENGALI := 0.5
```

### Implementation Guidelines
- Logika permainan yang bergantung waktu **must** maju hanya lewat `GameClock.tick`; **must never** memakai `Timer`, `_process(delta)`, atau `get_tree().paused` untuk logika.
- Semua durasi di data dan `balance.gd` (durasi event, jeda 90 detik, interval staf) **must** dalam detik simulasi.
- Semua keacakan simulasi **must** memakai `GameClock.rng` (atau RNG yang diturunkan darinya); **must never** memakai `randf()`/`randi()` global.
- `jeda()` dan `lanjut()` **must** memakai alasan bernama. Jam baru berjalan lagi setelah semua alasan dilepas.
- `SpreadSim` **must** tetap berupa objek data tanpa node, supaya bisa diduplikasi dan dijalankan headless.
- Proyeksi **must never** mengubah `GameState` atau memancarkan sinyal `Events`.
- Animasi dan UI **must** bereaksi lewat sinyal `Events`, bukan membaca akumulator atau tick.
- Sisa jeda antar event (cooldown) tidak disimpan; setelah memuat, cooldown dimulai dari awal.

## Alternatives Considered

- **Node `Timer` per sistem + `get_tree().paused`** — mudah di editor. Ditolak: pause tree ikut menghentikan UI dan animasi dilema, urutan timer tidak deterministik, dan tidak bisa dijalankan headless tanpa scene tree.
- **`_process(delta)` dengan akumulator per sistem** — tidak perlu autoload baru. Ditolak: logika jeda dan batas tick terduplikasi di setiap sistem, dan urutan antar sistem dalam satu tick tidak terjamin.
- **Simpan keadaan rumor lalu lanjutkan** — rumor tetap terlihat menjalar setelah dibuka. Ditolak: warga dan tetangganya dibangkitkan ulang, jadi kelanjutannya hanya mendekati, dan skema save jadi jauh lebih rumit.
- **Offline dengan menjalankan tick sebanyak waktu offline** — satu jalur kode. Ditolak: 8 jam = 144.000 tick, terlalu berat saat membuka game, dan rumor tidak berarti tanpa pemain.

## Consequences

### Positive
- Hasil simulasi sama di semua frame rate dan bisa diulang dengan seed yang sama
- Balancing bisa dijalankan headless ribuan kali (`jalankan_tick`)
- Menjeda untuk dilema, menu, dan tutorial konsisten
- Pemain tidak kehilangan hasil rumor walaupun aplikasi ditutup sistem

### Negative
- Satu autoload tambahan, dan setiap sistem waktu harus terhubung ke sinyal `tick`
- Setiap autosave saat ada rumor aktif menjalankan proyeksi (biaya CPU tambahan)
- Cooldown event ter-reset setelah memuat

## Risks
- **Proyeksi terlalu lambat di HP kelas bawah dan membuat frame tersendat saat autosave.** Mitigasi: ukur sejak 0.2.0, dengan target < 50 ms. Kalau lewat, autosave periodik menunggu sampai rumor selesai, sementara saat aplikasi dijeda atau ditutup proyeksi tetap dijalankan.
- **Android menghentikan proses sebelum proyeksi dan save selesai.** Mitigasi: autosave periodik tetap jalan, dan batasi `BATAS_TICK_PROYEKSI`.
- **Pemain memajukan jam HP untuk penghasilan offline.** Mitigasi: dibatasi 8 jam × 50%. Ini game single-player, jadi risikonya diterima.
- **Spiral lag (tick menumpuk).** Mitigasi: `MAKS_TICK_PER_FRAME`, sisa akumulator dibuang.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| konsep-game.md (belum ada GDD) | Penyebaran per tick dengan peluang tular | `SpreadSim.langkah()` dipanggil tiap `SIM_TICK` |
| EVENT.md | Durasi event, jeda minimal 90 detik, dilema menjeda waktu | Durasi dalam detik simulasi; `jeda(&"dilema")` |
| CHECKLIST.md 0.6.0 | Penghasilan offline ringan | Rumus tertutup, maks 8 jam × 0,5 |
| mvp-v1.md | Balancing berantakan (risiko) | RNG berseed + `jalankan_tick` untuk simulasi headless |
| ADR-0002 | Posisi warga tidak disimpan | Proyeksi menyimpan jumlah per distrik, bukan keadaan per warga |

## Performance Implications
- **CPU**: Satu sinyal tiap 0,2 detik; proyeksi maksimal `BATAS_TICK_PROYEKSI` tick saat menyimpan dengan rumor aktif
- **Memory**: Satu salinan `SpreadSim` sementara saat proyeksi
- **Load Time**: Hitungan offline berupa satu rumus
- **Network**: Tidak berlaku

## Migration Plan
Belum ada kode. Tambahkan `GameClock` ke autoload sebelum `SpreadSim` dibuat di 0.1.0, dan ubah butir "tiap tick (misalnya 0,2 detik)" di `CHECKLIST.md` supaya merujuk ke `GameClock`.

## Validation Criteria
- Seed dan urutan aksi yang sama menghasilkan jumlah warga percaya yang sama di 30 fps dan 60 fps (tes headless)
- Dilema menjeda penyebaran dan event, sementara animasi banner tetap berjalan
- Tutup paksa saat rumor menjalar, buka lagi: uang dan warga sesuai hasil rumor yang selesai
- Proyeksi < 50 ms di HP kelas bawah dengan ±300 warga
- Offline 10 jam menghasilkan tepat 8 jam × laju × 0,5

## Related
- [ADR-0001: Renderer Compatibility](adr-0001-renderer.md) — HP kelas bawah ikut didukung (anggaran CPU)
- [ADR-0002: Backend save](adr-0002-backend-save.md) — bergantung pada format save dan `disimpan_unix`
- [konsep-game.md](../panduan/konsep-game.md), [EVENT.md](../versi/1.0.0/event/EVENT.md), [CHECKLIST.md](../versi/1.0.0/mvp/CHECKLIST.md)
