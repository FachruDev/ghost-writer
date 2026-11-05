class_name Balance
extends RefCounted
## Semua angka balancing di satu tempat. Rumus ada di docs/panduan/konsep-game.md.

# Waktu simulasi (ADR-0003)
const SIM_TICK := 0.2
const MAKS_TICK_PER_FRAME := 5

# Skor rumor
const PENGALI_COCOK_SAMA := 1.5
const PENGALI_COCOK_NETRAL := 1.0
const PENGALI_COCOK_BEDA := 0.9
const PENGALI_COCOK_LAWAN := 0.6
const EMOSI_LAWAN := {"lucu": "takut", "takut": "lucu", "marah": "iri", "iri": "marah"}
const BATAS_HEBOH_AMAN := 6.0
const PENALTI_PER_HEBOH := 0.05
const DIPERCAYA_MIN := 0.1
const DIPERCAYA_MAKS := 1.0
const KREDIBILITAS_AWAL := 50.0

# Penyebaran
const PELUANG_TULAR_DASAR := 0.025
const TETANGGA_PER_WARGA := 6
const DURASI_MENULAR_DETIK := 1.2
const WARGA_AWAL_MIN := 1
const WARGA_AWAL_MAKS := 3
const RUMOR_MAKS_DETIK := 25.0
const RUMOR_DIAM_DETIK := 3.0
const PENGALI_PERCAYA_RAGU := 0.5
const RAGU_PULIH_PER_DETIK := 1.0 / 60.0
## Warga yang ragu tetap ikut bercerita selama durasi ini ("eh, katanya sih...").
## 0.0 = hanya warga yang percaya yang menularkan.
const DURASI_MENULAR_RAGU_DETIK := 1.0

# Ekonomi
const UANG_AWAL := 0
const UANG_PER_WARGA := 5
