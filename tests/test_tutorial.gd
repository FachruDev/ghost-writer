extends GdUnitTestSuite
## Tutorial tiga langkah (CHECKLIST 0.9.0): isi slot → kirim → beli kata.

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}
const MEJA_LENGKAP := {"lengkap": true, "butuh_distrik": false, "siap": true, "rumor_aktif": false}

var _main: Node
var _langkah: Array = []


func before_test() -> void:
	SaveSystem.reset_progres()
	_langkah = []


func after_test() -> void:
	if Events.tutorial_langkah.is_connected(_catat):
		Events.tutorial_langkah.disconnect(_catat)
	GameClock.lanjut(&"toko")
	SaveSystem.reset_progres()


func _catat(info: Dictionary) -> void:
	_langkah.append(info.duplicate())


func _hitung(meja: Dictionary, terkirim := false, jeda: Array = []) -> Dictionary:
	return TutorialController.hitung(GameState, DataDB.words, meja, terkirim, jeda)


func test_langkah_satu_dan_dua_mengikuti_meja() -> void:
	assert_str(str(_hitung({}).get("sasaran"))).is_equal("kartu")
	assert_int(int(_hitung({}).get("langkah"))).is_equal(1)
	var meja := MEJA_LENGKAP.duplicate()
	meja["butuh_distrik"] = true
	meja["siap"] = false
	assert_str(str(_hitung(meja).get("sasaran"))).is_equal("distrik")
	meja["butuh_distrik"] = false
	assert_str(str(_hitung(meja).get("sasaran"))).is_equal("saluran")
	var info := _hitung(MEJA_LENGKAP)
	assert_str(str(info.get("sasaran"))).is_equal("kirim")
	assert_int(int(info.get("langkah"))).is_equal(2)
	assert_str(str(info.get("kunci"))).is_equal("UI_TUT_KIRIM")


func test_lembar_yang_menutupi_meja_menyembunyikan_tutorial() -> void:
	assert_dict(_hitung({}, false, [&"toko"])).is_empty()
	assert_dict(_hitung({}, false, [&"dilema"])).is_empty()
	var meja := MEJA_LENGKAP.duplicate()
	meja["rumor_aktif"] = true
	assert_dict(_hitung(meja)).is_empty()


func test_langkah_tiga_menunggu_uang_cukup() -> void:
	GameState.uang = 0
	assert_dict(_hitung(MEJA_LENGKAP, true)).is_empty()
	GameState.uang = 40
	var info := _hitung(MEJA_LENGKAP, true)
	assert_str(str(info.get("sasaran"))).is_equal("toko")
	assert_int(int(info.get("langkah"))).is_equal(3)
	var kata := DataDB.get_word(str(info.get("kata_id")))
	assert_int(int(kata.get("harga", 0))).is_equal(40)
	assert_bool(GameState.punya_kata(str(info["kata_id"]))).is_false()
	var di_toko := _hitung(MEJA_LENGKAP, true, [&"toko"])
	assert_str(str(di_toko.get("sasaran"))).is_equal("beli")
	assert_str(str(di_toko.get("kata_id"))).is_equal(str(info["kata_id"]))
	assert_dict(_hitung(MEJA_LENGKAP, true, [&"toko", &"dilema"])).is_empty()


func test_rumor_tercatat_dari_save_dianggap_terkirim() -> void:
	GameState.uang = 40
	GameState.statistik["total_rumor"] = 1
	assert_str(str(_hitung({}).get("sasaran"))).is_equal("toko")


func test_selesai_saat_kata_dibeli_era_naik_atau_dilewati() -> void:
	GameState.uang = 500
	GameState.statistik["kata_dibeli"] = 1
	assert_dict(_hitung({}, true)).is_empty()
	GameState.statistik["kata_dibeli"] = 0
	GameState.era = 2
	assert_dict(_hitung({})).is_empty()
	GameState.era = 1
	GameState.statistik["tutorial_lewat"] = true
	assert_dict(_hitung({})).is_empty()
	assert_bool(TutorialController.selesai(GameState)).is_true()


func test_lewati_tersimpan_di_save() -> void:
	GameState.statistik["tutorial_lewat"] = true
	var data := GameState.ke_dict()
	GameState.mulai_baru()
	assert_bool(bool(GameState.statistik["tutorial_lewat"])).is_false()
	GameState.dari_dict(JSON.parse_string(JSON.stringify(data)))
	assert_bool(bool(GameState.statistik["tutorial_lewat"])).is_true()


func test_save_lama_tanpa_kunci_tutorial_termuat() -> void:
	var data := GameState.ke_dict()
	(data["statistik"] as Dictionary).erase("tutorial_lewat")
	GameState.dari_dict(data)
	assert_bool(bool(GameState.statistik["tutorial_lewat"])).is_false()


## Alur lengkap lewat main scene: sinyal asli dari meja, rumor, toko, dan pembelian.
func test_alur_di_main_scene() -> void:
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	Events.tutorial_langkah.connect(_catat)
	var tutor: TutorialController = _main.get_node("TutorialController")
	tutor._umumkan()
	assert_str(str(tutor.info().get("sasaran"))).is_equal("kartu")
	for slot in IDS:
		Events.kartu_dipilih.emit(IDS[slot])
	tutor._umumkan()
	assert_str(str(tutor.info().get("sasaran"))).is_equal("distrik")
	Events.distrik_dipilih.emit("pasar_lama")
	tutor._umumkan()
	assert_str(str(tutor.info().get("sasaran"))).is_equal("kirim")
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": IDS, "distrik_id": "pasar_lama", "saluran_id": "merpati"})
	GameState.uang = 0
	GameState.tambah_uang(0)
	tutor._umumkan()
	assert_dict(tutor.info()).is_empty()
	GameState.tambah_uang(45)
	tutor._umumkan()
	assert_str(str(tutor.info().get("sasaran"))).is_equal("toko")
	Events.toko_diminta.emit(true)
	tutor._umumkan()
	assert_str(str(tutor.info().get("sasaran"))).is_equal("beli")
	assert_bool(GameState.beli_kata(str(tutor.info()["kata_id"]))).is_true()
	tutor._umumkan()
	assert_dict(tutor.info()).is_empty()
	assert_bool(TutorialController.selesai(GameState)).is_true()
	var sasaran: Array = _langkah.map(func(i: Dictionary) -> String: return str(i.get("sasaran", "")))
	assert_array(sasaran).is_equal(["kartu", "distrik", "kirim", "", "toko", "beli", ""])
