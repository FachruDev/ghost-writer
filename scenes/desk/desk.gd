extends PanelContainer
## Meja redaksi (papan 02/09): kertas headline, tangan kartu untuk slot aktif, lalu tombol saluran
## dan KIRIM!. Menyimpan isi slot, target distrik, dan saluran pilihan.

const HAND := preload("res://scenes/hand/hand.tscn")

var _template_ids: Array[String] = []
var _idx := 0
var _isi: Dictionary = {}  # slot -> kata_id
var _slot_aktif := ""
var _target := ""
var _saluran := "merpati"
var _rumor_aktif := false
var _mengetik := false

var _kertas: KertasHeadline
var _judul_tangan: Label
var _petunjuk: Label
var _tangan: Control
var _tombol_saluran: Button
var _saluran_ikon: TextureRect
var _saluran_tile: PanelContainer
var _saluran_nama: Label
var _saluran_info: Label
var _tombol_kirim: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_bangun_ui()
	Events.kepemilikan_berubah.connect(_on_kepemilikan)
	Events.kartu_dipilih.connect(_on_kartu)
	Events.kartu_terbang.connect(_terbangkan_kartu)
	Events.distrik_dipilih.connect(func(id: String) -> void:
		_target = id
		_segarkan())
	Events.saluran_dipilih.connect(func(id: String) -> void:
		_saluran = id
		_segarkan())
	Events.money_changed.connect(func(_u: int) -> void: _segarkan_tombol())
	Events.pengikut_berubah.connect(func(_p: int) -> void: _segarkan_tombol())
	Events.rumor_published.connect(func(_i: Dictionary) -> void:
		_rumor_aktif = true
		_segarkan_tombol())
	Events.rumor_selesai.connect(func(_h: Dictionary) -> void:
		_rumor_aktif = false
		_segarkan_tombol())
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void: _segarkan())
	_on_kepemilikan()


func _bangun_ui() -> void:
	var kolom := UiKit.kolom(self, 0)
	var m := UiKit.margin(kolom, 24, -36, 24, 0)
	_kertas = KertasHeadline.new()
	m.add_child(_kertas)
	_kertas.slot_ditekan.connect(func(slot: String) -> void:
		_slot_aktif = slot
		Events.slot_aktif.emit(slot)
		_segarkan())
	_kertas.template_digeser.connect(_ganti_template)
	_kertas.ketik_selesai.connect(func() -> void:
		_mengetik = false
		_segarkan())
	var judul := UiKit.margin(kolom, 28, 14, 28, 0)
	var baris := UiKit.baris(judul, 12)
	_judul_tangan = UiKit.label(baris, 26, Palet.TEKS, Tema.font_ui(700))
	_judul_tangan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_petunjuk = UiKit.label(baris, 22, Palet.TEKS_REDUP, Tema.font_ui(500))
	_tangan = HAND.instantiate()
	kolom.add_child(_tangan)
	_bangun_kaki(kolom)


func _bangun_kaki(induk: Control) -> void:
	var kaki := PanelContainer.new()
	var gaya := Palet.kotak(Color("221c40"), Color.TRANSPARENT, 44)
	gaya.corner_radius_bottom_left = 0
	gaya.corner_radius_bottom_right = 0
	gaya.content_margin_left = 24
	gaya.content_margin_right = 24
	gaya.content_margin_top = 16
	gaya.content_margin_bottom = 24.0 + UiKit.inset_aman(self).y
	kaki.add_theme_stylebox_override("panel", gaya)
	induk.add_child(kaki)
	var baris := UiKit.baris(kaki, 16)
	_tombol_saluran = Button.new()
	_tombol_saluran.custom_minimum_size = Vector2(236, 108)
	_tombol_saluran.tooltip_text = tr("UI_PILIH_SALURAN")
	Palet.gaya_tombol(_tombol_saluran, Palet.PANEL_2, Palet.PANEL, Palet.TEKS, 28)
	_tombol_saluran.pressed.connect(func() -> void: Events.layar_diminta.emit("saluran"))
	baris.add_child(_tombol_saluran)
	var isi := UiKit.baris(null, 12)
	isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	_tombol_saluran.add_child(isi)
	_saluran_tile = PanelContainer.new()
	_saluran_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_saluran_tile.custom_minimum_size = Vector2(60, 60)
	_saluran_tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	isi.add_child(_saluran_tile)
	_saluran_ikon = UiKit.ikon(_saluran_tile, "merpati", 36, Palet.TINTA)
	var teks := UiKit.kolom(isi, 0)
	teks.alignment = BoxContainer.ALIGNMENT_CENTER
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_saluran_nama = UiKit.label(teks, 26, Palet.TEKS, Tema.font_ui(700))
	_saluran_info = UiKit.label(teks, 20, Palet.TEKS_REDUP, Tema.font_ui(600))
	_tombol_kirim = UiKit.tombol_utama(baris, tr("UI_KIRIM_SERU"))
	_tombol_kirim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_kirim.pressed.connect(_kirim)


