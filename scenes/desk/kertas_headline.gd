class_name KertasHeadline
extends PanelContainer
## Kertas headline di meja (papan 02/09): pengganti template, kalimat dengan slot yang bisa
## diketuk (chip), baris skor (emosi, viral, dipercaya), dan animasi mesin tik saat dikirim.

signal slot_ditekan(slot: String)
signal template_digeser(arah: int)
signal ketik_selesai

const POLA_SLOT := "\\{(\\w+)\\}"

var _info: Label
var _alir: HFlowContainer
var _ketikan: Label
var _baris_skor: HBoxContainer
var _emosi: PanelContainer
var _emosi_ikon: TextureRect
var _emosi_teks: Label
var _bar_viral: ProgressBar
var _angka_viral: Label
var _bar_percaya: ProgressBar
var _angka_percaya: Label
var _chip: Dictionary = {}  # slot -> Button
var _regex := RegEx.new()


func _ready() -> void:
	_regex.compile(POLA_SLOT)
	var gaya := Palet.kotak(Palet.KERTAS, Color("0e0b1f"), 36)
	gaya.border_width_bottom = 10
	gaya.border_width_top = 0
	gaya.border_width_left = 0
	gaya.border_width_right = 0
	gaya.content_margin_left = 20
	gaya.content_margin_right = 20
	gaya.content_margin_top = 12
	gaya.content_margin_bottom = 16
	add_theme_stylebox_override("panel", gaya)
	var kolom := UiKit.kolom(self, 8)
	var atas := UiKit.baris(kolom, 12)
	var kiri := UiKit.tombol_ikon(atas, "kiri", tr("UI_TEMPLATE"), Color("ece7f7"), Color("d6d0f0"), Palet.TINTA)
	kiri.custom_minimum_size = Vector2(64, 64)
	kiri.pressed.connect(func() -> void: template_digeser.emit(-1))
	_info = UiKit.label(atas, 22, Palet.TEKS_KERTAS_REDUP, Tema.font_ui(700))
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var kanan := UiKit.tombol_ikon(atas, "kanan", tr("UI_TEMPLATE"), Color("ece7f7"), Color("d6d0f0"), Palet.TINTA)
	kanan.custom_minimum_size = Vector2(64, 64)
	kanan.pressed.connect(func() -> void: template_digeser.emit(1))
	_alir = HFlowContainer.new()
	_alir.add_theme_constant_override("h_separation", 12)
	_alir.add_theme_constant_override("v_separation", 8)
	kolom.add_child(_alir)
	_ketikan = UiKit.label(kolom, 30, Palet.TINTA, Tema.font_ketik())
	_ketikan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ketikan.visible = false
	_bangun_skor(kolom)


func _bangun_skor(induk: Control) -> void:
	_baris_skor = UiKit.baris(induk, 16)
	_emosi = PanelContainer.new()
	_emosi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_baris_skor.add_child(_emosi)
	var isi := UiKit.baris(_emosi, 8)
	_emosi_ikon = UiKit.ikon(isi, "netral", 28, Palet.TINTA)
	_emosi_teks = UiKit.label(isi, 24, Palet.TINTA, Tema.font_ui(700))
	var viral := _kolom_bar(_baris_skor, tr("UI_VIRAL"), Palet.ORANYE)
	_bar_viral = viral[0]
	_angka_viral = viral[1]
	var percaya := _kolom_bar(_baris_skor, tr("UI_DIPERCAYA"), Palet.CYAN_GELAP)
	_bar_percaya = percaya[0]
	_angka_percaya = percaya[1]


func _kolom_bar(induk: Control, judul: String, warna: Color) -> Array:
	var k := UiKit.kolom(induk, 6)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var atas := UiKit.baris(k, 8)
	var j := UiKit.label(atas, 22, Palet.TEKS_KERTAS_REDUP, Tema.font_ui(700), judul)
	j.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var angka := UiKit.label(atas, 22, Palet.TINTA, Tema.font_ui(700), "—")
	var b := UiKit.bar(k, warna, 16, Color("ece7f7"))
	return [b, angka]


## Bangun ulang kalimat: kata biasa + chip slot. isi = slot -> kata_id.
func tampilkan(template_id: String, isi: Dictionary, slot_aktif: String, idx: int, total: int) -> void:
	var template := DataDB.get_template(template_id)
	_info.text = tr("UI_TEMPLATE_INFO") % [idx + 1, total, _angka_desimal(float(template.get("pengali_heboh", 1.0)))]
	for anak in _alir.get_children():
		_alir.remove_child(anak)
		anak.queue_free()
	_chip.clear()
	var pola := Bahasa.teks(template.get("pola", ""))
	var ukuran := 30 if pola.length() <= 60 else (26 if pola.length() <= 85 else 23)
	var unit_terakhir: HBoxContainer = null
	var pos := 0
	var pertama := true
	for m in _regex.search_all(pola):
		unit_terakhir = _literal(pola.substr(pos, m.get_start() - pos), unit_terakhir, ukuran, pertama)
		if pos < m.get_start():
			pertama = false
		var slot := m.get_string(1)
		unit_terakhir = _unit()
		unit_terakhir.add_child(_buat_chip(slot, str(isi.get(slot, "")), slot == slot_aktif, ukuran, pertama))
		pertama = false
		pos = m.get_end()
	_literal(pola.substr(pos), unit_terakhir, ukuran, pertama)


func chip(slot: String) -> Control:
	return _chip.get(slot)


