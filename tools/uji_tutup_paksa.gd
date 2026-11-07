extends SceneTree

## Uji tutup paksa saat autosave (CHECKLIST 0.9.0, versi desktop). Proses anak memanggil
## SaveSystem.simpan() terus-menerus lalu membunuh dirinya sendiri (OS.kill) pada waktu acak, jadi
## kematian jatuh di titik acak urutan tulis tmp -> ganti nama -> ganti nama (ADR-0002). Putaran
## berikutnya harus memuat save yang utuh dan uangnya tidak boleh mundur.
##
## Jalankan: godot --headless --path . -s res://tools/uji_tutup_paksa.gd
## Jumlah putaran (bawaan 30): tambahkan `-- --putaran=10` di akhir perintah.
## Save pemain di user:// dicadangkan dulu dan dikembalikan setelah selesai. Kode keluar 1 = gagal.
## Catatan: jangan rujuk class yang memakai autoload saat compile; runner -s mengompilasi script ini
## sebelum autoload terdaftar.

const LOG := "user://uji_tutup_paksa.log"
const CADANGAN := "user://uji_tutup_paksa_cadangan/"
const FILE_SAVE := ["save.json", "save.bak", "save.tmp", "save.rusak"]
const PUTARAN_BAWAAN := 30
## Batas tunggu satu proses anak (mulai + menyimpan + dibunuh).
const BATAS_ANAK_MS := 20000
## Rentang waktu hidup anak setelah frame pertamanya sebelum membunuh diri.
const HIDUP_MIN_MS := 20
const HIDUP_MAKS_MS := 900
const SIMPAN_PER_FRAME := 25

var _anak := "--anak" in OS.get_cmdline_user_args()
var _mulai := false
var _uang := 0
var _thread: Thread


func _process(_d: float) -> bool:
	if _anak:
		_kerja_anak()
	elif not _mulai:
		_mulai = true
		quit(0 if _jalankan_induk() else 1)
	return false


# --- Anak: catat hasil muat, lalu simpan terus sampai dibunuh. ---

func _kerja_anak() -> void:
	var state := root.get_node(^"GameState")
	if not _mulai:
		_mulai = true
		var rusak := FileAccess.file_exists("user://save.rusak")
		if rusak:
			DirAccess.remove_absolute("user://save.rusak")
		_tulis_log("%d %d" % [state.uang, int(rusak)])
		_uang = state.uang
		randomize()
		_thread = Thread.new()
		_thread.start(_bunuh_diri.bind(randi_range(HIDUP_MIN_MS, HIDUP_MAKS_MS)))
	var save := root.get_node(^"SaveSystem")
	for i in SIMPAN_PER_FRAME:
		_uang += 1
		state.uang = _uang
		save.simpan()


func _bunuh_diri(ms: int) -> void:
	OS.delay_msec(ms)
	OS.kill(OS.get_process_id())


func _tulis_log(baris: String) -> void:
	var f := FileAccess.open(LOG, FileAccess.READ_WRITE if FileAccess.file_exists(LOG) else FileAccess.WRITE)
	f.seek_end()
	f.store_line(baris)
	f.close()


# --- Induk: jalankan anak berulang kali dan periksa tiap hasil muat. ---

func _jalankan_induk() -> bool:
	# Autosave induk (state yang dimuat sebelum uji) tidak boleh menimpa save yang dipulihkan nanti.
	root.get_node(^"SaveSystem").process_mode = Node.PROCESS_MODE_DISABLED
	var putaran := PUTARAN_BAWAAN
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--putaran="):
			putaran = maxi(1, a.get_slice("=", 1).to_int())
	_cadangkan()
	var lolos := true
	var sebelumnya := 0
	var rusak := 0
	# Satu anak tambahan di akhir hanya untuk memuat hasil putaran terakhir.
	for i in putaran + 1:
		var hasil := _satu_anak()
		if hasil.is_empty():
			print("Putaran %d: anak tidak mencatat hasil muat (gagal mulai atau macet)" % (i + 1))
			lolos = false
			break
		var uang := int(hasil[0])
		rusak += int(hasil[1])
		if uang < sebelumnya:
			print("Putaran %d: uang mundur dari %d ke %d" % [i + 1, sebelumnya, uang])
			lolos = false
		sebelumnya = uang
	if lolos and sebelumnya <= 0:
		print("Tidak ada progres yang tersimpan sama sekali")
		lolos = false
	print("%s: %d kali dibunuh saat menyimpan, uang terakhir dimuat %d, save rusak terbaca %d kali" % [
		"LOLOS" if lolos else "GAGAL", putaran, sebelumnya, rusak])
	_pulihkan()
	return lolos


## Mengembalikan [uang, rusak] dari baris log baru anak, atau [] kalau tidak ada.
func _satu_anak() -> Array:
	var sebelum := _baris_log().size()
	var argumen := ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"-s", "res://tools/uji_tutup_paksa.gd", "--", "--anak"]
	var pid := OS.create_process(OS.get_executable_path(), argumen)
	if pid <= 0:
		return []
	var tunggu := 0
	while OS.is_process_running(pid) and tunggu < BATAS_ANAK_MS:
		OS.delay_msec(50)
		tunggu += 50
	if OS.is_process_running(pid):
		OS.kill(pid)
	var baris := _baris_log()
	return Array(baris[sebelum].split(" ")) if baris.size() > sebelum else []


func _baris_log() -> PackedStringArray:
	if not FileAccess.file_exists(LOG):
		return PackedStringArray()
	return FileAccess.get_file_as_string(LOG).strip_edges().split("\n", false)


func _cadangkan() -> void:
	DirAccess.make_dir_recursive_absolute(CADANGAN)
	for nama in FILE_SAVE:
		if FileAccess.file_exists("user://" + nama):
			DirAccess.copy_absolute("user://" + nama, CADANGAN + nama)
			DirAccess.remove_absolute("user://" + nama)
	if FileAccess.file_exists(LOG):
		DirAccess.remove_absolute(LOG)


func _pulihkan() -> void:
	for nama in FILE_SAVE:
		if FileAccess.file_exists("user://" + nama):
			DirAccess.remove_absolute("user://" + nama)
		if FileAccess.file_exists(CADANGAN + nama):
			DirAccess.copy_absolute(CADANGAN + nama, "user://" + nama)
			DirAccess.remove_absolute(CADANGAN + nama)
	DirAccess.remove_absolute(CADANGAN)
	if FileAccess.file_exists(LOG):
		DirAccess.remove_absolute(LOG)
