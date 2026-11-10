extends SceneTree

## Alat balancing: bot pemain sederhana memainkan beberapa sesi (waktu simulasi) dari kamar
## sampai kampanye akhir, dan mencatat kapan era naik, misi selesai, event, heat, dan ekonomi.
##
## Jalankan: godot --headless --path . -s res://tools/sesi_bot.gd
## Hanya kampanye akhir (mulai dari era 4, semua tokoh jatuh): tambahkan `-- final` di akhir perintah.
## Kata basi: bot memilih kartu tanpa melihat kata basi (tetap kena penaltinya), sama seperti bot sebelum
## kejenuhan ada, supaya hasilnya bisa dibandingkan dengan laporan lama. `-- peduli`: bot menurunkan nilai kartu
## basi (heuristik kasar; di uji 2026-11-10 justru memilih kartu lebih lemah). `-- tanpa_jenuh`: kejenuhan dimatikan.
## Coba angka lain tanpa mengubah CSV: `-- jenuh_per_pakai=0.1 jenuh_min=0.6`.
## Mengubah angka di balancing/*.csv (lalu tools/terapkan_balancing.gd) dan menjalankan ulang alat ini adalah cara
## menyetel balancing tanpa playtest manual (ADR-0003: simulasi berseed + headless).
## Catatan: jangan rujuk class yang memakai autoload saat compile (mis. MissionController);
## runner -s mengompilasi script ini sebelum autoload terdaftar.

const DURASI_SESI := 70.0 * 60.0
const JEDA_PIKIR := 10.0  # detik antara rumor selesai dan rumor berikutnya
const SEEDS := [1, 2, 3, 4, 5, 6, 7, 8]
## Nilai satu poin kredibilitas dalam skor pilihan bot: pemain wajar menghindari rumor yang
## kemungkinan dibongkar (kred -5 - heboh), apalagi saat kredibilitas sudah rendah.
const NILAI_KRED := 0.6
## Pengali nilai rumor tentang tokoh yang masih berdiri (bot mengejar syarat kampanye akhir).
const NILAI_TOKOH := 1.5
const Laporan := preload("res://tools/bot_laporan.gd")

var R: Node
var _mode_final: bool = "final" in OS.get_cmdline_user_args()
var _frame := 0
var _peduli: bool = "peduli" in OS.get_cmdline_user_args()
var _jenuh := {}  # kata_id -> jumlah pemakaian dalam rumor pemain terakhir (Kejenuhan), diisi tiap _kirim


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 2:
		_jalankan_semua()
	return false


func _jalankan_semua() -> void:
	R = get_root()
	for arg in OS.get_cmdline_user_args():
		if arg == "tanpa_jenuh":
			Balance.JENUH_PER_PAKAI = 0.0
		elif arg.begins_with("jenuh_per_pakai="):
			Balance.JENUH_PER_PAKAI = float(arg.get_slice("=", 1))
		elif arg.begins_with("jenuh_min="):
			Balance.JENUH_MIN = float(arg.get_slice("=", 1))
	# Bot memajukan waktu sendiri lewat jalankan_tick. Tanpa ini GameClock._process menambah tick dari
	# waktu nyata di sela await process_frame, sehingga hasil seed yang sama berbeda tiap run.
	a("GameClock").process_mode = Node.PROCESS_MODE_DISABLED
	var ringkas: Array = []
	for s in SEEDS:
		ringkas.append(await _sesi(s))
	Laporan.cetak(ringkas, _mode_final)
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
	var catatan := {"seed": seed, "misi": [], "event": [], "rumor": 0, "dibongkar": 0, "heat_maks": 0.0, "kred_min": 100.0, "beli": 0, "heat_sum": 0.0, "heat_panas": 0.0, "n": 0, "era2": -1.0, "staf": -1.0, "dilema": 0, "era3": -1.0, "kontrak_ok": 0, "kontrak_gagal": 0, "era4": -1.0, "tokoh_jatuh": 0, "final": [], "akhir": [], "jejak": [], "kebal_maks": 0}
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
	var fc: Node = main.get_node("FinalController")
	var f_akhir := func(h):
		catatan["akhir"].append([h, roundi(_t)])
		clock.lanjut(&"ending")  # bot langsung lanjut bermain
	ev.ending_tercapai.connect(f_akhir)
	if _mode_final:
		_siapkan_final(st, db, ev, rumor)
	while _t < (8.0 * 60.0 if _mode_final else DURASI_SESI):
		if _mode_final and not catatan["akhir"].is_empty():
			break
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
		if fc.bisa_mulai() and not clock.sedang_jeda() and st.hasil_akhir != "menang":
			catatan["final"].append([roundi(_t), roundi(fc.persen(1) * 100.0), roundi(fc.persen(3) * 100.0)])
			ev.final_diminta.emit()
		if st.hasil_akhir == "menang":
			break
		if st.punya_upgrade("staf_1") and catatan["staf"] < 0.0:
			catatan["staf"] = _t
		if not rumor.sim.ada_rumor_aktif():
			tunggu += Balance.SIM_TICK
			# Era 4 lebih panas (server, Humas): tiarap lebih awal.
			if st.heat >= (45.0 if st.era >= 4 else 60.0):
				tiarap = true
			elif st.heat < (20.0 if st.era >= 4 else 40.0):
				tiarap = false
			# Saat balapan kampanye akhir pemain tidak tiarap dan berpikir lebih cepat.
			if tunggu >= (3.0 if st.final_berjalan else JEDA_PIKIR) and (not tiarap or st.final_berjalan):
				tunggu = 0.0
				catatan["beli"] += _belanja(st, db)
				if _kirim(st, db, ev):
					catatan["rumor"] += 1
		if int(_t / Balance.SIM_TICK) % 1500 == 0:  # tiap 5 menit: [menit, pengikut, uang, kred, heat]
			catatan["jejak"].append([roundi(_t / 60.0), st.pengikut, st.uang, roundi(st.kredibilitas), roundi(st.heat)])
		if st.final_berjalan:
			catatan["kebal_maks"] = maxi(catatan["kebal_maks"], roundi(fc.persen(3) * 100.0))
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
	ev.ending_tercapai.disconnect(f_akhir)
	ev.misi_berubah.disconnect(f_misi); ev.event_mulai.disconnect(f_event); ev.rumor_selesai.disconnect(f_selesai)
	main.free()
	return catatan

