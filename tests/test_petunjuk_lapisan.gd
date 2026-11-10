extends GdUnitTestSuite
## Lapisan petunjuk (UI 0.9.0): kartu tampil dekat sasaran, Oke memancarkan petunjuk_ditutup,
## menunggu lembar yang terbuka, ikut ganti bahasa, dan lapisan baru membaca petunjuk aktif.

const LAPISAN := preload("res://scenes/ui/petunjuk_lapisan.gd")

var _main: Node
var _ditutup := 0


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(7)
	_ditutup = 0
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	GameState.statistik["tutorial_lewat"] = true
	Events.petunjuk_ditutup.connect(_catat)


func after_test() -> void:
	Events.petunjuk_ditutup.disconnect(_catat)
	TranslationServer.set_locale(Bahasa.kode())
	GameClock.lanjut(&"toko")
	SaveSystem.reset_progres()


func _catat() -> void:
	_ditutup += 1


func _lapisan():
	for n in _main.get_children():
		if n.get_script() == LAPISAN:
			return n
	return null


func _bingkai(n := 4) -> void:
	for i in n:
		await get_tree().process_frame


## Rumor selesai -> petunjuk kredibilitas muncul setelah JEDA_ANTAR detik simulasi.
func _picu_kredibilitas() -> void:
	Events.rumor_selesai.emit({})
	GameClock.jalankan_tick(roundi((PetunjukController.JEDA_ANTAR + 0.4) / Balance.SIM_TICK))
	await _bingkai()


func test_kartu_tampil_dekat_bar_kredibilitas() -> void:
	await _picu_kredibilitas()
	var l = _lapisan()
	assert_str(str(l.info().get("id"))).is_equal("kredibilitas")
	assert_bool(l.tampak()).is_true()
	assert_bool(l._kartu.visible).is_true()
	assert_str(l._kartu._teks.text).is_equal(PetunjukController.teks(l.info()))
	assert_str(l._kartu._tombol.text).is_equal(tr("UI_TIP_OKE"))
	var sasaran: Rect2 = l._sasaran
	assert_bool(sasaran.has_area()).is_true()
	# Bar ada di HUD atas: kartu di bawahnya, tidak menutupinya.
	assert_float(l._kartu.position.y).is_greater(sasaran.end.y)


func test_oke_memancarkan_ditutup_dan_petunjuk_berikut_boleh_muncul() -> void:
	await _picu_kredibilitas()
	var l = _lapisan()
	l._kartu._tombol.pressed.emit()
	await get_tree().create_timer(0.4).timeout
	assert_int(_ditutup).is_equal(1)
	assert_dict(l.info()).is_empty()
	assert_bool(l._kanvas.visible).is_false()
	assert_dict(_main.get_node("PetunjukController").info()).is_empty()


func test_menunggu_lembar_yang_terbuka() -> void:
	Events.layar_diminta.emit("saluran")  # lembar saluran tidak menjeda waktu
	await _picu_kredibilitas()
	var l = _lapisan()
	assert_str(str(l.info().get("id"))).is_equal("kredibilitas")
	assert_bool(l.tampak()).is_false()
	assert_bool(l._kartu.visible).is_false()
	l._tutup()  # belum terlihat: tidak boleh dianggap terbaca
	await get_tree().create_timer(0.3).timeout
	assert_int(_ditutup).is_equal(0)
	for n in _main.get_children():
		if n is Lembar and n.visible:
			n.tutup()
	await _bingkai()
	assert_bool(l.tampak()).is_true()


func test_teks_ikut_ganti_bahasa() -> void:
	await _picu_kredibilitas()
	TranslationServer.set_locale("en")
	Bahasa.bahasa_berubah.emit("en")
	var l = _lapisan()
	assert_str(l._kartu._teks.text).starts_with("Credibility drops")
	assert_str(l._kartu._tombol.text).is_equal("Got it")


func test_lapisan_baru_membaca_petunjuk_aktif() -> void:
	await _picu_kredibilitas()
	var baru = LAPISAN.new()  # dibebaskan bersama main
	_main.add_child(baru)
	assert_str(str(baru.info().get("id"))).is_equal("kredibilitas")
