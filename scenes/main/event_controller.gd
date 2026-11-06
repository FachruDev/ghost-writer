class_name EventController
extends Node
## Event kota dari data/events.json (EVENT.md): modifier acak dan ancaman berdasarkan kondisi.
## Waktu dalam detik simulasi; jeda antar event tidak disimpan (ADR-0003).

var sim: SpreadSim

## Event acak (modifier/peluang) yang sedang aktif; efeknya dibaca pengali_viral().
var _aktif: Dictionary = {}
var _sisa := 0.0
## Ancaman berjalan di jalur sendiri supaya tidak menimpa event acak (EVENT.md).
var _ancaman: Dictionary = {}
var _sisa_ancaman := 0.0
var _sejak_event := 0.0
var _sejak_ancaman := Balance.ANCAMAN_JEDA_DETIK
var _sejak_cek := 0.0


func _ready() -> void:
	GameClock.tick.connect(_on_tick)
	Events.dilema_dipilih.connect(_on_dilema_dipilih)
	Events.sim_diganti.connect(func(s: SpreadSim) -> void: sim = s)
	Events.ancaman_diminta.connect(_on_ancaman_diminta)


func sedang_dilema() -> bool:
	return str(_aktif.get("jenis", "")) == "dilema"


## Pengali viral dari event aktif untuk satu distrik dan emosi headline. Distrik "*" = semua.
func pengali_viral(distrik: int, emosi: String) -> float:
	var kali := 1.0
	if _aktif.is_empty():
		return kali
	var distrik_id := str(DataDB.districts[distrik]["id"])
	for efek in _aktif.get("efek", []):
		if not (str(efek.get("distrik", "")) in [distrik_id, "*"]):
			continue
		match str(efek.get("tipe", "")):
			"kerentanan_distrik":
				kali *= float(efek.get("kali", 1.0))
			"emosi_distrik":
				if str(efek.get("emosi", "")) == emosi:
					kali *= float(efek.get("kali", 1.0))
	return kali


## Pengali uang dan heat untuk satu rumor dari event aktif (E04 calon RT, E06 festival).
func pengali_rumor(kata_ids: Dictionary) -> Dictionary:
	var hasil := {"uang": 1.0, "heat": 1.0, "kred": 0}
	for efek in _aktif.get("efek", []):
		match str(efek.get("tipe", "")):
			"kred_kartu":
				hasil["kred"] += int(efek.get("nilai", 0))
			"uang_per_warga":
				hasil["uang"] *= float(efek.get("kali", 1.0))
			"pengali_tag":
				for slot in kata_ids:
					if str(DataDB.get_word(kata_ids[slot]).get("tag", "")) == str(efek.get("tag", "")):
						hasil["uang"] *= float(efek.get("uang", 1.0))
						hasil["heat"] *= float(efek.get("heat", 1.0))
						break
	return hasil


func _on_tick(dt: float) -> void:
	GameState.kurangi_kunci(dt)
	_sejak_event += dt
	_sejak_ancaman += dt
	_sejak_cek += dt
	if not _ancaman.is_empty():
		_sisa_ancaman -= dt
		if _sisa_ancaman <= 0.0:
			_ancaman = {}
			_selesai_atau_kembali()
	if not _aktif.is_empty() and not sedang_dilema():
		_sisa -= dt
		if _sisa <= 0.0:
			_aktif = {}
			_selesai_atau_kembali()
	if not _ancaman.is_empty():
		Events.event_sisa.emit(maxf(_sisa_ancaman, 0.0))
	elif not _aktif.is_empty():
		Events.event_sisa.emit(maxf(_sisa, 0.0))
	_cek_ancaman()
	_cek_ambang()
	if _sejak_cek >= Balance.EVENT_CEK_DETIK:
		_sejak_cek = 0.0
		_cek_acak()


func _cek_ancaman() -> void:
	if _sejak_ancaman < Balance.ANCAMAN_JEDA_DETIK:
		return
	for e in DataDB.events:
		var pemicu: Dictionary = e.get("pemicu", {})
		if str(e.get("jenis", "")) == "ancaman" and str(pemicu.get("tipe", "")) == "kondisi" \
				and _era_cocok(e) and _kondisi_ancaman(pemicu):
			_mulai_ancaman(e)
			return


func _mulai_ancaman(e: Dictionary) -> void:
	_sejak_ancaman = 0.0
	_ancaman = e
	_sisa_ancaman = float(e.get("durasi", 0))
	_umumkan(e, _sisa_ancaman)


## Pertahanan tokoh meminta ancaman tertentu; jalan kalau jalur ancaman sedang kosong.
func _on_ancaman_diminta(event_id: String) -> void:
	if not _ancaman.is_empty():
		return
	for e in DataDB.events:
		if str(e["id"]) == event_id:
			_mulai_ancaman(e)
			return


## Ancaman terpicu oleh heat tinggi (heat_min) atau kredibilitas rendah (kred_maks).
func _kondisi_ancaman(pemicu: Dictionary) -> bool:
	if pemicu.has("heat_min") and GameState.heat >= float(pemicu["heat_min"]):
		return true
	return pemicu.has("kred_maks") and GameState.kredibilitas < float(pemicu["kred_maks"])


