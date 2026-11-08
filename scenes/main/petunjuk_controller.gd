class_name PetunjukController
extends Node
## Petunjuk singkat saat sistem baru terbuka (CHECKLIST 0.9.0): kredibilitas & panas, saluran baru,
## staf. Hanya logika: menentukan petunjuk mana yang muncul dan kapan, lalu mengumumkannya lewat
## Events.petunjuk_tampil. Lapisan UI menampilkannya dekat sasaran dan memancarkan
## Events.petunjuk_ditutup saat pemain menutupnya (atau saat hilang sendiri); petunjuk berikut
## baru muncul setelah itu.
##
## Isi info:
##   id       "kredibilitas", "staf", atau "saluran_<id saluran>"
##   kunci    kunci teks di localization/ui.csv; teks(info) menyusunnya dalam bahasa aktif
##   sasaran  "kredibilitas" (bar kredibilitas & panas di HUD), "saluran" (tombol saluran di meja),
##            "staf" (cincin staf di HUD)
##   nilai    id saluran (sasaran "saluran") atau jeda staf dalam detik (sasaran "staf")
##
## Aturan: tiap id tampil sekali per progres (statistik.petunjuk). Petunjuk menunggu sampai tutorial
## selesai, waktu tidak dijeda, dan JEDA_ANTAR detik simulasi berlalu (setelah pemicu atau setelah
## petunjuk sebelumnya ditutup). Sistem yang sudah terbuka saat scene dimuat dianggap sudah dikenal.

const JEDA_ANTAR := 3.0
const STAF := "staf_1"
const SALURAN_AWAL := "merpati"

var _antrean: Array[Dictionary] = []
var _aktif: Dictionary = {}
var _tunggu := JEDA_ANTAR
var _saluran_dikenal: Dictionary = {}
var _punya_staf := false


func _ready() -> void:
	for id in _saluran_terbuka():
		_saluran_dikenal[id] = true
	_punya_staf = GameState.punya_upgrade(STAF)
	Events.rumor_selesai.connect(func(_h: Dictionary) -> void:
		_tambah(_info("kredibilitas", "UI_TIP_KREDIBILITAS", "kredibilitas", null)))
	Events.pengikut_berubah.connect(func(_p: int) -> void: _cek_saluran())
	Events.era_berubah.connect(func(_e: int) -> void: _cek_saluran())
	Events.kepemilikan_berubah.connect(_cek_kepemilikan)
	Events.petunjuk_ditutup.connect(_on_ditutup)
	GameClock.tick.connect(_on_tick)


## Petunjuk yang sedang tampil ({} = tidak ada).
func info() -> Dictionary:
	return _aktif


## Teks petunjuk dalam bahasa aktif (dipanggil ulang UI saat bahasa berganti).
static func teks(info: Dictionary) -> String:
	var t := TranslationServer.translate(StringName(str(info.get("kunci", ""))))
	match str(info.get("sasaran", "")):
		"saluran":
			return t % Bahasa.teks(DataDB.get_upgrade(str(info.get("nilai", ""))).get("nama", ""))
		"staf":
			return t % int(info.get("nilai", 0))
	return t


static func sudah_dilihat(state: Node, id: String) -> bool:
	return id in state.statistik.get("petunjuk", [])


func _cek_saluran() -> void:
	for id in _saluran_terbuka():
		if not _saluran_dikenal.has(id):
			_saluran_dikenal[id] = true
			_tambah(_info("saluran_" + id, "UI_TIP_SALURAN", "saluran", id))


func _cek_kepemilikan() -> void:
	_cek_saluran()
	if not _punya_staf and GameState.punya_upgrade(STAF):
		_punya_staf = true
		_tambah(_info("staf", "UI_TIP_STAF", "staf", int(DataDB.get_upgrade(STAF).get("jeda_detik", 40))))


## Saluran selain Merpati yang bisa dipakai sekarang. Kunci sementara (E09) membuatnya tertutup,
## tapi saluran yang sudah dikenal tidak dihitung baru lagi saat kuncinya habis.
func _saluran_terbuka() -> Array[String]:
	var hasil: Array[String] = []
	for id in DataDB.upgrades:
		if id != SALURAN_AWAL and str(DataDB.upgrades[id].get("jenis", "")) == "saluran" and GameState.saluran_terbuka(id):
			hasil.append(str(id))
	return hasil


func _tambah(info: Dictionary) -> void:
	var id := str(info["id"])
	if sudah_dilihat(GameState, id) or str(_aktif.get("id", "")) == id:
		return
	for lain in _antrean:
		if lain["id"] == id:
			return
	if _antrean.is_empty() and _aktif.is_empty():
		_tunggu = JEDA_ANTAR
	_antrean.append(info)


func _on_tick(dt: float) -> void:
	if not _aktif.is_empty() or _antrean.is_empty() or GameClock.sedang_jeda():
		return
	if not TutorialController.selesai(GameState):
		_tunggu = JEDA_ANTAR  # mulai menghitung setelah tutorial selesai
		return
	_tunggu -= dt
	if _tunggu > 0.0:
		return
	_aktif = _antrean.pop_front()
	if not GameState.statistik.has("petunjuk"):
		GameState.statistik["petunjuk"] = []
	(GameState.statistik["petunjuk"] as Array).append(_aktif["id"])
	Events.petunjuk_tampil.emit(_aktif)


func _on_ditutup() -> void:
	_aktif = {}
	_tunggu = JEDA_ANTAR


static func _info(id: String, kunci: String, sasaran: String, nilai: Variant) -> Dictionary:
	return {"id": id, "kunci": kunci, "sasaran": sasaran, "nilai": nilai}
