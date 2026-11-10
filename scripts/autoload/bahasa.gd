extends Node
## Bahasa aktif, teks konten per bahasa, dan format angka (ADR-0004).

signal bahasa_berubah(kode: String)

const DIDUKUNG := ["id", "en"]
const CADANGAN := "id"
const PATH_SETTINGS := "user://settings.cfg"

var _kode := CADANGAN
var _sudah_diperingatkan := {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	var tersimpan := ""
	if cfg.load(PATH_SETTINGS) == OK:
		tersimpan = str(cfg.get_value("umum", "bahasa", ""))
	if tersimpan in DIDUKUNG:
		_kode = tersimpan
	else:
		_kode = "id" if OS.get_locale_language() == "id" else "en"
	TranslationServer.set_locale(_kode)


func kode() -> String:
	return _kode


func atur(kode_baru: String) -> void:
	if not (kode_baru in DIDUKUNG) or kode_baru == _kode:
		return
	_kode = kode_baru
	TranslationServer.set_locale(_kode)
	var cfg := ConfigFile.new()
	cfg.load(PATH_SETTINGS)
	cfg.set_value("umum", "bahasa", _kode)
	cfg.save(PATH_SETTINGS)
	bahasa_berubah.emit(_kode)


## field: Dictionary {"id": ..., "en": ...} atau String. Cadangan ke bahasa Indonesia.
func teks(field: Variant) -> String:
	if field is String:
		return field
	if not field is Dictionary:
		return ""
	var d: Dictionary = field
	var hasil := str(d.get(_kode, ""))
	if hasil.is_empty():
		hasil = str(d.get(CADANGAN, ""))
		if OS.is_debug_build() and _kode != CADANGAN:
			_peringatkan(hasil)
	return hasil


## Pemisah ribuan: "1.000" (id) atau "1,000" (en).
func angka(n: int) -> String:
	var pemisah := "." if _kode == "id" else ","
	var s := str(absi(n))
	var hasil := ""
	while s.length() > 3:
		hasil = pemisah + s.substr(s.length() - 3) + hasil
		s = s.substr(0, s.length() - 3)
	hasil = s + hasil
	return "-" + hasil if n < 0 else hasil


func _peringatkan(teks_cadangan: String) -> void:
	if _sudah_diperingatkan.has(teks_cadangan):
		return
	_sudah_diperingatkan[teks_cadangan] = true
	push_warning("Bahasa: teks '%s' belum punya terjemahan %s" % [teks_cadangan, _kode])