func _cek_acak() -> void:
	# Jangan mulai event saat waktu dijeda (dilema atau tawaran kontrak sedang tampil).
	if not _aktif.is_empty() or _sejak_event < Balance.EVENT_JEDA_DETIK or GameClock.sedang_jeda():
		return
	for e in DataDB.events:
		var pemicu: Dictionary = e.get("pemicu", {})
		if str(pemicu.get("tipe", "")) == "acak" and _era_cocok(e) and _syarat_terpenuhi(pemicu) \
				and GameClock.rng.randf() < float(pemicu.get("peluang", 0.0)):
			# Ancaman acak (E10) memakai jalur ancaman sendiri.
			if str(e.get("jenis", "")) == "ancaman":
				if _ancaman.is_empty() and _sejak_ancaman >= Balance.ANCAMAN_JEDA_DETIK:
					_mulai_ancaman(e)
				continue
			_mulai(e)
			return


## Event berpemicu ambang pengikut (E04) terjadi sekali per permainan, saat jalur event acak kosong.
func _cek_ambang() -> void:
	if not _aktif.is_empty():
		return
	var sekali: Array = GameState.statistik["event_sekali"]
	for e in DataDB.events:
		var pemicu: Dictionary = e.get("pemicu", {})
		if str(pemicu.get("tipe", "")) == "pengikut" and not (str(e["id"]) in sekali) and _era_cocok(e) \
				and GameState.pengikut >= int(pemicu.get("nilai", 0)):
			sekali.append(str(e["id"]))
			_mulai(e)
			return


func _syarat_terpenuhi(pemicu: Dictionary) -> bool:
	var syarat: Dictionary = pemicu.get("syarat", {})
	return GameState.heat >= float(syarat.get("heat_min", 0.0))


## Memulai event acak (modifier/peluang).
func _mulai(e: Dictionary) -> void:
	_aktif = e
	_sisa = float(e.get("durasi", 0))
	_sejak_event = 0.0
	if sedang_dilema():
		GameClock.jeda(&"dilema")
	_umumkan(e, _sisa)


## Pemain memilih opsi dilema: terapkan efeknya, catat di feed, lalu jalankan waktu lagi.
func _on_dilema_dipilih(indeks: int) -> void:
	if not sedang_dilema():
		return
	var pilihan: Array = _aktif.get("pilihan", [])
	if indeks < 0 or indeks >= pilihan.size():
		return
	var info := {}
	for efek in pilihan[indeks].get("efek", []):
		_efek_langsung(efek, info)
	Events.feed_baru.emit({"jenis": "dilema", "teks": pilihan[indeks].get("label", "")})
	_aktif = {}
	GameClock.lanjut(&"dilema")
	_selesai_atau_kembali()


func _umumkan(e: Dictionary, durasi: float) -> void:
	GameState.catat_event(str(e["id"]))
	var info := _info(e, durasi)
	for efek in e.get("efek", []):
		_efek_langsung(efek, info)
	Events.event_mulai.emit(info)
	Events.feed_baru.emit({"jenis": "event", "teks": e.get("nama", ""), "info": info.get("hasil", "")})


func _info(e: Dictionary, durasi: float) -> Dictionary:
	var label: Array = []
	for p in e.get("pilihan", []):
		label.append(p.get("label", ""))
	return {"id": e["id"], "nama": e.get("nama", ""), "teks": e.get("teks", ""), "jenis": e.get("jenis", ""),
		"durasi": durasi, "pilihan": label}


## Saat satu jalur selesai: tampilkan lagi event yang masih berjalan, atau tutup banner.
func _selesai_atau_kembali() -> void:
	if not _ancaman.is_empty():
		Events.event_tampil.emit(_info(_ancaman, _sisa_ancaman))
	elif not _aktif.is_empty():
		Events.event_tampil.emit(_info(_aktif, _sisa))
	else:
		Events.event_selesai.emit("")


func _efek_langsung(efek: Dictionary, info: Dictionary) -> void:
	match str(efek.get("tipe", "")):
		"kredibilitas":
			GameState.ubah_kredibilitas(float(efek.get("nilai", 0)))
		"uang":
			GameState.tambah_uang(int(efek.get("nilai", 0)))
		"heat":
			GameState.ubah_heat(float(efek.get("nilai", 0)))
		"pengikut":
			GameState.tambah_pengikut(int(efek.get("nilai", 0)))
		"beri_kata":
			for id in efek.get("kata", []):
				GameState.beri_kata(str(id))
		"kartu_sementara":
			GameState.beri_kartu_sementara(str(efek.get("kata", "")), int(efek.get("rumor", 1)))
		"kunci_saluran":
			GameState.kunci_saluran(str(efek.get("saluran", "")), float(efek.get("detik", 60)))
		"ragukan":
			if sim != null:
				_ragukan(float(efek.get("persen", 40)) / 100.0)
		"pengikut_persen":
			GameState.tambah_pengikut(roundi(GameState.pengikut * float(efek.get("nilai", 0)) / 100.0))
		"pembongkar":
			if sim == null:
				return
			var n := sim.kebalkan_sekitar(_pusat_pembongkar(), float(efek.get("radius", 0.1)))
			info["hasil"] = tr("UI_PEMBONGKAR") % n
			Events.warga_berubah.emit()


## E10: sebagian warga yang percaya di distrik dengan pemercaya terbanyak menjadi ragu.
func _ragukan(persen: float) -> void:
	var terbaik := -1
	var paling := 0
	for d in sim.warga_per_distrik.size():
		var n := sim.jumlah_status(d, SpreadSim.Status.PERCAYA)
		if n > paling:
			paling = n
			terbaik = d
	if terbaik < 0:
		return
	for i in sim.warga_per_distrik[terbaik]:
		if sim.status[i] == SpreadSim.Status.PERCAYA and GameClock.rng.randf() < persen:
			sim.ubah_status(i, SpreadSim.Status.RAGU)
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
