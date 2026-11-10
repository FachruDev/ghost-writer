extends GdUnitTestSuite
## Kejenuhan kata: kata yang dipakai berulang dalam rumor pemain terakhir jadi basi (heboh turun),
## rumor staf tidak dihitung, kata ber-tag tidak bisa basi, dan kata pulih setelah tidak dipakai.


func _rumor(kata_ids: Dictionary, saluran := "merpati") -> Dictionary:
	return {"template_id": "t", "kata_ids": kata_ids, "saluran_id": saluran}


func _sama() -> Dictionary:
	return {"subjek": "pak_rt", "aksi": "a1", "tempat": "p1"}


func test_hitung_hanya_jendela_terakhir() -> void:
	var riwayat := [_rumor({"subjek": "lama"})]
	for _k in Balance.JENUH_JENDELA:
		riwayat.append(_rumor(_sama()))
	var jumlah := Kejenuhan.hitung(riwayat)
	assert_int(int(jumlah.get("pak_rt", 0))).is_equal(Balance.JENUH_JENDELA)
	assert_bool(jumlah.has("lama")).is_false()  # sudah di luar jendela: pulih


func test_rumor_staf_tidak_dihitung() -> void:
	var riwayat := [_rumor(_sama()), _rumor({"subjek": "bu_lurah"}, "staf"), _rumor({"subjek": "bu_lurah"}, "staf")]
	var jumlah := Kejenuhan.hitung(riwayat)
	assert_bool(jumlah.has("bu_lurah")).is_false()
	assert_int(int(jumlah.get("pak_rt", 0))).is_equal(1)  # staf tidak memakan jendela


func test_pengali_turun_lalu_mentok() -> void:
	assert_float(Kejenuhan.pengali(0)).is_equal(1.0)
	assert_float(Kejenuhan.pengali(1)).is_equal_approx(1.0 - Balance.JENUH_PER_PAKAI, 0.0001)
	assert_float(Kejenuhan.pengali(99)).is_equal(Balance.JENUH_MIN)


func test_kata_bertag_tidak_basi() -> void:
	var jumlah := {"tokoh_hartono": 9, "pak_rt": 9}
	assert_float(Kejenuhan.pengali_kata(DataDB.get_word("tokoh_hartono"), jumlah)).is_equal(1.0)
	assert_float(Kejenuhan.pengali_kata(DataDB.get_word("pak_rt"), jumlah)).is_equal(Balance.JENUH_MIN)


func test_terapkan_tidak_mengubah_data_asli() -> void:
	var asli := float(DataDB.get_word("pak_rt").get("heboh", 0))
	var hasil := Kejenuhan.terapkan({"subjek": DataDB.get_word("pak_rt")}, {"pak_rt": 1})
	assert_float(float(hasil["subjek"]["heboh"])).is_equal_approx(asli * Kejenuhan.pengali(1), 0.0001)
	assert_float(float(DataDB.get_word("pak_rt").get("heboh", 0))).is_equal(asli)


func test_rumor_sama_berulang_makin_lemah() -> void:
	var template: Dictionary = DataDB.templates.values()[0]
	var kata_ids := {}
	var kata_by_slot := {}
	for slot in RumorScorer.URUTAN_SLOT:
		for w: Dictionary in DataDB.words.values():
			if str(w.get("slot", "")) == slot and str(w.get("tag", "")) == "" and int(w.get("heboh", 0)) > 0:
				kata_ids[slot] = str(w["id"])
				kata_by_slot[slot] = w
				break
	var riwayat: Array = []
	var heboh_sebelum := INF
	for k in Balance.JENUH_JENDELA + 2:
		var basi := Kejenuhan.terapkan(kata_by_slot, Kejenuhan.hitung(riwayat))
		var skor := RumorScorer.nilai(template, basi, DataDB.districts, 50.0)
		var heboh := float(skor["heboh_total"])
		if k <= Balance.JENUH_JENDELA:
			assert_float(heboh).is_less(heboh_sebelum)
		else:
			assert_float(heboh).is_equal_approx(heboh_sebelum, 0.0001)  # mentok di JENUH_MIN
		heboh_sebelum = heboh
		riwayat.append(_rumor(kata_ids))
