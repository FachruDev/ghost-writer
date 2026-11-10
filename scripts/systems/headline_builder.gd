class_name HeadlineBuilder
extends RefCounted
## Menyusun headline dari template_id + kata_ids dalam bahasa aktif (ADR-0004).
## Slot yang belum terisi tampil sebagai [NAMA SLOT].
##
## Autoload diambil saat dipanggil (bukan lewat nama global) supaya class ini tetap
## bisa dikompilasi oleh runner tes headless yang memuat script sebelum autoload terdaftar.


static func susun(template_id: String, kata_ids: Dictionary) -> String:
	var db := _autoload(&"DataDB")
	var bahasa := _autoload(&"Bahasa")
	var template: Dictionary = db.get_template(template_id)
	if template.is_empty():
		return ""
	var isi := {}
	for slot in template.get("slot", []):
		var kata_id := str(kata_ids.get(slot, ""))
		if kata_id.is_empty():
			isi[slot] = "[%s]" % nama_slot(str(slot))
		else:
			isi[slot] = bahasa.teks(db.get_word(kata_id).get("text", ""))
	return _kapital(str(bahasa.teks(template.get("pola", ""))).format(isi))


static func nama_slot(slot: String) -> String:
	return str(TranslationServer.translate("UI_SLOT_" + slot.to_upper()))


static func _autoload(nama: StringName) -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node(NodePath(nama))


## Huruf pertama setiap kalimat jadi kapital (awal teks, dan setelah ". ", "! ", "? ").
static func _kapital(s: String) -> String:
	var hasil := ""
	var awal_kalimat := true
	for i in s.length():
		var c := s[i]
		if awal_kalimat and c != " ":
			hasil += c.to_upper()
			awal_kalimat = false
		else:
			hasil += c
		if c in [".", "!", "?"] and i + 1 < s.length() and s[i + 1] == " ":
			awal_kalimat = true
	return hasil
