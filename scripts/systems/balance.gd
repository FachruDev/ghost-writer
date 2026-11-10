class_name Balance
extends RefCounted
## Angka balancing. Nilainya dibaca dari res://data/balance.json, yang dibuat dari
## balancing/angka.csv oleh tools/terapkan_balancing.gd. Jangan ubah JSON-nya langsung;
## ubah CSV lalu jalankan alatnya. Rumus ada di docs/panduan/konsep-game.md.
##
## Konstanta teknis (bukan balancing) tetap `const` di bawah.

const PATH := "res://data/balance.json"

# Teknis: waktu simulasi (ADR-0003), save (ADR-0002), tampilan
const SIM_TICK := 0.2
const MAKS_TICK_PER_FRAME := 5
const AUTOSAVE_DETIK := 30.0
const BATAS_RIWAYAT := 200
const BATAS_FEED := 4
const BATAS_TICK_PROYEKSI := 300
const DURASI_DENYUT_DETIK := 0.6
## Aturan desain, bukan angka: emosi yang saling melemahkan.
const EMOSI_LAWAN := {"lucu": "takut", "takut": "lucu", "marah": "iri", "iri": "marah"}

## Harus dideklarasikan pertama: static var diisi sesuai urutan.
static var _data: Dictionary = _baca()

# Skor rumor
static var PENGALI_COCOK_SAMA: float = _f("PENGALI_COCOK_SAMA")
static var PENGALI_COCOK_NETRAL: float = _f("PENGALI_COCOK_NETRAL")
static var PENGALI_COCOK_BEDA: float = _f("PENGALI_COCOK_BEDA")
static var PENGALI_COCOK_LAWAN: float = _f("PENGALI_COCOK_LAWAN")
static var BATAS_HEBOH_AMAN: float = _f("BATAS_HEBOH_AMAN")
static var PENALTI_PER_HEBOH: float = _f("PENALTI_PER_HEBOH")
static var DIPERCAYA_MIN: float = _f("DIPERCAYA_MIN")
static var DIPERCAYA_MAKS: float = _f("DIPERCAYA_MAKS")
static var JENUH_JENDELA: int = _i("JENUH_JENDELA")
static var JENUH_PER_PAKAI: float = _f("JENUH_PER_PAKAI")
static var JENUH_MIN: float = _f("JENUH_MIN")
static var KREDIBILITAS_AWAL: float = _f("KREDIBILITAS_AWAL")

# Penyebaran
static var PELUANG_TULAR_DASAR: float = _f("PELUANG_TULAR_DASAR")
static var TETANGGA_PER_WARGA: int = _i("TETANGGA_PER_WARGA")
static var DURASI_MENULAR_DETIK: float = _f("DURASI_MENULAR_DETIK")
static var RUMOR_MAKS_DETIK: float = _f("RUMOR_MAKS_DETIK")
static var RUMOR_DIAM_DETIK: float = _f("RUMOR_DIAM_DETIK")
static var PENGALI_PERCAYA_RAGU: float = _f("PENGALI_PERCAYA_RAGU")
static var RAGU_PULIH_PER_DETIK: float = _f("RAGU_PULIH_PER_DETIK")
static var DURASI_MENULAR_RAGU_DETIK: float = _f("DURASI_MENULAR_RAGU_DETIK")
static var KEBAL_PULIH_PER_DETIK: float = _f("KEBAL_PULIH_PER_DETIK")

