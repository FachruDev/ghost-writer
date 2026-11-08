extends GdUnitTestSuite
## Petunjuk singkat saat sistem baru terbuka (CHECKLIST 0.9.0): kredibilitas, saluran, staf.

var _main: Node
var _tampil: Array = []


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(7)
	_tampil = []
	Events.petunjuk_tampil.connect(_catat)


func after_test() -> void:
	Events.petunjuk_tampil.disconnect(_catat)
	GameClock.lanjut(&"toko")
	SaveSystem.reset_progres()


func _catat(info: Dictionary) -> void:
	_tampil.append(info.duplicate())


func _mulai(tutorial_selesai := true) -> void:
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	GameState.statistik["tutorial_lewat"] = tutorial_selesai


func _detik(d: float) -> void:
	GameClock.jalankan_tick(roundi(d / Balance.SIM_TICK))


func _id() -> Array:
	return _tampil.map(func(i: Dictionary) -> String: return str(i["id"]))


func test_kredibilitas_muncul_setelah_rumor_selesai_dan_jeda() -> void:
	_mulai()
	Events.rumor_selesai.emit({})
	_detik(2.0)
	assert_array(_tampil).is_empty()
	_detik(1.4)
	assert_array(_id()).is_equal(["kredibilitas"])
	assert_str(str(_tampil[0]["sasaran"])).is_equal("kredibilitas")
	var teks := PetunjukController.teks(_tampil[0])
	assert_str(teks).is_not_empty()
	assert_str(teks).is_not_equal("UI_TIP_KREDIBILITAS")


func test_menunggu_tutorial_selesai() -> void:
	_mulai(false)
	Events.rumor_selesai.emit({})
	_detik(10.0)
	assert_array(_tampil).is_empty()
	Events.tutorial_dilewati.emit()
	_detik(3.4)
	assert_array(_id()).is_equal(["kredibilitas"])


func test_tidak_muncul_saat_waktu_dijeda() -> void:
	_mulai()
	Events.rumor_selesai.emit({})
	GameClock.jeda(&"toko")
	_detik(5.0)
	assert_array(_tampil).is_empty()
	GameClock.lanjut(&"toko")
	_detik(3.4)
	assert_array(_id()).is_equal(["kredibilitas"])


func test_satu_per_satu_dan_sekali_saja() -> void:
	_mulai()
	Events.rumor_selesai.emit({})
	GameState.tambah_pengikut(100)  # Koran terbuka
	_detik(3.4)
	assert_array(_id()).is_equal(["kredibilitas"])
	_detik(10.0)
	assert_array(_id()).is_equal(["kredibilitas"])  # menunggu petunjuk_ditutup
	Events.petunjuk_ditutup.emit()
	_detik(3.4)
	assert_array(_id()).is_equal(["kredibilitas", "saluran_koran"])
	assert_str(str(_tampil[1]["nilai"])).is_equal("koran")
	var nama := Bahasa.teks(DataDB.get_upgrade("koran")["nama"])
	assert_str(PetunjukController.teks(_tampil[1])).contains(nama)
	Events.petunjuk_ditutup.emit()
	Events.rumor_selesai.emit({})
	GameState.tambah_pengikut(-50)
	GameState.tambah_pengikut(50)  # Koran tertutup lalu terbuka lagi: bukan saluran baru
	_detik(10.0)
	assert_int(_tampil.size()).is_equal(2)


func test_saluran_yang_sudah_terbuka_saat_dimuat_tidak_dipetunjukkan() -> void:
	SaveSystem.selesaikan_reset()
	GameState.pengikut = 100
	_mulai()
	Events.pengikut_berubah.emit(100)
	_detik(5.0)
	assert_array(_tampil).is_empty()


func test_era_2_radio_lalu_staf() -> void:
	_mulai()
	GameState.uang = 5000
	GameState.tambah_pengikut(int(DataDB.get_upgrade("kantor")["pengikut_min"]))
	assert_bool(GameState.beli_upgrade("kantor")).is_true()
	assert_bool(GameState.beli_upgrade("staf_1")).is_true()
	for i in 3:
		_detik(3.4)
		Events.petunjuk_ditutup.emit()
	assert_array(_id()).is_equal(["saluran_koran", "saluran_radio", "staf"])
	assert_int(int(_tampil[2]["nilai"])).is_equal(int(DataDB.get_upgrade("staf_1")["jeda_detik"]))
	assert_str(PetunjukController.teks(_tampil[2])).contains(str(int(_tampil[2]["nilai"])))


func test_petunjuk_dilihat_tersimpan_di_save() -> void:
	_mulai()
	Events.rumor_selesai.emit({})
	_detik(3.4)
	var data := GameState.ke_dict()
	GameState.mulai_baru()
	assert_bool(PetunjukController.sudah_dilihat(GameState, "kredibilitas")).is_false()
	GameState.dari_dict(JSON.parse_string(JSON.stringify(data)))
	assert_bool(PetunjukController.sudah_dilihat(GameState, "kredibilitas")).is_true()
	(data["statistik"] as Dictionary).erase("petunjuk")  # save sebelum fitur ini
	GameState.dari_dict(data)
	assert_array(GameState.statistik["petunjuk"]).is_empty()
