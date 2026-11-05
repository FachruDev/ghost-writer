extends PanelContainer
## HUD tipis: uang, status rumor, tombol bahasa dan toko.

var _label_uang: Label
var _label_status: Label
var _status_kunci := ""
var _status_args: Array = []


func _ready() -> void:
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 12)
	add_child(baris)
	_label_uang = _label(baris)
	_label_status = _label(baris)
	_label_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_status.add_theme_color_override("font_color", Palet.TEKS_REDUP)
	var tombol_bahasa := _tombol("UI_BAHASA", baris)
	tombol_bahasa.pressed.connect(func() -> void: Bahasa.atur("en" if Bahasa.kode() == "id" else "id"))
	var tombol_toko := _tombol("UI_TOKO", baris)
	tombol_toko.pressed.connect(func() -> void: Events.toko_diminta.emit(true))
	Events.money_changed.connect(func(_uang: int) -> void: _segarkan())
	Events.rumor_published.connect(func(_info: Dictionary) -> void: _atur_status("UI_MENYEBAR", []))
	Events.rumor_selesai.connect(_on_rumor_selesai)
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void: _segarkan())
	_segarkan()


func _on_rumor_selesai(hasil: Dictionary) -> void:
	_atur_status("UI_HASIL", [int(hasil.get("uang", 0)), int(hasil.get("warga_percaya", 0))])


func _atur_status(kunci: String, args: Array) -> void:
	_status_kunci = kunci
	_status_args = args
	_segarkan()


func _segarkan() -> void:
	_label_uang.text = tr("UI_UANG") % Bahasa.angka(GameState.uang)
	if _status_kunci == "UI_HASIL":
		_label_status.text = tr(_status_kunci) % [Bahasa.angka(_status_args[0]), _status_args[1]]
	elif not _status_kunci.is_empty():
		_label_status.text = tr(_status_kunci)


func _label(induk: Control) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	induk.add_child(l)
	return l


func _tombol(kunci: String, induk: Control) -> Button:
	var b := Button.new()
	b.text = kunci
	b.custom_minimum_size = Vector2(72, 48)
	induk.add_child(b)
	return b
