extends VBoxContainer
## Feed headline yang beredar: rumor baru, mutasi, HOAKS, misi, event.
## Entri menyimpan ID, teks disusun saat ditampilkan supaya ikut berganti bahasa (ADR-0004).

var _entri: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 2)
	Events.feed_baru.connect(_on_feed_baru)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _gambar())


func _on_feed_baru(entri: Dictionary) -> void:
	_entri.push_front(entri)
	while _entri.size() > Balance.BATAS_FEED:
		_entri.pop_back()
	_gambar()
	var baris_baru := get_child(0) as Control if get_child_count() > 0 else null
	if baris_baru:
		baris_baru.modulate.a = 0.0
		create_tween().tween_property(baris_baru, "modulate:a", 1.0, 0.35)


func _gambar() -> void:
	for anak in get_children():
		remove_child(anak)
		anak.queue_free()
	for i in _entri.size():
		var l := Label.new()
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", _warna(_entri[i]))
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 1)
		l.modulate.a = 1.0 - i * 0.22
		l.text = _teks(_entri[i])
		add_child(l)
	queue_redraw.call_deferred()


## Latar gelap di belakang teks feed supaya terbaca di atas titik warga.
func _draw() -> void:
	if get_child_count() == 0:
		return
	var tinggi := 0.0
	for anak in get_children():
		tinggi += (anak as Control).size.y + 2.0
	draw_rect(Rect2(Vector2(-4, -2), Vector2(size.x + 8, tinggi + 4)), Color(0, 0, 0, 0.55))


func _teks(e: Dictionary) -> String:
	match str(e.get("jenis", "")):
		"rumor":
			return "» " + HeadlineBuilder.susun(e["template_id"], e["kata_ids"])
		"mutasi":
			return tr("UI_MUTASI") % HeadlineBuilder.susun(e["template_id"], e["kata_ids"])
		"hoaks":
			return tr("UI_HOAKS") % (tr("UI_DIBONGKAR") % roundi(float(e.get("kredibilitas", 0))))
		"misi":
			return tr("UI_MISI_SELESAI") % Bahasa.teks(e.get("teks", ""))
		"event":
			var info := str(e.get("info", ""))
			return "⚑ " + Bahasa.teks(e.get("teks", "")) + ("" if info.is_empty() else " · " + info)
	return ""


func _warna(e: Dictionary) -> Color:
	match str(e.get("jenis", "")):
		"mutasi":
			return Palet.emosi("lucu")
		"hoaks":
			return Palet.emosi("marah")
		"misi":
			return Palet.emosi("iri")
		"event":
			return Palet.STATUS[SpreadSim.Status.KEBAL]
	return Color.WHITE
