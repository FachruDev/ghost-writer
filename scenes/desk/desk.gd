extends PanelContainer
## Mesin tik: pilih template, isi slot dari kartu, pilih distrik, lalu KIRIM.

var _template_ids: Array[String] = []
var _idx := 0
var _isi: Dictionary = {}  # slot -> kata_id
var _target := ""
var _rumor_aktif := false

var _label_template: Label
var _label_headline: Label
var _baris_slot: HBoxContainer
var _label_target: Label
var _tombol_kirim: Button
var _label_skor: Label


func _ready() -> void:
	_bangun_ui()
	Events.kepemilikan_berubah.connect(_on_kepemilikan)
	Events.kartu_dipilih.connect(_on_kartu)
	Events.distrik_dipilih.connect(_on_distrik)
	Events.rumor_published.connect(_on_rumor_published)
	Events.rumor_selesai.connect(_on_rumor_selesai)
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void: _segarkan())
	_on_kepemilikan()


func _template_id() -> String:
	return _template_ids[_idx] if _idx < _template_ids.size() else ""


func _slot_template() -> Array:
	return DataDB.get_template(_template_id()).get("slot", [])


func _lengkap() -> bool:
	for slot in _slot_template():
		if not _isi.has(slot):
			return false
	return not _slot_template().is_empty()


func _on_kepemilikan() -> void:
	var lama := _template_id()
	_template_ids = GameState.template_dimiliki.duplicate()
	_idx = maxi(_template_ids.find(lama), 0)
	_segarkan()


func _on_kartu(kata_id: String) -> void:
	var slot := str(DataDB.get_word(kata_id).get("slot", ""))
	if slot in _slot_template():
		_isi[slot] = kata_id
		_segarkan()


func _on_distrik(distrik_id: String) -> void:
	_target = distrik_id
	_segarkan()


func _on_rumor_published(_info: Dictionary) -> void:
	_rumor_aktif = true
	_segarkan()


func _on_rumor_selesai(_hasil: Dictionary) -> void:
	_rumor_aktif = false
	_segarkan()


func _ganti_template(arah: int) -> void:
	if _template_ids.is_empty():
		return
	_idx = posmod(_idx + arah, _template_ids.size())
	for slot in _isi.keys():
		if not (slot in _slot_template()):
			_isi.erase(slot)
	_segarkan()


func _kirim() -> void:
	if not _lengkap() or _target.is_empty() or _rumor_aktif:
		return
	Events.kirim_diminta.emit({
		"template_id": _template_id(),
		"kata_ids": _isi.duplicate(),
		"distrik_id": _target,
	})
	_isi.clear()
	_segarkan()


func _segarkan() -> void:
	_label_template.text = tr("UI_TEMPLATE") % [_idx + 1, _template_ids.size()]
	_label_headline.text = HeadlineBuilder.susun(_template_id(), _isi)
	for anak in _baris_slot.get_children():
		anak.queue_free()
	for slot in _slot_template():
		var tombol := _tombol(_teks_slot(str(slot)))
		tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tombol.clip_text = true
		tombol.pressed.connect(func() -> void:
			_isi.erase(slot)
			_segarkan())
		_baris_slot.add_child(tombol)
	if _target.is_empty():
		_label_target.text = tr("UI_PILIH_DISTRIK")
	else:
		_label_target.text = tr("UI_TARGET") % Bahasa.teks(DataDB.get_district(_target).get("nama", ""))
	_tombol_kirim.disabled = not _lengkap() or _target.is_empty() or _rumor_aktif
	_label_skor.text = _teks_skor()


func _teks_slot(slot: String) -> String:
	if _isi.has(slot):
		return Bahasa.teks(DataDB.get_word(_isi[slot]).get("text", ""))
	return "[%s]" % HeadlineBuilder.nama_slot(slot)


func _teks_skor() -> String:
	if _rumor_aktif:
		return tr("UI_MENYEBAR")
	if not _lengkap() or _target.is_empty():
		return ""
	var kata_by_slot := {}
	for slot in _isi:
		kata_by_slot[slot] = DataDB.get_word(_isi[slot])
	var skor := RumorScorer.nilai(DataDB.get_template(_template_id()), kata_by_slot, DataDB.districts, GameState.kredibilitas)
	var viral: float = skor["viral_per_distrik"][DataDB.district_index(_target)]
	return tr("UI_DEBUG_SKOR") % [viral, roundi(float(skor["dipercaya_akhir"]) * 100.0)]


func _bangun_ui() -> void:
	var kotak := VBoxContainer.new()
	kotak.add_theme_constant_override("separation", 8)
	add_child(kotak)
	var baris_template := HBoxContainer.new()
	kotak.add_child(baris_template)
	var kiri := _tombol("◀")
	kiri.pressed.connect(_ganti_template.bind(-1))
	baris_template.add_child(kiri)
	_label_template = _label(baris_template)
	_label_template.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_template.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kanan := _tombol("▶")
	kanan.pressed.connect(_ganti_template.bind(1))
	baris_template.add_child(kanan)
	_label_headline = _label(kotak)
	_label_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_headline.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label_headline.add_theme_font_size_override("font_size", 28)
	_baris_slot = HBoxContainer.new()
	kotak.add_child(_baris_slot)
	var baris_kirim := HBoxContainer.new()
	kotak.add_child(baris_kirim)
	_label_target = _label(baris_kirim)
	_label_target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_kirim = Button.new()
	_tombol_kirim.text = "UI_KIRIM"
	_tombol_kirim.custom_minimum_size = Vector2(160, 56)
	Palet.gaya_tombol(_tombol_kirim, Palet.AKSEN)
	_tombol_kirim.pressed.connect(_kirim)
	baris_kirim.add_child(_tombol_kirim)
	_label_skor = _label(kotak)
	_label_skor.add_theme_color_override("font_color", Palet.TEKS_REDUP)
	_label_skor.add_theme_font_size_override("font_size", 18)


func _label(induk: Control) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	induk.add_child(l)
	return l


func _tombol(teks: String) -> Button:
	var b := Button.new()
	b.text = teks
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(56, 52)
	Palet.gaya_tombol(b, Palet.TEKS_REDUP)
	return b
