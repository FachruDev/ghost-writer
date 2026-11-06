extends GdUnitTestSuite
## Era 2 (0.3.0): sewa kantor, radio siaran, staf otomatis, event E04–E06 dan dilema.

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}

var _main: Node
var _hasil: Dictionary = {}


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(11)
	_hasil = {}
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	Events.rumor_selesai.connect(_simpan_hasil)


func after_test() -> void:
	Events.rumor_selesai.disconnect(_simpan_hasil)
	GameClock.lanjut(&"dilema")
	SaveSystem.reset_progres()


func _simpan_hasil(h: Dictionary) -> void:
	_hasil = h


func _naik_era_2() -> void:
	GameState.tambah_pengikut(200)
	GameState.uang = 1000
	assert_bool(GameState.beli_upgrade("kantor")).is_true()


func test_sewa_kantor_butuh_200_pengikut_dan_400_uang() -> void:
	GameState.uang = 1000
	assert_bool(GameState.beli_upgrade("kantor")).is_false()
	GameState.tambah_pengikut(200)
	GameState.uang = 300
	assert_bool(GameState.beli_upgrade("kantor")).is_false()
	GameState.uang = 400
	assert_bool(GameState.beli_upgrade("kantor")).is_true()
	assert_int(GameState.era).is_equal(2)
	assert_int(GameState.uang).is_equal(0)
	assert_bool(GameState.upgrade_tersedia("kantor")).is_false()


func test_konten_era_2_terkunci_sampai_naik_era() -> void:
	assert_bool(GameState.saluran_terbuka("radio")).is_false()
	assert_bool(GameState.upgrade_tersedia("staf_1")).is_false()
	assert_bool(GameState.era_terbuka(DataDB.get_word("juragan_tanah"))).is_false()
	_naik_era_2()
	assert_bool(GameState.saluran_terbuka("radio")).is_true()
	assert_bool(GameState.upgrade_tersedia("staf_1")).is_true()
	assert_bool(GameState.era_terbuka(DataDB.get_word("juragan_tanah"))).is_true()


func test_radio_menyuntik_warga_selama_siaran() -> void:
	_naik_era_2()
	var rumor := _main.get_node("RumorController")
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": IDS, "distrik_id": "", "saluran_id": "radio"})
	assert_bool(rumor.sim.ada_rumor_aktif()).is_true()
	# Siaran 10 detik = 50 tick; rumor tidak boleh selesai sebelum itu.
	GameClock.jalankan_tick(49)
	assert_bool(_hasil.is_empty()).is_true()
	var n := 0
	while _hasil.is_empty() and n < 600:
		GameClock.jalankan_tick(1)
		n += 1
	assert_bool(_hasil.is_empty()).is_false()
	# Benih awal 1 per distrik + 4 suntikan x 3 distrik = setidaknya 15 warga percaya.
	assert_int(int(_hasil["warga_percaya"])).is_greater_equal(15)


func test_staf_mengirim_rumor_abstrak() -> void:
	_naik_era_2()
	GameState.uang = 250
	assert_bool(GameState.beli_upgrade("staf_1")).is_true()
	var uang := GameState.uang
	var feed: Array = []
	var catat := func(e: Dictionary) -> void: feed.append(e)
	Events.feed_baru.connect(catat)
	GameClock.jalankan_tick(roundi(40.0 / Balance.SIM_TICK))
	Events.feed_baru.disconnect(catat)
	assert_bool(feed.any(func(e: Dictionary) -> bool: return e["jenis"] == "staf")).is_true()
	assert_int(GameState.riwayat_rumor.size()).is_equal(1)
	assert_str(str(GameState.riwayat_rumor[0]["saluran_id"])).is_equal("staf")
	assert_int(GameState.uang).is_greater_equal(uang)


func test_rumus_staf() -> void:
	var skor := {"emosi": "lucu", "dipercaya_akhir": 0.5}
	assert_int(Staf.warga_percaya(skor, {"emosi_favorit": "lucu"}, 8.0)).is_equal(6)
	assert_int(Staf.warga_percaya(skor, {"emosi_favorit": "takut"}, 8.0)).is_equal(roundi(8 * 0.5 * Balance.PENGALI_COCOK_LAWAN))


func test_pemilihan_rt_sekali_di_300_pengikut() -> void:
	GameState.tambah_pengikut(300)
	GameClock.jalankan_tick(1)
	assert_bool(GameState.punya_kata("calon_darto")).is_true()
	assert_bool(GameState.punya_kata("calon_wati")).is_true()
	var ec := _main.get_node("EventController")
	var p: Dictionary = ec.pengali_rumor({"subjek": "calon_darto", "aksi": "menari_malam"})
	assert_float(p["uang"]).is_equal_approx(2.0, 0.001)
	assert_float(p["heat"]).is_equal_approx(1.5, 0.001)
	assert_float(ec.pengali_rumor(IDS)["uang"]).is_equal_approx(1.0, 0.001)
	assert_array(GameState.statistik["event_sekali"]).contains(["e_pemilihan_rt"])


func test_festival_semua_distrik_dan_uang() -> void:
	var ec := _main.get_node("EventController")
	ec._mulai(DataDB.events[5])
	for d in 3:
		assert_float(ec.pengali_viral(d, "lucu")).is_equal_approx(1.2, 0.001)
	assert_float(ec.pengali_rumor(IDS)["uang"]).is_equal_approx(1.5, 0.001)


func test_dilema_menjeda_waktu_dan_menerapkan_pilihan() -> void:
	var ec := _main.get_node("EventController")
	GameState.uang = 500
	GameState.ubah_heat(60.0)
	ec._mulai(DataDB.events[4])
	assert_bool(ec.sedang_dilema()).is_true()
	assert_bool(GameClock.sedang_jeda()).is_true()
	Events.dilema_dipilih.emit(0)
	assert_bool(ec.sedang_dilema()).is_false()
	assert_bool(GameClock.sedang_jeda()).is_false()
	assert_int(GameState.uang).is_equal(300)
	assert_float(GameState.heat).is_equal_approx(30.0, 0.001)


func test_save_menyimpan_era_dan_upgrade() -> void:
	_naik_era_2()
	SaveSystem.simpan()
	GameState.mulai_baru()
	assert_int(GameState.era).is_equal(1)
	assert_bool(SaveSystem.muat()).is_true()
	assert_int(GameState.era).is_equal(2)
	assert_bool(GameState.punya_upgrade("kantor")).is_true()
