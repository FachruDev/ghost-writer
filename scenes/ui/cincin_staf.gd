class_name CincinStaf
extends Control
## Cincin hitung mundur staf di HUD, digambar sendiri. anim_staff_working: selama staf aktif, tiga
## titik "mengetik" memantul di tengah cincin; saat staf mengirim rumor cincin memantul (kirim()).

var nilai := 0.0
var warna := Palet.HIJAU
var mengetik := false:
	set(v):
		mengetik = v
		queue_redraw()

var _t := 0.0


func _process(delta: float) -> void:
	if mengetik and is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 3.0
	draw_arc(c, r, 0.0, TAU, 32, Palet.PANEL_2, 6.0)
	if nilai > 0.0:
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * nilai, 32, warna, 6.0)
	if mengetik:
		for k in 3:
			var naik := absf(sin(_t * 7.0 - k * 0.9)) * 4.0
			draw_circle(c + Vector2((k - 1) * 8.0, 2.0 - naik), 3.0, warna)


## Staf baru saja mengirim rumor: cincin membesar sebentar.
func kirim() -> void:
	pivot_offset = size / 2.0
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
