extends Node
## Pengaturan pemain di user://settings.cfg, terpisah dari save supaya tidak ikut terhapus
## saat reset progres (konsep-game.md). Bahasa disimpan oleh autoload Bahasa di file yang sama.
## Layar pengaturan (0.9.0) cukup memanggil atur(); Suara dan Getar mendengarkan sinyal `berubah`.

signal berubah(kunci: String)

const PATH := "user://settings.cfg"
const BAGIAN := "pemain"
## Volume 0..1 (linear), getar on/off.
const BAWAAN := {"musik": 1.0, "sfx": 1.0, "getar": true}

var _nilai := {}


func _ready() -> void:
	_nilai = BAWAAN.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for kunci in BAWAAN:
		var v: Variant = cfg.get_value(BAGIAN, kunci, BAWAAN[kunci])
		if typeof(v) == typeof(BAWAAN[kunci]) or (BAWAAN[kunci] is float and (v is int or v is float)):
			_nilai[kunci] = _rapikan(kunci, v)


func ambil(kunci: String) -> Variant:
	return _nilai.get(kunci, BAWAAN.get(kunci))


func atur(kunci: String, nilai: Variant) -> void:
	if not BAWAAN.has(kunci):
		push_warning("Pengaturan: kunci %s tidak dikenal" % kunci)
		return
	nilai = _rapikan(kunci, nilai)
	if _nilai.get(kunci) == nilai:
		return
	_nilai[kunci] = nilai
	var cfg := ConfigFile.new()
	cfg.load(PATH)  # pertahankan bagian lain (mis. bahasa)
	cfg.set_value(BAGIAN, kunci, nilai)
	cfg.save(PATH)
	berubah.emit(kunci)


func _rapikan(kunci: String, nilai: Variant) -> Variant:
	if BAWAAN[kunci] is float:
		return clampf(float(nilai), 0.0, 1.0)
	return bool(nilai)