var _t := 0.0


## Mode final: era 4 lengkap, semua kartu, semua tokoh jatuh, kota ±60% percaya dan 10% kebal.
func _siapkan_final(st, db, ev, rumor) -> void:
	st.tambah_pengikut(900)
	st.uang = 100000
	for u in ["kantor", "staf_1", "gedung_media", "menara_server"]:
		st.beli_upgrade(u)
	# Langsung ke daftar milik lalu satu sinyal: beli_kata satu per satu memancarkan kepemilikan_berubah
	# ±150 kali dalam satu frame, meja dibangun ulang tiap kali, dan antrean pesan Godot meluap (crash).
	for id in db.words:
		if db.words[id].get("toko", true) and not st.punya_kata(id):
			st.kartu_dimiliki.append(id)
	for t in db.templates:
		if not st.punya_template(t):
			st.template_dimiliki.append(t)
	ev.kepemilikan_berubah.emit()
	for t in db.tokoh:
		st.tokoh_reputasi[t["id"]] = 0
	ev.tokoh_berubah.emit()
	st.uang = 3000
	st.heat = 30.0
	st.kredibilitas = 60.0
	var sim = rumor.sim  # setelah peta era 4 dibangun ulang
	for i in sim.status.size():
		var r := randf()
		sim.ubah_status(i, 1 if r < 0.6 else (3 if r < 0.7 else 0))


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


## Kartu bernilai tertinggi per slot untuk satu distrik (rakus per slot).
## pakai_tokoh: varian yang mengutamakan kartu tokoh yang masih berdiri.
func _kartu_terbaik_per_slot(st, db, d: Dictionary, paksa_takut: bool, pakai_tokoh: bool) -> Dictionary:
	var hasil := {}
	var nilai := {}
	for id in st.kartu_dimiliki:
		var k: Dictionary = db.get_word(id)
		var v := _nilai_kartu(st, k, d, paksa_takut, pakai_tokoh)
		if not nilai.has(k["slot"]) or v > nilai[k["slot"]]:
			nilai[k["slot"]] = v
			hasil[k["slot"]] = id
	return hasil