## Kata biasa: pecah per spasi. Tanda baca yang menempel ke slot sebelumnya ikut unit itu.
func _literal(teks: String, sebelumnya: HBoxContainer, ukuran: int, pertama: bool) -> HBoxContainer:
	if teks.is_empty():
		return sebelumnya
	var kata := teks.split(" ", true)
	var unit := sebelumnya
	for k in kata.size():
		var w := kata[k]
		if w.is_empty():
			unit = null
			continue
		if pertama and k == 0:
			w = w.substr(0, 1).to_upper() + w.substr(1)
		if unit == null or k > 0:
			unit = _unit()
		UiKit.label(unit, ukuran, Palet.TINTA, Tema.font_ketik(), w)
	return unit


func _unit() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 2)
	_alir.add_child(h)
	return h


func _buat_chip(slot: String, kata_id: String, aktif: bool, ukuran: int, kapital: bool) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(0, ukuran + 22)
	var gaya := StyleBoxFlat.new()
	gaya.set_corner_radius_all(16)
	gaya.anti_aliasing = true
	gaya.content_margin_left = 12
	gaya.content_margin_right = 12
	gaya.content_margin_top = 4
	gaya.content_margin_bottom = 4
	if kata_id.is_empty():
		b.text = tr("UI_SLOT_TAMBAH") % HeadlineBuilder.nama_slot(slot).capitalize()
		b.add_theme_font_override("font", Tema.font_ui(600))
		b.add_theme_font_size_override("font_size", 22)
		gaya.bg_color = Color(Palet.PINK, 0.08) if aktif else Color.TRANSPARENT
		gaya.border_color = Palet.PINK if aktif else Palet.TEKS_REDUP
		gaya.set_border_width_all(4)
		_warna_teks(b, Palet.PINK if aktif else Palet.TEKS_KERTAS_REDUP)
	else:
		var data := DataDB.get_word(kata_id)
		var emosi := str(data.get("emosi", "netral"))
		var teks := Bahasa.teks(data.get("text", ""))
		b.text = teks.substr(0, 1).to_upper() + teks.substr(1) if kapital else teks
		b.add_theme_font_override("font", Tema.font_ketik())
		b.add_theme_font_size_override("font_size", ukuran)
		gaya.bg_color = Color(Palet.emosi(emosi), 0.35)
		gaya.border_color = Palet.PINK if aktif else Palet.emosi_gelap(emosi)
		if aktif:
			gaya.set_border_width_all(4)
		else:
			gaya.border_width_bottom = 4
		_warna_teks(b, Palet.TINTA)
	for nama in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(nama, gaya)
	var fokus := gaya.duplicate() as StyleBoxFlat
	fokus.draw_center = false
	fokus.border_color = Palet.KUNING
	fokus.set_border_width_all(4)
	b.add_theme_stylebox_override("focus", fokus)
	b.pressed.connect(func() -> void: slot_ditekan.emit(slot))
	_chip[slot] = b
	return b


func _warna_teks(b: Button, warna: Color) -> void:
	for nama in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(nama, warna)


## emosi "" = belum ada kartu: baris skor tetap tampil tapi kosong.
func atur_skor(emosi: String, viral: float, pengali: float, dipercaya: float, ada: bool) -> void:
	var e := emosi if not emosi.is_empty() else "netral"
	var gaya := Palet.tebal(Palet.emosi(e), Palet.emosi_gelap(e), 999, 6)
	gaya.content_margin_left = 14
	gaya.content_margin_right = 18
	gaya.content_margin_top = 6
	gaya.content_margin_bottom = 6
	_emosi.add_theme_stylebox_override("panel", gaya)
	_emosi_ikon.texture = UiKit.muat_ikon(e)
	_emosi_ikon.modulate = Palet.teks_di_atas(e)
	_emosi_teks.text = tr("UI_EMO_" + e.to_upper()).capitalize()
	_emosi_teks.add_theme_color_override("font_color", Palet.teks_di_atas(e))
	if not ada:
		_angka_viral.text = "—"
		_angka_percaya.text = "—"
		_bar_viral.value = 0
		_bar_percaya.value = 0
		return
	_angka_viral.text = _angka_desimal(viral) + ("" if is_equal_approx(pengali, 1.0) else " ×" + _angka_desimal(pengali))
	_bar_viral.max_value = 15.0
	_bar_viral.value = viral
	_angka_percaya.text = "%d%%" % roundi(dipercaya * 100.0)
	_bar_percaya.max_value = 1.0
	_bar_percaya.value = dipercaya


## Animasi mesin tik: headline yang dikirim muncul huruf demi huruf, lalu kembali ke kalimat slot.
func ketik(teks: String, durasi: float) -> void:
	_alir.visible = false
	_ketikan.visible = true
	_ketikan.text = teks
	_ketikan.add_theme_font_size_override("font_size", 30 if teks.length() <= 70 else (26 if teks.length() <= 100 else 23))
	_ketikan.visible_ratio = 0.0
	var t := create_tween()
	t.tween_property(_ketikan, "visible_ratio", 1.0, durasi)
	t.tween_interval(1.0)
	t.tween_callback(func() -> void:
		_ketikan.visible = false
		_alir.visible = true
		ketik_selesai.emit())


## Angka desimal sesuai bahasa (koma untuk Indonesia).
func _angka_desimal(x: float) -> String:
	var s := "%.1f" % x
	return s.replace(".", ",") if Bahasa.kode() == "id" else s
