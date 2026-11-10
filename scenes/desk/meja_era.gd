class_name MejaEra
extends Control
## Art meja per era (art_desk_era1..4) di belakang kertas, tangan kartu, dan kaki meja:
##   1 Kamar Kos: serat kayu hangat + cahaya lampu belajar
##   2 Kantor Sewaan: meja laminasi bergaris + bekas gelas kopi
##   3 Gedung Media: grid titik + lampu neon pink di tepi meja
##   4 Menara Server: jalur sirkuit hijau + lampu tepi hijau
## Kaki meja ikut berganti warna (Palet.MEJA_ERA) dan hiasan di tepi atasnya (Hiasan): tombol mesin
## tik, tuts keyboard, meter suara yang bergerak, atau lampu server yang berkedip.
## anim_era_transition: saat naik era, meja lama memudar ke meja baru sementara pita cahaya warna era
## naik dari bawah ("kamera naik"), lalu lembar Naik Era muncul (NaikEra menunggu LAMA_TRANSISI).

const LATAR := {1: Color("2c2036"), 2: Color("1d2240"), 3: Color("23163d"), 4: Color("111428")}
const LAMA_TRANSISI := 1.4


## Hiasan di tepi atas kaki meja (di dalam margin atasnya, di belakang tombol).
class Hiasan extends Control:
	var era := 1:
		set(v):
			era = v
			queue_redraw()
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if era >= 3 and is_visible_in_tree():
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var y := -9.0
		var w := size.x
		match era:
			1:  # tombol bulat mesin tik
				for x in range(10, int(w) - 6, 26):
					draw_circle(Vector2(x, y), 4.5, Color("3e2e4a"))
					draw_circle(Vector2(x, y - 1.0), 3.0, Color("5a476e"))
			2:  # tuts keyboard
				for x in range(4, int(w) - 18, 24):
					draw_rect(Rect2(x, y - 4.0, 18, 8), Color("2c3462"))
					draw_line(Vector2(x + 2, y - 3.0), Vector2(x + 16, y - 3.0), Color(Palet.CYAN, 0.35), 1.5)
			3:  # meter suara studio
				for k in int((w - 8.0) / 14.0):
					var tinggi := 2.0 + 7.0 * absf(sin(_t * 5.0 + k * 0.7))
					draw_rect(Rect2(6 + k * 14, y + 4.0 - tinggi, 8, tinggi), Palet.KUNING if k % 5 == 4 else Palet.PINK)
			4:  # lampu server
				for k in int((w - 8.0) / 20.0):
					var c := Vector2(10 + k * 20, y)
					var warna := Palet.KUNING if k % 4 == 3 else Palet.HIJAU
					if fmod(_t * 1.3 + k * 0.37, 1.0) < 0.6:
						draw_circle(c, 7.0, Color(warna, 0.18))
						draw_circle(c, 3.5, warna)
					else:
						draw_circle(c, 3.5, Color("1f2a3a"))


var _era := 1
var _era_lama := 1
var _p := 1.0  # kemajuan transisi 0..1
var _gaya_kaki: StyleBoxFlat
var _hiasan: Hiasan


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_era = clampi(GameState.era, 1, 4)
	_era_lama = _era
	Events.era_berubah.connect(_on_era)
	resized.connect(queue_redraw)


## Kaki meja (warna latar dan hiasan tepi atasnya) ikut era.
func pasang_kaki(gaya: StyleBoxFlat, hiasan: Hiasan) -> void:
	_gaya_kaki = gaya
	_hiasan = hiasan
	_gaya_kaki.bg_color = Palet.MEJA_ERA[_era]
	_hiasan.era = _era


func era() -> int:
	return _era


