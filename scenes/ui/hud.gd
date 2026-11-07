extends PanelContainer
## HUD (kanvas papan 02/09): tombol hantu (menu), era, uang & pengikut, toko; bar kredibilitas
## dan panas, cincin staf; strip utama (HudStrip: misi, tokoh, atau kampanye akhir) dan strip kontrak.


## Cincin hitung mundur staf, digambar sendiri.
class Cincin extends Control:
	var nilai := 0.0
	var warna := Palet.HIJAU

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		draw_arc(c, r, 0.0, TAU, 32, Palet.PANEL_2, 6.0)
		if nilai > 0.0:
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * nilai, 32, warna, 6.0)


var _era: Label
var _era_nama: Label
var _uang: Label
var _pengikut: Label
var _bar_kred: ProgressBar
var _angka_kred: Label
var _bar_panas: ProgressBar
var _angka_panas: Label
var _staf: PanelContainer
var _staf_label: Label
var _staf_cincin: Cincin
var _strip: HudStrip
var _kontrak: PanelContainer
var _kontrak_tag: Label
var _menu: Button
var _kontrak_teks: Label
var _kontrak_waktu: Label
var _info_final: Dictionary = {}
var _info_kontrak: Dictionary = {}


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var kolom := UiKit.kolom(self, 10)
	_baris_atas(kolom)
	_baris_meter(kolom)
	_bangun_strip(kolom)
	_bangun_kontrak(kolom)
	Events.money_changed.connect(func(_u: int) -> void: _segarkan())
	Events.pengikut_berubah.connect(func(_p: int) -> void: _segarkan())
	Events.reputasi_berubah.connect(_segarkan)
	Events.misi_berubah.connect(_segarkan)
	Events.tokoh_berubah.connect(_segarkan)
	Events.era_berubah.connect(func(_e: int) -> void: _segarkan())
	Events.final_berubah.connect(_segarkan)
	Events.final_data.connect(func(info: Dictionary) -> void:
		_info_final = info
		_segarkan_strip())
	Events.kontrak_progres.connect(func(info: Dictionary) -> void:
		_info_kontrak = info
		_segarkan_kontrak())
	Events.staf_hitung.connect(_on_staf)
	Events.kepemilikan_berubah.connect(func() -> void: _staf.visible = GameState.punya_upgrade(StaffController.UPGRADE_ID))
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _segarkan())
	_staf.visible = GameState.punya_upgrade(StaffController.UPGRADE_ID)
	_segarkan()


func _baris_atas(induk: Control) -> void:
	var baris := UiKit.baris(induk, 12)
	var menu := Button.new()
	_menu = menu
	menu.custom_minimum_size = Vector2(88, 88)
	menu.tooltip_text = tr("UI_MENU")
	Palet.gaya_tombol(menu, Palet.PANEL_2, Palet.PANEL)
	menu.pressed.connect(func() -> void: Events.layar_diminta.emit("pengaturan"))
	baris.add_child(menu)
	var hantu := Hantu.new()
	hantu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	menu.add_child(hantu)
	# Lencana kecil "menu" di pojok kanan bawah tombol hantu.
	var lencana := Panel.new()
	lencana.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lencana.add_theme_stylebox_override("panel", Palet.kotak(Palet.TEKS, Palet.MALAM, 999))
	lencana.position = Vector2(58, 58)
	lencana.size = Vector2(38, 38)
	menu.add_child(lencana)
	var garis := UiKit.ikon(lencana, "menu", 24, Palet.TINTA)
	garis.position = Vector2(7, 7)
	garis.size = Vector2(24, 24)
	var era := UiKit.kolom(baris, 0)
	era.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	era.alignment = BoxContainer.ALIGNMENT_CENTER
	_era = UiKit.label(era, 32, Palet.TEKS, Tema.font_judul())
	_era_nama = UiKit.label(era, 22, Palet.TEKS_REDUP, Tema.font_ui(600))
	_era_nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_uang = _pil_sumber(baris, Palet.KUNING, Palet.KUNING_GELAP, "")
	_pengikut = _pil_sumber(baris, Palet.CYAN, Palet.CYAN_GELAP, "orang")
	var toko := UiKit.tombol_ikon(baris, "toko", tr("UI_TOKO"), Palet.PINK, Palet.PINK_GELAP, Palet.TINTA)
	toko.pressed.connect(func() -> void: Events.toko_diminta.emit(true))


