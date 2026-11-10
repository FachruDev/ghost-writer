class_name KotaMemudar
extends Control
## anim_ending: sebelum layar ending, warga di peta berganti warna titik demi titik dalam urutan acak:
## kelabu untuk "Kota Mati Rasa" (kalah), emas untuk "Imperium Kabar Burung" (menang).
## Dipasang di atas peta; layar ending menunggu LAMA lalu muncul (ending.gd).

const LAMA := 4.0
const LAMA_TITIK := 0.35
const WARNA := {"menang": Color("ffc93c"), "kalah": Color("8a90a0")}

var _peta: PetaJaringan
var _warna := Color.WHITE
var _tunda := PackedFloat32Array()
var _t := 0.0


static func mulai(peta: PetaJaringan, hasil: String) -> KotaMemudar:
	var k := KotaMemudar.new()
	k._peta = peta
	k._warna = WARNA.get(hasil, WARNA["kalah"])
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	peta.get_parent().add_child(k)
	k.position = peta.position
	k.size = peta.size
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	k._tunda.resize(peta.posisi().size())
	for i in k._tunda.size():
		k._tunda[i] = rng.randf() * (LAMA - LAMA_TITIK - 0.4)
	return k


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if _peta == null:
		return
	var pos := _peta.posisi()
	var r := _peta.jari()
	# Peta perlahan meredup di bawah warga yang sudah berganti warna.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.05, 0.12, 0.45 * clampf(_t / LAMA, 0.0, 1.0)))
	for i in mini(pos.size(), _tunda.size()):
		var p := clampf((_t - _tunda[i]) / LAMA_TITIK, 0.0, 1.0)
		if p <= 0.0:
			continue
		var c := pos[i]
		draw_circle(c, r * (0.7 + 0.5 * p), Color(_warna, 0.85 * p))
		if p < 1.0:
			draw_arc(c, r * (1.0 + 1.6 * p), 0.0, TAU, 16, Color(_warna, 0.6 * (1.0 - p)), 2.0)
