extends Lembar
## Lembar pilihan (papan 12 Dilema, 13 Tawaran Kontrak): waktu sudah dijeda oleh pengendalinya.
## Dilema: dua kartu pilihan dengan chip efek. Kontrak: progres 2 distrik, hadiah & hukuman,
## lalu Tolak / TERIMA. Pilihan -> Events.dilema_dipilih(indeks).

var _info: Dictionary = {}
var _jeda: PanelContainer
var _tile: PanelContainer
var _ikon: TextureRect
var _tag: PanelContainer
var _teks: Label
var _khusus: VBoxContainer
var _pilihan: GridContainer


func _init() -> void:
	bisa_ditutup = false
	aksen = Palet.KUNING


func _bangun_isi() -> void:
	_jeda = UiKit.pil(null, tr("UI_WAKTU_DIJEDA"), Palet.TEKS, Palet.TINTA, 20)
	judul.get_parent().get_parent().add_child(_jeda)
	judul.get_parent().get_parent().move_child(_jeda, 1)
	_jeda.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var h := UiKit.baris(isi, 20)
	_tile = PanelContainer.new()
	_tile.custom_minimum_size = Vector2(150, 150)
	h.add_child(_tile)
	_ikon = UiKit.ikon(_tile, "kaca_pembesar", 84, Palet.TINTA)
	var k := UiKit.kolom(h, 10)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.alignment = BoxContainer.ALIGNMENT_CENTER
	_tag = UiKit.pil(k, "", Palet.KUNING, Palet.TINTA, 20)
	_tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_teks = UiKit.label(k, 26, Palet.TEKS_LEMBUT, Tema.font_ui(500))
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_khusus = UiKit.kolom(isi, 12)
	_pilihan = GridContainer.new()
	_pilihan.columns = 2
	_pilihan.add_theme_constant_override("h_separation", 20)
	_pilihan.add_theme_constant_override("v_separation", 20)
	isi.add_child(_pilihan)
	Events.event_mulai.connect(_on_event)
	Events.event_tampil.connect(_on_event)
	Events.event_selesai.connect(func(_id: String) -> void: tutup())


func _on_event(info: Dictionary) -> void:
	if info.get("pilihan", []).is_empty():
		return
	_info = info
	buka()


func _kontrak() -> bool:
	return str(_info.get("id", "")) == "kontrak"


func _segarkan() -> void:
	var kontrak := _kontrak()
	var warna := Palet.CYAN if kontrak else Palet.KUNING
	var bayang := Palet.CYAN_GELAP if kontrak else Palet.KUNING_GELAP
	(_panel.get_theme_stylebox("panel") as StyleBoxFlat).border_color = warna
	(_panel.get_theme_stylebox("panel") as StyleBoxFlat).border_width_top = 8
	_tile.add_theme_stylebox_override("panel", Palet.tebal(warna, bayang, 44, 14))
	_ikon.texture = UiKit.muat_ikon(_ikon_event())
	(_jeda.get_child(0) as Label).text = tr("UI_WAKTU_DIJEDA")
	(_tag.get_child(0) as Label).text = tr("UI_KONTRAK_TAG") if kontrak else tr("UI_DILEMA")
	(_tag.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = warna
	judul.text = Bahasa.teks(_info.get("nama", "")).to_upper()
	_teks.text = Bahasa.teks(_info.get("teks", ""))
	for anak in _khusus.get_children() + _pilihan.get_children():
		anak.get_parent().remove_child(anak)
		anak.queue_free()
	if kontrak:
		_isi_kontrak()
	else:
		_isi_dilema()


func _ikon_event() -> String:
	match str(_info.get("id", "")):
		"kontrak":
			return "orang"
		"e_wartawan":
			return "kaca_pembesar"
		"e_server_down":
			return "server"
	return "marah"


func _isi_dilema() -> void:
	var data := _event_data()
	var opsi: Array = data.get("pilihan", [])
	var label: Array = _info.get("pilihan", [])
	for i in label.size():
		var efek: Array = opsi[i].get("efek", []) if i < opsi.size() else []
		_kartu_pilihan(i, Bahasa.teks(label[i]), efek)


func _kartu_pilihan(i: int, teks: String, efek: Array) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 210)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Palet.gaya_tombol(b, Palet.MALAM, Color("120e26"), Palet.TEKS, 36)
	b.pressed.connect(_pilih.bind(i))
	_pilihan.add_child(b)
	var k := UiKit.kolom(null, 16)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k.alignment = BoxContainer.ALIGNMENT_CENTER
	k.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	b.add_child(k)
	var l := UiKit.label(k, 30, Palet.TEKS, Tema.font_ui(700), teks)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var chip := HFlowContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.alignment = FlowContainer.ALIGNMENT_CENTER
	chip.add_theme_constant_override("h_separation", 8)
	chip.add_theme_constant_override("v_separation", 8)
	k.add_child(chip)
	for e in efek:
		var t := _teks_efek(e)
		UiKit.pil(chip, t[0], Palet.HIJAU if t[1] else Palet.PINK, Palet.TINTA, 20)


