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

const KEBAL_PULIH_PER_DETIK := 1.0 / 180.0
const DURASI_DENYUT_DETIK := 0.6

# Konsekuensi (konsep-game.md, bagian Konsekuensi)
const HEAT_FAKTOR_KIRIM := 1.5
const HEAT_TURUN_PER_DETIK := 0.3
const HEAT_DIBONGKAR := 10.0
const BONGKAR_DASAR := 0.3
const BONGKAR_DARI_HEAT := 0.7
const KRED_TURUN_DIBONGKAR := 5.0
const PERSEN_KEBAL_DIBONGKAR := 0.5
const KRED_NAIK := 1.0
const KRED_NAIK_MIN_DIPERCAYA := 0.7

# Pengikut & mutasi
const WARGA_PER_PENGIKUT := 12
const PELUANG_MUTASI := 0.02
const PENGIKUT_PER_MUTASI := 3

# Event (EVENT.md)
const EVENT_CEK_DETIK := 10.0
const EVENT_JEDA_DETIK := 180.0
const ANCAMAN_JEDA_DETIK := 120.0

# Kontrak kampanye (Era 3)
const KONTRAK_JEDA_DETIK := 240.0
const KONTRAK_DURASI_DETIK := 180.0
const KONTRAK_PERSEN := 0.5
const KONTRAK_UANG := 600
const KONTRAK_PENGIKUT := 60
const KONTRAK_KRED_GAGAL := 10.0

# Ekonomi
const UANG_AWAL := 0
const UANG_PER_WARGA := 2

# Save (ADR-0002)
const AUTOSAVE_DETIK := 30.0
const BATAS_RIWAYAT := 200
const BATAS_FEED := 4
const BATAS_TICK_PROYEKSI := 300
