extends GdUnitTestSuite
## Preset Android: versi aplikasi ikut application/config/version (version/name kosong, jadi tidak
## tertinggal seperti 0.2.0 dulu), dan semua ikon serta boot splash menunjuk ke file yang ada.

const OPSI := "preset.0.options"
const IKON := ["launcher_icons/main_192x192", "launcher_icons/adaptive_foreground_432x432",
	"launcher_icons/adaptive_background_432x432", "launcher_icons/adaptive_monochrome_432x432"]


func _preset() -> ConfigFile:
	var c := ConfigFile.new()
	assert_int(c.load("res://export_presets.cfg")).is_equal(OK)
	return c


func test_versi_aplikasi_ikut_config_version() -> void:
	assert_str(str(_preset().get_value(OPSI, "version/name", ""))).is_empty()
	assert_str(str(ProjectSettings.get_setting("application/config/version", ""))).is_not_empty()


func test_ikon_dan_splash_ada() -> void:
	var c := _preset()
	for kunci in IKON:
		var path := str(c.get_value(OPSI, kunci, ""))
		assert_bool(FileAccess.file_exists(path)).override_failure_message("%s: %s tidak ada" % [kunci, path]).is_true()
	for kunci in ["application/config/icon", "application/boot_splash/image"]:
		var path := str(ProjectSettings.get_setting(kunci, ""))
		assert_bool(FileAccess.file_exists(path)).override_failure_message("%s: %s tidak ada" % [kunci, path]).is_true()
