class_name UiKit
extends RefCounted
## Pembuat node UI yang dipakai berulang: label, tombol tebal, panel, ikon, bar, pil.
## Semua teks diisi kode (auto_translate dimatikan) supaya ikut ADR-0004.

const IKON_DIR := "res://assets/ui/ikon/%s.svg"


static func label(induk: Node, ukuran: int = 26, warna: Color = Palet.TEKS, font: Font = null, teks := "") -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	if font:
		l.add_theme_font_override("font", font)
	l.text = teks
	if induk:
		induk.add_child(l)
	return l


## Tombol tebal. Teks gelap/terang dipilih otomatis dari kecerahan warna.
static func tombol(induk: Node, teks: String, warna: Color = Palet.PANEL_2, bayang := Color.TRANSPARENT,
		ukuran: int = 28, font: Font = null, tinggi: int = 104) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.text = teks
	b.custom_minimum_size = Vector2(88, tinggi)
	b.add_theme_font_size_override("font_size", ukuran)
	if font:
		b.add_theme_font_override("font", font)
	Palet.gaya_tombol(b, warna, bayang)
	if induk:
		induk.add_child(b)
	return b


## Tombol aksi utama (KIRIM!, MULAI): pink, huruf Lilita.
static func tombol_utama(induk: Node, teks: String, warna: Color = Palet.PINK, bayang: Color = Palet.PINK_GELAP,
		teks_warna: Color = Color.WHITE, tinggi: int = 108) -> Button:
	var b := tombol(induk, teks, warna, bayang, 48, Tema.font_judul(), tinggi)
	Palet.gaya_tombol(b, warna, bayang, teks_warna, 32)
	return b


## Tombol ikon persegi (tutup, toko, kembali). Minimal 88 px (44 px kanvas).
static func tombol_ikon(induk: Node, ikon_nama: String, aria: String, warna: Color = Palet.PANEL_2,
		bayang: Color = Palet.PANEL, ikon_warna: Color = Palet.TEKS) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.tooltip_text = aria
	b.custom_minimum_size = Vector2(88, 88)
	b.icon = muat_ikon(ikon_nama)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 40)
	for nama in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
		b.add_theme_color_override(nama, ikon_warna)
	Palet.gaya_tombol(b, warna, bayang, ikon_warna)
	for gaya in ["normal", "hover", "pressed", "hover_pressed"]:
		var s := b.get_theme_stylebox(gaya) as StyleBoxFlat
		s.content_margin_left = 22
		s.content_margin_right = 22
	if induk:
		induk.add_child(b)
	return b


static func muat_ikon(nama: String) -> Texture2D:
	var path := IKON_DIR % nama
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


static func ikon(induk: Node, nama: String, ukuran: int = 32, warna: Color = Palet.TEKS) -> TextureRect:
	var t := TextureRect.new()
	t.texture = muat_ikon(nama)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(ukuran, ukuran)
	t.modulate = warna
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if induk:
		induk.add_child(t)
	return t


static func panel(induk: Node, warna: Color = Palet.PANEL, radius: int = 36, pad: int = 24) -> PanelContainer:
	var p := PanelContainer.new()
	var gaya := Palet.kotak(warna, Color.TRANSPARENT, radius)
	gaya.set_content_margin_all(pad)
	p.add_theme_stylebox_override("panel", gaya)
	if induk:
		induk.add_child(p)
	return p


## Pil kecil berwarna berisi teks (label emosi, TARGET, KONTRAK).
static func pil(induk: Node, teks: String, warna: Color, teks_warna: Color = Palet.TINTA, ukuran: int = 20) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gaya := Palet.kotak(warna, Color.TRANSPARENT, 999)
	gaya.content_margin_left = 16
	gaya.content_margin_right = 16
	gaya.content_margin_top = 4
	gaya.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", gaya)
	label(p, ukuran, teks_warna, Tema.font_ui(700), teks)
	if induk:
		induk.add_child(p)
	return p


## Bar kemajuan bulat (kredibilitas, panas, reputasi, kontrak).
static func bar(induk: Node, warna: Color, tinggi: int = 18, latar: Color = Palet.PANEL) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, tinggi)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var isi := Palet.kotak(warna, Color.TRANSPARENT, tinggi)
	isi.set_content_margin_all(0)
	var bg := Palet.kotak(latar, Color.TRANSPARENT, tinggi)
	bg.set_content_margin_all(0)
	b.add_theme_stylebox_override("fill", isi)
	b.add_theme_stylebox_override("background", bg)
	if induk:
		induk.add_child(b)
	return b


static func margin(induk: Node, kiri: int, atas: int, kanan: int, bawah: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", kiri)
	m.add_theme_constant_override("margin_top", atas)
	m.add_theme_constant_override("margin_right", kanan)
	m.add_theme_constant_override("margin_bottom", bawah)
	if induk:
		induk.add_child(m)
	return m


static func baris(induk: Node, jarak: int = 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", jarak)
	if induk:
		induk.add_child(h)
	return h


static func kolom(induk: Node, jarak: int = 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", jarak)
	if induk:
		induk.add_child(v)
	return v


## Jarak aman notch (x = atas) dan bar gestur (y = bawah) dalam piksel viewport. Nol di desktop.
static func inset_aman(n: Node) -> Vector2:
	if not OS.has_feature("mobile") or n == null or not n.is_inside_tree():
		return Vector2.ZERO
	var aman := DisplayServer.get_display_safe_area()
	var jendela := DisplayServer.window_get_size()
	if aman.size.y <= 0 or jendela.y <= 0:
		return Vector2.ZERO
	var skala := n.get_viewport().get_visible_rect().size.y / float(jendela.y)
	var atas := maxf(0.0, aman.position.y) * skala
	var bawah := maxf(0.0, jendela.y - aman.end.y) * skala
	return Vector2(atas, bawah)


## Lapisan gelap layar penuh di belakang lembar/modal; menelan klik.
static func redup(induk: Node, alfa: float = 0.75) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color("0e0b1f", alfa)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	if induk:
		induk.add_child(r)
	return r