func _template_id() -> String:
	return _template_ids[_idx] if _idx < _template_ids.size() else ""


func _slot_template() -> Array:
	return DataDB.get_template(_template_id()).get("slot", [])


func _semua_distrik() -> bool:
	return str(DataDB.get_upgrade(_saluran).get("cakupan", "satu")) in ["semua", "siaran", "jaringan"]


func _siap_kirim() -> bool:
	var biaya := int(DataDB.get_upgrade(_saluran).get("biaya_kirim", 0))
	return _lengkap() and (_semua_distrik() or not _target.is_empty()) \
		and not _rumor_aktif and GameState.uang >= biaya and GameState.saluran_terbuka(_saluran)


func _lengkap() -> bool:
	for slot in _slot_template():
		if not _isi.has(slot):
			return false
	return not _slot_template().is_empty()


func _on_kepemilikan() -> void:
	var lama := _template_id()
	_template_ids = GameState.template_dimiliki.duplicate()
	_idx = maxi(_template_ids.find(lama), 0)
	# Kartu sementara yang habis atau kartu event yang hilang dilepas dari slot.
	for slot in _isi.keys():
		if not GameState.punya_kata(str(_isi[slot])):
			_isi.erase(slot)
	if not GameState.saluran_terbuka(_saluran) and not GameState.saluran_terkunci.has(_saluran):
		_saluran = "merpati"
	_segarkan()


## Kartu ditekan: pasang di slotnya; kartu yang sudah terpasang dilepas lagi.
func _on_kartu(kata_id: String) -> void:
	var slot := str(DataDB.get_word(kata_id).get("slot", ""))
	if not (slot in _slot_template()):
		Events.aksi_gagal.emit()
		return
	if _isi.get(slot, "") == kata_id:
		_isi.erase(slot)
		_slot_aktif = slot
	else:
		_isi[slot] = kata_id
		_slot_aktif = _slot_kosong_berikut(slot)
	_segarkan()


func _slot_kosong_berikut(dari: String) -> String:
	var urut := _slot_template()
	var mulai := urut.find(dari)
	for k in urut.size():
		var s := str(urut[(mulai + 1 + k) % urut.size()])
		if not _isi.has(s):
			return s
	return dari


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
	var teks := HeadlineBuilder.susun(_template_id(), _isi)
	var durasi := 0.03 * teks.length()
	Events.headline_diketik.emit(durasi)
	_mengetik = true
	_kertas.ketik(teks, durasi)
	_isi.clear()
	_slot_aktif = ""
	_segarkan()


func _segarkan() -> void:
	var slots := _slot_template()
	if _slot_aktif.is_empty() or not (_slot_aktif in slots):
		_slot_aktif = str(slots[0]) if not slots.is_empty() else ""
		for s in slots:
			if not _isi.has(s):
				_slot_aktif = str(s)
				break
	if not _mengetik:
		_kertas.tampilkan(_template_id(), _isi, _slot_aktif, _idx, _template_ids.size())
	_segarkan_skor()
	var judul_tangan := tr("UI_KARTU_SLOT") % HeadlineBuilder.nama_slot(_slot_aktif).to_lower()
	_judul_tangan.text = judul_tangan.substr(0, 1).to_upper() + judul_tangan.substr(1)
	_petunjuk.text = tr("UI_KARTU_PETUNJUK") + " · ›"
	_tombol_saluran.tooltip_text = tr("UI_PILIH_SALURAN")
	_tangan.tampilkan(_slot_aktif, str(_isi.get(_slot_aktif, "")))
	_segarkan_saluran()
	_segarkan_tombol()


