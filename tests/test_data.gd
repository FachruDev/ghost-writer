extends GdUnitTestSuite
## Validitas konten di res://data/ (ADR-0004: setiap teks punya "id"; pola memakai slot yang sama).


func test_jumlah_konten() -> void:
	assert_int(DataDB.words.size()).is_equal(156)
	var era2 := 0
	for id in DataDB.words:
		if int(DataDB.words[id].get("era_min", 1)) == 2:
			era2 += 1
	assert_int(era2).is_equal(40)
	var era3 := 0
	for id in DataDB.words:
		if int(DataDB.words[id].get("era_min", 1)) == 3:
			era3 += 1
	assert_int(era3).is_equal(40)
	for slot in RumorScorer.URUTAN_SLOT:
		assert_int(DataDB.kata_per_slot(slot).size()).is_greater_equal(30)
	assert_int(DataDB.templates.size()).is_equal(12)
	assert_int(DataDB.semua_distrik.size()).is_equal(8)
	assert_int(DataDB.saluran().size()).is_equal(5)
	assert_int(DataDB.tokoh.size()).is_equal(3)
	assert_int(DataDB.missions.size()).is_equal(5)
	assert_int(DataDB.events.size()).is_equal(12)
	assert_int(DataDB.endings.size()).is_equal(2)


func test_kartu_hadiah_event_tidak_dijual_dan_tidak_dimiliki_di_awal() -> void:
	SaveSystem.reset_progres()
	for id in ["calon_darto", "calon_wati", "dokumen_bocor", "tokoh_hartono", "tokoh_sasmita", "tokoh_bramantyo"]:
		assert_bool(DataDB.get_word(id).get("toko", true)).is_false()
		assert_bool(GameState.punya_kata(id)).is_false()


## ADR-0004: semua teks konten wajib ada dalam bahasa Indonesia dan Inggris (wajib sejak 0.9.0).
func test_semua_teks_konten_punya_id_dan_en() -> void:
	for bahasa in ["id", "en"]:
		var kosong: Array[String] = []
		for nama_teks in _semua_teks():
			var field: Variant = nama_teks[1]
			if not field is Dictionary or str(field.get(bahasa, "")).strip_edges().is_empty():
				kosong.append(str(nama_teks[0]))
		assert_array(kosong).override_failure_message("Teks %s kosong: %s" % [bahasa, str(kosong)]).is_empty()


func test_semua_teks_ui_punya_terjemahan() -> void:
	var f := FileAccess.open("res://localization/ui.csv", FileAccess.READ)
	var kepala := f.get_csv_line()
	assert_array(Array(kepala)).contains_exactly(["keys", "id", "en"])
	var kosong: Array[String] = []
	while not f.eof_reached():
		var sel := f.get_csv_line()
		if sel.size() < 1 or sel[0].is_empty():
			continue
		if sel.size() < 3 or sel[1].strip_edges().is_empty() or sel[2].strip_edges().is_empty():
			kosong.append(sel[0])
	assert_array(kosong).is_empty()


## [nama, field {"id","en"}] untuk setiap teks konten di res://data/.
func _semua_teks() -> Array:
	var hasil := []
	for id in DataDB.words:
		hasil.append(["kata " + id, DataDB.words[id].get("text")])
	for id in DataDB.templates:
		hasil.append(["template " + id, DataDB.templates[id].get("pola")])
	for d in DataDB.semua_distrik:
		hasil.append(["distrik " + str(d["id"]), d.get("nama")])
	for e in DataDB.events:
		hasil.append(["event nama " + str(e["id"]), e.get("nama")])
		hasil.append(["event teks " + str(e["id"]), e.get("teks")])
		for p in e.get("pilihan", []):
			hasil.append(["event pilihan " + str(e["id"]), p.get("label")])
	for m in DataDB.missions:
		hasil.append(["misi " + str(m["id"]), m.get("teks")])
	for id in DataDB.upgrades:
		hasil.append(["upgrade nama " + id, DataDB.upgrades[id].get("nama")])
		if DataDB.upgrades[id].has("info"):
			hasil.append(["upgrade info " + id, DataDB.upgrades[id].get("info")])
	for t in DataDB.tokoh:
		hasil.append(["tokoh nama " + str(t["id"]), t.get("nama")])
		hasil.append(["tokoh info " + str(t["id"]), t.get("info")])
	for id in DataDB.endings:
		hasil.append(["ending judul " + id, DataDB.endings[id].get("judul")])
		hasil.append(["ending epilog " + id, DataDB.endings[id].get("epilog")])
	return hasil


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
