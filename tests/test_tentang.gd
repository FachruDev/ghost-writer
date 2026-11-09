extends GdUnitTestSuite
## Layar Tentang (CHECKLIST 0.9.0): dibuka dari Pengaturan dan tampil di atasnya, memuat semua kredit
## pihak ketiga dari kredit.json plus Godot Engine, teks lisensi terbuka saat diketuk, ikut ganti
## bahasa, dan Back menutup Tentang lebih dulu.

const PENGATURAN := preload("res://scenes/ui/pengaturan_layar.gd")
const TENTANG := preload("res://scenes/ui/tentang_layar.gd")

var _induk: Control
var _atur
var _tentang
var _kode_awal := ""


func before_test() -> void:
	_kode_awal = Bahasa.kode()
	_induk = auto_free(Control.new())
	_induk.size = Vector2(720, 1280)
	add_child(_induk)
	_atur = PENGATURAN.new()
	_induk.add_child(_atur)
	_tentang = TENTANG.new()
	_induk.add_child(_tentang)


func after_test() -> void:
	# Bahasa diganti langsung (tanpa Bahasa.atur) supaya settings.cfg pemain tidak tertulis.
	Bahasa._kode = _kode_awal
	TranslationServer.set_locale(_kode_awal)


func _ganti_bahasa(kode: String) -> void:
	Bahasa._kode = kode
	TranslationServer.set_locale(kode)
	Bahasa.bahasa_berubah.emit(kode)


func _baris(judul: String) -> KreditBaris:
	for b in _tentang.baris():
		if b.judul_teks == judul:
			return b
	return null


func _entri(judul: String) -> Dictionary:
	for e in DataDB.kredit:
		if e["judul"] == judul:
			return e
	return {}


func test_tombol_pengaturan_membuka_tentang_dan_back_menutupnya_dulu() -> void:
	_atur.buka()
	assert_str(_atur._tentang.text).is_equal(tr("UI_TENTANG_TOMBOL"))
	_atur._tentang.pressed.emit()
	assert_bool(_tentang.visible).is_true()
	assert_object(_induk.get_child(_induk.get_child_count() - 1)).is_same(_tentang)
	# Urutan Back di main.gd dan judul.gd: anak teratas dulu.
	for i in range(_induk.get_child_count() - 1, -1, -1):
		if (_induk.get_child(i) as Lembar).tangani_back():
			break
	assert_bool(_tentang.visible).is_false()
	assert_bool(_atur.visible).is_true()


func test_semua_kredit_pihak_ketiga_dan_godot_tampil() -> void:
	Events.layar_diminta.emit("tentang")
	var tampil: Array[String] = []
	for b in _tentang.baris():
		tampil.append(b.judul_teks)
	var harap: Array[String] = ["Godot Engine"]
	for e in DataDB.kredit:
		if e["jenis"] != "proyek":
			harap.append(str(e["judul"]))
	assert_array(tampil).contains_exactly_in_any_order(harap)
	for b in _tentang.baris():
		var e := _entri(b.judul_teks)
		# Tombol lisensi: font OFL (teks_lisensi) dan Godot; musik/suara CC0 tidak.
		assert_bool(b.punya_lisensi()).is_equal(e.is_empty() or e.has("teks_lisensi"))


func test_lisensi_terbuka_saat_diketuk() -> void:
	Events.layar_diminta.emit("tentang")
	var font: KreditBaris = null
	for b in _tentang.baris():
		if b.punya_lisensi() and b.judul_teks != "Godot Engine":
			font = b
			break
	assert_bool(font.lisensi_terbuka()).is_false()
	font._tombol.pressed.emit()
	assert_bool(font.lisensi_terbuka()).is_true()
	assert_str(font._tombol.text).is_equal(tr("UI_KREDIT_SEMBUNYI"))
	assert_str(font.teks_lisensi()[0]).contains("SIL OPEN FONT LICENSE Version 1.1")
	font.alih()
	assert_bool(font.lisensi_terbuka()).is_false()
	assert_str(font._tombol.text).is_equal(tr("UI_KREDIT_LISENSI"))
	var godot := _baris("Godot Engine")
	godot.alih()
	var teks := godot.teks_lisensi()
	assert_str(teks[0]).is_equal(KreditBaris.rapikan(Engine.get_license_text()))
	assert_str(teks[1]).contains("FreeType")
	assert_int(teks.size()).is_equal(2 + Engine.get_license_info().size())


func test_rapikan_menyambung_paragraf_tapi_bukan_garis_dan_butir() -> void:
	var asal := "\n".join(PackedStringArray([
		"Baris pertama yang cukup panjang untuk disambung dengan baris",
		"berikutnya di paragraf yang sama.",
		"",
		"------------------------------------------------------------",
		"JUDUL PENDEK",
		"1) butir satu yang juga cukup panjang sampai lebih dari lima puluh",
		"2) butir dua",
	]))
	var harap := "\n".join(PackedStringArray([
		"Baris pertama yang cukup panjang untuk disambung dengan baris berikutnya di paragraf yang sama.",
		"",
		"------------------------------------------------------------",
		"JUDUL PENDEK",
		"1) butir satu yang juga cukup panjang sampai lebih dari lima puluh",
		"2) butir dua",
	]))
	assert_str(KreditBaris.rapikan(asal)).is_equal(harap)


func test_ikut_ganti_bahasa() -> void:
	_ganti_bahasa("id")
	Events.layar_diminta.emit("tentang")
	var musik: Dictionary = {}
	for e in DataDB.kredit:
		if e["jenis"] == "musik":
			musik = e
			break
	assert_str(_tentang.judul.text).is_equal("TENTANG")
	assert_str((_baris(musik["judul"]).get_child(1) as Label).text).is_equal("oleh %s" % musik["oleh"])
	_ganti_bahasa("en")
	assert_str(_tentang.judul.text).is_equal("ABOUT")
	assert_str((_baris(musik["judul"]).get_child(1) as Label).text).is_equal("by %s" % musik["oleh"])