## Coba semua template, distrik, dan dua varian kartu (dengan/tanpa tokoh); pilih skor terbaik.
func _kirim(st, db, ev) -> bool:
	var misi: Dictionary = db.missions[st.misi_idx] if st.misi_idx < db.missions.size() else {}
	var paksa_takut: bool = misi.get("syarat", {}).get("tipe", "") == "rumor_emosi_distrik"
	_jenuh = st.kejenuhan_kata() if _peduli else {}
	var terbaik := {}
	var nilai_terbaik := -INF
	var kartu_terbaik := {}  # [distrik, varian] -> {slot: kata_id}; nilai kartu tidak bergantung pada template
	for tid in st.template_dimiliki:
		var tmpl: Dictionary = db.get_template(tid)
		for di in db.districts.size():
			var d: Dictionary = db.districts[di]
			if paksa_takut and d["id"] != "gang_sempit":
				continue
			for pakai_tokoh in [true, false]:
				var kunci := [di, pakai_tokoh]
				if not kartu_terbaik.has(kunci):
					kartu_terbaik[kunci] = _kartu_terbaik_per_slot(st, db, d, paksa_takut, pakai_tokoh)
				var pilih := {}
				for slot in tmpl["slot"]:
					if not kartu_terbaik[kunci].has(slot):
						break
					pilih[slot] = kartu_terbaik[kunci][slot]
				if pilih.size() != tmpl["slot"].size():
					continue
				var n := _nilai_rumor(st, db, tmpl, pilih, di, paksa_takut)
				if n > nilai_terbaik:
					nilai_terbaik = n
					terbaik = {"template_id": tid, "kata_ids": pilih, "distrik_id": d["id"]}
	if terbaik.is_empty():
		return false
	var server_aman: bool = st.heat < 30.0 or st.final_berjalan
	var server: bool = st.saluran_terbuka("server") and st.uang >= 450 and not paksa_takut and server_aman
	var medsos: bool = not server and st.saluran_terbuka("medsos") and st.uang >= 250 and not paksa_takut
	var radio: bool = not medsos and st.saluran_terbuka("radio") and st.uang >= 160 and not paksa_takut
	var koran: bool = not radio and st.saluran_terbuka("koran") and st.uang >= 60 and not paksa_takut
	terbaik["saluran_id"] = "server" if server else "medsos" if medsos else ("radio" if radio else ("koran" if koran else "merpati"))
	if koran or radio:
		terbaik["distrik_id"] = ""
	ev.kirim_diminta.emit(terbaik)
	return true


## Perkiraan nilai satu rumor: jangkauan x dipercaya x tidak dibongkar, dikurangi risiko kredibilitas.
## Rumor tentang tokoh bernilai lebih; Pengacara membongkar pasti kalau dipercaya akhir di bawah ambangnya.
func _nilai_rumor(st, db, tmpl: Dictionary, pilih: Dictionary, di: int, paksa_takut: bool) -> float:
	var kata := {}
	for s in pilih:
		kata[s] = db.get_word(pilih[s])
	var skor := RumorScorer.nilai(tmpl, Kejenuhan.terapkan(kata, _jenuh), db.districts, st.kredibilitas)
	var pb := Konsekuensi.peluang_bongkar(skor["dipercaya_akhir"], st.heat)
	var tokoh := _tokoh_berdiri(st, db, pilih)
	var p: Dictionary = tokoh.get("pertahanan", {})
	if str(p.get("tipe", "")) == "pengacara" and skor["dipercaya_akhir"] < float(p.get("dipercaya_min", 0.0)):
		pb = 1.0
	var n: float = skor["viral_per_distrik"][di] * skor["dipercaya_akhir"] * (1.0 - pb)
	if not tokoh.is_empty():
		n *= NILAI_TOKOH
	n -= pb * (Balance.KRED_TURUN_DIBONGKAR + float(skor["heboh_total"]) * Balance.KRED_TURUN_PER_HEBOH) * NILAI_KRED * (100.0 / maxf(st.kredibilitas, 20.0))
	if skor["dipercaya"] >= Balance.KRED_NAIK_MIN_DIPERCAYA:
		n += Balance.KRED_NAIK * NILAI_KRED
	if paksa_takut and skor["emosi"] != "takut":
		n *= 0.01
	return n


func _tokoh_berdiri(st, db, pilih: Dictionary) -> Dictionary:
	for t in db.tokoh:
		if str(t["kata"]) in pilih.values() and int(st.tokoh_reputasi.get(t["id"], 0)) > 0:
			return t
	return {}


func _nilai_kartu(st, k: Dictionary, d: Dictionary, paksa_takut: bool, pakai_tokoh: bool) -> float:
	var v := float(k["kred"]) * 1.2 + float(k["heboh"]) * Kejenuhan.pengali_kata(k, _jenuh)
	if k["emosi"] == d["emosi_favorit"]:
		v += 2.0
	if paksa_takut and k["emosi"] == "takut":
		v += 10.0
	# Varian tokoh: utamakan tokoh yang masih berdiri (Era 4).
	if k.get("tag", "") == "tokoh":
		var berdiri := int(st.tokoh_reputasi.get(str(k["id"]).trim_prefix("tokoh_"), 0)) > 0
		v += 8.0 if pakai_tokoh and berdiri else -100.0
	return v
