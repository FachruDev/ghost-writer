extends GdUnitTestSuite
## 0.6.0: kampanye akhir + E12, layar ending, penghasilan offline, spreadsheet balancing.

var _main: Node
var _ending := ""


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(23)
	_ending = ""
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	Events.ending_tercapai.connect(_catat_ending)


func after_test() -> void:
	Events.ending_tercapai.disconnect(_catat_ending)
	for nama in [&"ending", &"kontrak", &"dilema"]:
		GameClock.lanjut(nama)
	SaveSystem.reset_progres()


func _catat_ending(hasil: String) -> void:
	_ending = hasil


func _final() -> FinalController:
	return _main.get_node("FinalController")


func _sim() -> SpreadSim:
	return _main.get_node("RumorController").sim


func _semua_tokoh_jatuh() -> void:
	GameState.tambah_pengikut(int(DataDB.get_upgrade("menara_server")["pengikut_min"]))
	GameState.uang = 20000
	for u in ["kantor", "gedung_media", "menara_server"]:
		assert_bool(GameState.beli_upgrade(u)).is_true()
	for t in DataDB.tokoh:
		GameState.tokoh_reputasi[t["id"]] = 0
	Events.tokoh_berubah.emit()


func _ubah_semua(dari: SpreadSim.Status, ke: SpreadSim.Status, batas: int = 100000) -> void:
	var sim := _sim()
	var n := 0
	for i in sim.status.size():
		if sim.status[i] == dari and n < batas:
			sim.ubah_status(i, ke)
			n += 1


func test_kampanye_akhir_butuh_semua_tokoh_jatuh() -> void:
	assert_bool(FinalController.bisa_mulai()).is_false()
	Events.final_diminta.emit()
	assert_bool(GameState.final_berjalan).is_false()
	_semua_tokoh_jatuh()
	assert_bool(FinalController.bisa_mulai()).is_true()
	Events.final_diminta.emit()
	assert_bool(GameState.final_berjalan).is_true()
	assert_bool(_sim().kebal_bisa_pulih).is_false()
	assert_bool(FinalController.bisa_mulai()).is_false()


func test_awal_e12_semua_jadi_ragu_dan_ada_benih_kebal() -> void:
	_semua_tokoh_jatuh()
	_ubah_semua(SpreadSim.Status.BELUM, SpreadSim.Status.PERCAYA, 100)
	_ubah_semua(SpreadSim.Status.BELUM, SpreadSim.Status.KEBAL, 50)
	Events.final_diminta.emit()
	var sim := _sim()
	assert_int(sim.status.count(SpreadSim.Status.PERCAYA)).is_equal(0)
	assert_int(sim.status.count(SpreadSim.Status.BELUM)).is_equal(0)
	assert_int(sim.status.count(SpreadSim.Status.RAGU)).is_equal(sim.status.size() - roundi(sim.status.size() * Balance.FINAL_BENIH_KEBAL))
	assert_int(sim.status.count(SpreadSim.Status.KEBAL)).is_equal(roundi(sim.status.size() * Balance.FINAL_BENIH_KEBAL))


func test_kebal_menular_ke_tetangga_tapi_tidak_ke_pemercaya() -> void:
	_semua_tokoh_jatuh()
	var sim := _sim()
	_ubah_semua(SpreadSim.Status.BELUM, SpreadSim.Status.PERCAYA)
	sim.ubah_status(0, SpreadSim.Status.KEBAL)
	assert_int(_final().tularkan_kebal()).is_equal(0)
	for j in sim.tetangga(0):
		sim.ubah_status(j, SpreadSim.Status.BELUM)
	assert_int(_final().tularkan_kebal()).is_equal(1)
	assert_int(sim.status.count(SpreadSim.Status.KEBAL)).is_equal(2)


func test_menang_saat_target_percaya_tercapai() -> void:
	_semua_tokoh_jatuh()
	Events.final_diminta.emit()
	_ubah_semua(SpreadSim.Status.BELUM, SpreadSim.Status.PERCAYA)
	_ubah_semua(SpreadSim.Status.RAGU, SpreadSim.Status.PERCAYA)
	GameClock.jalankan_tick(1)
	assert_str(_ending).is_equal("menang")
	assert_str(GameState.hasil_akhir).is_equal("menang")
	assert_bool(GameState.final_berjalan).is_false()
	assert_bool(_sim().kebal_bisa_pulih).is_true()
	assert_bool(FinalController.bisa_mulai()).is_false()


