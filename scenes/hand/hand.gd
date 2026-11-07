extends PanelContainer
## Tangan kartu (papan 02): satu baris kartu milik pemain untuk slot yang sedang diisi,
## bisa digeser ke samping. Meja yang memberi tahu slot aktif dan kartu yang sedang terpasang.

const WORD_CARD := preload("res://scenes/card/word_card.tscn")
const TINGGI_KARTU := 188

var _gulir: ScrollContainer
var _deret: HBoxContainer
var _slot := ""
var _terpasang := ""


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	custom_minimum_size = Vector2(0, TINGGI_KARTU + 36)
	_gulir = ScrollContainer.new()
	_gulir.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_gulir)
	var tepi := UiKit.margin(_gulir, 24, 18, 24, 12)
	_deret = UiKit.baris(tepi, 20)
	Events.kepemilikan_berubah.connect(_isi_ulang)
	Events.tokoh_berubah.connect(_isi_ulang)
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void: _isi_ulang())


## Dipanggil meja: tampilkan kartu untuk `slot`; `terpasang` = kata_id yang sedang di slot itu.
func tampilkan(slot: String, terpasang: String) -> void:
	var ganti := slot != _slot
	_slot = slot
	_terpasang = terpasang
	_isi_ulang()
	if ganti:
		_gulir.scroll_horizontal = 0


func _isi_ulang() -> void:
	for anak in _deret.get_children():
		_deret.remove_child(anak)
		anak.queue_free()
	for id in _urutkan(_kartu_slot()):
		var kartu := WORD_CARD.instantiate()
		kartu.atur(id, id == _terpasang)
		_deret.add_child(kartu)


func _kartu_slot() -> Array[String]:
	var hasil: Array[String] = []
	for id in GameState.kartu_dimiliki:
		if _slot.is_empty() or str(DataDB.get_word(id).get("slot", "")) == _slot:
			hasil.append(id)
	return hasil


## Tokoh dulu, lalu kartu khusus (calon, sementara), lalu sisanya.
func _urutkan(ids: Array[String]) -> Array[String]:
	var hasil := ids.duplicate()
	hasil.sort_custom(func(a: String, b: String) -> bool:
		var pa := _prioritas(a)
		var pb := _prioritas(b)
		return pa < pb if pa != pb else a < b)
	return hasil


func _prioritas(id: String) -> int:
	match str(DataDB.get_word(id).get("tag", "")):
		"tokoh":
			return 0
		"kandidat", "sementara":
			return 1
	return 2

