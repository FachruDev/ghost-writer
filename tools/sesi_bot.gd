extends SceneTree

## Alat balancing: bot pemain sederhana memainkan beberapa sesi 15 menit (waktu simulasi)
## dan mencatat kapan misi selesai, berapa event muncul, heat, dan kondisi ekonomi.
##
## Jalankan: godot --headless --path . -s res://tools/sesi_bot.gd
## Mengubah angka di scripts/systems/balance.gd lalu menjalankan ulang alat ini adalah cara
## menyetel balancing tanpa playtest manual (ADR-0003: simulasi berseed + headless).
## Catatan: jangan rujuk class yang memakai autoload saat compile (mis. MissionController);
## runner -s mengompilasi script ini sebelum autoload terdaftar.

const DURASI_SESI := 50.0 * 60.0
const JEDA_PIKIR := 10.0  # detik antara rumor selesai dan rumor berikutnya
const SEEDS := [1, 2, 3, 4, 5, 6, 7, 8]

var R: Node
var _frame := 0


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		_jalankan_semua()
	return false


func _jalankan_semua() -> void:
	R = get_root()
	var ringkas: Array = []
	for s in SEEDS:
		ringkas.append(await _sesi(s))
	_cetak(ringkas)
	quit()


func a(n: String) -> Node:
	return R.get_node(n)


func _sesi(seed: int) -> Dictionary:
	var st = a("GameState"); var ev = a("Events"); var clock = a("GameClock"); var db = a("DataDB")
	a("SaveSystem").reset_progres()
	clock.atur_seed(seed)
	seed(seed)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	R.add_child(main)
	var rumor: Node = main.get_node("RumorController")
	var catatan := {"seed": seed, "misi": [], "event": [], "rumor": 0, "dibongkar": 0, "heat_maks": 0.0, "kred_min": 100.0, "beli": 0, "heat_sum": 0.0, "heat_panas": 0.0, "n": 0, "era2": -1.0, "staf": -1.0, "dilema": 0, "era3": -1.0, "kontrak_ok": 0, "kontrak_gagal": 0, "era4": -1.0, "tokoh_jatuh": 0}
	var f_misi := func(): catatan["misi"].append([st.misi_idx, roundi(_t)])
	var f_event := func(i): catatan["event"].append([str(i["id"]), roundi(_t)])
	var f_selesai := func(h): if h.get("dibongkar", false): catatan["dibongkar"] += 1
	ev.misi_berubah.connect(f_misi); ev.event_mulai.connect(f_event); ev.rumor_selesai.connect(f_selesai)
	_t = 0.0
	var tunggu := 0.0
	var tiarap := false  # pemain berhenti mengirim saat heat tinggi
	var ec: Node = main.get_node("EventController")
	var kc: Node = main.get_node("CampaignController")
	var f_kontrak := func(e):
		if e.get("jenis", "") == "tokoh_jatuh":
			catatan["tokoh_jatuh"] += 1
		if e.get("jenis", "") == "kontrak":
			catatan["kontrak_ok" if e.get("berhasil", false) else "kontrak_gagal"] += 1
	ev.feed_baru.connect(f_kontrak)
	while _t < DURASI_SESI:
		if ec.sedang_dilema():
			catatan["dilema"] += 1
			ev.dilema_dipilih.emit(0 if st.uang >= 400 else 1)
		if not kc._tawaran.is_empty():
			ev.dilema_dipilih.emit(0)
		if st.era >= 4 and catatan["era4"] < 0.0:
			catatan["era4"] = _t
		if st.era >= 3 and catatan["era3"] < 0.0:
			catatan["era3"] = _t
		if st.era >= 2 and catatan["era2"] < 0.0:
			catatan["era2"] = _t
		if st.punya_upgrade("staf_1") and catatan["staf"] < 0.0:
			catatan["staf"] = _t
		if not rumor.sim.ada_rumor_aktif():
			tunggu += Balance.SIM_TICK
			if st.heat >= 60.0:
				tiarap = true
			elif st.heat < 40.0:
				tiarap = false
			if tunggu >= JEDA_PIKIR and not tiarap:
				tunggu = 0.0
				catatan["beli"] += _belanja(st, db)
				if _kirim(st, db, ev):
					catatan["rumor"] += 1
		clock.jalankan_tick(1)
		# Beri satu frame tiap 1.000 tick supaya antrean pesan Godot (redraw, ukuran label) sempat dikosongkan.
		if int(_t / Balance.SIM_TICK) % 1000 == 0:
			await process_frame
		_t += Balance.SIM_TICK
		catatan["heat_maks"] = maxf(catatan["heat_maks"], st.heat)
		catatan["kred_min"] = minf(catatan["kred_min"], st.kredibilitas)
		catatan["heat_sum"] += st.heat
		catatan["n"] += 1
		if st.heat >= 70.0:
			catatan["heat_panas"] += Balance.SIM_TICK
	catatan["uang"] = st.uang; catatan["pengikut"] = st.pengikut; catatan["misi_akhir"] = st.misi_idx
	catatan["kartu"] = st.kartu_dimiliki.size(); catatan["template"] = st.template_dimiliki.size()
	ev.feed_baru.disconnect(f_kontrak)
	ev.misi_berubah.disconnect(f_misi); ev.event_mulai.disconnect(f_event); ev.rumor_selesai.disconnect(f_selesai)
	main.free()
	return catatan

