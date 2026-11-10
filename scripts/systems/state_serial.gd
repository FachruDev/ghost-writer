class_name StateSerial
extends RefCounted
## Ubah GameState ke dictionary save dan sebaliknya (ADR-0002). Konten selalu dirujuk lewat ID;
## ID yang tidak lagi ada di res://data/ diabaikan saat memuat.
##
## DataDB diambil dari root (bukan nama global) supaya class ini tetap bisa dikompilasi
## oleh runner headless yang memuat script sebelum autoload terdaftar.

const STAT_BULAT := ["total_rumor", "total_uang", "total_dibongkar", "kata_dibeli", "rekor_warga"]


static func statistik_kosong() -> Dictionary:
	return {
		"total_rumor": 0, "total_uang": 0, "total_dibongkar": 0, "kata_dibeli": 0,
		"rekor_warga": 0, "emosi_distrik": [], "rumor_terbaik": null, "event_sekali": [],
		"tutorial_lewat": false, "petunjuk": [],
	}


static func ke_dict(st: Node) -> Dictionary:
	return {
		"pemain": {
			"uang": st.uang, "pengikut": st.pengikut, "kredibilitas": st.kredibilitas, "heat": st.heat,
			"era": st.era, "waktu_main_detik": st.waktu_main_detik, "misi_idx": st.misi_idx,
			"hasil_akhir": st.hasil_akhir,
		},
		"kartu_dimiliki": st.kartu_dimiliki.duplicate(),
		"template_dimiliki": st.template_dimiliki.duplicate(),
		"upgrade_dimiliki": st.upgrade_dimiliki.duplicate(),
		"kartu_sementara": st.kartu_sementara.duplicate(),
		"tokoh_reputasi": st.tokoh_reputasi.duplicate(),
		"distrik_status": st.distrik_status.duplicate(true),
		"riwayat_rumor": st.riwayat_rumor.duplicate(true),
		"riwayat_event": st.riwayat_event.duplicate(true),
		"statistik": st.statistik.duplicate(true),
	}


## Angka dari JSON terbaca sebagai float; semua bilangan bulat di-cast (ADR-0002).
static func dari_dict(st: Node, data: Dictionary) -> void:
	var db := (Engine.get_main_loop() as SceneTree).root.get_node(^"DataDB")
	var p: Dictionary = data.get("pemain", {})
	st.uang = int(p.get("uang", 0))
	st.pengikut = int(p.get("pengikut", 0))
	st.kredibilitas = float(p.get("kredibilitas", Balance.KREDIBILITAS_AWAL))
	st.heat = float(p.get("heat", 0.0))
	st.era = int(p.get("era", 1))
	st.waktu_main_detik = float(p.get("waktu_main_detik", 0.0))
	st.misi_idx = int(p.get("misi_idx", 0))
	st.hasil_akhir = str(p.get("hasil_akhir", ""))
	_isi_daftar(st.kartu_dimiliki, data.get("kartu_dimiliki", []), db.words)
	_isi_daftar(st.template_dimiliki, data.get("template_dimiliki", []), db.templates)
	st.upgrade_dimiliki = _angka_per_id(data.get("upgrade_dimiliki", {}), db.upgrades)
	st.kartu_sementara = _angka_per_id(data.get("kartu_sementara", {}), db.words)
	st.saluran_terkunci = {}
	st.tokoh_reputasi = _angka_per_id(data.get("tokoh_reputasi", {}), {})
	st.distrik_status = data.get("distrik_status", {})
	st.riwayat_rumor = data.get("riwayat_rumor", [])
	st.riwayat_event = data.get("riwayat_event", [])
	st.statistik = statistik_kosong()
	st.statistik.merge(data.get("statistik", {}), true)
	for k in STAT_BULAT:
		st.statistik[k] = int(st.statistik[k])


## Isi `tujuan` dengan ID dari `sumber` yang masih ada di `ada` (dictionary data per ID).
static func _isi_daftar(tujuan: Array[String], sumber: Array, ada: Dictionary) -> void:
	tujuan.clear()
	for id in sumber:
		if ada.has(str(id)):
			tujuan.append(str(id))


## {id: angka} dari JSON. `ada` kosong = semua ID diterima.
static func _angka_per_id(sumber: Dictionary, ada: Dictionary) -> Dictionary:
	var hasil := {}
	for id in sumber:
		if ada.is_empty() or ada.has(str(id)):
			hasil[str(id)] = int(sumber[id])
	return hasil
