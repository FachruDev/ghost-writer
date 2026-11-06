extends PanelContainer
## Mesin tik: pilih template, isi slot dari kartu, pilih saluran dan distrik, lalu KIRIM.

const CHANNEL_PICKER := preload("res://scenes/desk/channel_picker.tscn")

var _template_ids: Array[String] = []
var _idx := 0
var _isi: Dictionary = {}  # slot -> kata_id
var _target := ""
var _saluran := "merpati"
var _rumor_aktif := false
var _mengetik := false
var _tombol_slot: Dictionary = {}  # slot -> Button

var _label_template: Label
var _label_headline: Label
var _baris_slot: HBoxContainer
var _label_target: Label
var _tombol_kirim: Button
var _label_skor: Label


func _ready() -> void:
	_bangun_ui()
	_warnai_era(GameState.era)
	Events.kepemilikan_berubah.connect(_on_kepemilikan)
	Events.kartu_dipilih.connect(_on_kartu)
	Events.kartu_terbang.connect(_terbangkan_kartu)
	Events.distrik_dipilih.connect(_on_distrik)
	Events.saluran_dipilih.connect(func(id: String) -> void:
		_saluran = id
		_segarkan())
	Events.money_changed.connect(func(_u: int) -> void: _segarkan())
	Events.era_berubah.connect(_warnai_era)
	Events.rumor_published.connect(_on_rumor_published)
	Events.rumor_selesai.connect(_on_rumor_selesai)
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void:
		_mengetik = false
		_label_headline.visible_ratio = 1.0
		_segarkan())
	_on_kepemilikan()


func _template_id() -> String:
	return _template_ids[_idx] if _idx < _template_ids.size() else ""


func _slot_template() -> Array:
	return DataDB.get_template(_template_id()).get("slot", [])


## Latar meja per era (sementara warna polos; art kantor menyusul dari desain UI).
func _warnai_era(era: int) -> void:
	add_theme_stylebox_override("panel", Palet.kotak(Palet.MEJA_ERA.get(era, Palet.PANEL), Color.TRANSPARENT, 6))


func _semua_distrik() -> bool:
	return str(DataDB.get_upgrade(_saluran).get("cakupan", "satu")) in ["semua", "siaran", "jaringan"]


func _siap_kirim() -> bool:
	var biaya := int(DataDB.get_upgrade(_saluran).get("biaya_kirim", 0))
	return _lengkap() and (_semua_distrik() or not _target.is_empty()) 		and not _rumor_aktif and GameState.uang >= biaya and GameState.saluran_terbuka(_saluran)


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
	else:
		Events.aksi_gagal.emit()


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
	Events.template_diganti.emit()
	for slot in _isi.keys():
		if not (slot in _slot_template()):
			_isi.erase(slot)
	_segarkan()


func _kirim() -> void:
	if not _siap_kirim():
		return
	Events.kirim_diminta.emit({
		"template_id": _template_id(),
		"kata_ids": _isi.duplicate(),
		"distrik_id": "" if _semua_distrik() else _target,
		"saluran_id": _saluran,
	})
	_ketik(_label_headline.text)
	_isi.clear()
	_segarkan()


func _segarkan() -> void:
	_label_template.text = tr("UI_TEMPLATE") % [_idx + 1, _template_ids.size()]
	if not _mengetik:
		_tulis_headline(HeadlineBuilder.susun(_template_id(), _isi))
	for anak in _baris_slot.get_children():
		anak.queue_free()
	_tombol_slot.clear()
	for slot in _slot_template():
		var tombol := _tombol(_teks_slot(str(slot)))
		_tombol_slot[slot] = tombol
		tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tombol.clip_text = true
		tombol.pressed.connect(func() -> void:
			_isi.erase(slot)
			_segarkan())
		_baris_slot.add_child(tombol)
	if _semua_distrik():
		_label_target.text = tr("UI_SEMUA_DISTRIK")
	elif _target.is_empty():
		_label_target.text = tr("UI_PILIH_DISTRIK")
	else:
		_label_target.text = tr("UI_TARGET") % Bahasa.teks(DataDB.get_district(_target).get("nama", ""))
	_tombol_kirim.disabled = not _siap_kirim()
	_label_skor.text = _teks_skor()


## Animasi mesin tik: headline yang dikirim muncul huruf demi huruf, lalu kembali ke pratinjau.
func _ketik(teks: String) -> void:
	_mengetik = true
	_tulis_headline(teks)
	_label_headline.visible_ratio = 0.0
	var t := create_tween()
	var durasi := 0.03 * teks.length()
	Events.headline_diketik.emit(durasi)
	t.tween_property(_label_headline, "visible_ratio", 1.0, durasi)
	t.tween_interval(1.0)
	t.tween_callback(func() -> void:
		_mengetik = false
		_segarkan())


## Animasi kartu terbang ke slotnya.
func _terbangkan_kartu(kata_id: String, dari: Vector2) -> void:
	var slot := str(DataDB.get_word(kata_id).get("slot", ""))
	if not (slot in _slot_template()):
		return
	await get_tree().process_frame
	var tujuan: Button = _tombol_slot.get(slot)
	if tujuan == null:
		return
	var hantu := Label.new()
	hantu.top_level = true
	hantu.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hantu.text = Bahasa.teks(DataDB.get_word(kata_id).get("text", ""))
	hantu.add_theme_color_override("font_color", Palet.emosi(str(DataDB.get_word(kata_id).get("emosi", ""))))
	add_child(hantu)
	hantu.global_position = dari - hantu.size / 2.0
	tujuan.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(hantu, "global_position", tujuan.global_position + tujuan.size / 2.0 - hantu.size / 2.0, 0.25) 		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(hantu.queue_free)
	t.tween_property(tujuan, "modulate:a", 1.0, 0.1)


## Headline panjang (era 3-4) dikecilkan supaya muat di meja.
func _tulis_headline(teks: String) -> void:
	_label_headline.text = teks
	var ukuran := 28 if teks.length() <= 70 else (24 if teks.length() <= 100 else 20)
	_label_headline.add_theme_font_size_override("font_size", ukuran)


func _teks_slot(slot: String) -> String:
	if _isi.has(slot):
		return Bahasa.teks(DataDB.get_word(_isi[slot]).get("text", ""))
	return "[%s]" % HeadlineBuilder.nama_slot(slot)


func _teks_skor() -> String:
	if _rumor_aktif:
		return tr("UI_MENYEBAR")
	if not _lengkap() or (_target.is_empty() and not _semua_distrik()):
		return ""
	var kata_by_slot := {}
	for slot in _isi:
		kata_by_slot[slot] = DataDB.get_word(_isi[slot])
	var skor := RumorScorer.nilai(DataDB.get_template(_template_id()), kata_by_slot, DataDB.districts, GameState.kredibilitas)
	var idx := 0 if _semua_distrik() else DataDB.district_index(_target)
	var viral: float = skor["viral_per_distrik"][idx]
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
	kotak.add_child(CHANNEL_PICKER.instantiate())
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
