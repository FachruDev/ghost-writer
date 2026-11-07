class_name TutorialGelembung
extends PanelContainer
## Gelembung Si Hantu untuk tutorial: pil LANGKAH n/3, teks petunjuk, dan tombol Lewati.
## Hanya tombol Lewati yang menangkap ketukan; sisanya tembus ke permainan di bawahnya.

signal dilewati

const UKURAN_HANTU := 104
const JARAK := 16
const PAD := 20

var _hantu: Hantu
var _pil: PanelContainer
var _teks: Label
var _lewati: Button
var _info: Dictionary = {}
var _rayakan := false
var _tenang: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gaya := Palet.kotak(Palet.PANEL, Palet.KUNING, 36)
	gaya.set_content_margin_all(PAD)
	gaya.shadow_color = Color(0, 0, 0, 0.35)
	gaya.shadow_size = 18
	gaya.shadow_offset = Vector2(0, 8)
	add_theme_stylebox_override("panel", gaya)
	var baris := UiKit.baris(self, JARAK)
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hantu = Hantu.new()
	_hantu.custom_minimum_size = Vector2(UKURAN_HANTU, UKURAN_HANTU)
	_hantu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(_hantu)
	var kolom := UiKit.kolom(baris, 4)
	kolom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolom.alignment = BoxContainer.ALIGNMENT_CENTER
	var atas := UiKit.baris(kolom, 12)
	atas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pil = UiKit.pil(atas, "", Palet.KUNING, Palet.TINTA, 20)
	_pil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sela := Control.new()
	sela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sela.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atas.add_child(sela)
	_lewati = _tombol_lewati(atas)
	_teks = UiKit.label(kolom, 28, Palet.TEKS, Tema.font_ui(600))
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Tombol teks redup setinggi 88 px (area ketuk minimum) tanpa kotak, supaya gelembung tetap ringan.
func _tombol_lewati(induk: Control) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(88, 88)
	b.add_theme_font_override("font", Tema.font_ui(700))
	b.add_theme_font_size_override("font_size", 22)
	var kosong := StyleBoxEmpty.new()
	kosong.content_margin_left = 12
	kosong.content_margin_right = 4
	for nama in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(nama, kosong)
	b.add_theme_color_override("font_color", Palet.TEKS_REDUP)
	b.add_theme_color_override("font_hover_color", Palet.TEKS)
	b.add_theme_color_override("font_pressed_color", Palet.KUNING)
	b.add_theme_color_override("font_hover_pressed_color", Palet.KUNING)
	b.add_theme_color_override("font_focus_color", Palet.TEKS_REDUP)
	b.pressed.connect(func() -> void: dilewati.emit())
	induk.add_child(b)
	return b


## Lebar tetap (piksel viewport); label diberi lebar minimum supaya tingginya diukur benar sejak awal.
func atur_lebar(lebar: float) -> void:
	custom_minimum_size.x = lebar
	_teks.custom_minimum_size.x = maxf(0.0, lebar - PAD * 2 - UKURAN_HANTU - JARAK)


## Langkah baru: muncul dengan pantulan; langkah yang sama hanya memperbarui teks.
func tampilkan(info: Dictionary) -> void:
	var baru: bool = _rayakan or info.get("langkah") != _info.get("langkah") or info.get("sasaran") != _info.get("sasaran")
	_info = info
	_rayakan = false
	segarkan_teks()
	if baru:
		_muncul(Hantu.Suasana.MENGETIK)


## Tutorial selesai: Hantu girang, tanpa pil langkah dan tombol Lewati.
func rayakan() -> void:
	_rayakan = true
	_info = {}
	segarkan_teks()
	_muncul(Hantu.Suasana.GIRANG)


func segarkan_teks() -> void:
	_pil.visible = not _rayakan
	_lewati.visible = not _rayakan
	if _rayakan:
		_teks.text = tr("UI_TUT_SELESAI")
		return
	(_pil.get_child(0) as Label).text = tr("UI_TUT_LANGKAH") % [int(_info.get("langkah", 1)), TutorialController.JUMLAH_LANGKAH]
	_lewati.text = tr("UI_TUT_LEWATI") + " ›"
	_teks.text = tr(str(_info.get("kunci", "")))


func _muncul(suasana: Hantu.Suasana) -> void:
	_hantu.suasana = suasana
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "modulate:a", 1.0, 0.15)
	if _tenang:
		_tenang.kill()
	if suasana == Hantu.Suasana.MENGETIK:
		_tenang = create_tween()
		_tenang.tween_interval(0.9)
		_tenang.tween_callback(func() -> void: _hantu.suasana = Hantu.Suasana.DIAM)
