extends Node
## Simpan/muat progres ke user://save.json dengan tulis atomik (ADR-0002).
## Rumor yang sedang menjalar disimpan sebagai hasil proyeksi (ADR-0003).

const PATH := "user://save.json"
const PATH_TMP := "user://save.tmp"
const PATH_BAK := "user://save.bak"
const PATH_RUSAK := "user://save.rusak"
const VERSI_SKEMA := 1

## MIGRASI[i] mengubah dictionary dari versi i + 1 ke versi i + 2. Tambah di akhir; jangan ubah yang lama.
const MIGRASI: Array[Callable] = []

## () -> {"distrik_status": Dictionary, "delta": Dictionary}. Diisi RumorController.
var sumber_snapshot: Callable

## Hasil penghasilan offline saat memuat terakhir: {"detik", "uang"} (ADR-0003). Ditampilkan main.
var offline: Dictionary = {}

var _timer: Timer


func _ready() -> void:
	muat()
	_timer = Timer.new()
	_timer.wait_time = Balance.AUTOSAVE_DETIK
	_timer.autostart = true
	_timer.timeout.connect(simpan)
	add_child(_timer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		simpan()


func simpan() -> Error:
	var data := GameState.ke_dict()
	if sumber_snapshot.is_valid():
		_terapkan_snapshot(data, sumber_snapshot.call())
	data["versi_skema"] = VERSI_SKEMA
	data["versi_game"] = str(ProjectSettings.get_setting("application/config/version", "0.2.0"))
	data["disimpan_pada"] = Time.get_datetime_string_from_system()
	data["disimpan_unix"] = Time.get_unix_time_from_system()
	var f := FileAccess.open(PATH_TMP, FileAccess.WRITE)
	if f == null:
		push_warning("SaveSystem: gagal membuka %s (%s)" % [PATH_TMP, error_string(FileAccess.get_open_error())])
		return FileAccess.get_open_error()
	var ok := f.store_string(JSON.stringify(data))
	f.close()
	if not ok:
		push_warning("SaveSystem: gagal menulis %s" % PATH_TMP)
		return ERR_FILE_CANT_WRITE
	if FileAccess.file_exists(PATH):
		DirAccess.rename_absolute(PATH, PATH_BAK)
	return DirAccess.rename_absolute(PATH_TMP, PATH)


## Mengembalikan false kalau tidak ada save valid (game baru).
func muat() -> bool:
	for path in [PATH, PATH_BAK, PATH_TMP]:
		var data := _baca(path)
		if data.is_empty():
			continue
		GameState.dari_dict(_migrasi(data))
		_hitung_offline(float(data.get("disimpan_unix", Time.get_unix_time_from_system())))
		return true
	return false


## Staf bekerja selama aplikasi tertutup: maks 8 jam × 0,5 (ADR-0003).
func _hitung_offline(disimpan_unix: float) -> void:
	var detik := Economy.detik_offline(disimpan_unix, Time.get_unix_time_from_system())
	var laju := Economy.laju_pasif_per_detik(GameState.punya_upgrade("staf_1"), DataDB.get_upgrade("staf_1"))
	offline = {"detik": detik, "uang": Economy.uang_offline(laju, detik)}
	if int(offline["uang"]) > 0:
		GameState.tambah_uang(int(offline["uang"]))


func reset_progres() -> void:
	offline = {}
	for path in [PATH, PATH_BAK, PATH_TMP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	GameState.mulai_baru()


func _baca(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary and json.data.has("pemain"):
		return json.data
	push_warning("SaveSystem: %s rusak, disalin ke %s" % [path, PATH_RUSAK])
	DirAccess.copy_absolute(path, PATH_RUSAK)
	return {}


## `daftar` bisa diganti untuk tes; permainan selalu memakai MIGRASI.
func _migrasi(data: Dictionary, daftar: Array = MIGRASI) -> Dictionary:
	var versi := int(data.get("versi_skema", 1))
	while versi - 1 < daftar.size():
		data = daftar[versi - 1].call(data)
		versi += 1
		data["versi_skema"] = versi
	return data


## Hasil proyeksi hanya masuk ke dictionary save, tidak ke GameState (ADR-0003).
func _terapkan_snapshot(data: Dictionary, snap: Dictionary) -> void:
	data["distrik_status"] = snap.get("distrik_status", {})
	var delta: Dictionary = snap.get("delta", {})
	if delta.is_empty():
		return
	var p: Dictionary = data["pemain"]
	p["uang"] = int(p["uang"]) + int(delta.get("uang", 0))
	p["pengikut"] = int(p["pengikut"]) + int(delta.get("pengikut", 0))
	p["kredibilitas"] = clampf(float(p["kredibilitas"]) + float(delta.get("kredibilitas", 0.0)), 0.0, 100.0)
	p["heat"] = clampf(float(p["heat"]) + float(delta.get("heat", 0.0)), 0.0, 100.0)
	if delta.has("riwayat"):
		var riwayat: Array = data["riwayat_rumor"]
		riwayat.append(delta["riwayat"])
		while riwayat.size() > Balance.BATAS_RIWAYAT:
			riwayat.pop_front()
