extends Button
## Satu kartu kata. Tap -> Events.kartu_dipilih.

const UKURAN := Vector2(158, 150)

var kata_id := ""

var _nama: Label
var _info: Label


func _ready() -> void:
	custom_minimum_size = UKURAN
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var kotak := VBoxContainer.new()
	kotak.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	kotak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kotak)
	_nama = _label(kotak, 20)
	_nama.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info = _label(kotak, 16)
	pressed.connect(func() -> void: Events.kartu_dipilih.emit(kata_id))
	_segarkan()


func atur(id: String) -> void:
	kata_id = id
	if is_node_ready():
		_segarkan()


func _segarkan() -> void:
	var kata := DataDB.get_word(kata_id)
	if kata.is_empty():
		return
	var emosi := str(kata.get("emosi", "netral"))
	_nama.text = Bahasa.teks(kata.get("text", ""))
	_info.text = "%s · %s\n%s" % [
		HeadlineBuilder.nama_slot(str(kata.get("slot", ""))),
		tr("UI_EMO_" + emosi.to_upper()),
		tr("UI_HEBOH_KRED") % [int(kata.get("heboh", 0)), int(kata.get("kred", 0))],
	]
	_atur_gaya(Palet.emosi(emosi))


func _atur_gaya(warna: Color) -> void:
	for nama in ["normal", "hover", "pressed", "focus"]:
		var gaya := StyleBoxFlat.new()
		gaya.bg_color = warna.darkened(0.45 if nama == "normal" else 0.25)
		gaya.border_color = warna
		gaya.set_border_width_all(2)
		gaya.set_corner_radius_all(8)
		add_theme_stylebox_override(nama, gaya)


func _label(induk: Control, ukuran_font: int) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", ukuran_font)
	induk.add_child(l)
	return l