# Konsekuensi
static var HEAT_FAKTOR_KIRIM: float = _f("HEAT_FAKTOR_KIRIM")
static var HEAT_TURUN_PER_DETIK: float = _f("HEAT_TURUN_PER_DETIK")
static var HEAT_DIBONGKAR: float = _f("HEAT_DIBONGKAR")
static var BONGKAR_DASAR: float = _f("BONGKAR_DASAR")
static var BONGKAR_DARI_HEAT: float = _f("BONGKAR_DARI_HEAT")
static var KRED_TURUN_DIBONGKAR: float = _f("KRED_TURUN_DIBONGKAR")
static var KRED_TURUN_PER_HEBOH: float = _f("KRED_TURUN_PER_HEBOH")
static var PERSEN_KEBAL_DIBONGKAR: float = _f("PERSEN_KEBAL_DIBONGKAR")
static var KRED_NAIK: float = _f("KRED_NAIK")
static var KRED_NAIK_MIN_DIPERCAYA: float = _f("KRED_NAIK_MIN_DIPERCAYA")
static var KRED_PULIH_PER_DETIK: float = _f("KRED_PULIH_PER_DETIK")
static var KRED_PULIH_SAMPAI: float = _f("KRED_PULIH_SAMPAI")

# Pengikut & mutasi
static var WARGA_PER_PENGIKUT: int = _i("WARGA_PER_PENGIKUT")
static var PELUANG_MUTASI: float = _f("PELUANG_MUTASI")
static var PENGIKUT_PER_MUTASI: int = _i("PENGIKUT_PER_MUTASI")

# Event
static var EVENT_CEK_DETIK: float = _f("EVENT_CEK_DETIK")
static var EVENT_JEDA_DETIK: float = _f("EVENT_JEDA_DETIK")
static var ANCAMAN_JEDA_DETIK: float = _f("ANCAMAN_JEDA_DETIK")

# Kontrak kampanye (Era 3)
static var KONTRAK_JEDA_DETIK: float = _f("KONTRAK_JEDA_DETIK")
static var KONTRAK_DURASI_DETIK: float = _f("KONTRAK_DURASI_DETIK")
static var KONTRAK_PERSEN: float = _f("KONTRAK_PERSEN")
static var KONTRAK_UANG: int = _i("KONTRAK_UANG")
static var KONTRAK_PENGIKUT: int = _i("KONTRAK_PENGIKUT")
static var KONTRAK_KRED_GAGAL: float = _f("KONTRAK_KRED_GAGAL")

# Kampanye akhir (E12)
static var FINAL_DURASI_DETIK: float = _f("FINAL_DURASI_DETIK")
static var FINAL_TULAR_KEBAL_DETIK: float = _f("FINAL_TULAR_KEBAL_DETIK")
static var FINAL_PELUANG_TULAR_KEBAL: float = _f("FINAL_PELUANG_TULAR_KEBAL")
static var FINAL_BENIH_KEBAL: float = _f("FINAL_BENIH_KEBAL")
static var FINAL_PENGALI_PERCAYA: float = _f("FINAL_PENGALI_PERCAYA")
static var FINAL_TARGET_PERCAYA: float = _f("FINAL_TARGET_PERCAYA")
static var FINAL_BATAS_KEBAL: float = _f("FINAL_BATAS_KEBAL")

# Ekonomi
static var UANG_AWAL: int = _i("UANG_AWAL")
static var UANG_PER_WARGA: int = _i("UANG_PER_WARGA")

# Penghasilan offline (ADR-0003)
static var OFFLINE_MAKS_DETIK: float = _f("OFFLINE_MAKS_DETIK")
static var OFFLINE_PENGALI: float = _f("OFFLINE_PENGALI")
static var OFFLINE_DIPERCAYA_RATA: float = _f("OFFLINE_DIPERCAYA_RATA")


## Semua kunci di balance.json; dipakai tes untuk memastikan tidak ada yang hilang atau berlebih.
static func kunci() -> Array:
	return _data.keys()


static func _baca() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (data is Dictionary):
		push_error("Balance: %s tidak terbaca" % PATH)
		return {}
	return data


static func _f(k: String) -> float:
	if not _data.has(k):
		push_error("Balance: kunci %s tidak ada di %s" % [k, PATH])
		return 0.0
	return float(_data[k])


static func _i(k: String) -> int:
	return roundi(_f(k))
