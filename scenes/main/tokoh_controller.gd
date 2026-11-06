class_name TokohController
extends Node
## Tokoh fiktif target besar (Era 4, data/tokoh.json): kartu SUBJEK khusus dengan reputasi dan
## satu pertahanan. Rumor tentang tokoh yang tidak dibongkar mengurangi reputasinya sebanyak
## warga yang percaya; di 0 tokoh jatuh. Semua tokoh jatuh = syarat kampanye akhir (0.6.0).


func _ready() -> void:
	Events.era_berubah.connect(_on_era)
	_on_era(GameState.era)


func _on_era(era: int) -> void:
	if era < 4:
		return
	for t in DataDB.tokoh:
		if not GameState.tokoh_reputasi.has(t["id"]):
			GameState.tokoh_reputasi[t["id"]] = int(t.get("reputasi", 100))
			GameState.beri_kata(str(t["kata"]))
	Events.tokoh_berubah.emit()


## Tokoh yang masih berdiri dan disebut dalam headline, atau {} kalau tidak ada.
static func tokoh_dari(kata_ids: Dictionary) -> Dictionary:
	var db := (Engine.get_main_loop() as SceneTree).root.get_node(^"DataDB")
	var state := (Engine.get_main_loop() as SceneTree).root.get_node(^"GameState")
	for slot in kata_ids:
		for t in db.tokoh:
			if str(t["kata"]) == str(kata_ids[slot]) and int(state.tokoh_reputasi.get(t["id"], 0)) > 0:
				return t
	return {}


func tokoh_di(kata_ids: Dictionary) -> Dictionary:
	return tokoh_dari(kata_ids)


## Humas: rumor tentang tokoh ini lebih panas.
func pengali_heat(t: Dictionary) -> float:
	var p: Dictionary = t.get("pertahanan", {})
	return float(p.get("heat_kali", 1.0)) if str(p.get("tipe", "")) == "humas" else 1.0


## Media sendiri: setiap rumor tentang tokoh ini memicu ancaman (Rumor Tandingan).
func saat_dikirim(t: Dictionary) -> void:
	var p: Dictionary = t.get("pertahanan", {})
	if str(p.get("tipe", "")) == "media":
		Events.ancaman_diminta.emit(str(p.get("event", "")))


## Pengacara: rumor yang kurang dipercaya otomatis dibongkar.
func membantah(t: Dictionary, skor: Dictionary) -> bool:
	var p: Dictionary = t.get("pertahanan", {})
	var bantah := str(p.get("tipe", "")) == "pengacara" \
		and float(skor["dipercaya_akhir"]) < float(p.get("dipercaya_min", 0.0))
	if bantah:
		Events.feed_baru.emit({"jenis": "pengacara", "nama": t.get("nama", "")})
	return bantah


func serang(t: Dictionary, warga_percaya: int) -> void:
	var id := str(t["id"])
	var sisa := maxi(0, int(GameState.tokoh_reputasi.get(id, 0)) - warga_percaya)
	GameState.tokoh_reputasi[id] = sisa
	Events.feed_baru.emit({"jenis": "tokoh", "nama": t.get("nama", ""), "kurang": warga_percaya, "sisa": sisa})
	if sisa <= 0:
		var hadiah: Dictionary = t.get("hadiah", {})
		GameState.tambah_uang(int(hadiah.get("uang", 0)))
		GameState.tambah_pengikut(int(hadiah.get("pengikut", 0)))
		Events.feed_baru.emit({"jenis": "tokoh_jatuh", "nama": t.get("nama", ""),
			"uang": int(hadiah.get("uang", 0)), "pengikut": int(hadiah.get("pengikut", 0))})
	Events.tokoh_berubah.emit()


static func semua_jatuh() -> bool:
	var db := (Engine.get_main_loop() as SceneTree).root.get_node(^"DataDB")
	var state := (Engine.get_main_loop() as SceneTree).root.get_node(^"GameState")
	if state.tokoh_reputasi.is_empty():
		return false
	for t in db.tokoh:
		if int(state.tokoh_reputasi.get(t["id"], 1)) > 0:
			return false
	return true


## Ringkasan untuk HUD, mis. "Pak Hartono 70 · Bu Sasmita 100 · Juragan Bramantyo 45".
static func teks_progres() -> String:
	var db := (Engine.get_main_loop() as SceneTree).root.get_node(^"DataDB")
	var state := (Engine.get_main_loop() as SceneTree).root.get_node(^"GameState")
	var bahasa := (Engine.get_main_loop() as SceneTree).root.get_node(^"Bahasa")
	var bagian: Array[String] = []
	for t in db.tokoh:
		if state.tokoh_reputasi.has(t["id"]):
			bagian.append("%s %d" % [bahasa.teks(t.get("nama", "")), int(state.tokoh_reputasi[t["id"]])])
	return " · ".join(bagian)
