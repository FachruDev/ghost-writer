class_name Tema
extends RefCounted
## Theme global "Kota Gosip Malam": font, ukuran, warna teks, tombol tebal, panel, scroll.
## Font OFL di assets/fonts/ (Lilita One, Fredoka, Courier Prime). Kalau file belum ada,
## Godot memakai font bawaan supaya game tetap jalan.

const FONT_JUDUL_PATH := "res://assets/fonts/LilitaOne-Regular.ttf"
const FONT_UI_PATH := "res://assets/fonts/Fredoka-Variable.ttf"
const FONT_KETIK_PATH := "res://assets/fonts/CourierPrime-Bold.ttf"

## Ukuran huruf (piksel Godot = 2 × kanvas desain).
const UKURAN := {"kecil": 20, "label": 22, "isi": 26, "tombol": 28, "judul": 44, "besar": 56}

static var _cache: Dictionary = {}


## Lilita One: judul, tombol utama, stempel.
static func font_judul() -> Font:
	return _font("judul", FONT_JUDUL_PATH, 0)


## Fredoka dengan ketebalan 400–700.
static func font_ui(tebal: int = 500) -> Font:
	return _font("ui_%d" % tebal, FONT_UI_PATH, tebal)


## Courier Prime Bold: hanya teks headline di atas kertas.
static func font_ketik() -> Font:
	return _font("ketik", FONT_KETIK_PATH, 0)


static func buat() -> Theme:
	var t := Theme.new()
	t.default_font = font_ui(500)
	t.default_font_size = UKURAN["isi"]
	t.set_color("font_color", "Label", Palet.TEKS)
	t.set_font("font", "Button", font_ui(600))
	t.set_font_size("font_size", "Button", UKURAN["tombol"])
	_gaya_tombol(t, "Button", Palet.PANEL_2, Palet.PANEL)
	t.set_stylebox("panel", "PanelContainer", Palet.kotak(Palet.PANEL, Color.TRANSPARENT, 36))
	t.set_stylebox("panel", "Panel", Palet.kotak(Palet.PANEL, Color.TRANSPARENT, 36))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	var batang := Palet.kotak(Color(Palet.GARIS, 0.7), Color.TRANSPARENT, 6)
	batang.set_content_margin_all(3)
	for jenis in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", jenis, StyleBoxEmpty.new())
		t.set_stylebox("grabber", jenis, batang)
		t.set_stylebox("grabber_highlight", jenis, batang)
		t.set_stylebox("grabber_pressed", jenis, batang)
	t.set_constant("separation", "VBoxContainer", 16)
	t.set_constant("separation", "HBoxContainer", 16)
	return t


static func _gaya_tombol(t: Theme, jenis: String, warna: Color, bayang: Color) -> void:
	t.set_stylebox("normal", jenis, Palet.tebal(warna, bayang))
	t.set_stylebox("hover", jenis, Palet.tebal(warna.lightened(0.06), bayang))
	t.set_stylebox("pressed", jenis, Palet.tebal(warna, bayang, 28, 10, true))
	t.set_stylebox("hover_pressed", jenis, Palet.tebal(warna, bayang, 28, 10, true))
	t.set_stylebox("disabled", jenis, Palet.kotak(Color(Palet.PANEL_2, 0.5), Color.TRANSPARENT, 28))
	var fokus := Palet.kotak(Color.TRANSPARENT, Palet.KUNING, 28)
	fokus.draw_center = false
	t.set_stylebox("focus", jenis, fokus)
	for nama in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(nama, jenis, Palet.TEKS)
	t.set_color("font_disabled_color", jenis, Palet.TEKS_REDUP)


static func _font(kunci: String, path: String, tebal: int) -> Font:
	if _cache.has(kunci):
		return _cache[kunci]
	var dasar: Font = null
	if ResourceLoader.exists(path):
		dasar = load(path) as Font
	if dasar == null:
		dasar = ThemeDB.fallback_font
	var hasil := dasar
	if tebal > 0 and dasar is FontFile:
		var v := FontVariation.new()
		v.base_font = dasar
		v.variation_opentype = {"wght": tebal}
		hasil = v
	_cache[kunci] = hasil
	return hasil
