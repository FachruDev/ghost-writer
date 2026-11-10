class_name GambarWajah
extends RefCounted
## Menggambar wajah warga (Konsep A "Jaringan Gosip") ke CanvasItem mana pun lewat _draw().
## Status dibaca dari ekspresi + warna cincin, tidak dari warna saja (Panduan Gaya 07).

const TINTA := Color("1a1530")


## c = pusat, r = jari-jari wajah (tanpa cincin), status = SpreadSim.Status, idx = variasi kulit/rambut.
static func gambar(ci: CanvasItem, c: Vector2, r: float, status: int, idx: int, cahaya := 1.0) -> void:
	var cincin: Color = Palet.STATUS[status]
	var tebal := maxf(2.0, r * 0.22)
	if status == SpreadSim.Status.PERCAYA and cahaya > 0.0:
		ci.draw_circle(c, r * 1.9, Color(Palet.PINK, 0.16 * cahaya))
	ci.draw_circle(c, r + tebal, cincin)
	var kulit: Color = Palet.KULIT[idx % Palet.KULIT.size()]
	if status == SpreadSim.Status.KEBAL:
		kulit = kulit.lerp(Color("aab0bd"), 0.45)
	ci.draw_circle(c, r, kulit)
	if r >= 7.0:
		_rambut(ci, c, r, Palet.RAMBUT[idx % Palet.RAMBUT.size()])
	_mata(ci, c, r, status)
	_mulut(ci, c, r, status)


static func _rambut(ci: CanvasItem, c: Vector2, r: float, warna: Color) -> void:
	var titik := PackedVector2Array()
	var pusat := c + Vector2(0, -r * 0.42)
	for k in 13:
		var a := PI + PI * k / 12.0
		titik.append(pusat + Vector2(cos(a) * r * 0.8, sin(a) * r * 0.62))
	ci.draw_colored_polygon(titik, warna)


static func _mata(ci: CanvasItem, c: Vector2, r: float, status: int) -> void:
	var w := maxf(1.5, r * 0.17)
	match status:
		SpreadSim.Status.KEBAL:
			ci.draw_rect(Rect2(c + Vector2(-r * 0.72, -r * 0.3), Vector2(r * 1.44, r * 0.36)), TINTA)
		SpreadSim.Status.RAGU:
			var h := maxf(1.2, r * 0.12)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.22, -r * 0.1), Vector2(w, h)), TINTA)
			ci.draw_rect(Rect2(c + Vector2(r * 0.36, -r * 0.1), Vector2(w, h)), TINTA)
		SpreadSim.Status.PERCAYA:
			var h := r * 0.42
			ci.draw_rect(Rect2(c + Vector2(-r * 0.42, -r * 0.3), Vector2(w, h)), TINTA)
			ci.draw_rect(Rect2(c + Vector2(r * 0.26, -r * 0.3), Vector2(w, h)), TINTA)
		_:
			var h := r * 0.3
			ci.draw_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.22), Vector2(w, h)), TINTA)
			ci.draw_rect(Rect2(c + Vector2(r * 0.24, -r * 0.22), Vector2(w, h)), TINTA)


static func _mulut(ci: CanvasItem, c: Vector2, r: float, status: int) -> void:
	var tebal := maxf(1.5, r * 0.14)
	match status:
		SpreadSim.Status.PERCAYA:
			ci.draw_circle(c + Vector2(0, r * 0.42), r * 0.22, TINTA)
		SpreadSim.Status.RAGU:
			ci.draw_line(c + Vector2(-r * 0.32, r * 0.52), c + Vector2(r * 0.32, r * 0.36), TINTA, tebal)
		_:
			ci.draw_line(c + Vector2(-r * 0.28, r * 0.46), c + Vector2(r * 0.28, r * 0.46), TINTA, tebal)


## Gelembung "!" (percaya) atau "?" (ragu) di atas kanan wajah.
static func gelembung(ci: CanvasItem, c: Vector2, r: float, status: int, font: Font, naik := 0.0) -> void:
	if status != SpreadSim.Status.PERCAYA and status != SpreadSim.Status.RAGU:
		return
	var b := maxf(9.0, r * 0.75)
	var p := c + Vector2(r * 0.85, -r * 1.25 - naik)
	ci.draw_circle(p, b, Palet.PINK if status == SpreadSim.Status.PERCAYA else Palet.KUNING)
	var teks := "!" if status == SpreadSim.Status.PERCAYA else "?"
	var ukuran := int(b * 1.5)
	var lebar := font.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	ci.draw_string(font, p + Vector2(-lebar / 2.0, ukuran * 0.36), teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, TINTA)
