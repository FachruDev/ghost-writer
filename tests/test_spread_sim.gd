extends GdUnitTestSuite
## SpreadSim: determinisme dengan seed, rumor berhenti, dan salinan untuk proyeksi (ADR-0003).


func _sim(seed: int) -> SpreadSim:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return SpreadSim.new(DataDB.districts, rng)


func _jalankan(s: SpreadSim) -> Dictionary:
	s.mulai({0: 2}, PackedFloat32Array([4.5, 2.7, 1.8]), 0.5)
	var tick := 0
	while s.ada_rumor_aktif() and tick < 1000:
		s.langkah(Balance.SIM_TICK)
		tick += 1
	return {"tick": tick, "percaya": s.jumlah_status(0, SpreadSim.Status.PERCAYA), "ragu": s.jumlah_status(0, SpreadSim.Status.RAGU)}


func test_jumlah_warga_sesuai_data() -> void:
	var s := _sim(1)
	assert_int(s.posisi.size()).is_equal(105)
	assert_int(s.warga_per_distrik[0].size()).is_equal(40)


func test_seed_sama_hasil_sama() -> void:
	assert_dict(_jalankan(_sim(42))).is_equal(_jalankan(_sim(42)))


func test_rumor_menyebar_lalu_berhenti() -> void:
	var hasil := _jalankan(_sim(42))
	assert_int(hasil["tick"]).is_less(1000)
	assert_int(hasil["percaya"]).is_greater(2)


func test_duplikat_tidak_mengubah_aslinya() -> void:
	var s := _sim(7)
	s.mulai({0: 2}, PackedFloat32Array([4.5, 2.7, 1.8]), 0.5)
	var status_awal := s.status.duplicate()
	var salinan := s.duplikat()
	salinan.jalankan_sampai_selesai(500)
	assert_bool(s.ada_rumor_aktif()).is_true()
	assert_array(Array(s.status)).is_equal(Array(status_awal))
	assert_bool(salinan.ada_rumor_aktif()).is_false()


func test_kebal_sekitar_dan_terapkan_jumlah() -> void:
	var s := _sim(5)
	var n := s.kebalkan_sekitar(Vector2(0.25, 0.27), 0.1)
	assert_int(n).is_greater(0)
	assert_int(s.jumlah_status(0, SpreadSim.Status.KEBAL)).is_equal(n)
	s.terapkan_jumlah(2, 10, 5, 3)
	assert_int(s.jumlah_status(2, SpreadSim.Status.PERCAYA)).is_equal(10)
	assert_int(s.jumlah_status(2, SpreadSim.Status.RAGU)).is_equal(5)
	assert_int(s.jumlah_status(2, SpreadSim.Status.KEBAL)).is_equal(3)
