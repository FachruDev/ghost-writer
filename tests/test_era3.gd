extends GdUnitTestSuite
## Era 3 (0.4.0): gedung media, peta 6 distrik, medsos, kontrak kampanye, E07–E09.

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}

var _main: Node


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(13)
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)


func after_test() -> void:
	GameClock.lanjut(&"kontrak")
	GameClock.lanjut(&"dilema")
	SaveSystem.reset_progres()


func _rumor() -> Node:
	return _main.get_node("RumorController")


func _naik_era_3() -> void:
	GameState.tambah_pengikut(int(DataDB.get_upgrade("gedung_media")["pengikut_min"]))
	GameState.uang = 5000
	assert_bool(GameState.beli_upgrade("kantor")).is_true()
	assert_bool(GameState.beli_upgrade("gedung_media")).is_true()


func test_gedung_media_meluaskan_peta_dan_mempertahankan_warga() -> void:
	var sim_lama: SpreadSim = _rumor().sim
	sim_lama.terapkan_jumlah(0, 12, 0, 5)
	_naik_era_3()
	assert_int(GameState.era).is_equal(3)
	assert_int(DataDB.districts.size()).is_equal(6)
	var sim: SpreadSim = _rumor().sim
	assert_object(sim).is_not_same(sim_lama)
	assert_int(sim.posisi.size()).is_equal(200)
	assert_int(sim.jumlah_status(0, SpreadSim.Status.PERCAYA)).is_equal(12)
	assert_int(sim.jumlah_status(0, SpreadSim.Status.KEBAL)).is_equal(5)
	# Tata letak era 3: Pasar Lama mengecil ke sepertiga atas.
	assert_float(float(DataDB.districts[0]["area"][3])).is_equal_approx(0.34, 0.001)
	assert_object(_main.get_node("EventController").sim).is_same(sim)


func test_peta_meluas_saat_rumor_berjalan_menyelesaikannya_dulu() -> void:
	GameState.tambah_pengikut(int(DataDB.get_upgrade("gedung_media")["pengikut_min"]))
	GameState.uang = 5000
	GameState.beli_upgrade("kantor")
	var hasil := {}
	var catat := func(h: Dictionary) -> void: hasil.merge(h, true)
	Events.rumor_selesai.connect(catat)
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": IDS, "distrik_id": "pasar_lama", "saluran_id": "merpati"})
	assert_bool(_rumor().sim.ada_rumor_aktif()).is_true()
	GameState.beli_upgrade("gedung_media")
	Events.rumor_selesai.disconnect(catat)
	assert_bool(hasil.is_empty()).is_false()
	assert_bool(_rumor().sim.ada_rumor_aktif()).is_false()


func test_medsos_melompat_antar_distrik() -> void:
	_naik_era_3()
	var rumor := _rumor()
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": IDS, "distrik_id": "pasar_lama", "saluran_id": "medsos"})
	assert_bool(rumor.sim.ada_rumor_aktif()).is_true()
	var n := 0
	while rumor.sim.ada_rumor_aktif() and n < 600:
		GameClock.jalankan_tick(1)
		n += 1
	var distrik_tersentuh := 0
	for d in DataDB.districts.size():
		if rumor.sim.jumlah_status(d, SpreadSim.Status.PERCAYA) + rumor.sim.jumlah_status(d, SpreadSim.Status.RAGU) > 0:
			distrik_tersentuh += 1
	assert_int(distrik_tersentuh).is_greater_equal(4)


func test_kontrak_ditawarkan_diterima_dan_berhasil() -> void:
	_naik_era_3()
	var kc := _main.get_node("CampaignController")
	kc._hitung = Balance.KONTRAK_JEDA_DETIK
	GameClock.jalankan_tick(1)
	assert_bool(GameClock.sedang_jeda()).is_true()
	Events.dilema_dipilih.emit(0)
	assert_bool(GameClock.sedang_jeda()).is_false()
	assert_bool(kc.ada_kontrak()).is_true()
	var target: Array = kc._kontrak["distrik"]
	for d in target:
		_rumor().sim.terapkan_jumlah(d, _rumor().sim.warga_per_distrik[d].size(), 0, 0)
	var uang := GameState.uang
	GameClock.jalankan_tick(1)
	assert_bool(kc.ada_kontrak()).is_false()
	assert_int(GameState.uang).is_equal(uang + Balance.KONTRAK_UANG)


func test_kontrak_gagal_saat_waktu_habis() -> void:
	_naik_era_3()
	var kc := _main.get_node("CampaignController")
	kc._hitung = Balance.KONTRAK_JEDA_DETIK
	GameClock.jalankan_tick(1)
	Events.dilema_dipilih.emit(0)
	var kred := GameState.kredibilitas
	kc._kontrak["sisa"] = 0.1
	GameClock.jalankan_tick(1)
	assert_bool(kc.ada_kontrak()).is_false()
	assert_float(GameState.kredibilitas).is_equal_approx(kred - Balance.KONTRAK_KRED_GAGAL, 0.5)


func test_tawaran_kontrak_bisa_ditolak() -> void:
	_naik_era_3()
	var kc := _main.get_node("CampaignController")
	kc._hitung = Balance.KONTRAK_JEDA_DETIK
	GameClock.jalankan_tick(1)
	Events.dilema_dipilih.emit(1)
	assert_bool(kc.ada_kontrak()).is_false()
	assert_bool(GameClock.sedang_jeda()).is_false()


func test_dokumen_bocor_hilang_setelah_3_rumor() -> void:
	GameState.beri_kartu_sementara("dokumen_bocor", 3)
	assert_bool(GameState.punya_kata("dokumen_bocor")).is_true()
	var ids := IDS.duplicate()
	ids["sumber"] = "dokumen_bocor"
	for i in 3:
		GameState.pakai_kartu(ids)
	assert_bool(GameState.punya_kata("dokumen_bocor")).is_false()


func test_viral_challenge_menurunkan_kred_kartu() -> void:
	var ec := _main.get_node("EventController")
	ec._mulai(DataDB.events[7])
	var p: Dictionary = ec.pengali_rumor(IDS)
	assert_int(int(p["kred"])).is_equal(-1)
	assert_float(ec.pengali_viral(0, "lucu")).is_equal_approx(2.0, 0.001)
	var kata := {}
	for s in IDS:
		kata[s] = DataDB.get_word(IDS[s])
	var normal := RumorScorer.nilai(DataDB.get_template("t_dasar"), kata, DataDB.districts, 50.0)
	var turun := RumorScorer.nilai(DataDB.get_template("t_dasar"), kata, DataDB.districts, 50.0, -1)
	assert_float(turun["dipercaya_akhir"]).is_less(normal["dipercaya_akhir"])


func test_razia_hoaks_mengunci_medsos_dan_mengurangi_pengikut() -> void:
	_naik_era_3()
	var ec := _main.get_node("EventController")
	GameState.ubah_kredibilitas(-100.0)
	ec._sejak_ancaman = 999.0
	var pengikut := GameState.pengikut
	GameClock.jalankan_tick(1)
	assert_bool(GameState.saluran_terbuka("medsos")).is_false()
	assert_int(GameState.pengikut).is_less(pengikut)
	GameClock.jalankan_tick(roundi(91.0 / Balance.SIM_TICK))
	assert_bool(GameState.saluran_terkunci.has("medsos")).is_false()