var _t := 0.0


## Beli kata termurah kalau uang cukup dengan cadangan 30 untuk Koran; template kalau jauh lebih kaya.
func _belanja(st, db) -> int:
	var dibeli := 0
	for u in ["kantor", "staf_1", "gedung_media", "menara_server"]:
		if st.upgrade_tersedia(u) and st.uang >= int(db.get_upgrade(u)["harga"]):
			if st.beli_upgrade(u):
				dibeli += 1
	for u in ["kantor", "gedung_media", "menara_server"]:
		if st.upgrade_tersedia(u):
			return dibeli  # menabung untuk naik era
	for t in db.templates:
		if not st.punya_template(t) and st.era_terbuka(db.templates[t]) and st.uang >= int(db.templates[t]["harga"]) + 150:
			if st.beli_template(t):
				dibeli += 1
	var calon: Array = []
	for id in db.words:
		if not st.punya_kata(id) and st.era_terbuka(db.words[id]) and db.words[id].get("toko", true):
			calon.append(id)
	calon.sort_custom(func(x, y): return int(db.words[x]["harga"]) < int(db.words[y]["harga"]))
	for id in calon:
		if st.uang >= int(db.words[id]["harga"]) + 30:
			if st.beli_kata(id):
				dibeli += 1
	return dibeli


## Coba semua template dan kombinasi kartu per slot (rakus per slot), pilih skor terbaik untuk distrik terbaik.
func _kirim(st, db, ev) -> bool:
	var misi: Dictionary = db.missions[st.misi_idx] if st.misi_idx < db.missions.size() else {}
	var paksa_takut: bool = misi.get("syarat", {}).get("tipe", "") == "rumor_emosi_distrik"
	var terbaik := {}
	var nilai_terbaik := -1.0
	for tid in st.template_dimiliki:
		var tmpl: Dictionary = db.get_template(tid)
		for di in db.districts.size():
			var d: Dictionary = db.districts[di]
			if paksa_takut and d["id"] != "gang_sempit":
				continue
			var pilih := {}
			for slot in tmpl["slot"]:
				var kandidat: Array = st.kartu_dimiliki.filter(func(k): return db.get_word(k)["slot"] == slot)
				kandidat.sort_custom(func(x, y): return _nilai_kartu(db.get_word(x), d, paksa_takut) > _nilai_kartu(db.get_word(y), d, paksa_takut))
				if kandidat.is_empty():
					break
				pilih[slot] = kandidat[0]
			if pilih.size() != tmpl["slot"].size():
				continue
			var kata := {}
			for s in pilih:
				kata[s] = db.get_word(pilih[s])
			var skor := RumorScorer.nilai(tmpl, kata, db.districts, st.kredibilitas)
			var n: float = skor["viral_per_distrik"][di] * skor["dipercaya_akhir"] * (1.0 - Konsekuensi.peluang_bongkar(skor["dipercaya_akhir"], st.heat))
			if paksa_takut and skor["emosi"] != "takut":
				n *= 0.01
			if n > nilai_terbaik:
				nilai_terbaik = n
				terbaik = {"template_id": tid, "kata_ids": pilih, "distrik_id": d["id"]}
	if terbaik.is_empty():
		return false
	var server: bool = st.saluran_terbuka("server") and st.uang >= 450 and not paksa_takut
	var medsos: bool = not server and st.saluran_terbuka("medsos") and st.uang >= 250 and not paksa_takut
	var radio: bool = not medsos and st.saluran_terbuka("radio") and st.uang >= 160 and not paksa_takut
	var koran: bool = not radio and st.saluran_terbuka("koran") and st.uang >= 60 and not paksa_takut
	terbaik["saluran_id"] = "server" if server else "medsos" if medsos else ("radio" if radio else ("koran" if koran else "merpati"))
	if koran or radio:
		terbaik["distrik_id"] = ""
	ev.kirim_diminta.emit(terbaik)
	return true