## Pil uang/pengikut: lingkaran berwarna (koin "R" atau ikon) + angka.
func _pil_sumber(induk: Control, warna: Color, bayang: Color, ikon_nama: String) -> Label:
	var pil := UiKit.panel(induk, Palet.PANEL, 999, 0)
	var gaya := pil.get_theme_stylebox("panel") as StyleBoxFlat
	gaya.content_margin_left = 8
	gaya.content_margin_right = 18
	pil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var isi := UiKit.baris(pil, 10)
	var koin := PanelContainer.new()
	koin.custom_minimum_size = Vector2(48, 48)
	koin.add_theme_stylebox_override("panel", Palet.tebal(warna, bayang, 999, 6))
	(koin.get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(4)
	isi.add_child(koin)
	if ikon_nama.is_empty():
		var r := UiKit.label(koin, 24, Palet.TINTA, Tema.font_ui(700), tr("UI_SIMBOL_UANG"))
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		UiKit.ikon(koin, ikon_nama, 28, Palet.TINTA)
	var angka := UiKit.label(isi, 28, Palet.TEKS, Tema.font_ui(700))
	angka.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return angka


func _baris_meter(induk: Control) -> void:
	var baris := UiKit.baris(induk, 20)
	var kred := _meter(baris, "perisai", Palet.CYAN)
	_bar_kred = kred[0]
	_angka_kred = kred[1]
	var panas := _meter(baris, "api", Palet.ORANYE)
	_bar_panas = panas[0]
	_angka_panas = panas[1]
	_staf = UiKit.panel(baris, Palet.PANEL, 999, 0)
	var gaya := _staf.get_theme_stylebox("panel") as StyleBoxFlat
	gaya.content_margin_left = 6
	gaya.content_margin_right = 16
	var isi := UiKit.baris(_staf, 8)
	_staf_cincin = Cincin.new()
	_staf_cincin.custom_minimum_size = Vector2(40, 40)
	isi.add_child(_staf_cincin)
	_staf_label = UiKit.label(isi, 22, Palet.TEKS, Tema.font_ui(700))
	_staf_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _meter(induk: Control, ikon_nama: String, warna: Color) -> Array:
	var baris := UiKit.baris(induk, 10)
	baris.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.ikon(baris, ikon_nama, 30, warna)
	var b := UiKit.bar(baris, warna, 18)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var angka := UiKit.label(baris, 24, Palet.TEKS, Tema.font_ui(700))
	angka.custom_minimum_size = Vector2(40, 0)
	angka.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return [b, angka]


func _bangun_strip(induk: Control) -> void:
	_strip = HudStrip.new()
	induk.add_child(_strip)


func _bangun_kontrak(induk: Control) -> void:
	_kontrak = UiKit.panel(induk, Palet.PANEL, 20, 10)
	(_kontrak.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Palet.CYAN
	(_kontrak.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(3)
	var isi := UiKit.baris(_kontrak, 12)
	var tag := UiKit.pil(isi, tr("UI_KONTRAK_TAG"), Palet.CYAN)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_kontrak_tag = tag.get_child(0)
	_kontrak_teks = UiKit.label(isi, 24, Palet.TEKS, Tema.font_ui(600))
	_kontrak_teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kontrak_teks.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_kontrak_waktu = UiKit.label(isi, 24, Palet.TEKS, Tema.font_ui(700))
	_kontrak.visible = false


func _segarkan() -> void:
	_menu.tooltip_text = tr("UI_MENU")
	_kontrak_tag.text = tr("UI_KONTRAK_TAG")
	_era.text = tr("UI_ERA_PENDEK") % GameState.era
	_era_nama.text = tr("UI_ERA_NAMA_%d" % clampi(GameState.era, 1, 4))
	_uang.text = Bahasa.angka(GameState.uang)
	_pengikut.text = Bahasa.angka(GameState.pengikut)
	_bar_kred.value = GameState.kredibilitas
	_angka_kred.text = str(roundi(GameState.kredibilitas))
	_bar_panas.value = GameState.heat
	_angka_panas.text = str(roundi(GameState.heat))
	_angka_panas.add_theme_color_override("font_color", Palet.ORANYE if GameState.heat >= 70.0 else Palet.TEKS)
	_segarkan_strip()
	_segarkan_kontrak()


func _segarkan_strip() -> void:
	_strip.segarkan(_info_final)


func _segarkan_kontrak() -> void:
	_kontrak.visible = not _info_kontrak.is_empty()
	if _info_kontrak.is_empty():
		return
	var d: Array = _info_kontrak["distrik"]
	var p: Array = _info_kontrak["persen"]
	var nama := func(i: int) -> String: return Bahasa.teks(DataDB.districts[i].get("nama", "")) if i < DataDB.districts.size() else ""
	_kontrak_teks.text = "%s %d%% · %s %d%%" % [nama.call(d[0]), roundi(float(p[0]) * 100.0), nama.call(d[1]), roundi(float(p[1]) * 100.0)]
	var sisa := int(_info_kontrak["sisa"])
	_kontrak_waktu.text = "%d:%02d" % [sisa / 60, sisa % 60]


func _on_staf(sisa: float, jeda: float) -> void:
	_staf.visible = true
	if sisa < 0.0:
		_staf_label.text = tr("UI_STAF_MATI")
		_staf_cincin.warna = Palet.PINK
		_staf_cincin.nilai = 1.0
	else:
		_staf_label.text = tr("UI_STAF_HITUNG") % ceili(sisa)
		_staf_cincin.warna = Palet.HIJAU
		_staf_cincin.nilai = 1.0 - sisa / maxf(jeda, 0.001)
	_staf_cincin.queue_redraw()
