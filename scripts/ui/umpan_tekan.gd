class_name UmpanTekan
## Umpan balik tekan (anim_button_feedback): tombol mengecil sedikit saat ditekan lalu memantul kembali
## saat dilepas. Warna tekan sudah diatur gaya "pressed" (Palet.gaya_tombol); ini menambah gerak skala.

const SKALA_TEKAN := 0.95
const LAMA_TEKAN := 0.08
const LAMA_LEPAS := 0.16


static func pasang(b: BaseButton) -> void:
	b.button_down.connect(func() -> void: _ke(b, SKALA_TEKAN, LAMA_TEKAN, Tween.TRANS_QUAD))
	b.button_up.connect(func() -> void: _ke(b, 1.0, LAMA_LEPAS, Tween.TRANS_BACK))


static func _ke(b: Control, skala: float, lama: float, trans: Tween.TransitionType) -> void:
	if not b.is_inside_tree():
		return
	b.pivot_offset = b.size / 2.0
	var lama_tween: Tween = b.get_meta("_tween_tekan") if b.has_meta("_tween_tekan") else null
	if lama_tween and lama_tween.is_valid():
		lama_tween.kill()
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2(skala, skala), lama).set_trans(trans).set_ease(Tween.EASE_OUT)
	b.set_meta("_tween_tekan", t)
