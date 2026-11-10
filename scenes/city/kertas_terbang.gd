class_name KertasTerbang
extends Control
## anim_send_paper: lembar kecil bergaris tinta terbang melengkung dari meja (atau cincin staf) ke
## distrik sasaran sambil berputar dan mengecil, lalu riak cincin di tempat mendarat.
## Dipasang top_level di atas peta, jadi tidak terpotong clip_contents peta dan tidak diatur container.

const LAMA_TERBANG := 0.5
const LAMA_RIAK := 0.4
const UKURAN := Vector2(64, 46)

var _dari := Vector2.ZERO
var _ke := Vector2.ZERO
var _puncak := Vector2.ZERO
var _aksen := Palet.PINK
var _skala_awal := 1.0
var _arah := 1.0
var _kemajuan := 0.0  # 0..1 selama terbang
var _riak := -1.0  # 0..1 selama riak; -1 = belum mendarat


## Luncurkan dari titik global `dari` ke `ke` (koordinat layar). `induk` sebaiknya tidak memotong isi.
static func luncurkan(induk: Node, dari: Vector2, ke: Vector2, aksen: Color = Palet.PINK, skala := 1.0,
		tunda := 0.0) -> KertasTerbang:
	var k := KertasTerbang.new()
	k._dari = dari
	k._ke = ke
	k._aksen = aksen
	k._skala_awal = skala
	k._arah = 1.0 if ke.x >= dari.x else -1.0
	# Titik kendali kurva: di atas tengah lintasan, makin jauh makin tinggi.
	k._puncak = (dari + ke) / 2.0 + Vector2(0.0, -clampf(dari.distance_to(ke) * 0.45, 60.0, 260.0))
	induk.add_child(k)
	k.top_level = true
	k.z_index = 20
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k.global_position = dari
	k.visible = tunda <= 0.0
	var t := k.create_tween()
	if tunda > 0.0:
		t.tween_interval(tunda)
		t.tween_callback(func() -> void: k.visible = true)
	t.tween_method(k._terbang, 0.0, 1.0, LAMA_TERBANG).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(k._beriak, 0.0, 1.0, LAMA_RIAK).set_ease(Tween.EASE_OUT)
	t.tween_callback(k.queue_free)
	return k


func _terbang(v: float) -> void:
	_kemajuan = v
	var a := _dari.lerp(_puncak, v)
	var b := _puncak.lerp(_ke, v)
	global_position = a.lerp(b, v)
	queue_redraw()


func _beriak(v: float) -> void:
	_riak = v
	global_position = _ke
	queue_redraw()


func _draw() -> void:
	if _riak >= 0.0:
		var r := lerpf(8.0, 46.0, _riak)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(_aksen, 1.0 - _riak), 5.0 * (1.0 - _riak) + 1.0)
		return
	var s := lerpf(_skala_awal, 0.4, _kemajuan)
	draw_set_transform(Vector2.ZERO, _arah * lerpf(-0.1, 0.7, _kemajuan), Vector2(s, s))
	var kotak := Rect2(-UKURAN / 2.0, UKURAN)
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Palet.KERTAS
	gaya.set_corner_radius_all(8)
	gaya.border_width_bottom = 4
	gaya.border_color = Color("d6d0f0")
	gaya.anti_aliasing = true
	draw_style_box(gaya, kotak)
	for i in 3:
		var y := kotak.position.y + 12.0 + i * 10.0
		var x2 := kotak.end.x - 12.0 - i * 9.0
		draw_line(Vector2(kotak.position.x + 10.0, y), Vector2(x2, y), Color(Palet.TINTA, 0.75), 3.0)
	draw_circle(Vector2(kotak.end.x - 9.0, kotak.position.y + 9.0), 5.0, _aksen)
	draw_set_transform(Vector2.ZERO)