func _segarkan_skor() -> void:
	if _isi.is_empty():
		_kertas.atur_skor("", 0.0, 1.0, 0.0, false)
		return
	var kata_by_slot := {}
	for slot in _isi:
		kata_by_slot[slot] = DataDB.get_word(_isi[slot])
	var skor := RumorScorer.nilai(DataDB.get_template(_template_id()), kata_by_slot, DataDB.districts, GameState.kredibilitas)
	var idx := 0 if _semua_distrik() or _target.is_empty() else maxi(DataDB.district_index(_target), 0)
	var viral: float = skor["viral_per_distrik"][idx] if idx < skor["viral_per_distrik"].size() else 0.0
	var heboh := float(skor["heboh_total"])
	_kertas.atur_skor(str(skor["emosi"]), viral, viral / heboh if heboh > 0.0 else 1.0, float(skor["dipercaya_akhir"]), true)


func _segarkan_saluran() -> void:
	var s := DataDB.get_upgrade(_saluran)
	var warna := Palet.saluran(_saluran)
	_saluran_tile.add_theme_stylebox_override("panel", Palet.kotak(warna, Color.TRANSPARENT, 18))
	_saluran_ikon.texture = UiKit.muat_ikon(_saluran)
	_saluran_nama.text = Bahasa.teks(s.get("nama", ""))
	var biaya := int(s.get("biaya_kirim", 0))
	_saluran_info.text = "%s · %s ▴" % [tr("UI_GRATIS") if biaya == 0 else Bahasa.angka(biaya), tr("UI_GANTI")]
	(_tombol_saluran.get_theme_stylebox("normal") as StyleBoxFlat).border_color = warna.darkened(0.3)


func _segarkan_tombol() -> void:
	var siap := _siap_kirim()
	_tombol_kirim.disabled = not siap
	if siap:
		_tombol_kirim.text = tr("UI_KIRIM_SERU")
		_tombol_kirim.add_theme_font_override("font", Tema.font_judul())
		_tombol_kirim.add_theme_font_size_override("font_size", 48)
		return
	_tombol_kirim.add_theme_font_override("font", Tema.font_ui(700))
	_tombol_kirim.add_theme_font_size_override("font_size", 24)
	var kurang := 0
	for slot in _slot_template():
		if not _isi.has(slot):
			kurang += 1
	if _rumor_aktif:
		_tombol_kirim.text = tr("UI_MENYEBAR")
	elif kurang > 0:
		_tombol_kirim.text = tr("UI_ISI_SLOT") % kurang
	elif not _semua_distrik() and _target.is_empty():
		_tombol_kirim.text = tr("UI_PILIH_DISTRIK")
	elif not GameState.saluran_terbuka(_saluran):
		_tombol_kirim.text = tr("UI_DIKUNCI") % Bahasa.teks(DataDB.get_upgrade(_saluran).get("nama", ""))
	else:
		_tombol_kirim.text = tr("UI_BIAYA") % Bahasa.angka(int(DataDB.get_upgrade(_saluran).get("biaya_kirim", 0)))


## Animasi kartu terbang ke chip slotnya di kertas.
func _terbangkan_kartu(kata_id: String, dari: Vector2) -> void:
	await get_tree().process_frame
	var slot := str(DataDB.get_word(kata_id).get("slot", ""))
	var tujuan := _kertas.chip(slot)
	if tujuan == null or not is_instance_valid(tujuan):
		return
	var hantu := UiKit.pil(null, Bahasa.teks(DataDB.get_word(kata_id).get("text", "")),
		Palet.emosi(str(DataDB.get_word(kata_id).get("emosi", ""))), Palet.TINTA, 22)
	hantu.top_level = true
	add_child(hantu)
	hantu.reset_size()
	hantu.global_position = dari - hantu.size / 2.0
	tujuan.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(hantu, "global_position", tujuan.global_position + tujuan.size / 2.0 - hantu.size / 2.0, 0.25) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(hantu.queue_free)
	t.tween_property(tujuan, "modulate:a", 1.0, 0.1)