func _nilai_kartu(k: Dictionary, d: Dictionary, paksa_takut: bool) -> float:
	var v := float(k["kred"]) * 1.2 + float(k["heboh"])
	if k["emosi"] == d["emosi_favorit"]:
		v += 2.0
	if paksa_takut and k["emosi"] == "takut":
		v += 10.0
	# Era 4: utamakan tokoh yang masih berdiri.
	if k.get("tag", "") == "tokoh" and int(R.get_node("GameState").tokoh_reputasi.get(str(k["id"]).trim_prefix("tokoh_"), 0)) > 0:
		v += 8.0
	return v


func _cetak(daftar: Array) -> void:
	var k := daftar.size()
	var rata := func(f: Callable) -> float:
		var t := 0.0
		for l in daftar:
			t += float(f.call(l))
		return t / k
	var m5 := daftar.filter(func(l): return l["misi_akhir"] >= 5).map(func(l): return l["misi"].filter(func(x): return x[0] == 5)[0][1] / 60.0)
	var era2 := daftar.filter(func(l): return l["era2"] >= 0.0).map(func(l): return snappedf(l["era2"] / 60.0, 0.1))
	var staf := daftar.filter(func(l): return l["staf"] >= 0.0).map(func(l): return snappedf(l["staf"] / 60.0, 0.1))
	var era3 := daftar.filter(func(l): return l["era3"] >= 0.0).map(func(l): return snappedf(l["era3"] / 60.0, 0.1))
	var era4 := daftar.filter(func(l): return l["era4"] >= 0.0).map(func(l): return snappedf(l["era4"] / 60.0, 0.1))
	print("ERA4: menara server %d/%d @menit %s | tokoh jatuh=%.1f per sesi" % [era4.size(), k, str(era4), rata.call(func(l): return l["tokoh_jatuh"])])
	print("ERA3: gedung media %d/%d @menit %s | kontrak berhasil=%.1f gagal=%.1f per sesi" % [era3.size(), k, str(era3),
		rata.call(func(l): return l["kontrak_ok"]), rata.call(func(l): return l["kontrak_gagal"])])
	print("ERA2: sewa kantor %d/%d @menit %s | staf %d/%d @menit %s | dilema=%.1f per sesi" % [era2.size(), k, str(era2), staf.size(), k, str(staf), rata.call(func(l): return l["dilema"])])
	print("RINGKAS: misi5_selesai=%d/%d @menit %s | rumor=%.0f | bongkar=%.0f%% | heat_rata=%.0f | menit_heat>=70=%.1f | kred_min=%.0f | acak=%.1f | ancaman=%.1f | kartu=%.1f/40 | uang=%.0f" % [
		m5.size(), k, str(m5.map(func(x): return snappedf(x, 0.1))), rata.call(func(l): return l["rumor"]),
		100.0 * rata.call(func(l): return float(l["dibongkar"]) / maxf(1, l["rumor"])), rata.call(func(l): return l["heat_sum"] / maxf(1, l["n"])),
		rata.call(func(l): return l["heat_panas"] / 60.0), rata.call(func(l): return l["kred_min"]),
		rata.call(func(l): return l["event"].filter(func(e): return e[0] != "e_pembongkar_fakta").size()),
		rata.call(func(l): return l["event"].filter(func(e): return e[0] == "e_pembongkar_fakta").size()),
		rata.call(func(l): return l["kartu"]), rata.call(func(l): return l["uang"])])
	return
	print("seed | rumor | misi selesai (menit ke-) | event (menit ke-) | bongkar | heat maks | kred min | uang | pengikut | kartu | template")
	for l in daftar:
		var m := ", ".join(l["misi"].filter(func(x): return x[0] > 0).map(func(x): return "M%d@%.1f" % [x[0], x[1] / 60.0]))
		var e := ", ".join(l["event"].map(func(x): return "%s@%.1f" % [str(x[0]).replace("e_", ""), x[1] / 60.0]))
		print("%d | %d | %s | %s | %d | %.0f | %.0f | %d | %d | %d | %d" % [l["seed"], l["rumor"], m, e, l["dibongkar"], l["heat_maks"], l["kred_min"], l["uang"], l["pengikut"], l["kartu"], l["template"]])
