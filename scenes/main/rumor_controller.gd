class_name RumorController
extends Node
## Alur satu rumor: kirim lewat saluran, menjalar per tick, mutasi, lalu konsekuensi di akhir.

var sim: SpreadSim
## (distrik_idx: int, emosi: String) -> float. Diisi main dari EventController.
var pengali_event: Callable
## (kata_ids: Dictionary) -> {"uang": float, "heat": float}. Diisi main dari EventController.
var pengali_rumor: Callable
## Pertahanan dan reputasi tokoh target (Era 4). Diisi main.
var tokoh: TokohController

var _rumor: Dictionary = {}
var _warga_percaya := 0
var _uang_didapat := 0
var _pengali_uang := 1.0
var _kata_per_slot: Dictionary = {}
## Radio: {"sisa": jumlah suntikan tersisa, "jeda": detik antar suntikan, "hitung": detik ke suntikan berikut}
var _siaran: Dictionary = {}


func _ready() -> void:
	sim = SpreadSim.new(DataDB.districts, GameClock.rng)
	for slot in RumorScorer.URUTAN_SLOT:
		_kata_per_slot[slot] = DataDB.kata_per_slot(slot)
	_bangkitkan_warga()
	GameClock.tick.connect(_on_tick)
	Events.kirim_diminta.connect(_on_kirim)
	Events.peta_berubah.connect(_bangun_ulang_peta)


## Peta meluas (Era 3): rumor yang berjalan diselesaikan dulu, lalu simulasi dibangun ulang
## dengan status warga lama dipertahankan per distrik.
func _bangun_ulang_peta() -> void:
	if sim.ada_rumor_aktif():
		sim.paksa_selesai()
		_siaran = {}
		_selesai()
	GameState.distrik_status = _hitung_status(sim)
	sim = SpreadSim.new(DataDB.districts, GameClock.rng)
	_bangkitkan_warga()
	Events.sim_diganti.emit(sim)
	Events.warga_berubah.emit()


func biaya_kirim(saluran_id: String) -> int:
	return int(DataDB.get_upgrade(saluran_id).get("biaya_kirim", 0))


func _on_kirim(data: Dictionary) -> void:
	var saluran_id := str(data.get("saluran_id", "merpati"))
	var saluran := DataDB.get_upgrade(saluran_id)
	if sim.ada_rumor_aktif() or not GameState.saluran_terbuka(saluran_id) or GameState.uang < biaya_kirim(saluran_id):
		return
	var benih := _benih(saluran, str(data.get("distrik_id", "")))
	if benih.is_empty():
		return
	var kata_ids: Dictionary = data.get("kata_ids", {})
	var kata_by_slot := {}
	for slot in kata_ids:
		kata_by_slot[slot] = DataDB.get_word(kata_ids[slot])
	kata_by_slot = Kejenuhan.terapkan(kata_by_slot, GameState.kejenuhan_kata())  # kata basi kurang heboh
	var template_id := str(data.get("template_id", ""))
	var pengali := {"uang": 1.0, "heat": 1.0, "kred": 0}
	if pengali_rumor.is_valid():
		pengali = pengali_rumor.call(kata_ids)
	var skor := RumorScorer.nilai(DataDB.get_template(template_id), kata_by_slot, DataDB.districts,
		GameState.kredibilitas, int(pengali.get("kred", 0)))
	var viral: PackedFloat32Array = skor["viral_per_distrik"]
	if pengali_event.is_valid():
		for i in viral.size():
			viral[i] *= float(pengali_event.call(i, skor["emosi"]))
	_pengali_uang = float(pengali["uang"])
	GameState.pakai_kartu(kata_ids)
	var sasaran := tokoh.tokoh_di(kata_ids) if tokoh else {}
	if not sasaran.is_empty():
		pengali["heat"] = float(pengali["heat"]) * tokoh.pengali_heat(sasaran)
	GameState.tambah_uang(-biaya_kirim(saluran_id))
	GameState.ubah_heat(Konsekuensi.heat_kirim(skor, float(saluran.get("pengali_heat", 1.0))) * float(pengali["heat"]))
	_rumor = data.duplicate(true)
	_rumor["skor"] = skor
	_rumor["headline"] = HeadlineBuilder.susun(template_id, kata_ids)
	_rumor["distrik"] = benih.keys()
	_rumor["tokoh"] = sasaran
	_warga_percaya = 0
	_uang_didapat = 0
	_catat_kiriman(skor["emosi"], benih.keys())
	# E12: kota yang tak percaya lagi lebih sulit diyakinkan selama kampanye akhir.
	var percaya: float = skor["dipercaya_akhir"] * (Balance.FINAL_PENGALI_PERCAYA if GameState.final_berjalan else 1.0)
	var awal := sim.mulai(benih, viral, percaya, int(saluran.get("lompatan", 0)))
	_siaran = {}
	if str(saluran.get("cakupan", "")) in ["siaran", "jaringan"]:
		var jeda := float(saluran.get("siaran_jeda", 2.0))
		var durasi := float(saluran.get("siaran_detik", 10.0))
		_siaran = {"sisa": roundi(durasi / jeda) - 1, "jeda": jeda, "hitung": jeda, "mode": saluran["cakupan"]}
		sim.tahan(durasi)
	Events.rumor_published.emit(_rumor)
	if not sasaran.is_empty():
		tokoh.saat_dikirim(sasaran)
	Events.feed_baru.emit({"jenis": "rumor", "template_id": template_id, "kata_ids": kata_ids})
	_tambah_percaya(awal, -1)
	Events.warga_berubah.emit()
	if not sim.ada_rumor_aktif():
		_selesai()


