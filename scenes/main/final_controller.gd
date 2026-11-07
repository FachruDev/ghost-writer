class_name FinalController
extends Node
## Kampanye akhir (0.6.0) dengan E12 "Kota Tak Percaya Lagi" (EVENT.md): balapan setelah ketiga
## tokoh jatuh, dimulai oleh pemain sendiri. Saat mulai, kota diseragamkan: semua warga jadi ragu,
## lalu FINAL_BENIH_KEBAL warga acak langsung kebal. Jadi tiap balapan (termasuk percobaan ulang)
## mulai dari kondisi yang sama, berapa pun pemercaya sebelumnya. Selama balapan peluang percaya
## dikali FINAL_PENGALI_PERCAYA (RumorController), kebal tidak pulih, dan tiap FINAL_TULAR_KEBAL_DETIK
## tiap warga kebal menulari satu tetangga yang belum dengar atau ragu. Pemercaya tidak bisa ditulari.
## Menang: FINAL_TARGET_PERCAYA warga kota percaya sekaligus.
## Kalah: waktu habis atau FINAL_BATAS_KEBAL warga kebal.
## Balapan tidak disimpan (ADR-0003); setelah memuat, kampanye bisa dimulai lagi.

const EVENT_ID := "e_kota_tak_percaya"

var sim: SpreadSim

var _sisa := 0.0
var _hitung_tular := 0.0
var _teks_terakhir := ""


func _ready() -> void:
	GameClock.tick.connect(_on_tick)
	Events.final_diminta.connect(mulai)
	Events.sim_diganti.connect(func(s: SpreadSim) -> void:
		sim = s
		if GameState.final_berjalan:
			sim.kebal_bisa_pulih = false)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void:
		_teks_terakhir = ""
		_umumkan_progres())


## Tombol Kampanye Akhir tampil: semua tokoh jatuh, belum menang, dan balapan belum berjalan.
static func bisa_mulai() -> bool:
	var state := (Engine.get_main_loop() as SceneTree).root.get_node(^"GameState")
	return not state.final_berjalan and state.hasil_akhir != "menang" and TokohController.semua_jatuh()


func mulai() -> void:
	if not bisa_mulai() or sim == null:
		return
	if GameClock.sedang_jeda():  # mis. tawaran kontrak atau dilema sedang tampil
		Events.aksi_gagal.emit()
		return
	GameState.final_berjalan = true
	_sisa = Balance.FINAL_DURASI_DETIK
	_hitung_tular = 0.0
	_teks_terakhir = ""
	sim.kebal_bisa_pulih = false
	_kota_tak_percaya()
	Events.final_berubah.emit()
	var e := _event()
	GameState.catat_event(EVENT_ID)
	Events.event_mulai.emit({"id": EVENT_ID, "jenis": "ancaman", "nama": e.get("nama", ""),
		"teks": _teks_event(e), "durasi": _sisa, "pilihan": []})
	Events.feed_baru.emit({"jenis": "event", "teks": e.get("nama", "")})
	Events.warga_berubah.emit()
	_umumkan_progres()


## Bagian warga kota (0..1) dengan status tertentu.
func persen(s: SpreadSim.Status) -> float:
	if sim == null or sim.status.is_empty():
		return 0.0
	return float(sim.status.count(s)) / sim.status.size()


func _on_tick(dt: float) -> void:
	if not GameState.final_berjalan or sim == null:
		return
	_sisa -= dt
	_hitung_tular += dt
	if _hitung_tular >= Balance.FINAL_TULAR_KEBAL_DETIK:
		_hitung_tular -= Balance.FINAL_TULAR_KEBAL_DETIK
		tularkan_kebal()
	Events.event_sisa.emit(maxf(_sisa, 0.0))
	if persen(SpreadSim.Status.PERCAYA) >= Balance.FINAL_TARGET_PERCAYA:
		_akhiri("menang")
	elif persen(SpreadSim.Status.KEBAL) >= Balance.FINAL_BATAS_KEBAL or _sisa <= 0.0:
		_akhiri("kalah")
	else:
		_umumkan_progres()


## Satu putaran E12: tiap warga kebal mencoba menulari satu tetangga acak. Mengembalikan jumlahnya.
func tularkan_kebal() -> int:
	var rng := GameClock.rng
	var kebal := PackedInt32Array()
	for i in sim.status.size():
		if sim.status[i] == SpreadSim.Status.KEBAL:
			kebal.append(i)
	var n := 0
	for i in kebal:
		var t := sim.tetangga(i)
		if t.is_empty() or rng.randf() >= Balance.FINAL_PELUANG_TULAR_KEBAL:
			continue
		var j := t[rng.randi_range(0, t.size() - 1)]
		if sim.status[j] == SpreadSim.Status.BELUM or sim.status[j] == SpreadSim.Status.RAGU:
			sim.ubah_status(j, SpreadSim.Status.KEBAL)
			n += 1
	if n > 0:
		Events.warga_berubah.emit()
	return n


## Awal E12: semua warga jadi ragu ("kota tak percaya lagi"), lalu benih kebal ditanam.
func _kota_tak_percaya() -> void:
	var rng := GameClock.rng
	var calon: Array[int] = []
	for i in sim.status.size():
		sim.ubah_status(i, SpreadSim.Status.RAGU)
		calon.append(i)
	for k in mini(roundi(sim.status.size() * Balance.FINAL_BENIH_KEBAL), calon.size()):
		sim.ubah_status(calon.pop_at(rng.randi_range(0, calon.size() - 1)), SpreadSim.Status.KEBAL)


func _akhiri(hasil: String) -> void:
	GameState.final_berjalan = false
	if GameState.hasil_akhir != "menang":
		GameState.hasil_akhir = hasil
	sim.kebal_bisa_pulih = true
	_teks_terakhir = ""
	Events.event_selesai.emit(EVENT_ID)
	Events.final_progres.emit("")
	Events.final_data.emit({})
	Events.final_berubah.emit()
	Events.ending_tercapai.emit(hasil)
	SaveSystem.simpan()


## HUD hanya diperbarui kalau angka yang tampil berubah.
func _umumkan_progres() -> void:
	if not GameState.final_berjalan:
		return
	var sisa := maxi(0, ceili(_sisa))
	Events.final_data.emit({"percaya": persen(SpreadSim.Status.PERCAYA), "kebal": persen(SpreadSim.Status.KEBAL),
		"sisa": sisa})
	var teks := tr("UI_FINAL_JALAN") % [roundi(persen(SpreadSim.Status.PERCAYA) * 100.0),
		roundi(Balance.FINAL_TARGET_PERCAYA * 100.0), roundi(persen(SpreadSim.Status.KEBAL) * 100.0),
		roundi(Balance.FINAL_BATAS_KEBAL * 100.0), "%d:%02d" % [sisa / 60, sisa % 60]]
	if teks != _teks_terakhir:
		_teks_terakhir = teks
		Events.final_progres.emit(teks)


func _event() -> Dictionary:
	for e in DataDB.events:
		if str(e["id"]) == EVENT_ID:
			return e
	return {}


## Angka di teks E12 diambil dari balancing, untuk kedua bahasa (ADR-0004).
func _teks_event(e: Dictionary) -> Dictionary:
	var hasil := {}
	var teks: Dictionary = e.get("teks", {})
	for kode in teks:
		hasil[kode] = str(teks[kode]) % [roundi(Balance.FINAL_TULAR_KEBAL_DETIK),
			roundi(Balance.FINAL_TARGET_PERCAYA * 100.0), roundi(Balance.FINAL_BATAS_KEBAL * 100.0)]
	return hasil
