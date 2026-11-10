class_name IndikatorGulir
extends Control
## Indikator gulir tipis di tepi kanan ScrollContainer: muncul saat daftar bergulir, lalu memudar sendiri.
## Pengganti scrollbar bawaan yang disembunyikan GulirSentuh. Abu netral supaya terlihat di kertas terang
## maupun latar malam.

const LEBAR := 6.0
const TEPI := 3.0
const MIN_PANJANG := 36.0
const WARNA := Color(0.55, 0.53, 0.62, 0.55)
const TAHAN := 0.6  # detik tetap terlihat setelah gulir berhenti
const PUDAR := 0.35

var _gulir: ScrollContainer
var _tween: Tween
var _gaya := StyleBoxFlat.new()


static func pasang(gulir: ScrollContainer) -> IndikatorGulir:
	var bar := IndikatorGulir.new()
	bar._gulir = gulir
	bar.top_level = true  # tidak ikut ditata/digulir sebagai isi ScrollContainer
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.modulate.a = 0.0
	bar.z_index = 10
	bar._gaya.bg_color = WARNA
	bar._gaya.set_corner_radius_all(int(LEBAR / 2.0))
	gulir.add_child(bar, false, Node.INTERNAL_MODE_BACK)
	gulir.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: bar.tampilkan())
	return bar


func tampilkan() -> void:
	if GulirSentuh.ruang(_gulir, true) <= 1.0:
		return
	_tata()
	modulate.a = 1.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(TAHAN)
	_tween.tween_property(self, "modulate:a", 0.0, PUDAR)


func _process(_delta: float) -> void:
	if modulate.a > 0.0:
		_tata()


func _tata() -> void:
	var kotak := _gulir.get_global_rect()
	global_position = Vector2(kotak.end.x - LEBAR - TEPI, kotak.position.y)
	size = Vector2(LEBAR, kotak.size.y)
	visible = _gulir.is_visible_in_tree()
	queue_redraw()


func _draw() -> void:
	var v := _gulir.get_v_scroll_bar()
	if v.max_value <= 0.0:
		return
	var jalur := size.y - TEPI * 2.0
	var panjang := clampf(jalur * v.page / v.max_value, MIN_PANJANG, jalur)
	var y := TEPI + (jalur - panjang) * clampf(v.value / maxf(GulirSentuh.ruang(_gulir, true), 1.0), 0.0, 1.0)
	draw_style_box(_gaya, Rect2(0, y, LEBAR, panjang))
