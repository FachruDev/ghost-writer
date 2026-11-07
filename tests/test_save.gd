extends GdUnitTestSuite
## 0.9.0 (save): cadangan saat save rusak, save skema lama, migrasi, dan waktu proyeksi (ADR-0002, ADR-0003).

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}


func before_test() -> void:
	SaveSystem.reset_progres()
	for path in [SaveSystem.PATH_RUSAK]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func after_test() -> void:
	SaveSystem.reset_progres()


func _simpan_dengan_uang(uang: int) -> void:
	GameState.uang = uang
	assert_int(SaveSystem.simpan()).is_equal(OK)


func _rusak(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{\"pemain\": {\"uang\": 9")  # terpotong di tengah tulis
	f.close()


func test_save_rusak_dimuat_dari_cadangan() -> void:
	_simpan_dengan_uang(111)
	_simpan_dengan_uang(222)
	_simpan_dengan_uang(333)  # .bak harus ikut berganti walau sudah ada (Windows dan Android)
	_rusak(SaveSystem.PATH)
	GameState.mulai_baru()
	assert_bool(SaveSystem.muat()).is_true()
	assert_int(GameState.uang).is_equal(222)
	assert_bool(FileAccess.file_exists(SaveSystem.PATH_RUSAK)).is_true()


func test_semua_save_rusak_berarti_game_baru_tanpa_crash() -> void:
	_simpan_dengan_uang(111)
	_simpan_dengan_uang(222)
	_rusak(SaveSystem.PATH)
	_rusak(SaveSystem.PATH_BAK)
	GameState.mulai_baru()
	assert_bool(SaveSystem.muat()).is_false()
	assert_int(GameState.uang).is_equal(Balance.UANG_AWAL)


func test_save_skema_lama_0_2_0_tetap_termuat() -> void:
	# Save dari 0.2.0: belum ada upgrade, kartu sementara, tokoh, hasil akhir; angka tersimpan sebagai float.
	var lama := {
		"versi_skema": 1, "versi_game": "0.2.0", "disimpan_unix": Time.get_unix_time_from_system(),
		"pemain": {"uang": 50.0, "pengikut": 30.0, "kredibilitas": 55.0, "heat": 10.0, "era": 1.0,
			"waktu_main_detik": 600.0, "misi_idx": 2.0},
		"kartu_dimiliki": ["pak_rt", "kata_yang_sudah_dihapus"],
		"template_dimiliki": ["t_dasar"],
		"distrik_status": {"pasar_lama": {"percaya": 5.0, "ragu": 2.0, "kebal": 1.0}},
		"riwayat_rumor": [], "riwayat_event": [],
		"statistik": {"total_rumor": 5.0, "total_uang": 120.0, "total_dibongkar": 1.0, "kata_dibeli": 0.0,
			"rekor_warga": 12.0, "emosi_distrik": []},
	}
	var f := FileAccess.open(SaveSystem.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(lama))
	f.close()
	assert_bool(SaveSystem.muat()).is_true()
	assert_int(GameState.uang).is_equal(50)
	assert_int(GameState.misi_idx).is_equal(2)
	assert_array(GameState.kartu_dimiliki).contains_exactly(["pak_rt"])
	assert_dict(GameState.upgrade_dimiliki).is_empty()
	assert_dict(GameState.tokoh_reputasi).is_empty()
	assert_str(GameState.hasil_akhir).is_equal("")
	assert_int(int(GameState.statistik["total_rumor"])).is_equal(5)
	assert_array(GameState.statistik["event_sekali"]).is_empty()
	assert_that(GameState.statistik["rumor_terbaik"]).is_null()


func test_migrasi_dijalankan_berurutan_dari_versi_save() -> void:
	var daftar := [
		func(d: Dictionary) -> Dictionary:
			d["urutan"] = str(d.get("urutan", "")) + "a"
			return d,
		func(d: Dictionary) -> Dictionary:
			d["urutan"] = str(d.get("urutan", "")) + "b"
			return d,
	]
	var dari_1: Dictionary = SaveSystem._migrasi({"versi_skema": 1}, daftar)
	assert_str(dari_1["urutan"]).is_equal("ab")
	assert_int(int(dari_1["versi_skema"])).is_equal(3)
	var dari_2: Dictionary = SaveSystem._migrasi({"versi_skema": 2}, daftar)
	assert_str(dari_2["urutan"]).is_equal("b")
	assert_bool(SaveSystem._migrasi({"versi_skema": 3}, daftar).has("urutan")).is_false()


## ADR-0003: proyeksi rumor saat menyimpan < 50 ms. Diukur dengan kota terbesar (Era 4, 260 warga)
## dan rumor server yang baru dikirim. Desktop jauh lebih cepat dari HP kelas bawah; angkanya dicetak.
func test_proyeksi_save_cepat_di_kota_terbesar() -> void:
	GameClock.atur_seed(9)
	var main: Node = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(main)
	GameState.tambah_pengikut(int(DataDB.get_upgrade("menara_server")["pengikut_min"]))
	GameState.uang = 20000
	for u in ["kantor", "gedung_media", "menara_server"]:
		assert_bool(GameState.beli_upgrade(u)).is_true()
	var rumor := main.get_node("RumorController")
	Events.kirim_diminta.emit({"template_id": "t_dasar", "kata_ids": IDS, "distrik_id": "", "saluran_id": "server"})
	GameClock.jalankan_tick(5)
	assert_bool(rumor.sim.ada_rumor_aktif()).is_true()
	var terlama := 0
	for i in 5:
		var mulai := Time.get_ticks_usec()
		rumor.snapshot_untuk_save()
		terlama = maxi(terlama, Time.get_ticks_usec() - mulai)
	print("Proyeksi save terlama (desktop): %.1f ms" % (terlama / 1000.0))
	assert_int(terlama).is_less(50000)


func test_pengaturan_tersimpan_dan_tidak_terhapus_saat_reset_progres() -> void:
	var bahasa_awal := Bahasa.kode()
	Pengaturan.atur("musik", 0.4)
	SaveSystem.reset_progres()
	var cfg := ConfigFile.new()
	assert_int(cfg.load(Pengaturan.PATH)).is_equal(OK)
	assert_float(float(cfg.get_value(Pengaturan.BAGIAN, "musik", -1.0))).is_equal_approx(0.4, 0.001)
	assert_str(str(cfg.get_value("umum", "bahasa", bahasa_awal))).is_equal(bahasa_awal)
	Pengaturan.atur("musik", 1.0)


func test_volume_nol_membisukan_bus() -> void:
	var sfx := AudioServer.get_bus_index("SFX")
	Pengaturan.atur("sfx", 0.0)
	assert_bool(AudioServer.is_bus_mute(sfx)).is_true()
	Pengaturan.atur("sfx", 0.5)
	assert_bool(AudioServer.is_bus_mute(sfx)).is_false()
	assert_float(AudioServer.get_bus_volume_db(sfx)).is_less(Suara.VOLUME_SFX_DB)
	Pengaturan.atur("sfx", 1.0)
	assert_float(AudioServer.get_bus_volume_db(sfx)).is_equal_approx(Suara.VOLUME_SFX_DB, 0.01)


func test_getar_bisa_dimatikan() -> void:
	Pengaturan.atur("getar", false)
	assert_bool(Getar.getar(30)).is_false()
	Pengaturan.atur("getar", true)
	assert_bool(Getar.getar(30)).is_true()
