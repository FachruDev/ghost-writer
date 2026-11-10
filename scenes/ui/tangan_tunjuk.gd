class_name TanganTunjuk
extends Control
## Tangan kartun penunjuk tutorial, digambar lewat _draw() seperti maskot (gaya stiker: isi putih,
## garis tinta tebal, manset pink). Ujung telunjuk ada di posisi node; badan tangan ke kanan bawah,
## atau ke kiri bawah kalau `cermin`. Mengetuk berulang dengan riak kuning di ujung jari.

const PERIODE := 1.1
const SKALA := 0.9
const MIRING := 0.35  # radian; telunjuk condong ke arah sasaran
const MIRING_BAWAH := 1.05  # sasaran di tepi bawah layar: tangan lebih rebah supaya tidak terpotong
const GARIS := 5.0
const KULIT := Color("fffdf7")
const KUKU := Color("ffd6e4")
## Bentuk dasar (telunjuk tegak, ujungnya di 0,0): kapsul [a, b, jari-jari].
const BENTUK := [
	[Vector2(10, 80), Vector2(42, 80), 25.0],  # telapak
	[Vector2(0, 11), Vector2(0, 50), 11.0],  # telunjuk
	[Vector2(-13, 64), Vector2(-3, 84), 10.0],  # jempol
	[Vector2(21, 50), Vector2(21, 60), 10.5],  # jari tengah, ditekuk
	[Vector2(39, 56), Vector2(39, 64), 10.0],  # jari manis
	[Vector2(55, 63), Vector2(55, 70), 9.0],  # kelingking
]
const MANSET := [Vector2(6, 112), Vector2(46, 112), 13.0]
const BATAS_DASAR := Rect2(-28, -6, 98, 136)

var cermin := false
var miring := MIRING
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t = fmod(_t + delta, PERIODE)
	queue_redraw()


## Kotak yang ditempati tangan, relatif terhadap ujung jari (supaya gelembung tidak menutupinya).
func batas() -> Rect2:
	var arah := -1.0 if cermin else 1.0
	var t := Transform2D(-miring * arah, Vector2(SKALA * arah, SKALA), 0.0, Vector2.ZERO)
	return (t * BATAS_DASAR).grow(20.0)


func _draw() -> void:
	var p := _t / PERIODE
	var tekan: float = smoothstep(0.0, 0.22, p) if p < 0.22 else (1.0 if p < 0.4 else 1.0 - smoothstep(0.4, 0.75, p))
	if p >= 0.22 and p < 0.9:
		var q := (p - 0.22) / 0.68
		draw_arc(Vector2.ZERO, lerpf(10.0, 50.0, q), 0.0, TAU, 40, Color(Palet.KUNING, 0.9 * (1.0 - q)), 5.0, true)
	var arah := -1.0 if cermin else 1.0
	var s := SKALA * lerpf(1.0, 0.94, tekan)
	# Saat terangkat, tangan mundur searah badannya.
	var angkat := Vector2(0.0, 22.0).rotated(-miring * arah) * (1.0 - tekan)
	draw_set_transform(angkat, -miring * arah, Vector2(s * arah, s))
	for b in BENTUK:
		_kapsul(b[0], b[1], b[2] + GARIS, Palet.TINTA)
	_kapsul(MANSET[0], MANSET[1], MANSET[2] + GARIS, Palet.TINTA)
	for b in BENTUK:
		_kapsul(b[0], b[1], b[2], KULIT)
	# Lipatan jari yang ditekuk dan kuku telunjuk.
	draw_line(Vector2(30, 52), Vector2(30, 66), Color(Palet.TINTA, 0.3), 3.0, true)
	draw_line(Vector2(47, 59), Vector2(47, 72), Color(Palet.TINTA, 0.3), 3.0, true)
	_kapsul(Vector2(0, 5), Vector2(0, 11), 5.5, KUKU)
	_kapsul(MANSET[0], MANSET[1], MANSET[2], Palet.PINK)
	_kapsul(MANSET[0] + Vector2(2, -4), MANSET[1] + Vector2(-2, -4), 4.0, Color(Color.WHITE, 0.35))
	draw_set_transform(Vector2.ZERO)


func _kapsul(a: Vector2, b: Vector2, r: float, warna: Color) -> void:
	draw_circle(a, r, warna, true, -1.0, true)
	draw_circle(b, r, warna, true, -1.0, true)
	if a != b:
		draw_line(a, b, warna, r * 2.0, true)
