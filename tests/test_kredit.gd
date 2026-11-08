extends GdUnitTestSuite
## Kredit aset (layar Tentang, CHECKLIST 0.9.0): setiap font, musik, dan efek suara tercatat di
## data/kredit.json, setiap file yang dicatat ada, dan teks lisensi OFL ikut diekspor.

const FOLDER := {"res://assets/fonts/": ["ttf", "otf"], "res://assets/music/": ["ogg", "mp3", "wav"],
	"res://assets/sfx/": ["ogg", "mp3", "wav"]}
const JENIS := ["font", "musik", "suara", "proyek"]


func _tercatat() -> Dictionary:
	var hasil := {}
	for k in DataDB.kredit:
		for f in k.get("file", []):
			hasil[str(f)] = k
	return hasil


func test_semua_aset_tercatat() -> void:
	var tercatat := _tercatat()
	var hilang: Array[String] = []
	for folder in FOLDER:
		for nama in DirAccess.get_files_at(folder):
			if nama.get_extension() in FOLDER[folder] and not tercatat.has(folder + nama):
				hilang.append(folder + nama)
	assert_array(hilang).is_empty()


func test_file_tercatat_ada_dan_lengkap() -> void:
	assert_array(DataDB.kredit).is_not_empty()
	for k in DataDB.kredit:
		assert_bool(str(k.get("jenis", "")) in JENIS).is_true()
		assert_str(str(k.get("judul", ""))).is_not_empty()
		assert_array(k.get("file", [])).is_not_empty()
		for f in k["file"]:
			assert_bool(FileAccess.file_exists(str(f))).override_failure_message("tidak ada: %s" % f).is_true()
		if k["jenis"] != "proyek":
			assert_str(str(k.get("oleh", ""))).is_not_empty()
			assert_str(str(k.get("lisensi", ""))).is_not_empty()


func test_font_ofl_membawa_teks_lisensi_yang_diekspor() -> void:
	var preset := ConfigFile.new()
	assert_int(preset.load("res://export_presets.cfg")).is_equal(OK)
	var filter := str(preset.get_value("preset.0", "include_filter", ""))
	for k in DataDB.kredit:
		if k["jenis"] != "font":
			continue
		var lisensi := str(k.get("teks_lisensi", ""))
		assert_bool(FileAccess.file_exists(lisensi)).is_true()
		var cocok := false
		for pola in filter.split(",", false):
			cocok = cocok or lisensi.trim_prefix("res://").match(pola.strip_edges())
		assert_bool(cocok).override_failure_message("%s tidak ikut include_filter" % lisensi).is_true()