## [teks, baik?] untuk satu efek dilema.
func _teks_efek(e: Dictionary) -> Array:
	var n := int(e.get("nilai", 0))
	var tanda := ("+" if n > 0 else "−") + Bahasa.angka(absi(n))
	match str(e.get("tipe", "")):
		"uang":
			return [tr("UI_EFEK_UANG") % tanda, n > 0]
		"heat":
			return [tr("UI_EFEK_HEAT") % tanda, n < 0]
		"pengikut":
			return [tr("UI_EFEK_PENGIKUT") % tanda, n > 0]
		"kredibilitas":
			return [tr("UI_EFEK_KRED") % tanda, n > 0]
		"kunci_saluran":
			var id := str(e.get("saluran", ""))
			return [tr("UI_EFEK_KUNCI") % [Bahasa.teks(DataDB.get_upgrade(id).get("nama", id)), int(e.get("detik", 0))], false]
	return [str(e.get("tipe", "")), false]


func _isi_kontrak() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	_khusus.add_child(grid)
	var d: Array = _info.get("distrik", [])
	var p: Array = _info.get("persen", [0.0, 0.0])
	for k in d.size():
		var i := int(d[k])
		if i >= DataDB.districts.size():
			continue
		var data: Dictionary = DataDB.districts[i]
		var kotak := UiKit.panel(grid, Palet.MALAM, 28, 18)
		kotak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kol := UiKit.kolom(kotak, 8)
		var atas := UiKit.baris(kol, 8)
		var n := UiKit.label(atas, 26, Palet.TEKS, Tema.font_ui(700), Bahasa.teks(data.get("nama", "")))
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UiKit.label(atas, 26, Color("ff8fb3"), Tema.font_ui(700), "%d%%" % roundi(float(p[k]) * 100.0))
		var b := UiKit.bar(kol, Palet.PINK, 18, Palet.PANEL_2)
		b.max_value = 1.0
		b.value = float(p[k])
		UiKit.label(kol, 20, Palet.TEKS_REDUP, Tema.font_ui(500), tr("UI_TARGET_PERSEN") % roundi(Balance.KONTRAK_PERSEN * 100.0))
	var hadiah := HFlowContainer.new()
	hadiah.add_theme_constant_override("h_separation", 10)
	hadiah.add_theme_constant_override("v_separation", 10)
	_khusus.add_child(hadiah)
	UiKit.label(hadiah, 22, Palet.TEKS_REDUP, Tema.font_ui(600), tr("UI_BERHASIL"))
	UiKit.pil(hadiah, tr("UI_EFEK_UANG") % ("+" + Bahasa.angka(Balance.KONTRAK_UANG)), Palet.KUNING, Palet.TINTA, 22)
	UiKit.pil(hadiah, tr("UI_EFEK_PENGIKUT") % ("+" + str(Balance.KONTRAK_PENGIKUT)), Palet.CYAN, Palet.TINTA, 22)
	UiKit.label(hadiah, 22, Palet.TEKS_REDUP, Tema.font_ui(600), tr("UI_GAGAL"))
	UiKit.pil(hadiah, tr("UI_EFEK_KRED") % ("−" + str(roundi(Balance.KONTRAK_KRED_GAGAL))), Palet.PINK, Palet.TINTA, 22)
	var label: Array = _info.get("pilihan", [])
	# Urutan data: 0 = Terima, 1 = Tolak. Tampil: Tolak di kiri, TERIMA besar di kanan.
	var tolak := UiKit.tombol(_pilihan, Bahasa.teks(label[1]) if label.size() > 1 else tr("UI_TOLAK"), Palet.PANEL_2, Palet.MALAM, 28, Tema.font_ui(700))
	tolak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tolak.pressed.connect(_pilih.bind(1))
	var terima := UiKit.tombol_utama(_pilihan, Bahasa.teks(label[0]).to_upper() if label.size() > 0 else tr("UI_TERIMA"), Palet.CYAN, Palet.CYAN_GELAP, Palet.TINTA)
	terima.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	terima.pressed.connect(_pilih.bind(0))


func _event_data() -> Dictionary:
	for e in DataDB.events:
		if str(e.get("id", "")) == str(_info.get("id", "")):
			return e
	return {}


func _pilih(i: int) -> void:
	tutup()
	Events.dilema_dipilih.emit(i)
