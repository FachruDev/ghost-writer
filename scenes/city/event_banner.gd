extends PanelContainer
## Banner event di atas peta: ikon jenis, nama, teks, sisa durasi. Masuk/keluar dengan tween.

const IKON := {"modifier": "☀", "ancaman": "⚠", "dilema": "?", "peluang": "★"}

var _judul: Label
var _teks: Label
var _baris_pilihan: HBoxContainer
var _info: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", Palet.kotak(Color(Palet.PANEL, 0.92), Palet.AKSEN, 10))
	var kotak := VBoxContainer.new()
	add_child(kotak)
	_judul = _label(kotak, 22)
	_teks = _label(kotak, 17)
	_baris_pilihan = HBoxContainer.new()
	_baris_pilihan.add_theme_constant_override("separation", 10)
	kotak.add_child(_baris_pilihan)
	visible = false
	Events.event_mulai.connect(_on_mulai)
	Events.event_tampil.connect(_on_mulai)
	Events.event_sisa.connect(_on_sisa)
	Events.event_selesai.connect(func(_id: String) -> void: _tutup())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _on_sisa(float(_info.get("sisa", 0.0))))


func _on_mulai(info: Dictionary) -> void:
	_info = info.duplicate()
	_info["sisa"] = float(info.get("durasi", 0.0))
	_on_sisa(_info["sisa"])
	_buat_pilihan(info.get("pilihan", []))
	visible = true
	modulate.a = 0.0
	scale = Vector2(1.0, 0.6)
	pivot_offset = Vector2(size.x / 2.0, 0.0)
	var t := create_tween().set_parallel()
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	t.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_sisa(sisa: float) -> void:
	if _info.is_empty():
		return
	_info["sisa"] = sisa
	var ikon: String = IKON.get(str(_info.get("jenis", "")), "•")
	var nama := Bahasa.teks(_info.get("nama", ""))
	if _info.get("pilihan", []).is_empty():
		_judul.text = "%s %s · %s" % [ikon, nama, tr("UI_SISA_DETIK") % ceili(sisa)]
	else:
		_judul.text = "%s %s" % [ikon, nama]
	_teks.text = Bahasa.teks(_info.get("teks", ""))


## Dilema: satu tombol per pilihan; waktu permainan dijeda sampai pemain memilih.
func _buat_pilihan(label: Array) -> void:
	for anak in _baris_pilihan.get_children():
		anak.queue_free()
	_baris_pilihan.visible = not label.is_empty()
	for i in label.size():
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = Bahasa.teks(label[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 52)
		Palet.gaya_tombol(b, Palet.AKSEN if i == 0 else Palet.TEKS_REDUP)
		b.pressed.connect(func() -> void: Events.dilema_dipilih.emit(i))
		_baris_pilihan.add_child(b)


func _tutup() -> void:
	_info = {}
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: visible = false)


func _label(induk: Control, ukuran: int) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", ukuran)
	induk.add_child(l)
	return l