func test_kalah_saat_waktu_habis_lalu_bisa_dicoba_lagi() -> void:
	_semua_tokoh_jatuh()
	Events.final_diminta.emit()
	var n := 0
	while _ending.is_empty() and n < ceili(Balance.FINAL_DURASI_DETIK / Balance.SIM_TICK) + 5:
		GameClock.jalankan_tick(1)
		n += 1
	assert_str(_ending).is_equal("kalah")
	assert_str(GameState.hasil_akhir).is_equal("kalah")
	assert_bool(FinalController.bisa_mulai()).is_true()


func test_kalah_saat_separuh_kota_kebal() -> void:
	_semua_tokoh_jatuh()
	Events.final_diminta.emit()
	_ubah_semua(SpreadSim.Status.BELUM, SpreadSim.Status.KEBAL)
	_ubah_semua(SpreadSim.Status.RAGU, SpreadSim.Status.KEBAL)
	GameClock.jalankan_tick(1)
	assert_str(_ending).is_equal("kalah")


func test_layar_ending_menjeda_waktu_dan_lanjut_bermain() -> void:
	_semua_tokoh_jatuh()
	GameState.catat_rumor({"template_id": "t_dasar", "warga_percaya": 40, "dibongkar": false,
		"kata_ids": {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}})
	Events.ending_tercapai.emit("menang")
	var ending := _main.get_node("Ending")
	assert_bool(ending.visible).is_true()
	assert_bool(GameClock.sedang_jeda()).is_true()
	assert_str(ending._judul.text).is_equal(Bahasa.teks(DataDB.endings["menang"]["judul"]))
	assert_int(ending._statistik.get_child_count()).is_equal(12)
	ending._on_lanjut()
	assert_bool(ending.visible).is_false()
	assert_bool(GameClock.sedang_jeda()).is_false()


func test_event_dan_kontrak_berhenti_selama_kampanye_akhir() -> void:
	_semua_tokoh_jatuh()
	var ec := _main.get_node("EventController")
	ec._mulai(DataDB.events[0])
	Events.final_diminta.emit()
	assert_bool(ec._aktif.is_empty()).is_true()
	ec._sejak_event = 9999.0
	ec._sejak_cek = 9999.0
	GameClock.jalankan_tick(1)
	assert_bool(ec._aktif.is_empty()).is_true()


## Kredibilitas 0 harus bisa pulih: +1 dari dipercaya dasar kartu, dan "orang lupa" di bawah batas.
func test_kredibilitas_rendah_bisa_pulih() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var skor := {"heboh_total": 3.0, "dipercaya": 0.9, "dipercaya_akhir": 0.45}
	var naik := 0
	for i in 50:
		var akhir := Konsekuensi.akhir_rumor(skor, 10, 0.0, rng)
		if not akhir["dibongkar"]:
			assert_float(akhir["kredibilitas"]).is_equal(Balance.KRED_NAIK)
			naik += 1
	assert_int(naik).is_greater(0)
	GameState.kredibilitas = 0.0
	GameClock.jalankan_tick(roundi(10.0 / Balance.SIM_TICK))
	assert_float(GameState.kredibilitas).is_equal_approx(10.0 * Balance.KRED_PULIH_PER_DETIK, 0.01)
	GameState.kredibilitas = Balance.KRED_PULIH_SAMPAI + 5.0
	GameClock.jalankan_tick(50)
	assert_float(GameState.kredibilitas).is_equal(Balance.KRED_PULIH_SAMPAI + 5.0)


func test_rumor_terbaik_tidak_dari_rumor_dibongkar() -> void:
	GameState.catat_rumor({"template_id": "t_dasar", "kata_ids": {}, "warga_percaya": 30, "dibongkar": false})
	GameState.catat_rumor({"template_id": "t_dasar", "kata_ids": {}, "warga_percaya": 90, "dibongkar": true})
	GameState.catat_rumor({"template_id": "t_dasar", "kata_ids": {}, "warga_percaya": 20, "dibongkar": false})
	assert_int(int(GameState.statistik["rumor_terbaik"]["warga_percaya"])).is_equal(30)


