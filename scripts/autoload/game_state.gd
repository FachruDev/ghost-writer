extends Node
## Satu-satunya tempat angka pemain disimpan; scene membaca dari sini.
## Serialisasi untuk SaveSystem ada di StateSerial (ADR-0002).

var uang: int = 0
var pengikut: int = 0
var kredibilitas: float = Balance.KREDIBILITAS_AWAL
var heat: float = 0.0
var era: int = 1
var waktu_main_detik: float = 0.0
var kartu_dimiliki: Array[String] = []
var template_dimiliki: Array[String] = []
## upgrade_id -> level (kantor, staf, ...). Saluran tidak dibeli; terbuka lewat pengikut/era.
var upgrade_dimiliki: Dictionary = {}
## kata_id -> sisa rumor (E07 dokumen bocor). Kartu hilang saat sisa habis.
var kartu_sementara: Dictionary = {}
## saluran_id -> sisa detik dikunci (E09). Tidak disimpan, seperti jeda event (ADR-0003).
var saluran_terkunci: Dictionary = {}
## tokoh_id -> reputasi tersisa (Era 4). 0 = tokoh sudah jatuh.
var tokoh_reputasi: Dictionary = {}
var misi_idx: int = 0
## distrik_id -> {"percaya", "ragu", "kebal"}; diisi saat memuat, dipakai untuk membangkitkan warga.
var distrik_status: Dictionary = {}
var riwayat_rumor: Array = []
var riwayat_event: Array = []
var statistik: Dictionary = {}
## Hasil kampanye akhir terakhir: "" (belum), "menang", atau "kalah". Disimpan.
var hasil_akhir: String = ""
## Kampanye akhir sedang berjalan (FinalController). Tidak disimpan, seperti kontrak (ADR-0003).
var final_berjalan := false


func _ready() -> void:
	mulai_baru()


func _process(delta: float) -> void:
	waktu_main_detik += delta


func mulai_baru() -> void:
	uang = Balance.UANG_AWAL
	pengikut = 0
	kredibilitas = Balance.KREDIBILITAS_AWAL
	heat = 0.0
	era = 1
	waktu_main_detik = 0.0
	kartu_dimiliki.clear()
	template_dimiliki.clear()
	for id in DataDB.words:
		var kata: Dictionary = DataDB.words[id]
		if int(kata.get("harga", 0)) == 0 and kata.get("toko", true) and int(kata.get("era_min", 1)) <= 1:
			kartu_dimiliki.append(id)
	for id in DataDB.templates:
		if int(DataDB.templates[id].get("harga", 0)) == 0:
			template_dimiliki.append(id)
	upgrade_dimiliki = {}
	kartu_sementara = {}
	saluran_terkunci = {}
	tokoh_reputasi = {}
	misi_idx = 0
	distrik_status = {}
	riwayat_rumor = []
	riwayat_event = []
	statistik = StateSerial.statistik_kosong()
	hasil_akhir = ""
	final_berjalan = false
	_umumkan_semua()


func tambah_uang(jumlah: int) -> void:
	uang += jumlah
	if jumlah > 0:
		statistik["total_uang"] = int(statistik.get("total_uang", 0)) + jumlah
	Events.money_changed.emit(uang)


func tambah_pengikut(jumlah: int) -> void:
	if jumlah == 0:
		return
	pengikut = maxi(0, pengikut + jumlah)
	Events.pengikut_berubah.emit(pengikut)


## Sinyal hanya dipancarkan kalau angka bulat yang tampil di HUD berubah (heat turun tiap tick).
func ubah_heat(delta: float) -> void:
	var lama := roundi(heat)
	heat = clampf(heat + delta, 0.0, 100.0)
	if roundi(heat) != lama:
		Events.reputasi_berubah.emit()


func ubah_kredibilitas(delta: float) -> void:
	var lama := roundi(kredibilitas)
	kredibilitas = clampf(kredibilitas + delta, 0.0, 100.0)
	if roundi(kredibilitas) != lama:
		Events.reputasi_berubah.emit()


func saluran_terbuka(id: String) -> bool:
	var s := DataDB.get_upgrade(id)
	return not s.is_empty() and pengikut >= int(s.get("pengikut_min", 0)) and era_terbuka(s) \
		and not saluran_terkunci.has(id)


func kunci_saluran(id: String, detik: float) -> void:
	saluran_terkunci[id] = detik
	Events.kepemilikan_berubah.emit()


## Dipanggil tiap tick oleh EventController.
func kurangi_kunci(dt: float) -> void:
	for id in saluran_terkunci.keys():
		saluran_terkunci[id] -= dt
		if saluran_terkunci[id] <= 0.0:
			saluran_terkunci.erase(id)
			Events.kepemilikan_berubah.emit()


