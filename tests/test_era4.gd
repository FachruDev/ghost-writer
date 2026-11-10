extends GdUnitTestSuite
## Era 4 (0.5.0): menara server, peta 8 distrik, saluran server, tokoh target, E10–E11.

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}

var _main: Node
var _hasil: Dictionary = {}


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(17)
	_hasil = {}
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	Events.rumor_selesai.connect(_simpan_hasil)


func after_test() -> void:
	Events.rumor_selesai.disconnect(_simpan_hasil)
	GameClock.lanjut(&"kontrak")
	GameClock.lanjut(&"dilema")
	SaveSystem.reset_progres()


func _simpan_hasil(h: Dictionary) -> void:
	_hasil = h


func _rumor() -> Node:
	return _main.get_node("RumorController")


func _naik_era_4() -> void:
	GameState.tambah_pengikut(int(DataDB.get_upgrade("menara_server")["pengikut_min"]))
	GameState.uang = 20000
	for u in ["kantor", "gedung_media", "menara_server"]:
		assert_bool(GameState.beli_upgrade(u)).is_true()
	assert_int(GameState.era).is_equal(4)


func _kirim_tunggu(ids: Dictionary, saluran: String, distrik: String) -> void:
	_hasil = {}
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": ids, "distrik_id": distrik, "saluran_id": saluran})
	var n := 0
	while _hasil.is_empty() and n < 600:
		GameClock.jalankan_tick(1)
		n += 1


func test_menara_server_peta_8_distrik_dan_kartu_tokoh() -> void:
	_naik_era_4()
	assert_int(DataDB.districts.size()).is_equal(8)
	assert_int(_rumor().sim.posisi.size()).is_equal(260)
	for id in ["tokoh_hartono", "tokoh_sasmita", "tokoh_bramantyo"]:
		assert_bool(GameState.punya_kata(id)).is_true()
	assert_int(GameState.tokoh_reputasi.size()).is_equal(3)


func test_server_menyuntik_warga_acak_selama_15_detik() -> void:
	_naik_era_4()
	_kirim_tunggu(IDS, "server", "")
	assert_bool(_hasil.is_empty()).is_false()
	# Benih 1 + 14 suntikan; sebagian bisa jatuh pada warga yang sudah mendengar.
	assert_int(int(_hasil["warga_percaya"])).is_greater_equal(12)


func test_serangan_mengurangi_reputasi_tokoh() -> void:
	_naik_era_4()
	var ids := IDS.duplicate()
	ids["subjek"] = "tokoh_sasmita"
	var heat := GameState.heat
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": ids, "distrik_id": "pasar_lama", "saluran_id": "merpati"})
	var heat_humas := GameState.heat - heat
	var kata := {}
	for s in ids:
		kata[s] = DataDB.get_word(ids[s])
	var skor := RumorScorer.nilai(DataDB.get_template("t_dasar"), kata, DataDB.districts, GameState.kredibilitas)
	assert_float(heat_humas).is_equal_approx(Konsekuensi.heat_kirim(skor, 1.0) * 2.0, 0.01)
	var n := 0
	while _hasil.is_empty() and n < 600:
		GameClock.jalankan_tick(1)
		n += 1
	if not _hasil["dibongkar"]:
		assert_int(int(GameState.tokoh_reputasi["sasmita"])).is_equal(maxi(0, int(DataDB.tokoh[1]["reputasi"]) - int(_hasil["warga_percaya"])))


func test_pengacara_membantah_rumor_yang_kurang_dipercaya() -> void:
	_naik_era_4()
	var tc := _main.get_node("TokohController")
	var hartono: Dictionary = DataDB.tokoh[0]
	assert_bool(tc.membantah(hartono, {"dipercaya_akhir": 0.5})).is_true()
	assert_bool(tc.membantah(hartono, {"dipercaya_akhir": 0.7})).is_false()
	var rng := RandomNumberGenerator.new()
	assert_bool(Konsekuensi.akhir_rumor({"dipercaya_akhir": 0.9, "heboh_total": 1.0}, 10, 0.0, rng, true)["dibongkar"]).is_true()


func test_bramantyo_memicu_rumor_tandingan() -> void:
	_naik_era_4()
	var mulai: Array = []
	var catat := func(i: Dictionary) -> void: mulai.append(i["id"])
	Events.event_mulai.connect(catat)
	var ids := IDS.duplicate()
	ids["subjek"] = "tokoh_bramantyo"
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": ids, "distrik_id": "pasar_lama", "saluran_id": "merpati"})
	Events.event_mulai.disconnect(catat)
	assert_array(mulai).contains(["e_rumor_tandingan"])


func test_tokoh_jatuh_memberi_hadiah() -> void:
	_naik_era_4()
	var tc := _main.get_node("TokohController")
	var uang := GameState.uang
	tc.serang(DataDB.tokoh[1], int(DataDB.tokoh[1]["reputasi"]) + 50)
	assert_int(int(GameState.tokoh_reputasi["sasmita"])).is_equal(0)
	assert_int(GameState.uang).is_equal(uang + 2000)
	assert_dict(TokohController.tokoh_dari({"subjek": "tokoh_sasmita"})).is_empty()
	assert_bool(TokohController.semua_jatuh()).is_false()
	tc.serang(DataDB.tokoh[0], int(DataDB.tokoh[0]["reputasi"]))
	tc.serang(DataDB.tokoh[2], int(DataDB.tokoh[2]["reputasi"]))
	assert_bool(TokohController.semua_jatuh()).is_true()


func test_rumor_tandingan_membuat_pemercaya_ragu() -> void:
	var sim: SpreadSim = _rumor().sim
	sim.terapkan_jumlah(0, 30, 0, 0)
	var ec := _main.get_node("EventController")
	ec._ragukan(1.0)
	assert_int(sim.jumlah_status(0, SpreadSim.Status.PERCAYA)).is_equal(0)
	assert_int(sim.jumlah_status(0, SpreadSim.Status.RAGU)).is_equal(30)


func test_server_down_mematikan_staf_dan_server() -> void:
	_naik_era_4()
	GameState.uang = 300
	assert_bool(GameState.beli_upgrade("staf_1")).is_true()
	var ec := _main.get_node("EventController")
	ec._mulai(DataDB.events[10])
	assert_bool(ec.sedang_dilema()).is_true()
	Events.dilema_dipilih.emit(1)
	assert_bool(GameState.saluran_terbuka("server")).is_false()
	assert_bool(GameState.saluran_terkunci.has("staf_1")).is_true()


func test_save_menyimpan_reputasi_tokoh() -> void:
	_naik_era_4()
	GameState.tokoh_reputasi["hartono"] = 42
	SaveSystem.simpan()
	GameState.mulai_baru()
	assert_bool(SaveSystem.muat()).is_true()
	assert_int(int(GameState.tokoh_reputasi["hartono"])).is_equal(42)
	assert_int(DataDB.districts.size()).is_equal(8)
