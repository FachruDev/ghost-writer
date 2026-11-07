extends GdUnitTestSuite
## Lapisan tutorial (UI 0.9.0): tangan menunjuk node sasaran lewat grup, teks ikut bahasa,
## Lewati, dan sembunyi saat lembar lain menutupi meja.

const LAPISAN := preload("res://scenes/ui/tutorial_lapisan.gd")
const SLOT := ["subjek", "aksi", "tempat", "sumber"]

var _main: Node


func before_test() -> void:
	SaveSystem.reset_progres()
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)


func after_test() -> void:
	TranslationServer.set_locale(Bahasa.kode())
	for nama in [&"toko", &"dilema", &"kontrak"]:
		GameClock.lanjut(nama)
	SaveSystem.reset_progres()


func _lapisan():
	for n in _main.get_children():
		if n.get_script() == LAPISAN:
			return n
	return null


func _toko():
	for n in _main.get_children():
		if n.get_script() and str(n.get_script().resource_path).ends_with("shop.gd"):
			return n
	return null


func _bingkai(n := 4) -> void:
	for i in n:
		await get_tree().process_frame


func _sasaran() -> Control:
	return _lapisan()._sasaran.get("node")


func test_langkah_pertama_menunjuk_kartu_di_tangan() -> void:
	await _bingkai()
	var l = _lapisan()
	assert_bool(l._kanvas.visible).is_true()
	assert_bool(l._tangan.visible).is_true()
	assert_str(l._gelembung._teks.text).is_equal(tr("UI_TUT_ISI_SLOT"))
	assert_bool(_sasaran().is_in_group(TutorialSasaran.KARTU)).is_true()


func test_teks_ikut_ganti_bahasa() -> void:
	await _bingkai()
	TranslationServer.set_locale("en")
	Bahasa.bahasa_berubah.emit("en")
	assert_str(_lapisan()._gelembung._teks.text).is_equal("Tap a card to fill the empty slot")
	assert_str(_lapisan()._gelembung._lewati.text).starts_with("Skip")


func test_lewati_menyembunyikan_lapisan() -> void:
	await _bingkai()
	_lapisan()._gelembung._lewati.pressed.emit()
	await _bingkai()
	assert_bool(bool(GameState.statistik["tutorial_lewat"])).is_true()
	assert_bool(_lapisan()._kanvas.visible).is_false()


func test_lembar_lain_menutupi_tutorial() -> void:
	await _bingkai()
	Events.layar_diminta.emit("pengaturan")
	await _bingkai()
	assert_bool(_lapisan()._gelembung.visible).is_false()
	assert_bool(_lapisan()._tangan.visible).is_false()


func test_toko_lalu_beli_dengan_cadangan_filter_dan_tab() -> void:
	GameState.statistik["total_rumor"] = 1
	GameState.uang = 60
	Events.money_changed.emit(60)
	await _bingkai()
	assert_bool(_sasaran().is_in_group(TutorialSasaran.TOKO)).is_true()
	Events.toko_diminta.emit(true)
	await _bingkai()
	var info: Dictionary = _main.get_node("TutorialController").info()
	assert_str(str(info.get("sasaran"))).is_equal("beli")
	# Tetap tampil di atas toko (lembar layar penuh).
	assert_bool(_lapisan()._gelembung.visible).is_true()
	var beli := _sasaran()
	assert_bool(beli.is_in_group(TutorialSasaran.BELI)).is_true()
	assert_str(str(beli.get_parent().get_parent().get_parent().get_meta("kata_id"))).is_equal(str(info["kata_id"]))
	var toko = _toko()
	var slot_kata := str(DataDB.get_word(str(info["kata_id"])).get("slot", ""))
	toko._filter = SLOT[(SLOT.find(slot_kata) + 1) % SLOT.size()]
	toko._segarkan()
	await _bingkai()
	assert_bool(_sasaran().is_in_group(TutorialSasaran.FILTER_SEMUA)).is_true()
	toko._tab = "template"
	toko._segarkan()
	await _bingkai()
	assert_bool(_sasaran().is_in_group(TutorialSasaran.TAB_KATA)).is_true()


func test_selesai_dirayakan_lalu_hilang() -> void:
	GameState.statistik["total_rumor"] = 1
	GameState.uang = 60
	Events.money_changed.emit(60)
	Events.toko_diminta.emit(true)
	await _bingkai()
	var info: Dictionary = _main.get_node("TutorialController").info()
	assert_bool(GameState.beli_kata(str(info["kata_id"]))).is_true()
	await _bingkai()
	var l = _lapisan()
	assert_bool(l._kanvas.visible).is_true()
	assert_bool(l._tangan.visible).is_false()
	assert_str(l._gelembung._teks.text).is_equal(tr("UI_TUT_SELESAI"))
	assert_bool(l._gelembung._lewati.visible).is_false()