## E07: kartu masuk ke tangan untuk `rumor` kiriman, lalu hilang.
func beri_kartu_sementara(id: String, rumor: int) -> void:
	if not DataDB.words.has(id):
		return
	kartu_sementara[id] = rumor
	if not punya_kata(id):
		kartu_dimiliki.append(id)
	Events.kepemilikan_berubah.emit()


## Kurangi jatah kartu sementara yang dipakai dalam satu rumor.
func pakai_kartu(kata_ids: Dictionary) -> void:
	var berubah := false
	for slot in kata_ids:
		var id := str(kata_ids[slot])
		if kartu_sementara.has(id):
			kartu_sementara[id] -= 1
			if kartu_sementara[id] <= 0:
				kartu_sementara.erase(id)
				kartu_dimiliki.erase(id)
			berubah = true
	if berubah:
		Events.kepemilikan_berubah.emit()


## Konten dan upgrade dengan era_min di atas era sekarang belum tersedia.
func era_terbuka(item: Dictionary) -> bool:
	return era >= int(item.get("era_min", 1))


func punya_upgrade(id: String) -> bool:
	return upgrade_dimiliki.has(id)


## Bisa dibeli sekarang: era dan pengikut cukup, belum dimiliki (uang dicek terpisah).
func upgrade_tersedia(id: String) -> bool:
	var u := DataDB.get_upgrade(id)
	return not u.is_empty() and not punya_upgrade(id) and era_terbuka(u) \
		and pengikut >= int(u.get("pengikut_min", 0)) and str(u.get("jenis", "")) != "saluran"


func beli_upgrade(id: String) -> bool:
	var u := DataDB.get_upgrade(id)
	if not upgrade_tersedia(id) or not _bayar(u):
		return false
	upgrade_dimiliki[id] = 1
	if str(u.get("jenis", "")) == "era":
		era = maxi(era, int(u.get("era", era)))
		Events.era_berubah.emit(era)
	Events.kepemilikan_berubah.emit()
	return true


## Kata hadiah event (mis. calon RT di E04) masuk ke tangan tanpa dibeli.
func beri_kata(id: String) -> void:
	if DataDB.words.has(id) and not punya_kata(id):
		kartu_dimiliki.append(id)
		Events.kepemilikan_berubah.emit()


func punya_kata(id: String) -> bool:
	return id in kartu_dimiliki


func punya_template(id: String) -> bool:
	return id in template_dimiliki


func beli_kata(id: String) -> bool:
	if punya_kata(id) or not _bayar(DataDB.get_word(id)):
		return false
	kartu_dimiliki.append(id)
	statistik["kata_dibeli"] = int(statistik.get("kata_dibeli", 0)) + 1
	Events.kepemilikan_berubah.emit()
	return true


func beli_template(id: String) -> bool:
	if punya_template(id) or not _bayar(DataDB.get_template(id)):
		return false
	template_dimiliki.append(id)
	Events.kepemilikan_berubah.emit()
	return true


## Kata basi: jumlah pemakaian tiap kata_id dalam rumor pemain terakhir (Kejenuhan.hitung).
func kejenuhan_kata() -> Dictionary:
	return Kejenuhan.hitung(riwayat_rumor)


func catat_rumor(entri: Dictionary) -> void:
	riwayat_rumor.append(entri)
	var terbaik: Variant = statistik.get("rumor_terbaik")
	var warga := int(entri.get("warga_percaya", 0))
	if not entri.get("dibongkar", false) and (terbaik == null or warga > int(terbaik.get("warga_percaya", 0))):
		statistik["rumor_terbaik"] = {"template_id": entri.get("template_id", ""),
			"kata_ids": entri.get("kata_ids", {}), "warga_percaya": warga}
	while riwayat_rumor.size() > Balance.BATAS_RIWAYAT:
		riwayat_rumor.pop_front()


func catat_event(event_id: String) -> void:
	riwayat_event.append({"event_id": event_id, "terjadi_pada": Time.get_datetime_string_from_system()})
	while riwayat_event.size() > Balance.BATAS_RIWAYAT:
		riwayat_event.pop_front()


func ke_dict() -> Dictionary:
	return StateSerial.ke_dict(self)


func dari_dict(data: Dictionary) -> void:
	StateSerial.dari_dict(self, data)
	final_berjalan = false
	_umumkan_semua()


func _bayar(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	var harga := int(item.get("harga", 0))
	if uang < harga:
		return false
	tambah_uang(-harga)
	Events.dibeli.emit()
	return true


func _umumkan_semua() -> void:
	Events.kepemilikan_berubah.emit()
	Events.money_changed.emit(uang)
	Events.pengikut_berubah.emit(pengikut)
	Events.reputasi_berubah.emit()
	Events.misi_berubah.emit()
	Events.era_berubah.emit(era)
