class_name MissionController
extends Node
## Lima misi berurutan dari data/missions.json. Syarat dibaca dari GameState, jadi ikut tersimpan.


func _ready() -> void:
	Events.rumor_published.connect(func(_i: Dictionary) -> void: _cek())
	Events.rumor_selesai.connect(func(_h: Dictionary) -> void: _cek())
	Events.kepemilikan_berubah.connect(_cek)
	Events.pengikut_berubah.connect(func(_p: int) -> void: _cek())
	_cek()


static func misi_aktif() -> Dictionary:
	var idx: int = _autoload(&"GameState").misi_idx
	var daftar: Array = _autoload(&"DataDB").missions
	return daftar[idx] if idx < daftar.size() else {}


static func terpenuhi(misi: Dictionary, state: Node) -> bool:
	var syarat: Dictionary = misi.get("syarat", {})
	var nilai := int(syarat.get("nilai", 0))
	var stat: Dictionary = state.statistik
	match str(syarat.get("tipe", "")):
		"rumor_dikirim":
			return int(stat["total_rumor"]) >= nilai
		"warga_sekaligus":
			return int(stat["rekor_warga"]) >= nilai
		"kata_dibeli":
			return int(stat["kata_dibeli"]) >= nilai
		"rumor_emosi_distrik":
			return ("%s@%s" % [syarat.get("emosi", ""), syarat.get("distrik", "")]) in stat["emosi_distrik"]
		"pengikut":
			return state.pengikut >= nilai
	return false


func _cek() -> void:
	var misi := misi_aktif()
	while not misi.is_empty() and terpenuhi(misi, GameState):
		var hadiah: Dictionary = misi.get("hadiah", {})
		GameState.misi_idx += 1
		Events.feed_baru.emit({"jenis": "misi", "teks": misi.get("teks", "")})
		GameState.tambah_uang(int(hadiah.get("uang", 0)))
		Events.misi_berubah.emit()
		misi = misi_aktif()


static func _autoload(nama: StringName) -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node(NodePath(nama))
