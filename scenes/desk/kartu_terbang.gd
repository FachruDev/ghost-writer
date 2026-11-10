class_name KartuTerbang
## anim_card_to_slot: pil kata terbang dari kartu yang diketuk ke chip slotnya di kertas headline.
## Dipindah dari desk.gd supaya meja tetap di bawah batas ±300 baris.

const LAMA := 0.25


static func terbangkan(induk: Control, kertas: KertasHeadline, kata_id: String, dari: Vector2) -> void:
	await induk.get_tree().process_frame
	var kata := DataDB.get_word(kata_id)
	var tujuan := kertas.chip(str(kata.get("slot", "")))
	if tujuan == null or not is_instance_valid(tujuan):
		return
	var pil := UiKit.pil(null, Bahasa.teks(kata.get("text", "")), Palet.emosi(str(kata.get("emosi", ""))), Palet.TINTA, 22)
	pil.top_level = true
	induk.add_child(pil)
	pil.reset_size()
	pil.global_position = dari - pil.size / 2.0
	tujuan.modulate.a = 0.0
	var t := induk.create_tween()
	t.tween_property(pil, "global_position", tujuan.global_position + tujuan.size / 2.0 - pil.size / 2.0, LAMA) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(pil.queue_free)
	t.tween_property(tujuan, "modulate:a", 1.0, 0.1)