func _on_era(era_baru: int) -> void:
	var baru := clampi(era_baru, 1, 4)
	if baru == _era:
		return
	var lama := _era
	_era = baru
	if baru < lama or not is_visible_in_tree():
		_era_lama = baru
		_p = 1.0
		if _gaya_kaki:
			_gaya_kaki.bg_color = Palet.MEJA_ERA[baru]
			_hiasan.era = baru
		queue_redraw()
		return
	_era_lama = lama
	_p = 0.0
	var t := create_tween()
	t.tween_method(_atur_kemajuan, 0.0, 1.0, LAMA_TRANSISI * 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _gaya_kaki:
		var kaki := create_tween()
		kaki.tween_method(func(c: Color) -> void: _gaya_kaki.bg_color = c,
			Palet.MEJA_ERA[lama], Palet.MEJA_ERA[baru], LAMA_TRANSISI * 0.85)
		kaki.parallel().tween_callback(func() -> void: _hiasan.era = baru).set_delay(LAMA_TRANSISI * 0.45)


func _atur_kemajuan(v: float) -> void:
	_p = v
	queue_redraw()


func _draw() -> void:
	if _p >= 1.0:
		_gambar_era(_era, 1.0)
		return
	_gambar_era(_era_lama, 1.0)
	_gambar_era(_era, _p)
	# Pita cahaya warna era naik dari bawah meja ke atas.
	var y := lerpf(size.y + 40.0, -60.0, _p)
	var aksen: Color = Palet.ERA[_era]
	for k in 6:
		draw_rect(Rect2(0.0, y + k * 10.0, size.x, 10.0), Color(aksen, 0.4 - k * 0.06))


func _gambar_era(era_gambar: int, a: float) -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(LATAR[era_gambar], a))
	match era_gambar:
		1:
			for i in int(h / 22.0) + 1:
				var garis := PackedVector2Array()
				for x in range(0, int(w) + 24, 24):
					garis.append(Vector2(x, 10.0 + i * 22.0 + sin(x * 0.012 + i * 1.7) * 4.0))
				draw_polyline(garis, Color("3b2a47", a * 0.9), 2.0)
			draw_arc(Vector2(w * 0.8, h * 0.42), 12.0, 0.0, TAU, 20, Color("47345a", a), 2.0)
			draw_arc(Vector2(w * 0.8, h * 0.42), 6.0, 0.0, TAU, 14, Color("47345a", a), 2.0)
			for k in 6:
				draw_circle(Vector2(w * 0.1, 0.0), 300.0 - k * 45.0, Color(1.0, 0.79, 0.24, a * 0.022))
		2:
			for y in range(0, int(h), 12):
				draw_line(Vector2(0, y), Vector2(w, y), Color("222850", a), 2.0)
			draw_arc(Vector2(w * 0.87, h * 0.46), 28.0, 0.4, TAU - 0.5, 32, Color("7a5a48", a * 0.3), 5.0)
			draw_arc(Vector2(w * 0.87, h * 0.46), 22.0, 1.2, TAU - 1.6, 28, Color("7a5a48", a * 0.15), 3.0)
		3:
			for y in range(16, int(h), 28):
				for x in range(16, int(w), 28):
					draw_circle(Vector2(x, y), 2.0, Color("3a2a5e", a))
			draw_rect(Rect2(0.0, 0.0, w, 4.0), Color(Palet.PINK, a))
			for k in 4:
				draw_rect(Rect2(0.0, 4.0 + k * 4.0, w, 4.0), Color(Palet.PINK, a * 0.14 / (k + 1)))
		4:
			var rng := RandomNumberGenerator.new()
			rng.seed = 404
			for j in 16:
				var titik := Vector2(rng.randf() * w, rng.randf() * h)
				var garis := PackedVector2Array([titik])
				for s in 3:
					titik += Vector2(rng.randf_range(40.0, 120.0), 0.0) if s % 2 == 0 else Vector2(0.0, rng.randf_range(-60.0, 60.0))
					garis.append(titik)
				draw_polyline(garis, Color(Palet.HIJAU, a * 0.16), 2.0)
				draw_circle(garis[garis.size() - 1], 4.0, Color(Palet.HIJAU, a * 0.32))
			draw_rect(Rect2(0.0, 0.0, w, 3.0), Color(Palet.HIJAU, a * 0.6))
