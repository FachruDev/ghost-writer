extends GdUnitTestSuite
## Validitas konten di res://data/ (ADR-0004: setiap teks punya "id"; pola memakai slot yang sama).


func test_jumlah_konten() -> void:
	assert_int(DataDB.words.size()).is_equal(40)
	for slot in RumorScorer.URUTAN_SLOT:
		assert_int(DataDB.kata_per_slot(slot).size()).is_equal(10)
	assert_int(DataDB.templates.size()).is_equal(5)
	assert_int(DataDB.districts.size()).is_equal(3)
	assert_int(DataDB.saluran().size()).is_equal(2)
	assert_int(DataDB.missions.size()).is_equal(5)
	assert_int(DataDB.events.size()).is_equal(3)


func test_semua_teks_punya_bahasa_indonesia() -> void:
	var kosong: Array[String] = []
	for id in DataDB.words:
		_cek_teks(DataDB.words[id].get("text"), "kata " + id, kosong)
	for id in DataDB.templates:
		_cek_teks(DataDB.templates[id].get("pola"), "template " + id, kosong)
	for d in DataDB.districts:
		_cek_teks(d.get("nama"), "distrik " + str(d["id"]), kosong)
	for e in DataDB.events:
		_cek_teks(e.get("nama"), "event " + str(e["id"]), kosong)
		_cek_teks(e.get("teks"), "event " + str(e["id"]), kosong)
	for m in DataDB.missions:
		_cek_teks(m.get("teks"), "misi " + str(m["id"]), kosong)
	assert_array(kosong).is_empty()


## Mulai 0.9.0 semua teks Inggris wajib terisi (ADR-0004). Sekarang hanya dilaporkan.
func test_laporan_teks_inggris_kosong() -> void:
	var n := 0
	for id in DataDB.words:
		if str(DataDB.words[id]["text"].get("en", "")).is_empty():
			n += 1
	print("Teks EN kosong (kata): %d" % n)
	assert_int(n).is_greater_equal(0)


func test_pola_template_memakai_slotnya() -> void:
	for id in DataDB.templates:
		var t: Dictionary = DataDB.templates[id]
		for bahasa in ["id", "en"]:
			var pola := str(t["pola"].get(bahasa, ""))
			for slot in t["slot"]:
				assert_str(pola).contains("{%s}" % slot)
			for slot in RumorScorer.URUTAN_SLOT:
				if not (slot in t["slot"]):
					assert_str(pola).not_contains("{%s}" % slot)


func _cek_teks(field: Variant, nama: String, kosong: Array[String]) -> void:
	if not field is Dictionary or str(field.get("id", "")).is_empty():
		kosong.append(nama)
