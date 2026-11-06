extends PanelContainer
## HUD: uang, pengikut, kredibilitas & heat, misi aktif, tombol bahasa dan toko.

var _label_uang: Label
var _label_pengikut: Label
var _label_reputasi: Label
var _label_misi: Label
var _teks_kontrak := ""


func _ready() -> void:
	var kotak := VBoxContainer.new()
	add_child(kotak)
	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 14)
	kotak.add_child(baris)
	_label_uang = _label(baris)
	_label_pengikut = _label(baris)
	_label_reputasi = _label(baris)
	_label_reputasi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_reputasi.add_theme_color_override("font_color", Palet.TEKS_REDUP)
	var tombol_bahasa := _tombol("UI_BAHASA", baris)
	tombol_bahasa.pressed.connect(func() -> void: Bahasa.atur("en" if Bahasa.kode() == "id" else "id"))
	var tombol_toko := _tombol("UI_TOKO", baris)
	tombol_toko.pressed.connect(func() -> void: Events.toko_diminta.emit(true))
	_label_misi = _label(kotak)
	_label_misi.add_theme_font_size_override("font_size", 20)
	_label_misi.add_theme_color_override("font_color", Palet.emosi("lucu"))
	Events.money_changed.connect(func(_u: int) -> void: _segarkan())
	Events.pengikut_berubah.connect(func(_p: int) -> void: _segarkan())
	Events.reputasi_berubah.connect(_segarkan)
	Events.misi_berubah.connect(_segarkan)
	Events.tokoh_berubah.connect(_segarkan)
	Events.kontrak_berubah.connect(func(teks: String) -> void:
		_teks_kontrak = teks
		_segarkan())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _segarkan())
	_segarkan()


func _segarkan() -> void:
	_label_uang.text = tr("UI_UANG") % Bahasa.angka(GameState.uang)
	_label_pengikut.text = tr("UI_PENGIKUT") % Bahasa.angka(GameState.pengikut)
	_label_reputasi.text = tr("UI_KRED_HEAT") % [roundi(GameState.kredibilitas), roundi(GameState.heat)]
	_label_reputasi.add_theme_color_override("font_color", Palet.emosi("marah") if GameState.heat >= 70.0 else Palet.TEKS_REDUP)
	if not _teks_kontrak.is_empty():
		_label_misi.text = _teks_kontrak
		return
	if not GameState.tokoh_reputasi.is_empty() and not TokohController.semua_jatuh():
		_label_misi.text = tr("UI_TOKOH") % TokohController.teks_progres()
		return
	var misi := MissionController.misi_aktif()
	_label_misi.text = tr("UI_MISI_HABIS") if misi.is_empty() else tr("UI_MISI") % Bahasa.teks(misi.get("teks", ""))


func _label(induk: Control) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	induk.add_child(l)
	return l


func _tombol(kunci: String, induk: Control) -> Button:
	var b := Button.new()
	b.text = kunci
	b.custom_minimum_size = Vector2(72, 48)
	Palet.gaya_tombol(b, Palet.TEKS_REDUP)
	induk.add_child(b)
	return b
