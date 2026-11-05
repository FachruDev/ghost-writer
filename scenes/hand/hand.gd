extends PanelContainer
## Tangan kartu kata milik pemain, di zona jempol bawah.

const WORD_CARD := preload("res://scenes/card/word_card.tscn")

var _alir: HFlowContainer


func _ready() -> void:
	var gulir := ScrollContainer.new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(gulir)
	_alir = HFlowContainer.new()
	_alir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_alir.add_theme_constant_override("h_separation", 8)
	_alir.add_theme_constant_override("v_separation", 8)
	gulir.add_child(_alir)
	Events.kepemilikan_berubah.connect(_isi_ulang)
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void: _isi_ulang())
	_isi_ulang()


func _isi_ulang() -> void:
	for anak in _alir.get_children():
		anak.queue_free()
	for id in _urutkan(GameState.kartu_dimiliki):
		var kartu := WORD_CARD.instantiate()
		kartu.atur(id)
		_alir.add_child(kartu)


func _urutkan(ids: Array[String]) -> Array[String]:
	var hasil := ids.duplicate()
	hasil.sort_custom(func(a: String, b: String) -> bool:
		var sa := RumorScorer.URUTAN_SLOT.find(str(DataDB.get_word(a).get("slot", "")))
		var sb := RumorScorer.URUTAN_SLOT.find(str(DataDB.get_word(b).get("slot", "")))
		return sa < sb if sa != sb else a < b)
	return hasil