func test_hasil_akhir_tersimpan() -> void:
	GameState.hasil_akhir = "kalah"
	SaveSystem.simpan()
	GameState.mulai_baru()
	assert_bool(SaveSystem.muat()).is_true()
	assert_str(GameState.hasil_akhir).is_equal("kalah")


func test_penghasilan_offline_maks_8_jam_kali_setengah() -> void:
	var cfg := DataDB.get_upgrade("staf_1")
	assert_float(Economy.laju_pasif_per_detik(false, cfg)).is_equal(0.0)
	var laju := Economy.laju_pasif_per_detik(true, cfg)
	assert_float(laju).is_greater(0.0)
	assert_float(Economy.detik_offline(1000.0, 1000.0 + 10 * 3600)).is_equal(Balance.OFFLINE_MAKS_DETIK)
	assert_float(Economy.detik_offline(5000.0, 1000.0)).is_equal(0.0)
	assert_int(Economy.uang_offline(laju, 8 * 3600)).is_equal(floori(laju * 8 * 3600 * 0.5))


func test_offline_ditambahkan_saat_memuat() -> void:
	GameState.tambah_pengikut(300)
	GameState.uang = 20000
	for u in ["kantor", "staf_1"]:
		assert_bool(GameState.beli_upgrade(u)).is_true()
	GameState.uang = 100
	var uang := GameState.uang
	var data := GameState.ke_dict()
	data["disimpan_unix"] = Time.get_unix_time_from_system() - 3600.0
	var f := FileAccess.open(SaveSystem.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	assert_bool(SaveSystem.muat()).is_true()
	var harap := Economy.uang_offline(Economy.laju_pasif_per_detik(true, DataDB.get_upgrade("staf_1")), 3600.0)
	assert_int(GameState.uang - uang).is_between(harap - 1, harap + 1)


func test_balance_json_sinkron_dengan_angka_csv() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Balance.PATH))
	var csv := _baca_csv("res://balancing/angka.csv")
	assert_int(csv.size()).is_equal(data.size())
	for b in csv:
		assert_bool(data.has(b[0])).override_failure_message("%s tidak ada di balance.json" % b[0]).is_true()
		var nilai := float(b[1]) if not "/" in b[1] else float(b[1].get_slice("/", 0)) / float(b[1].get_slice("/", 1))
		assert_float(float(data.get(b[0], -1))).is_equal_approx(nilai, 0.000001)
	# Tiap kunci di JSON dipakai balance.gd, dan sebaliknya.
	var sumber := FileAccess.get_file_as_string("res://scripts/systems/balance.gd")
	var dipakai := RegEx.create_from_string('_[fi]\\("([A-Z_]+)"\\)').search_all(sumber).map(func(m: RegExMatch) -> String: return m.get_string(1))
	assert_array(dipakai).contains_exactly_in_any_order(data.keys())


func test_harga_csv_sinkron_dengan_data() -> void:
	for b in _baca_csv("res://balancing/harga.csv"):
		var item: Dictionary
		match b[1]:
			"kata":
				item = DataDB.get_word(b[0])
			"template":
				item = DataDB.get_template(b[0])
			"tokoh":
				item = _tokoh(b[0])
			_:
				item = DataDB.get_upgrade(b[0])
		assert_bool(item.is_empty()).override_failure_message("%s tidak ada" % b[0]).is_false()
		var field: String = {"saluran": "biaya_kirim", "tokoh": "reputasi"}.get(b[1], "harga")
		assert_int(int(item.get(field, -1))).override_failure_message("%s.%s" % [b[0], field]).is_equal(int(b[2]))
		if not b[3].is_empty():
			assert_int(int(item.get("pengikut_min", -1))).is_equal(int(b[3]))


func _tokoh(id: String) -> Dictionary:
	for t in DataDB.tokoh:
		if t["id"] == id:
			return t
	return {}


func _baca_csv(path: String) -> Array[PackedStringArray]:
	var hasil: Array[PackedStringArray] = []
	var f := FileAccess.open(path, FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var sel := f.get_csv_line()
		if sel.size() >= 3 and not sel[0].is_empty():
			hasil.append(sel)
	return hasil
