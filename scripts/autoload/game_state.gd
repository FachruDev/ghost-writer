extends Node
## Satu-satunya tempat angka pemain disimpan; scene membaca dari sini.

var uang: int = 0
var kredibilitas: float = Balance.KREDIBILITAS_AWAL
var heat: float = 0.0
var kartu_dimiliki: Array[String] = []
var template_dimiliki: Array[String] = []


func _ready() -> void:
	mulai_baru()


func mulai_baru() -> void:
	uang = Balance.UANG_AWAL
	kredibilitas = Balance.KREDIBILITAS_AWAL
	heat = 0.0
	kartu_dimiliki.clear()
	template_dimiliki.clear()
	for id in DataDB.words:
		if int(DataDB.words[id].get("harga", 0)) == 0:
			kartu_dimiliki.append(id)
	for id in DataDB.templates:
		if int(DataDB.templates[id].get("harga", 0)) == 0:
			template_dimiliki.append(id)
	Events.kepemilikan_berubah.emit()
	Events.money_changed.emit(uang)


func tambah_uang(jumlah: int) -> void:
	uang += jumlah
	Events.money_changed.emit(uang)


func punya_kata(id: String) -> bool:
	return id in kartu_dimiliki


func punya_template(id: String) -> bool:
	return id in template_dimiliki


func beli_kata(id: String) -> bool:
	if punya_kata(id) or not _bayar(DataDB.get_word(id)):
		return false
	kartu_dimiliki.append(id)
	Events.kepemilikan_berubah.emit()
	return true


func beli_template(id: String) -> bool:
	if punya_template(id) or not _bayar(DataDB.get_template(id)):
		return false
	template_dimiliki.append(id)
	Events.kepemilikan_berubah.emit()
	return true


func _bayar(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	var harga := int(item.get("harga", 0))
	if uang < harga:
		return false
	tambah_uang(-harga)
	return true
