class_name EventController
extends Node
## Event kota dari data/events.json (EVENT.md): modifier acak dan ancaman berdasarkan kondisi.
## Waktu dalam detik simulasi; jeda antar event tidak disimpan (ADR-0003).

var sim: SpreadSim

var _aktif: Dictionary = {}
var _sisa := 0.0
var _sejak_event := 0.0
var _sejak_ancaman := Balance.ANCAMAN_JEDA_DETIK
var _sejak_cek := 0.0


func _ready() -> void:
	GameClock.tick.connect(_on_tick)


## Pengali viral dari event aktif untuk satu distrik dan emosi headline.
func pengali_viral(distrik: int, emosi: String) -> float:
	var kali := 1.0
	if _aktif.is_empty():
		return kali
	var distrik_id := str(DataDB.districts[distrik]["id"])
	for efek in _aktif.get("efek", []):
		if str(efek.get("distrik", "")) != distrik_id:
			continue
		match str(efek.get("tipe", "")):
			"kerentanan_distrik":
				kali *= float(efek.get("kali", 1.0))
			"emosi_distrik":
				if str(efek.get("emosi", "")) == emosi:
					kali *= float(efek.get("kali", 1.0))
	return kali


func _on_tick(dt: float) -> void:
	_sejak_event += dt
	_sejak_ancaman += dt
	_sejak_cek += dt
	if not _aktif.is_empty():
		_sisa -= dt
		Events.event_sisa.emit(maxf(_sisa, 0.0))
		if _sisa <= 0.0:
			var id := str(_aktif["id"])
			_aktif = {}
			Events.event_selesai.emit(id)
	_cek_ancaman()
	if _sejak_cek >= Balance.EVENT_CEK_DETIK:
		_sejak_cek = 0.0
		_cek_acak()


func _cek_ancaman() -> void:
	if _sejak_ancaman < Balance.ANCAMAN_JEDA_DETIK:
		return
	for e in DataDB.events:
		var pemicu: Dictionary = e.get("pemicu", {})
		if str(e.get("jenis", "")) == "ancaman" and str(pemicu.get("tipe", "")) == "kondisi" \
				and _era_cocok(e) and GameState.heat >= float(pemicu.get("heat_min", 999)):
			_sejak_ancaman = 0.0
			_mulai(e)
			return


func _cek_acak() -> void:
	if not _aktif.is_empty() or _sejak_event < Balance.EVENT_JEDA_DETIK:
		return
	for e in DataDB.events:
		var pemicu: Dictionary = e.get("pemicu", {})
		if str(pemicu.get("tipe", "")) == "acak" and _era_cocok(e) \
				and GameClock.rng.randf() < float(pemicu.get("peluang", 0.0)):
			_mulai(e)
			return


func _mulai(e: Dictionary) -> void:
	_aktif = e
	_sisa = float(e.get("durasi", 0))
	_sejak_event = 0.0
	GameState.catat_event(str(e["id"]))
	var info := {"id": e["id"], "nama": e.get("nama", ""), "teks": e.get("teks", ""), "jenis": e.get("jenis", ""), "durasi": _sisa}
	for efek in e.get("efek", []):
		_efek_langsung(efek, info)
	Events.event_mulai.emit(info)
	Events.feed_baru.emit({"jenis": "event", "teks": e.get("nama", ""), "info": info.get("hasil", "")})


func _efek_langsung(efek: Dictionary, info: Dictionary) -> void:
	match str(efek.get("tipe", "")):
		"kredibilitas":
			GameState.ubah_kredibilitas(float(efek.get("nilai", 0)))
		"pembongkar":
			if sim == null:
				return
			var n := sim.kebalkan_sekitar(_pusat_pembongkar(), float(efek.get("radius", 0.1)))
			info["hasil"] = tr("UI_PEMBONGKAR") % n
			Events.warga_berubah.emit()


## Pembongkar muncul di dekat warga yang percaya; kalau tidak ada, di tengah kota.
func _pusat_pembongkar() -> Vector2:
	var calon := PackedInt32Array()
	for i in sim.status.size():
		if sim.status[i] == SpreadSim.Status.PERCAYA:
			calon.append(i)
	if calon.is_empty():
		return Vector2(0.5, 0.5)
	return sim.posisi[calon[GameClock.rng.randi_range(0, calon.size() - 1)]]


func _era_cocok(e: Dictionary) -> bool:
	return GameState.era >= int(e.get("era_min", 1))
