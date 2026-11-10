class_name IlustrasiEra
extends Control
## Ilustrasi lembar Naik Era (kanvas papan 11): sinar kuning berputar, cahaya, bintang berkelip, dan
## gedung era baru (kantor kecil, gedung media lebar, menara server tinggi) dengan jendela menyala.
## mulai(era): gedung tumbuh dari bawah, jendela menyala satu per satu, Si Hantu mendarat di atapnya.

const KOTAK := Vector2(400, 340)  # ruang gambar (papan 11: 200x170 px kanvas)
## Gedung per era dalam koordinat KOTAK: [x, y, lebar, tinggi, warna].
const GEDUNG := {
	2: [128.0, 108.0, 144.0, 192.0, Color("3a3170")],
	3: [80.0, 60.0, 240.0, 240.0, Color("2e2660")],
	4: [148.0, 12.0, 104.0, 288.0, Color("2a2152")],
}
const BINTANG := [[Vector2(-250, 60), Palet.KUNING, 16.0], [Vector2(230, 20), Palet.PINK, 20.0],
	[Vector2(250, 240), Palet.CYAN, 14.0]]
const LAMA_TUMBUH := 0.55
## Ruang di atas gedung untuk hantu yang melompat (menara era 4 hampir setinggi kotak).
const RUANG_ATAS := 56.0

var era := 2
var _t := 0.0
var _tumbuh := 1.0
var _sinar := 1.0
var _turun := 1.0  # 0 = hantu masih di atas, 1 = sudah mendarat di atap
var _hantu: Hantu


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, KOTAK.y + RUANG_ATAS + 10.0)
	_hantu = Hantu.new()
	_hantu.suasana = Hantu.Suasana.GIRANG
	_hantu.size = Vector2(120, 150)
	add_child(_hantu)


func mulai(era_baru: int) -> void:
	era = clampi(era_baru, 2, 4)
	_tumbuh = 0.0
	_sinar = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(self, "_tumbuh", 1.0, LAMA_TUMBUH).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_sinar", 1.0, 0.4)
	_turun = 0.0
	var h := create_tween()
	h.tween_interval(LAMA_TUMBUH * 0.6)
	h.tween_property(self, "_turun", 1.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _asal() -> Vector2:
	return Vector2((size.x - KOTAK.x) / 2.0, RUANG_ATAS)


## Hantu berdiri di atap gedung (papan 11), jatuh dari atas selama _turun < 1. Dihitung tiap frame
## karena lebar ilustrasi baru diketahui setelah tata letak.
func _tata_hantu() -> void:
	var g: Array = GEDUNG[era]
	_hantu.position = _asal() + Vector2(KOTAK.x / 2.0 - 60.0, maxf(float(g[1]) - 110.0, -40.0) - 120.0 * (1.0 - _turun))
	_hantu.modulate.a = clampf(_turun * 4.0, 0.0, 1.0)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		_tata_hantu()
		queue_redraw()


func _draw() -> void:
	var asal := _asal()
	var pusat := asal + Vector2(KOTAK.x / 2.0, 150.0)
	# Sinar berputar (24 dtk per putaran) dan cahaya di belakang gedung.
	var putar := _t * TAU / 24.0
	for k in 18:
		var a0 := putar + k * TAU / 18.0
		var titik := PackedVector2Array([pusat, pusat + Vector2.from_angle(a0) * 320.0,
			pusat + Vector2.from_angle(a0 + TAU / 36.0) * 320.0])
		draw_colored_polygon(titik, Color(Palet.KUNING, 0.12 * _sinar))
	for k in 6:
		draw_circle(pusat, 200.0 - k * 30.0, Color(Palet.KUNING, 0.05 * _sinar))
	_gedung(asal)
	for b in BINTANG:
		var denyut := 0.6 + 0.4 * sin(_t * 5.0 + b[2])
		_bintang(pusat + b[0], float(b[2]) * denyut, Color(b[1], 0.3 + 0.7 * denyut))


func _gedung(asal: Vector2) -> void:
	var g: Array = GEDUNG[era]
	var tinggi := float(g[3]) * _tumbuh
	var bawah := asal.y + float(g[1]) + float(g[3])
	var kotak := Rect2(asal.x + float(g[0]), bawah - tinggi, float(g[2]), tinggi)
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = g[4]
	gaya.corner_radius_top_left = 12
	gaya.corner_radius_top_right = 12
	gaya.anti_aliasing = true
	draw_style_box(gaya, kotak)
	draw_rect(Rect2(kotak.end.x - 16.0, kotak.position.y + 8.0, 16.0, maxf(kotak.size.y - 8.0, 0.0)), Color(0, 0, 0, 0.2))
	var kolom := 4 if era == 3 else 2
	var baris := 6 if era == 4 else 3
	var lebar := (float(g[2]) - 32.0) / kolom - 12.0
	for r in baris:
		for c in kolom:
			var jendela := Rect2(kotak.position.x + 16.0 + c * ((float(g[2]) - 32.0) / kolom),
				bawah - float(g[3]) + 20.0 + r * 44.0, lebar, 24.0)
			if jendela.position.y < kotak.position.y + 8.0:
				continue  # gedung belum tumbuh setinggi jendela ini
			var nyala := (r + c) % 3 == 0
			if nyala:
				draw_rect(jendela.grow(5.0), Color(Palet.PINK, 0.25))
			draw_rect(jendela, Palet.PINK if nyala else Color(Palet.KUNING, 0.33))
	# Tanah.
	draw_rect(Rect2(asal.x + 20.0, bawah, KOTAK.x - 40.0, 6.0), Color(Palet.GARIS, 0.6))


func _bintang(c: Vector2, r: float, warna: Color) -> void:
	var titik := PackedVector2Array()
	for k in 8:
		var jari := r if k % 2 == 0 else r * 0.3
		titik.append(c + Vector2.from_angle(k * TAU / 8.0 - PI / 2.0) * jari)
	draw_colored_polygon(titik, warna)
