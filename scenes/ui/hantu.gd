class_name Hantu
extends Control
## Maskot "Si Hantu Penulis" (papan 08 Karakter): digambar lewat _draw() supaya tajam di semua ukuran.
## Suasana: DIAM (melayang), MENGETIK (bergetar kecil), GIRANG (melompat), PANIK (gemetar + keringat).

enum Suasana { DIAM, MENGETIK, GIRANG, PANIK }

const DASAR := Vector2(120, 150)  # ruang gambar dalam satuan desain
const BADAN := Color("f4f1ff")
const BAYANG := Color("d6d0f0")
const TOPI := Color("120e26")
const TINTA := Color("1a1530")

@export var suasana: Suasana = Suasana.DIAM:
	set(v):
		suasana = v
		queue_redraw()
## Mahkota emas menggantikan topi (ending menang).
@export var bermahkota := false

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x / DASAR.x, size.y / DASAR.y)
	var asal := (size - DASAR * s) / 2.0
	var geser := Vector2.ZERO
	match suasana:
		Suasana.DIAM:
			geser.y = sin(_t * 2.4) * 5.0
		Suasana.MENGETIK:
			geser.y = absf(sin(_t * 22.0)) * 2.0
		Suasana.GIRANG:
			geser.y = -absf(sin(_t * 6.0)) * 12.0
		Suasana.PANIK:
			geser.x = sin(_t * 40.0) * 2.5
	draw_set_transform(asal + geser * s, sin(_t * 40.0) * 0.03 if suasana == Suasana.PANIK else 0.0, Vector2(s, s))
	_badan()
	if bermahkota:
		_mahkota()
	else:
		_topi()
	_wajah()
	draw_set_transform(Vector2.ZERO)


func _badan() -> void:
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = BADAN
	gaya.corner_radius_top_left = 45
	gaya.corner_radius_top_right = 45
	gaya.corner_radius_bottom_left = 16
	gaya.corner_radius_bottom_right = 16
	gaya.anti_aliasing = true
	draw_style_box(gaya, Rect2(15, 40, 90, 92))
	draw_circle(Vector2(32, 132), 14, BADAN)
	draw_circle(Vector2(60, 135), 14, BADAN)
	draw_circle(Vector2(88, 132), 14, BAYANG)
	draw_circle(Vector2(12, 96), 10, BADAN)
	draw_circle(Vector2(108, 96), 10, BAYANG)


func _topi() -> void:
	var mahkota := StyleBoxFlat.new()
	mahkota.bg_color = TOPI
	mahkota.corner_radius_top_left = 10
	mahkota.corner_radius_top_right = 10
	draw_style_box(mahkota, Rect2(30, 6, 60, 38))
	draw_rect(Rect2(30, 32, 60, 8), Palet.PINK)
	draw_rect(Rect2(6, 40, 108, 9), TOPI)
	# kartu PERS terselip di pita
	draw_rect(Rect2(68, 18, 18, 13), Palet.KERTAS)
	draw_line(Vector2(71, 23), Vector2(83, 23), TINTA, 1.5)
	draw_line(Vector2(71, 27), Vector2(80, 27), TINTA, 1.5)


func _mahkota() -> void:
	var t := PackedVector2Array([Vector2(32, 42), Vector2(32, 14), Vector2(46, 28), Vector2(60, 4),
		Vector2(74, 28), Vector2(88, 14), Vector2(88, 42)])
	draw_colored_polygon(t, Palet.KUNING)


func _wajah() -> void:
	match suasana:
		Suasana.GIRANG:
			draw_arc(Vector2(44, 76), 7, PI, TAU, 10, TINTA, 4.0)
			draw_arc(Vector2(76, 76), 7, PI, TAU, 10, TINTA, 4.0)
		Suasana.PANIK:
			for x in [42.0, 78.0]:
				draw_circle(Vector2(x, 76), 11, TINTA)
				draw_circle(Vector2(x, 76), 9, Color.WHITE)
				draw_circle(Vector2(x, 78), 3.5, TINTA)
		Suasana.MENGETIK:
			draw_rect(Rect2(36, 78, 14, 6), TINTA)
			draw_rect(Rect2(70, 78, 14, 6), TINTA)
		_:
			_oval(Vector2(44, 76), 6, 9, TINTA)
			_oval(Vector2(76, 76), 6, 9, TINTA)
			draw_circle(Vector2(46, 72), 2, Color.WHITE)
			draw_circle(Vector2(78, 72), 2, Color.WHITE)
	_oval(Vector2(30, 94), 8, 5, Color(Palet.PINK, 0.45))
	_oval(Vector2(90, 94), 8, 5, Color(Palet.PINK, 0.45))
	match suasana:
		Suasana.GIRANG:
			var mulut := PackedVector2Array()
			for k in 9:
				var a := PI * k / 8.0
				mulut.append(Vector2(60, 94) + Vector2(cos(a) * 13, sin(a) * 11))
			draw_colored_polygon(mulut, Color("e2557a"))
		Suasana.PANIK:
			_oval(Vector2(60, 100), 7, 8, TINTA)
			var tetes := Vector2(104, 66 + fmod(_t * 30.0, 18.0))
			draw_circle(tetes, 4.5, Palet.CYAN)
		Suasana.MENGETIK:
			draw_line(Vector2(54, 98), Vector2(66, 98), TINTA, 4.0)
		_:
			draw_arc(Vector2(60, 92), 9, 0.3, PI - 0.3, 10, TINTA, 4.0)


func _oval(c: Vector2, rx: float, ry: float, warna: Color) -> void:
	var titik := PackedVector2Array()
	for k in 16:
		var a := TAU * k / 16.0
		titik.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(titik, warna)
