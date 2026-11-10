extends GdUnitTestSuite
## Alur permainan lewat main scene: rumor, saluran, misi, event, save (ADR-0002/0003).

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}

var _main: Node
var _hasil: Dictionary = {}


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(7)
	_hasil = {}
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	Events.rumor_selesai.connect(_simpan_hasil)


func after_test() -> void:
	Events.rumor_selesai.disconnect(_simpan_hasil)
	SaveSystem.reset_progres()


func _simpan_hasil(h: Dictionary) -> void:
	_hasil = h


func _rumor() -> Node:
	return _main.get_node("RumorController")


func _kirim(saluran: String, distrik: String) -> void:
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": IDS, "distrik_id": distrik, "saluran_id": saluran})


func _sampai_selesai() -> void:
	var n := 0
	while _hasil.is_empty() and n < 600:
		GameClock.jalankan_tick(1)
		n += 1


func test_rumor_merpati_memberi_uang_dan_tercatat() -> void:
	_kirim("merpati", "pasar_lama")
	assert_float(GameState.heat).is_greater(0.0)
	_sampai_selesai()
	assert_bool(_hasil.is_empty()).is_false()
	assert_int(int(_hasil["uang"])).is_equal(int(_hasil["warga_percaya"]) * Balance.UANG_PER_WARGA)
	assert_int(GameState.riwayat_rumor.size()).is_equal(1)
	assert_int(int(GameState.statistik["total_rumor"])).is_equal(1)


func test_koran_terkunci_lalu_terbuka() -> void:
	GameState.uang = 100
	_kirim("koran", "")
	assert_bool(_rumor().sim.ada_rumor_aktif()).is_false()
	GameState.tambah_pengikut(100)
	assert_bool(GameState.saluran_terbuka("koran")).is_true()
	_kirim("koran", "")
	assert_bool(_rumor().sim.ada_rumor_aktif()).is_true()
	for d in 3:
		assert_int(_rumor().sim.jumlah_status(d, SpreadSim.Status.PERCAYA)).is_greater(0)


func test_misi_berurutan_dan_hadiah() -> void:
	GameState.statistik["kata_dibeli"] = 2
	GameState.statistik["rekor_warga"] = 25
	GameState.statistik["total_rumor"] = 1
	GameState.statistik["emosi_distrik"] = ["takut@gang_sempit"]
	GameState.tambah_pengikut(150)
	assert_int(GameState.misi_idx).is_equal(5)
	assert_int(GameState.uang).is_equal(20 + 30 + 30 + 40 + 50)


func test_event_modifier_dan_ancaman() -> void:
	var ec := _main.get_node("EventController")
	ec._mulai(DataDB.events[0])
	var pasar := DataDB.district_index("pasar_lama")
	assert_float(ec.pengali_viral(pasar, "iri")).is_equal_approx(1.5, 0.001)
	GameState.ubah_heat(100.0)
	ec._sejak_ancaman = 999.0
	var kred := GameState.kredibilitas
	GameClock.jalankan_tick(1)
	assert_float(GameState.kredibilitas).is_less_equal(kred - 9.0)
	# Ancaman tidak menimpa event acak yang sedang aktif.
	assert_float(ec.pengali_viral(pasar, "iri")).is_equal_approx(1.5, 0.001)


func test_save_proyeksi_muat_dan_cadangan() -> void:
	_kirim("merpati", "pasar_lama")
	var snap: Dictionary = _rumor().snapshot_untuk_save()
	assert_bool(snap["delta"].is_empty()).is_false()
	var uang := GameState.uang
	assert_int(SaveSystem.simpan()).is_equal(OK)
	assert_int(GameState.uang).is_equal(uang)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.PATH))
	assert_int(int(data["versi_skema"])).is_equal(SaveSystem.VERSI_SKEMA)
	assert_bool(data.has("disimpan_unix")).is_true()
	assert_int(int(data["pemain"]["uang"])).is_equal(uang + int(snap["delta"]["uang"]))
	GameState.uang = 999999
	assert_bool(SaveSystem.muat()).is_true()
	assert_int(GameState.uang).is_equal(int(data["pemain"]["uang"]))
	assert_int(typeof(GameState.uang)).is_equal(TYPE_INT)
	SaveSystem.simpan()
	var f := FileAccess.open(SaveSystem.PATH, FileAccess.WRITE)
	f.store_string("{rusak")
	f.close()
	GameState.uang = 1
	assert_bool(SaveSystem.muat()).is_true()
	assert_int(GameState.uang).is_not_equal(1)
