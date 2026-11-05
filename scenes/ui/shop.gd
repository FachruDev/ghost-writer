extends Control
## Toko sederhana: beli kata dan template baru. Lapisan di atas layar utama.

var _daftar: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var redup := ColorRect.new()
	redup.color = Color(0, 0, 0, 0.6)
	redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(redup)
	var tepi := MarginContainer.new()
	tepi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for sisi in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		tepi.add_theme_constant_override(sisi, 32)
	add_child(tepi)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Palet.kotak(Palet.PANEL, Palet.TEKS_REDUP, 12))
	tepi.add_child(panel)
	var kotak := VBoxContainer.new()
	kotak.add_theme_constant_override("separation", 10)
	panel.add_child(kotak)
	var judul := Label.new()
	judul.text = "UI_TOKO"
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	judul.add_theme_font_size_override("font_size", 32)
	kotak.add_child(judul)
	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kotak.add_child(gulir)
	_daftar = VBoxContainer.new()
	_daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar.add_theme_constant_override("separation", 8)
	gulir.add_child(_daftar)
	var tutup := Button.new()
	tutup.text = "UI_TUTUP"
	tutup.custom_minimum_size = Vector2(0, 56)
	tutup.pressed.connect(func() -> void: visible = false)
	kotak.add_child(tutup)
	Events.toko_diminta.connect(_on_toko_diminta)
	Events.money_changed.connect(func(_uang: int) -> void: _isi_ulang_jika_terlihat())
	Events.kepemilikan_berubah.connect(_isi_ulang_jika_terlihat)
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void: _isi_ulang_jika_terlihat())


func _on_toko_diminta(buka: bool) -> void:
	visible = buka
	_isi_ulang_jika_terlihat()


func _isi_ulang_jika_terlihat() -> void:
	if visible:
		_isi_ulang()


func _isi_ulang() -> void:
	for anak in _daftar.get_children():
		anak.queue_free()
	var kata := _belum_dimiliki(DataDB.words, GameState.kartu_dimiliki)
	var template := _belum_dimiliki(DataDB.templates, GameState.template_dimiliki)
	_judul_bagian("UI_TOKO_KATA")
	for id in kata:
		var data := DataDB.get_word(id)
		var info := "%s · %s · %s" % [
			HeadlineBuilder.nama_slot(str(data.get("slot", ""))),
			tr("UI_EMO_" + str(data.get("emosi", "netral")).to_upper()),
			tr("UI_HEBOH_KRED") % [int(data.get("heboh", 0)), int(data.get("kred", 0))],
		]
		_baris(Bahasa.teks(data.get("text", "")), info, int(data.get("harga", 0)), GameState.beli_kata.bind(id))
	_judul_bagian("UI_TOKO_TEMPLATE")
	for id in template:
		var data := DataDB.get_template(id)
		_baris(HeadlineBuilder.susun(id, {}), "×%.1f" % float(data.get("pengali_heboh", 1.0)),
			int(data.get("harga", 0)), GameState.beli_template.bind(id))
	if kata.is_empty() and template.is_empty():
		_judul_bagian("UI_TOKO_KOSONG")


func _belum_dimiliki(sumber: Dictionary, dimiliki: Array[String]) -> Array[String]:
	var hasil: Array[String] = []
	for id in sumber:
		if not (id in dimiliki):
			hasil.append(id)
	hasil.sort_custom(func(a: String, b: String) -> bool:
		return int(sumber[a].get("harga", 0)) < int(sumber[b].get("harga", 0)))
	return hasil


func _judul_bagian(kunci: String) -> void:
	var l := Label.new()
	l.text = kunci
	l.add_theme_color_override("font_color", Palet.TEKS_REDUP)
	_daftar.add_child(l)


func _baris(nama: String, info: String, harga: int, beli: Callable) -> void:
	var baris := HBoxContainer.new()
	_daftar.add_child(baris)
	var teks := Label.new()
	teks.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.text = "%s\n%s" % [nama, info]
	baris.add_child(teks)
	var tombol := Button.new()
	tombol.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	tombol.text = "%s %s" % [tr("UI_BELI"), Bahasa.angka(harga)]
	tombol.custom_minimum_size = Vector2(150, 56)
	tombol.disabled = GameState.uang < harga
	Palet.gaya_tombol(tombol, Palet.AKSEN)
	tombol.pressed.connect(func() -> void: beli.call())
	baris.add_child(tombol)
