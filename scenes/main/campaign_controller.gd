class_name CampaignController
extends Node
## Kontrak kampanye (Era 3): tawaran klien fiktif untuk meyakinkan sebagian warga di 2 distrik
## dalam batas waktu. Tawaran menjeda waktu sampai pemain menerima atau menolak.
## Kontrak tidak disimpan; setelah memuat, tawaran baru muncul lagi (ADR-0003).

const ID := "kontrak"

var sim: SpreadSim

var _hitung := 0.0
var _tawaran: Dictionary = {}  # {"distrik": [i, j]} saat tawaran tampil
var _kontrak: Dictionary = {}  # {"distrik": [i, j], "sisa": detik} saat berjalan


func _ready() -> void:
	GameClock.tick.connect(_on_tick)
	Events.dilema_dipilih.connect(_on_pilih)
	Events.sim_diganti.connect(func(s: SpreadSim) -> void: sim = s)
	Events.final_berubah.connect(func() -> void:
		# Kontrak batal saat kampanye akhir dimulai; tawaran berikutnya setelah jeda penuh.
		_kontrak = {}
		_hitung = 0.0
		_umumkan_progres())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _umumkan_progres())


func ada_kontrak() -> bool:
	return not _kontrak.is_empty()


## Persentase warga percaya di satu distrik (0..1).
func progres(distrik: int) -> float:
	var total := sim.warga_per_distrik[distrik].size()
	return 0.0 if total == 0 else float(sim.jumlah_status(distrik, SpreadSim.Status.PERCAYA)) / total


func _on_tick(dt: float) -> void:
	if GameState.era < 3 or sim == null or GameState.final_berjalan:
		return
	if not _kontrak.is_empty():
		_kontrak["sisa"] -= dt
		var target: Array = _kontrak["distrik"]
		if progres(target[0]) >= Balance.KONTRAK_PERSEN and progres(target[1]) >= Balance.KONTRAK_PERSEN:
			_berhasil()
		elif _kontrak["sisa"] <= 0.0:
			_gagal()
		else:
			_umumkan_progres()
		return
	_hitung += dt
	if _hitung >= Balance.KONTRAK_JEDA_DETIK and _tawaran.is_empty() and not GameClock.sedang_jeda():
		_tawarkan()


## Tampilkan tawaran sebagai banner dengan dua pilihan; waktu dijeda.
func _tawarkan() -> void:
	_hitung = 0.0
	var acak := range(DataDB.districts.size())
	acak.shuffle()
	_tawaran = {"distrik": [acak[0], acak[1]]}
	GameClock.jeda(&"kontrak")
	Events.event_mulai.emit({
		"id": ID, "jenis": "peluang", "durasi": 0.0,
		"nama": tr("UI_KONTRAK_NAMA"),
		"teks": tr("UI_KONTRAK_TEKS") % [Bahasa.angka(Balance.KONTRAK_UANG), roundi(Balance.KONTRAK_PERSEN * 100.0),
			_nama(acak[0]), _nama(acak[1]), roundi(Balance.KONTRAK_DURASI_DETIK / 60.0)],
		"pilihan": [tr("UI_TERIMA"), tr("UI_TOLAK")],
	})


func _on_pilih(indeks: int) -> void:
	if _tawaran.is_empty():
		return
	if indeks == 0:
		_kontrak = {"distrik": _tawaran["distrik"], "sisa": Balance.KONTRAK_DURASI_DETIK}
	_tawaran = {}
	GameClock.lanjut(&"kontrak")
	Events.event_selesai.emit(ID)
	_umumkan_progres()


func _berhasil() -> void:
	_kontrak = {}
	GameState.tambah_uang(Balance.KONTRAK_UANG)
	GameState.tambah_pengikut(Balance.KONTRAK_PENGIKUT)
	Events.feed_baru.emit({"jenis": "kontrak", "berhasil": true})
	_umumkan_progres()


func _gagal() -> void:
	_kontrak = {}
	GameState.ubah_kredibilitas(-Balance.KONTRAK_KRED_GAGAL)
	Events.feed_baru.emit({"jenis": "kontrak", "berhasil": false})
	_umumkan_progres()


func _umumkan_progres() -> void:
	if _kontrak.is_empty():
		Events.kontrak_berubah.emit("")
		return
	var t: Array = _kontrak["distrik"]
	var sisa := maxi(0, ceili(float(_kontrak["sisa"])))
	Events.kontrak_berubah.emit(tr("UI_KONTRAK_JALAN") % [_nama(t[0]), roundi(progres(t[0]) * 100.0),
		_nama(t[1]), roundi(progres(t[1]) * 100.0), "%d:%02d" % [sisa / 60, sisa % 60]])


func _nama(distrik: int) -> String:
	return Bahasa.teks(DataDB.districts[distrik].get("nama", ""))
