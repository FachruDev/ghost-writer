class_name StaffController
extends Node
## Staf otomatis (Era 2): tiap jeda_detik mengirim rumor kecil dari kartu milik pemain lewat Merpati.
## Hasilnya dihitung tanpa peta (Staf.warga_percaya); konsekuensi berlaku seperti rumor biasa.

const UPGRADE_ID := "staf_1"

## (kata_ids: Dictionary) -> {"uang": float, "heat": float}. Diisi main dari EventController.
var pengali_rumor: Callable

var _hitung := 0.0


func _ready() -> void:
	GameClock.tick.connect(_on_tick)


func _on_tick(dt: float) -> void:
	# E11 Server Down bisa mematikan staf sementara (kunci dengan id upgrade).
	if not GameState.punya_upgrade(UPGRADE_ID) or GameState.saluran_terkunci.has(UPGRADE_ID):
		return
	_hitung += dt
	if _hitung >= float(DataDB.get_upgrade(UPGRADE_ID).get("jeda_detik", 40)):
		_hitung = 0.0
		kirim()


## Satu rumor staf. Mengembalikan ringkasan hasil, atau {} kalau ada slot tanpa kartu.
func kirim() -> Dictionary:
	var cfg := DataDB.get_upgrade(UPGRADE_ID)
	var rng := GameClock.rng
	var template_ids := GameState.template_dimiliki
	if template_ids.is_empty():
		return {}
	var template_id: String = template_ids[rng.randi_range(0, template_ids.size() - 1)]
	var kata_ids := {}
	var kata_by_slot := {}
	for slot in DataDB.get_template(template_id).get("slot", []):
		# Staf tidak berani memakai kartu tokoh target.
		var milik: Array = GameState.kartu_dimiliki.filter(func(k: String) -> bool:
			return str(DataDB.get_word(k).get("slot", "")) == slot and DataDB.get_word(k).get("tag", "") != "tokoh")
		if milik.is_empty():
			return {}
		kata_ids[slot] = milik[rng.randi_range(0, milik.size() - 1)]
		kata_by_slot[slot] = DataDB.get_word(kata_ids[slot])
	var distrik := rng.randi_range(0, DataDB.districts.size() - 1)
	var pengali := {"uang": 1.0, "heat": 1.0, "kred": 0}
	if pengali_rumor.is_valid():
		pengali = pengali_rumor.call(kata_ids)
	var skor := RumorScorer.nilai(DataDB.get_template(template_id), kata_by_slot, DataDB.districts,
		GameState.kredibilitas, int(pengali.get("kred", 0)))
	var warga := Staf.warga_percaya(skor, DataDB.districts[distrik], float(cfg.get("warga_dasar", 8)))
	GameState.pakai_kartu(kata_ids)
	var uang := roundi(Economy.uang_dari_warga(warga) * float(pengali["uang"]))
	GameState.tambah_uang(uang)
	GameState.ubah_heat(Konsekuensi.heat_kirim(skor, float(cfg.get("pengali_heat", 0.7))) * float(pengali["heat"]))
	var akhir := Konsekuensi.akhir_rumor(skor, warga, GameState.heat, rng)
	GameState.ubah_kredibilitas(akhir["kredibilitas"])
	GameState.ubah_heat(akhir["heat"])
	GameState.tambah_pengikut(akhir["pengikut"])
	if akhir["dibongkar"]:
		GameState.statistik["total_dibongkar"] += 1
	GameState.catat_rumor({
		"template_id": template_id, "kata_ids": kata_ids, "saluran_id": "staf",
		"distrik_id": DataDB.districts[distrik]["id"], "viral": skor["heboh_total"], "dipercaya": skor["dipercaya_akhir"],
		"warga_percaya": warga, "uang_didapat": uang, "dibongkar": akhir["dibongkar"],
		"dibuat_pada": Time.get_datetime_string_from_system(),
	})
	Events.feed_baru.emit({"jenis": "staf", "template_id": template_id, "kata_ids": kata_ids,
		"dibongkar": akhir["dibongkar"], "kredibilitas": -akhir["kredibilitas"]})
	Events.uang_dari_distrik.emit(distrik, uang)
	return {"warga": warga, "uang": uang, "dibongkar": akhir["dibongkar"], "template_id": template_id, "kata_ids": kata_ids}
