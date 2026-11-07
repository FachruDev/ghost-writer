extends Button
## Satu kartu kata (papan 02/09): pita emosi + ikon, teks kata, titik heboh & kred.
## Varian: tokoh (pita gelap, bingkai emas, bar reputasi), calon RT, kartu sementara (sisa N).
## Tap -> Events.kartu_dipilih.

const UKURAN := Vector2(196, 188)

var kata_id := ""
var terpilih := false:
	set(v):
		terpilih = v
		if is_node_ready():
			_atur_gaya()

var _pita: PanelContainer
var _ikon: TextureRect
var _emosi: Label
var _lencana: PanelContainer
var _nama: Label
var _bawah: HBoxContainer


func _ready() -> void:
	custom_minimum_size = UKURAN
	add_to_group(&"tanpa_klik")
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	clip_contents = true
	offset_transform_enabled = true
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 0)
	kolom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kolom)
	_pita = PanelContainer.new()
	_pita.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pita.custom_minimum_size = Vector2(0, 52)
	kolom.add_child(_pita)
	var isi_pita := UiKit.baris(_pita, 8)
	_ikon = UiKit.ikon(isi_pita, "lucu", 28)
	_emosi = UiKit.label(isi_pita, 22, Palet.TINTA, Tema.font_ui(700))
	_emosi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_emosi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lencana = UiKit.pil(isi_pita, "", Palet.MALAM, Palet.TEKS, 16)
	_lencana.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tengah := UiKit.margin(kolom, 16, 10, 16, 0)
	tengah.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tengah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nama = UiKit.label(tengah, 26, Palet.TINTA, Tema.font_ui(600))
	_nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nama.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var m := UiKit.margin(kolom, 16, 0, 16, 12)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bawah = UiKit.baris(m, 4)
	_bawah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pressed.connect(func() -> void:
		pivot_offset = size / 2.0
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
		t.tween_property(self, "scale", Vector2.ONE, 0.05)
		Events.kartu_terbang.emit(kata_id, global_position + size / 2.0)
		Events.kartu_dipilih.emit(kata_id))
	_segarkan()


func atur(id: String, pilih := false) -> void:
	kata_id = id
	terpilih = pilih
	if is_node_ready():
		_segarkan()


func _segarkan() -> void:
	var kata := DataDB.get_word(kata_id)
	if kata.is_empty():
		return
	var emosi := str(kata.get("emosi", "netral"))
	var tag := str(kata.get("tag", ""))
	_nama.text = Bahasa.teks(kata.get("text", ""))
	_nama.add_theme_font_size_override("font_size", 25 if _nama.text.length() <= 18 else 21)
	var gaya_pita := StyleBoxFlat.new()
	gaya_pita.corner_radius_top_left = 26
	gaya_pita.corner_radius_top_right = 26
	gaya_pita.content_margin_left = 14
	gaya_pita.content_margin_right = 10
	gaya_pita.anti_aliasing = true
	_lencana.visible = false
	if tag == "tokoh":
		gaya_pita.bg_color = Palet.MALAM
		_ikon.texture = UiKit.muat_ikon("mahkota")
		_ikon.modulate = Palet.KUNING
		_emosi.text = tr("UI_KARTU_TOKOH")
		_emosi.add_theme_color_override("font_color", Palet.KUNING)
	else:
		gaya_pita.bg_color = Palet.emosi(emosi)
		gaya_pita.border_color = Palet.emosi_gelap(emosi)
		gaya_pita.border_width_bottom = 6
		_ikon.texture = UiKit.muat_ikon(emosi)
		_ikon.modulate = Palet.teks_di_atas(emosi)
		_emosi.text = tr("UI_EMO_" + emosi.to_upper()).capitalize()
		_emosi.add_theme_color_override("font_color", Palet.teks_di_atas(emosi))
		if tag == "kandidat":
			_isi_lencana(tr("UI_KARTU_CALON"))
		elif GameState.kartu_sementara.has(kata_id):
			_isi_lencana(tr("UI_KARTU_SISA") % int(GameState.kartu_sementara[kata_id]))
	_pita.add_theme_stylebox_override("panel", gaya_pita)
	_isi_bawah(kata, tag)
	_atur_gaya()


func _isi_lencana(teks: String) -> void:
	_lencana.visible = true
	(_lencana.get_child(0) as Label).text = teks


func _isi_bawah(kata: Dictionary, tag: String) -> void:
	for anak in _bawah.get_children():
		anak.queue_free()
	if tag == "tokoh":
		var rep := _reputasi()
		var b := UiKit.bar(_bawah, Palet.KUNING, 12, Color("ece7f7"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.max_value = rep.y
		b.value = rep.x
		UiKit.label(_bawah, 20, Palet.TEKS_KERTAS_REDUP, Tema.font_ui(700), Bahasa.angka(int(rep.x)))
		return
	_pips("api", int(kata.get("heboh", 0)), Palet.ORANYE)
	var jarak := Control.new()
	jarak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jarak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bawah.add_child(jarak)
	_pips("perisai", int(kata.get("kred", 0)), Palet.CYAN_GELAP)


func _pips(ikon_nama: String, n: int, warna: Color) -> void:
	UiKit.ikon(_bawah, ikon_nama, 22, warna)
	for k in 3:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(14, 14)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", Palet.kotak(warna if k < n else Color("e3def0"), Color.TRANSPARENT, 999))
		_bawah.add_child(p)


## Reputasi tokoh untuk kartu ini: (sisa, maksimum).
func _reputasi() -> Vector2:
	for t in DataDB.tokoh:
		if str(t.get("kata", "")) == kata_id:
			var maks := float(t.get("reputasi", 1000))
			return Vector2(float(GameState.tokoh_reputasi.get(t["id"], maks)), maks)
	return Vector2(0, 1)


func _atur_gaya() -> void:
	var tokoh := str(DataDB.get_word(kata_id).get("tag", "")) == "tokoh"
	for nama in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var g := StyleBoxFlat.new()
		g.bg_color = Palet.KERTAS
		g.set_corner_radius_all(28)
		g.anti_aliasing = true
		g.border_color = Palet.PINK if terpilih else (Palet.KUNING if tokoh else Color("0e0b1f"))
		if terpilih:
			g.set_border_width_all(6)
		elif tokoh:
			g.set_border_width_all(5)
		else:
			g.border_width_bottom = 8
		if nama == "focus":
			g.draw_center = false
			g.border_color = Palet.KUNING
			g.set_border_width_all(4)
		add_theme_stylebox_override(nama, g)
	offset_transform_position = Vector2(0, -12) if terpilih else Vector2.ZERO
