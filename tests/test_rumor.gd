extends GdUnitTestSuite
## RumorScorer, HeadlineBuilder, Konsekuensi, Mutasi (rumus di docs/panduan/konsep-game.md).

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}


func after_test() -> void:
	Bahasa.atur("id")


func _kata(ids: Dictionary) -> Dictionary:
	var hasil := {}
	for slot in ids:
		hasil[slot] = DataDB.get_word(ids[slot])
	return hasil


func test_emosi_dominan() -> void:
	assert_str(RumorScorer.emosi_dominan(_kata(IDS))).is_equal("lucu")
	assert_str(RumorScorer.emosi_dominan(_kata({"subjek": "pak_rt", "aksi": "menyamar_hantu"}))).is_equal("takut")
	assert_str(RumorScorer.emosi_dominan(_kata({"tempat": "pasar", "sumber": "tetangga"}))).is_equal("netral")


func test_cocok_emosi() -> void:
	assert_float(RumorScorer.cocok_emosi("lucu", "lucu")).is_equal(Balance.PENGALI_COCOK_SAMA)
	assert_float(RumorScorer.cocok_emosi("lucu", "takut")).is_equal(Balance.PENGALI_COCOK_LAWAN)
	assert_float(RumorScorer.cocok_emosi("lucu", "iri")).is_equal(Balance.PENGALI_COCOK_BEDA)
	assert_float(RumorScorer.cocok_emosi("netral", "iri")).is_equal(Balance.PENGALI_COCOK_NETRAL)


func test_skor_headline_awal() -> void:
	var skor := RumorScorer.nilai(DataDB.get_template("t_dasar"), _kata(IDS), DataDB.districts, 50.0)
	assert_float(skor["heboh_total"]).is_equal_approx(3.0, 0.001)
	assert_float(skor["dipercaya_akhir"]).is_equal_approx(0.5, 0.001)
	assert_float(skor["viral_per_distrik"][0]).is_equal_approx(4.5, 0.001)


func test_headline_dua_bahasa() -> void:
	Bahasa.atur("id")
	assert_str(HeadlineBuilder.susun("t_dasar", IDS)).is_equal("Pak RT ketahuan menari tengah malam di pasar, kata tetangga!")
	Bahasa.atur("en")
	assert_str(HeadlineBuilder.susun("t_dasar", IDS)).is_equal("A neighbor says the Neighborhood Chief was caught dancing at midnight at the market!")
	assert_str(HeadlineBuilder.susun("t_dasar", {"subjek": "pak_rt"})).contains("[WHERE]")


func test_headline_kapital_tiap_kalimat() -> void:
	Bahasa.atur("id")
	var h := HeadlineBuilder.susun("t_heboh", {"subjek": "kucing_oren", "aksi": "curhat_ayam", "tempat": "salon"})
	assert_str(h).starts_with("HEBOH! Kucing oren")


func test_semua_template_tersusun_lengkap() -> void:
	var semua := {"subjek": "kucing_oren", "aksi": "curhat_ayam", "tempat": "salon", "sumber": "burung_beo"}
	for bahasa in ["id", "en"]:
		Bahasa.atur(bahasa)
		for t in DataDB.templates:
			var h := HeadlineBuilder.susun(t, semua)
			assert_str(h).not_contains("{")
			assert_str(h).not_contains("[")


func test_format_angka() -> void:
	Bahasa.atur("id")
	assert_str(Bahasa.angka(1234567)).is_equal("1.234.567")
	Bahasa.atur("en")
	assert_str(Bahasa.angka(1234567)).is_equal("1,234,567")
	assert_str(Bahasa.angka(-50)).is_equal("-50")


func test_konsekuensi() -> void:
	var skor := {"heboh_total": 8.0, "dipercaya_akhir": 0.4}
	assert_float(Konsekuensi.heat_kirim(skor, 1.0)).is_equal_approx(8.8, 0.001)
	assert_float(Konsekuensi.peluang_bongkar(0.4, 20.0)).is_equal_approx(0.264, 0.001)
	assert_int(Konsekuensi.pengikut_dari_warga(24)).is_equal(floori(24.0 / Balance.WARGA_PER_PENGIKUT))


func test_frekuensi_bongkar_sesuai_peluang() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var skor := {"heboh_total": 8.0, "dipercaya_akhir": 0.4}
	var n := 0
	for i in 4000:
		if Konsekuensi.akhir_rumor(skor, 10, 20.0, rng)["dibongkar"]:
			n += 1
	assert_float(n / 4000.0).is_equal_approx(0.264, 0.025)


func test_mutasi_ganti_tepat_satu_kata_di_slot_sama() -> void:
	var per_slot := {}
	for s in RumorScorer.URUTAN_SLOT:
		per_slot[s] = DataDB.kata_per_slot(s)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 50:
		var m := Mutasi.acak(IDS, per_slot, rng)
		var beda := 0
		for s in IDS:
			if m[s] != IDS[s]:
				beda += 1
				assert_str(str(DataDB.get_word(m[s])["slot"])).is_equal(s)
		assert_int(beda).is_equal(1)
