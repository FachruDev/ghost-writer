extends Lembar
## Lembar "Pilih Saluran" (papan 10): semua saluran yang eranya sudah terbuka, dengan biaya,
## cakupan, pengali panas, dan status terkunci (pengikut kurang / razia hoaks / server down).

var _daftar: VBoxContainer
var _pakai: Button
var _pilihan := "merpati"
var _dipakai := "merpati"


func _init() -> void:
	aksen = Palet.PINK


func _bangun_isi() -> void:
	judul.text = tr("UI_PILIH_SALURAN")
	_daftar = UiKit.kolom(isi, 14)
	_pakai = UiKit.tombol_utama(isi, "")
	_pakai.pressed.connect(func() -> void:
		Events.saluran_dipilih.emit(_pilihan)
		tutup())
	Events.layar_diminta.connect(func(nama: String) -> void:
		if nama == "saluran":
			_pilihan = _dipakai
			buka())
	Events.saluran_dipilih.connect(func(id: String) -> void: _dipakai = id)
	Events.kepemilikan_berubah.connect(func() -> void:
		if visible:
			_segarkan())


func _segarkan() -> void:
	judul.text = tr("UI_PILIH_SALURAN")
	for anak in _daftar.get_children():
		_daftar.remove_child(anak)
		anak.queue_free()
	for s in DataDB.saluran():
		if GameState.era_terbuka(s):
			_baris(s)
	var nama := Bahasa.teks(DataDB.get_upgrade(_pilihan).get("nama", ""))
	_pakai.text = tr("UI_PAKAI") % nama.to_upper()
	_pakai.disabled = not GameState.saluran_terbuka(_pilihan)


func _baris(s: Dictionary) -> void:
	var id := str(s["id"])
	var terbuka := GameState.saluran_terbuka(id)
	var dipilih := id == _pilihan
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 132)
	b.disabled = not terbuka
	b.tooltip_text = Bahasa.teks(s.get("nama", ""))
	var gaya := Palet.kotak(Palet.PANEL_2 if dipilih else Palet.MALAM, Palet.PINK if dipilih else Color.TRANSPARENT, 32)
	if not terbuka:
		gaya = Palet.kotak(Color.TRANSPARENT, Palet.GARIS, 32)
	for nama in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(nama, gaya)
	var fokus := Palet.kotak(Color.TRANSPARENT, Palet.KUNING, 32)
	fokus.draw_center = false
	b.add_theme_stylebox_override("focus", fokus)
	b.pressed.connect(func() -> void:
		_pilihan = id
		_segarkan())
	_daftar.add_child(b)
	var isi_baris := UiKit.baris(null, 16)
	isi_baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	isi_baris.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	b.add_child(isi_baris)
	var tile := PanelContainer.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.custom_minimum_size = Vector2(88, 88)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var warna: Color = Palet.saluran(id) if terbuka else Palet.GARIS
	tile.add_theme_stylebox_override("panel", Palet.kotak(warna, Color.TRANSPARENT, 24))
	isi_baris.add_child(tile)
	UiKit.ikon(tile, id, 44, Palet.TINTA)
	var tengah := UiKit.kolom(isi_baris, 4)
	tengah.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tengah.alignment = BoxContainer.ALIGNMENT_CENTER
	var atas := UiKit.baris(tengah, 10)
	UiKit.label(atas, 30, Palet.TEKS if terbuka else Palet.TEKS_REDUP, Tema.font_ui(700), Bahasa.teks(s.get("nama", "")))
	var tag := _tag(s, terbuka)
	if not tag.is_empty():
		var p := UiKit.pil(atas, tag, Palet.PINK if not terbuka else Palet.PANEL_2, Palet.TINTA if not terbuka else Palet.CYAN, 18)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var info := UiKit.label(tengah, 22, Palet.TEKS_LEMBUT, Tema.font_ui(500), Bahasa.teks(s.get("info", "")))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var kanan := UiKit.kolom(isi_baris, 6)
	kanan.alignment = BoxContainer.ALIGNMENT_CENTER
	var biaya := int(s.get("biaya_kirim", 0))
	var harga := UiKit.pil(kanan, tr("UI_GRATIS") if biaya == 0 else Bahasa.angka(biaya),
		Palet.HIJAU if biaya == 0 else Palet.KUNING, Palet.TINTA, 24)
	harga.size_flags_horizontal = Control.SIZE_SHRINK_END
	var panas := UiKit.label(kanan, 20, Color("ff8f6b"), Tema.font_ui(700),
		tr("UI_PANAS_KALI") % _desimal(float(s.get("pengali_heat", 1.0))))
	panas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _tag(s: Dictionary, terbuka: bool) -> String:
	var id := str(s["id"])
	if GameState.saluran_terkunci.has(id):
		return tr("UI_DIKUNCI") % ("%ds" % ceili(float(GameState.saluran_terkunci[id])))
	if not terbuka:
		return tr("UI_SYARAT_PENGIKUT") % [Bahasa.angka(GameState.pengikut), Bahasa.angka(int(s.get("pengikut_min", 0)))]
	if s.has("siaran_detik"):
		return tr("UI_SIARAN") % [tr("UI_SIARAN_TAG"), int(s["siaran_detik"])]
	return ""


func _desimal(x: float) -> String:
	var t := "%.1f" % x
	return t.replace(".", ",") if Bahasa.kode() == "id" else t