func _on_tick(dt: float) -> void:
	var aktif_sebelum := sim.ada_rumor_aktif()
	_siarkan(dt)
	var hasil := sim.langkah(dt)
	var per_distrik: PackedInt32Array = hasil["percaya_per_distrik"]
	for d in per_distrik.size():
		_tambah_percaya(per_distrik[d], d)
	for n in int(hasil["baru_dengar"]):
		if GameClock.rng.randf() < Balance.PELUANG_MUTASI:
			_mutasi()
	if GameState.heat > 0.0:
		GameState.ubah_heat(-Balance.HEAT_TURUN_PER_DETIK * dt)
	# Orang lupa: kredibilitas rendah pulih pelan sampai batas tertentu.
	if GameState.kredibilitas < Balance.KRED_PULIH_SAMPAI:
		GameState.ubah_kredibilitas(minf(Balance.KRED_PULIH_PER_DETIK * dt, Balance.KRED_PULIH_SAMPAI - GameState.kredibilitas))
	Events.warga_berubah.emit()
	if aktif_sebelum and hasil["selesai"]:
		_selesai()


## Untuk SaveSystem: jumlah status per distrik dan delta rumor yang sedang menjalar,
## dihitung pada salinan simulasi sampai selesai (ADR-0003). Tidak mengubah state.
func snapshot_untuk_save() -> Dictionary:
	var salinan := sim.duplikat()
	var delta := {}
	if salinan.ada_rumor_aktif():
		var tambahan := salinan.jalankan_sampai_selesai(Balance.BATAS_TICK_PROYEKSI)
		var akhir := Konsekuensi.akhir_rumor(_rumor["skor"], _warga_percaya + tambahan, GameState.heat, salinan.rng())
		if akhir["dibongkar"]:
			salinan.kebalkan_rumor(Balance.PERSEN_KEBAL_DIBONGKAR)
		delta = akhir
		delta["uang"] = roundi(Economy.uang_dari_warga(tambahan) * _pengali_uang)
		delta["riwayat"] = _entri_riwayat(_warga_percaya + tambahan, _uang_didapat + delta["uang"], akhir["dibongkar"])
	return {"distrik_status": _hitung_status(salinan), "delta": delta}


func _benih(saluran: Dictionary, distrik_id: String) -> Dictionary:
	var rentang: Array = saluran.get("warga_awal", [1, 1])
	var hasil := {}
	var cakupan := str(saluran.get("cakupan", "satu"))
	if cakupan in ["semua", "siaran"]:
		for i in DataDB.districts.size():
			hasil[i] = GameClock.rng.randi_range(int(rentang[0]), int(rentang[1]))
	elif cakupan == "jaringan":
		hasil[sim.distrik_warga[GameClock.rng.randi_range(0, sim.posisi.size() - 1)]] = int(rentang[0])
	else:
		var idx := DataDB.district_index(distrik_id)
		if idx >= 0:
			hasil[idx] = GameClock.rng.randi_range(int(rentang[0]), int(rentang[1]))
	return hasil


## Radio: tiap `jeda` detik satu warga di setiap distrik langsung mendengar dan percaya.
func _siarkan(dt: float) -> void:
	if _siaran.is_empty() or not sim.ada_rumor_aktif():
		return
	_siaran["hitung"] -= dt
	if _siaran["hitung"] > 0.0:
		return
	_siaran["hitung"] = _siaran["jeda"]
	_siaran["sisa"] -= 1
	if _siaran.get("mode", "siaran") == "jaringan":
		# Server: satu warga acak di mana pun di kota (dipilih lewat distrik warga acak).
		var d := sim.distrik_warga[GameClock.rng.randi_range(0, sim.posisi.size() - 1)]
		_tambah_percaya(sim.suntik({d: 1}), d)
	else:
		for d in DataDB.districts.size():
			_tambah_percaya(sim.suntik({d: 1}), d)
	if _siaran["sisa"] <= 0:
		_siaran = {}


