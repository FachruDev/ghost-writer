class_name PetaLatar
extends Control
## Lapisan latar peta (di belakang PetaJaringan): kotak peta, titik grid, dan cahaya gugus distrik.
## Statis, jadi hanya digambar ulang saat ukuran peta atau susunan distrik berubah, bukan tiap frame.

var peta: PetaJaringan
var _cahaya: GradientTexture2D


func _ready() -> void:
	show_behind_parent = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.5))
	g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.6, Color(1, 1, 1, 0.16))
	_cahaya = GradientTexture2D.new()
	_cahaya.gradient = g
	_cahaya.fill = GradientTexture2D.FILL_RADIAL
	_cahaya.fill_from = Vector2(0.5, 0.5)
	_cahaya.fill_to = Vector2(1.0, 0.5)
	_cahaya.width = 128
	_cahaya.height = 128


func _draw() -> void:
	draw_style_box(Palet.kotak(Palet.PETA, Color.TRANSPARENT, 40), Rect2(Vector2.ZERO, size))
	var y := PetaJaringan.JARAK_GRID / 2.0
	while y < size.y:
		var x := PetaJaringan.JARAK_GRID / 2.0
		while x < size.x:
			draw_circle(Vector2(x, y), 2.0, Palet.PANEL_2)
			x += PetaJaringan.JARAK_GRID
		y += PetaJaringan.JARAK_GRID
	if peta == null or not peta.siap():
		return
	for i in DataDB.districts.size():
		var rg := peta.rect_distrik(i).grow(minf(size.x, size.y) * 0.08)
		var warna: Color = Palet.EMOSI_PETA.get(str(DataDB.districts[i].get("emosi_favorit", "netral")), Palet.GARIS)
		draw_texture_rect(_cahaya, rg, false, warna)
