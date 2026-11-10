class_name TutorialController
extends Node
## Tutorial tiga langkah yang dimainkan, bukan dibaca (CHECKLIST 0.9.0): isi slot → kirim → beli kata.
## Hanya logika: menentukan langkah dan sasaran yang perlu ditunjuk, lalu mengumumkannya lewat
## Events.tutorial_langkah. Lapisan UI menggambar tangan penunjuk dan teksnya, dan memancarkan
## Events.tutorial_dilewati saat pemain menekan Lewati.
##
## Isi info (kosong = tidak ada yang perlu ditunjuk sekarang, misalnya ada lembar yang menutupi
## meja, uang belum cukup untuk kata baru, atau tutorial sudah selesai):
##   langkah  1..JUMLAH_LANGKAH
##   sasaran  "kartu"    kartu di tangan untuk slot aktif
##            "distrik"  distrik di peta (saluran Merpati butuh sasaran)
##            "saluran"  tombol saluran (saluran pilihan terkunci atau biayanya kurang)
##            "kirim"    tombol KIRIM!
##            "toko"     tombol toko di HUD
##            "beli"     tombol Beli pada kartu toko `kata_id`
##   kunci    kunci teks di localization/ui.csv
##   kata_id  hanya untuk "toko" dan "beli": kata termurah yang uangnya cukup
##
## Progres tidak disimpan tersendiri: dibaca dari statistik (rumor terkirim, kata dibeli) dan era,
## jadi save lama dan reset progres ikut benar. Hanya "dilewati" yang disimpan
## (statistik.tutorial_lewat).

const JUMLAH_LANGKAH := 3

var _meja: Dictionary = {}
var _terkirim := false
var _terakhir: Dictionary = {}
var _antre := false


func _ready() -> void:
	Events.meja_berubah.connect(func(m: Dictionary) -> void:
		_meja = m
		_segarkan())
	Events.rumor_published.connect(func(_i: Dictionary) -> void:
		_terkirim = true
		_segarkan())
	Events.money_changed.connect(func(_u: int) -> void: _segarkan())
	Events.kepemilikan_berubah.connect(_segarkan)
	Events.era_berubah.connect(func(_e: int) -> void: _segarkan())
	Events.tutorial_dilewati.connect(_lewati)
	GameClock.jeda_berubah.connect(_segarkan)
	_segarkan()


## Langkah yang sedang tampil (sama dengan sinyal terakhir).
func info() -> Dictionary:
	return _terakhir


static func selesai(state: Node) -> bool:
	var stat: Dictionary = state.statistik
	return bool(stat.get("tutorial_lewat", false)) or int(stat.get("kata_dibeli", 0)) > 0 or int(state.era) > 1


## Sumber kebenaran langkah; statis supaya bisa dites tanpa scene.
## meja: isi Events.meja_berubah terakhir. jeda: GameClock.alasan_jeda().
static func hitung(state: Node, words: Dictionary, meja: Dictionary, terkirim: bool, jeda: Array) -> Dictionary:
	if selesai(state):
		return {}
	var toko := jeda.has(&"toko")
	# Lembar lain (dilema, kontrak) menutupi semua sasaran.
	if jeda.size() > (1 if toko else 0):
		return {}
	if not (terkirim or int(state.statistik.get("total_rumor", 0)) > 0 or not state.riwayat_rumor.is_empty()):
		return {} if toko else _langkah_kirim(meja)
	var kata := kata_termurah(state, words)
	if kata.is_empty():
		return {}
	var hasil := _info(3, "beli", "UI_TUT_BELI") if toko else _info(3, "toko", "UI_TUT_TOKO")
	hasil["kata_id"] = kata
	return hasil


## Langkah 1–2: lengkapi slot, pilih distrik atau saluran bila perlu, lalu KIRIM!.
static func _langkah_kirim(meja: Dictionary) -> Dictionary:
	if bool(meja.get("rumor_aktif", false)):
		return {}
	if not bool(meja.get("lengkap", false)):
		return _info(1, "kartu", "UI_TUT_ISI_SLOT")
	if bool(meja.get("butuh_distrik", false)):
		return _info(2, "distrik", "UI_TUT_DISTRIK")
	if not bool(meja.get("siap", false)):
		return _info(2, "saluran", "UI_TUT_SALURAN")
	return _info(2, "kirim", "UI_TUT_KIRIM")


## Kata toko termurah yang belum dimiliki, era-nya terbuka, dan uangnya cukup; "" kalau tidak ada.
## Urutan sama dengan daftar toko (harga naik), jadi kartunya ada di baris atas.
static func kata_termurah(state: Node, words: Dictionary) -> String:
	var terbaik := ""
	var harga_terbaik := 0
	for id in words:
		var kata: Dictionary = words[id]
		var harga := int(kata.get("harga", 0))
		if harga <= 0 or harga > int(state.uang) or not kata.get("toko", true) or str(id) in state.kartu_dimiliki:
			continue
		if int(kata.get("era_min", 1)) > int(state.era):
			continue
		if terbaik.is_empty() or harga < harga_terbaik:
			terbaik = str(id)
			harga_terbaik = harga
	return terbaik


static func _info(langkah: int, sasaran: String, kunci: String) -> Dictionary:
	return {"langkah": langkah, "sasaran": sasaran, "kunci": kunci}


func _lewati() -> void:
	GameState.statistik["tutorial_lewat"] = true
	_segarkan()


## Banyak sinyal bisa datang dalam satu frame; hitung sekali di akhir frame.
func _segarkan() -> void:
	if not _antre:
		_antre = true
		_umumkan.call_deferred()


func _umumkan() -> void:
	_antre = false
	if not is_inside_tree():
		return
	var baru := hitung(GameState, DataDB.words, _meja, _terkirim, GameClock.alasan_jeda())
	if not baru.recursive_equal(_terakhir, 2):
		_terakhir = baru
		Events.tutorial_langkah.emit(baru)
