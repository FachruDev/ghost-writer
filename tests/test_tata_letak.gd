extends GdUnitTestSuite
## Tata letak meja di layar 16:9 (feedback UI): chip slot ramping dengan area ketuk 88 px, ukuran
## huruf kertas mengikuti kalimat yang tampil, dan semua nama kata muat di kartunya (ID + EN).

const WORD_CARD := preload("res://scenes/card/word_card.tscn")

var _kode_awal := ""


func before_test() -> void:
	_kode_awal = Bahasa.kode()


func after_test() -> void:
	# Bahasa diganti langsung (tanpa Bahasa.atur) supaya settings.cfg pemain tidak tertulis.
	Bahasa._kode = _kode_awal
	TranslationServer.set_locale(_kode_awal)


func _bingkai(n := 2) -> void:
	for i in n:
		await get_tree().process_frame


func test_chip_ramping_tapi_area_ketuk_88_px() -> void:
	var k: KertasHeadline = auto_free(KertasHeadline.new())
	add_child(k)
	k.tampilkan("t_dasar", {}, "subjek", 0, 1)
	await _bingkai()
	var c: Control = k.chip("subjek")
	assert_float(c.size.y).is_equal(float(KertasHeadline.TINGGI_CHIP))
	var lebih := (KertasHeadline.TINGGI_KETUK - c.size.y) / 2.0
	assert_bool(c._has_point(Vector2(10.0, -lebih + 1.0))).is_true()
	assert_bool(c._has_point(Vector2(10.0, c.size.y + lebih - 1.0))).is_true()
	assert_bool(c._has_point(Vector2(10.0, -lebih - 1.0))).is_false()
	assert_bool(c._has_point(Vector2(c.size.x + 1.0, 10.0))).is_false()


func test_huruf_kertas_mengecil_untuk_kalimat_panjang() -> void:
	var k: KertasHeadline = auto_free(KertasHeadline.new())
	add_child(k)
	var pola := Bahasa.teks(DataDB.get_template("t_resmi").get("pola", ""))
	var panjang := {}
	for id in DataDB.words:
		var s := str(DataDB.words[id].get("slot", ""))
		var teks := Bahasa.teks(DataDB.words[id].get("text", ""))
		if not panjang.has(s) or teks.length() > Bahasa.teks(DataDB.get_word(panjang[s]).get("text", "")).length():
			panjang[s] = str(id)
	var kosong := k._ukuran_huruf(Bahasa.teks(DataDB.get_template("t_dasar").get("pola", "")), {})
	assert_int(kosong).is_equal(30)
	assert_int(k._ukuran_huruf(pola, panjang)).is_less(k._ukuran_huruf(pola, {}))


func test_nama_kata_muat_di_kartu_id_dan_en() -> void:
	var kartu: Button = auto_free(WORD_CARD.instantiate())
	add_child(kartu)
	await _bingkai()
	var isi: Control = kartu.get_child(0)
	var tidak_muat: Array[String] = []
	for kode in ["id", "en"]:
		Bahasa._kode = kode
		TranslationServer.set_locale(kode)
		for id in DataDB.words:
			kartu.atur(str(id))
			await _bingkai(1)
			if isi.get_combined_minimum_size().y > kartu.size.y:
				tidak_muat.append("%s:%s" % [kode, id])
	assert_array(tidak_muat).is_empty()