func _tambah_percaya(jumlah: int, distrik: int) -> void:
	if jumlah <= 0:
		return
	var uang := roundi(Economy.uang_dari_warga(jumlah) * _pengali_uang)
	_warga_percaya += jumlah
	_uang_didapat += uang
	GameState.tambah_uang(uang)
	if distrik >= 0:
		Events.uang_dari_distrik.emit(distrik, uang)


func _mutasi() -> void:
	var baru := Mutasi.acak(_rumor.get("kata_ids", {}), _kata_per_slot, GameClock.rng)
	if baru.is_empty():
		return
	GameState.tambah_pengikut(Balance.PENGIKUT_PER_MUTASI)
	Events.feed_baru.emit({"jenis": "mutasi", "template_id": _rumor["template_id"], "kata_ids": baru})


func _selesai() -> void:
	var sasaran: Dictionary = _rumor.get("tokoh", {})
	var paksa := not sasaran.is_empty() and tokoh.membantah(sasaran, _rumor["skor"])
	var akhir := Konsekuensi.akhir_rumor(_rumor["skor"], _warga_percaya, GameState.heat, GameClock.rng, paksa)
	GameState.ubah_kredibilitas(akhir["kredibilitas"])
	GameState.ubah_heat(akhir["heat"])
	GameState.tambah_pengikut(akhir["pengikut"])
	if akhir["dibongkar"]:
		sim.kebalkan_rumor(Balance.PERSEN_KEBAL_DIBONGKAR)
		GameState.statistik["total_dibongkar"] += 1
		Events.feed_baru.emit({"jenis": "hoaks", "template_id": _rumor["template_id"],
			"kata_ids": _rumor["kata_ids"], "kredibilitas": -akhir["kredibilitas"]})
	if not sasaran.is_empty() and not akhir["dibongkar"]:
		tokoh.serang(sasaran, _warga_percaya)
	GameState.statistik["rekor_warga"] = maxi(int(GameState.statistik["rekor_warga"]), _warga_percaya)
	GameState.catat_rumor(_entri_riwayat(_warga_percaya, _uang_didapat, akhir["dibongkar"]))
	var hasil := _rumor.duplicate()
	hasil.merge({"warga_percaya": _warga_percaya, "uang": _uang_didapat, "dibongkar": akhir["dibongkar"]}, true)
	Events.warga_berubah.emit()
	Events.rumor_selesai.emit(hasil)


func _catat_kiriman(emosi: String, distrik: Array) -> void:
	GameState.statistik["total_rumor"] += 1
	var daftar: Array = GameState.statistik["emosi_distrik"]
	for d in distrik:
		var kunci := "%s@%s" % [emosi, DataDB.districts[d]["id"]]
		if not (kunci in daftar):
			daftar.append(kunci)


func _entri_riwayat(warga: int, uang: int, dibongkar: bool) -> Dictionary:
	var skor: Dictionary = _rumor["skor"]
	return {
		"template_id": _rumor["template_id"], "kata_ids": _rumor["kata_ids"],
		"saluran_id": _rumor.get("saluran_id", "merpati"), "distrik_id": _rumor.get("distrik_id", ""),
		"viral": skor["heboh_total"], "dipercaya": skor["dipercaya_akhir"], "warga_percaya": warga,
		"uang_didapat": uang, "dibongkar": dibongkar, "dibuat_pada": Time.get_datetime_string_from_system(),
	}


func _hitung_status(s: SpreadSim) -> Dictionary:
	var hasil := {}
	# Simulasi lama bisa punya distrik lebih sedikit dari DataDB.districts (saat peta baru meluas);
	# distrik baru selalu ditambah di akhir, jadi indeks distrik lama tetap sama.
	for i in mini(s.warga_per_distrik.size(), DataDB.districts.size()):
		hasil[DataDB.districts[i]["id"]] = {
			"percaya": s.jumlah_status(i, SpreadSim.Status.PERCAYA),
			"ragu": s.jumlah_status(i, SpreadSim.Status.RAGU),
			"kebal": s.jumlah_status(i, SpreadSim.Status.KEBAL),
		}
	return hasil


func _bangkitkan_warga() -> void:
	for i in DataDB.districts.size():
		var st: Dictionary = GameState.distrik_status.get(DataDB.districts[i]["id"], {})
		if not st.is_empty():
			sim.terapkan_jumlah(i, int(st.get("percaya", 0)), int(st.get("ragu", 0)), int(st.get("kebal", 0)))
