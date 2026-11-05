class_name RumorController
extends Node
## Menghubungkan meja, simulasi, dan ekonomi untuk satu rumor aktif.

var sim: SpreadSim

var _rumor: Dictionary = {}
var _warga_percaya := 0
var _uang_didapat := 0


func _ready() -> void:
	sim = SpreadSim.new(DataDB.districts, GameClock.rng)
	GameClock.tick.connect(_on_tick)
	Events.kirim_diminta.connect(_on_kirim)


func _on_kirim(data: Dictionary) -> void:
	if sim.ada_rumor_aktif():
		return
	var target := DataDB.district_index(str(data.get("distrik_id", "")))
	if target < 0:
		return
	var kata_ids: Dictionary = data.get("kata_ids", {})
	var kata_by_slot := {}
	for slot in kata_ids:
		kata_by_slot[slot] = DataDB.get_word(kata_ids[slot])
	var template := DataDB.get_template(str(data.get("template_id", "")))
	var skor := RumorScorer.nilai(template, kata_by_slot, DataDB.districts, GameState.kredibilitas)
	_rumor = data.duplicate(true)
	_rumor["skor"] = skor
	_rumor["headline"] = HeadlineBuilder.susun(str(data.get("template_id", "")), kata_ids)
	_warga_percaya = 0
	_uang_didapat = 0
	var awal := sim.mulai(target, skor["viral_per_distrik"], skor["dipercaya_akhir"])
	Events.rumor_published.emit(_rumor)
	_tambah_percaya(awal)
	Events.warga_berubah.emit()
	if not sim.ada_rumor_aktif():
		_selesai()


func _on_tick(dt: float) -> void:
	var aktif_sebelum := sim.ada_rumor_aktif()
	var hasil := sim.langkah(dt)
	_tambah_percaya(int(hasil["baru_percaya"]))
	Events.warga_berubah.emit()
	if aktif_sebelum and hasil["selesai"]:
		_selesai()


func _tambah_percaya(jumlah: int) -> void:
	if jumlah <= 0:
		return
	var uang := Economy.uang_dari_warga(jumlah)
	_warga_percaya += jumlah
	_uang_didapat += uang
	GameState.tambah_uang(uang)


func _selesai() -> void:
	var hasil := _rumor.duplicate()
	hasil["warga_percaya"] = _warga_percaya
	hasil["uang"] = _uang_didapat
	Events.rumor_selesai.emit(hasil)
