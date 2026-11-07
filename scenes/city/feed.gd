extends VBoxContainer
## Feed kabar di bawah peta: satu baris terbaru; ketuk untuk membuka 5 kabar terakhir.
## Entri menyimpan ID, teks disusun saat ditampilkan supaya ikut berganti bahasa (ADR-0004).

const BARIS_TERBUKA := 5

var _entri: Array[Dictionary] = []
var _terbuka := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 6)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	Events.feed_baru.connect(_on_feed_baru)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _gambar())


func _on_feed_baru(entri: Dictionary) -> void:
	if _teks(entri).is_empty():
		return
	_entri.push_front(entri)
	while _entri.size() > Balance.BATAS_FEED:
		_entri.pop_back()
	_gambar()
	var baru := get_child(get_child_count() - 1) as Control if get_child_count() > 0 else null
	if baru:
		baru.modulate.a = 0.0
		create_tween().tween_property(baru, "modulate:a", 1.0, 0.3)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_terbuka = not _terbuka
		_gambar()
		accept_event()


func _gambar() -> void:
	for anak in get_children():
		remove_child(anak)
		anak.queue_free()
	var jumlah := mini(_entri.size(), BARIS_TERBUKA if _terbuka else 1)
	# Kabar terbaru di paling bawah, dekat jempol.
	for k in range(jumlah - 1, -1, -1):
		_baris(_entri[k], k == 0)
	size = Vector2(size.x, 0.0)
	if get_parent() is Control:
		position.y = (get_parent() as Control).size.y - size.y - 56.0


func _baris(e: Dictionary, terbaru: bool) -> void:
	var pil := PanelContainer.new()
	pil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gaya := Palet.kotak(Color(Palet.MALAM, 0.9), Color.TRANSPARENT, 24)
	gaya.content_margin_top = 8
	gaya.content_margin_bottom = 8
	gaya.content_margin_left = 14
	gaya.content_margin_right = 16
	pil.add_theme_stylebox_override("panel", gaya)
	add_child(pil)
	var isi := UiKit.baris(pil, 10)
	var titik := Panel.new()
	titik.custom_minimum_size = Vector2(14, 14)
	titik.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titik.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titik.add_theme_stylebox_override("panel", Palet.kotak(_warna(e), Color.TRANSPARENT, 999))
	isi.add_child(titik)
	var l := UiKit.label(isi, 22, Palet.TEKS if terbaru else Palet.TEKS_LEMBUT, Tema.font_ui(500), _teks(e))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _terbuka:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if terbaru and not _terbuka and _entri.size() > 1:
		UiKit.label(isi, 20, Palet.TEKS_REDUP, Tema.font_ui(600), tr("UI_FEED") + " ›")


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
		"staf":
			if e.get("dibongkar", false):
				return tr("UI_STAF_HOAKS") % roundi(float(e.get("kredibilitas", 0)))
			return tr("UI_STAF") % HeadlineBuilder.susun(e["template_id"], e["kata_ids"])
		"dilema":
			return tr("UI_DILEMA_DIPILIH") % Bahasa.teks(e.get("teks", ""))
		"pengacara":
			return tr("UI_PENGACARA") % Bahasa.teks(e.get("nama", ""))
		"tokoh":
			return tr("UI_TOKOH_SERANG") % [Bahasa.teks(e.get("nama", "")), int(e.get("kurang", 0)), int(e.get("sisa", 0))]
		"tokoh_jatuh":
			return tr("UI_TOKOH_JATUH") % [Bahasa.teks(e.get("nama", "")), Bahasa.angka(int(e.get("uang", 0))), int(e.get("pengikut", 0))]
		"kontrak":
			if e.get("berhasil", false):
				return tr("UI_KONTRAK_BERHASIL") % [Bahasa.angka(Balance.KONTRAK_UANG), Balance.KONTRAK_PENGIKUT]
			return tr("UI_KONTRAK_GAGAL") % roundi(Balance.KONTRAK_KRED_GAGAL)
		"era":
			return tr("UI_ERA_NAIK") % int(e.get("era", 2))
		"offline":
			var menit := roundi(float(e.get("detik", 0)) / 60.0)
			return tr("UI_OFFLINE") % [Bahasa.angka(int(e.get("uang", 0))), "%d:%02d" % [menit / 60, menit % 60]]
		"event":
			var info := str(e.get("info", ""))
			return Bahasa.teks(e.get("teks", "")) + ("" if info.is_empty() else " · " + info)
	return ""


func _warna(e: Dictionary) -> Color:
	match str(e.get("jenis", "")):
		"mutasi", "hoaks", "pengacara":
			return Palet.PINK
		"misi", "era", "offline":
			return Palet.KUNING
		"kontrak":
			return Palet.CYAN if e.get("berhasil", false) else Palet.PINK
		"tokoh", "tokoh_jatuh", "dilema":
			return Palet.KUNING
		"staf":
			return Palet.PINK if e.get("dibongkar", false) else Palet.HIJAU
		"event":
			return Palet.ABU_KEBAL
	return Palet.TEKS_REDUP
