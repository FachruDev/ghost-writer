extends Lembar
## Toko layar penuh (papan 05): tab Kata (filter slot, kartu 2 kolom), Template, dan Kantor & staf
## (naik era + rekrut staf, dengan syarat pengikut). Lapisan di atas layar utama.
## Waktu permainan dijeda selama toko terbuka, jadi uang hanya berubah karena pembelian; daftar
## dibangun ulang paling banyak sekali per frame supaya tombol tidak berganti saat sedang ditekan.

const SLOT := ["", "subjek", "aksi", "tempat", "sumber"]

var _tab := "kata"
var _filter := ""
var _uang: Label
var _tombol_tab: Dictionary = {}
var _baris_filter: HFlowContainer
var _gulir: ScrollContainer
var _konten: Container
var _antre := false


func _init() -> void:
	penuh = true
	jeda = &"toko"


func _bangun_isi() -> void:
	var pil := UiKit.panel(null, Palet.PANEL, 999, 0)
	var gaya := pil.get_theme_stylebox("panel") as StyleBoxFlat
	gaya.content_margin_left = 8
	gaya.content_margin_right = 20
	var h := UiKit.baris(pil, 10)
	var koin := PanelContainer.new()
	koin.custom_minimum_size = Vector2(52, 52)
	koin.add_theme_stylebox_override("panel", Palet.tebal(Palet.KUNING, Palet.KUNING_GELAP, 999, 6))
	h.add_child(koin)
	var r := UiKit.label(koin, 24, Palet.TINTA, Tema.font_ui(700), tr("UI_SIMBOL_UANG"))
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_uang = UiKit.label(h, 30, Palet.TEKS, Tema.font_ui(700))
	_uang.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	judul.get_parent().add_child(pil)
	judul.get_parent().move_child(pil, 1)
	pil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tab := UiKit.panel(isi, Palet.PANEL, 32, 8)
	var tabs := UiKit.baris(tab, 8)
	for t in [["kata", "UI_TOKO_KATA_TAB"], ["template", "UI_TOKO_TEMPLATE_TAB"], ["kantor", "UI_TOKO_UPGRADE"]]:
		var b := UiKit.tombol(tabs, "", Palet.PANEL, Palet.PANEL, 26, Tema.font_ui(700), 88)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("kunci", t[1])
		b.pressed.connect(func() -> void:
			_tab = t[0]
			_segarkan())
		_tombol_tab[t[0]] = b
	_baris_filter = HFlowContainer.new()
	_baris_filter.add_theme_constant_override("h_separation", 12)
	_baris_filter.add_theme_constant_override("v_separation", 12)
	isi.add_child(_baris_filter)
	_gulir = ScrollContainer.new()
	_gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	isi.add_child(_gulir)
	Events.toko_diminta.connect(func(b: bool) -> void:
		if b:
			buka()
		else:
			tutup())
	Events.money_changed.connect(func(_u: int) -> void: _segarkan_jika_terbuka())
	Events.kepemilikan_berubah.connect(_segarkan_jika_terbuka)
	Events.pengikut_berubah.connect(func(_p: int) -> void: _segarkan_jika_terbuka())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _segarkan_jika_terbuka())


func _segarkan_jika_terbuka() -> void:
	if visible and not _antre:
		_antre = true
		_segarkan_antre.call_deferred()


func _segarkan_antre() -> void:
	_antre = false
	if visible:
		_segarkan()


func _segarkan() -> void:
	judul.text = tr("UI_TOKO").to_upper()
	_uang.text = Bahasa.angka(GameState.uang)
	for id in _tombol_tab:
		var b: Button = _tombol_tab[id]
		b.text = tr(str(b.get_meta("kunci")))
		var aktif: bool = id == _tab
		Palet.gaya_tombol(b, Palet.KUNING if aktif else Palet.PANEL, Palet.KUNING_GELAP if aktif else Palet.PANEL,
			Palet.TINTA if aktif else Palet.TEKS, 24)
	var y := _gulir.scroll_vertical
	if _konten:
		_gulir.remove_child(_konten)
		_konten.queue_free()
	for anak in _baris_filter.get_children():
		_baris_filter.remove_child(anak)
		anak.queue_free()
	_baris_filter.visible = _tab == "kata"
	match _tab:
		"kata":
			_isi_kata()
		"template":
			_isi_template()
		_:
			_isi_kantor()
	_gulir.set_deferred("scroll_vertical", y)


func _isi_kata() -> void:
	for s in SLOT:
		var b := UiKit.tombol(_baris_filter, tr("UI_SEMUA") if s.is_empty() else HeadlineBuilder.nama_slot(s).capitalize(),
			Palet.TEKS if s == _filter else Palet.MALAM, Palet.TEKS_REDUP if s == _filter else Palet.PANEL_2, 24, Tema.font_ui(600), 88)
		b.pressed.connect(func() -> void:
			_filter = s
			_segarkan())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pasang(grid)
	var ada := false
	for id in _belum_dimiliki(DataDB.words, GameState.kartu_dimiliki):
		var kata := DataDB.get_word(id)
		if not _filter.is_empty() and str(kata.get("slot", "")) != _filter:
			continue
		ada = true
		grid.add_child(_kartu_toko(id, kata))
	if not ada:
		_kosong(grid)


func _kartu_toko(id: String, kata: Dictionary) -> Control:
	var emosi := str(kata.get("emosi", "netral"))
	var kartu := PanelContainer.new()
	kartu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gaya := Palet.kotak(Palet.KERTAS, Color("0e0b1f"), 32)
	gaya.set_border_width_all(0)
	gaya.border_width_bottom = 8
	gaya.set_content_margin_all(0)
	kartu.add_theme_stylebox_override("panel", gaya)
	var kolom := UiKit.kolom(kartu, 8)
	var pita := PanelContainer.new()
	var gp := StyleBoxFlat.new()
	gp.bg_color = Palet.emosi(emosi)
	gp.border_color = Palet.emosi_gelap(emosi)
	gp.border_width_bottom = 6
	gp.corner_radius_top_left = 32
	gp.corner_radius_top_right = 32
	gp.content_margin_left = 18
	gp.content_margin_right = 18
	gp.content_margin_top = 10
	gp.content_margin_bottom = 10
	pita.add_theme_stylebox_override("panel", gp)
	kolom.add_child(pita)
	var hp := UiKit.baris(pita, 8)
	UiKit.ikon(hp, emosi, 26, Palet.teks_di_atas(emosi))
	var e := UiKit.label(hp, 22, Palet.teks_di_atas(emosi), Tema.font_ui(700), tr("UI_EMO_" + emosi.to_upper()).capitalize())
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.label(hp, 20, Palet.teks_di_atas(emosi), Tema.font_ui(600), HeadlineBuilder.nama_slot(str(kata.get("slot", ""))).to_lower())
	var tengah := UiKit.margin(kolom, 18, 4, 18, 0)
	var nama := UiKit.label(tengah, 28, Palet.TINTA, Tema.font_ui(600), Bahasa.teks(kata.get("text", "")))
	nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nama.custom_minimum_size = Vector2(0, 72)
	UiKit.margin(kolom, 18, 0, 18, 0).add_child(UiKit.label(null, 22, Palet.TEKS_KERTAS_REDUP, Tema.font_ui(600),
		tr("UI_HEBOH_KRED") % [int(kata.get("heboh", 0)), int(kata.get("kred", 0))]))
	var harga := int(kata.get("harga", 0))
	var bawah := UiKit.margin(kolom, 14, 4, 14, 14)
	var b := _tombol_beli(bawah, harga)
	b.pressed.connect(func() -> void: GameState.beli_kata(id))
	return kartu


func _tombol_beli(induk: Control, harga: int) -> Button:
	var cukup := GameState.uang >= harga
	var b := UiKit.tombol(induk, "%s · %s" % [tr("UI_BELI") if cukup else tr("UI_KURANG"), Bahasa.angka(harga)],
		Palet.PINK if cukup else Color("ece7f7"), Palet.PINK_GELAP if cukup else Color("d6d0f0"), 26, Tema.font_ui(700), 88)
	# Di dalam ScrollContainer: PASS supaya seret jari tetap menggulir daftar.
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	Palet.gaya_tombol(b, Palet.PINK if cukup else Color("ece7f7"), Palet.PINK_GELAP if cukup else Color("d6d0f0"),
		Palet.TINTA if cukup else Palet.TEKS_KERTAS_REDUP, 24)
	b.disabled = not cukup
	b.add_theme_stylebox_override("disabled", Palet.kotak(Color("ece7f7"), Color.TRANSPARENT, 24))
	b.add_theme_color_override("font_disabled_color", Palet.TEKS_KERTAS_REDUP)
	return b


func _isi_template() -> void:
	var kolom := UiKit.kolom(null, 20)
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pasang(kolom)
	var ada := false
	for id in _belum_dimiliki(DataDB.templates, GameState.template_dimiliki):
		ada = true
		var data := DataDB.get_template(id)
		var kartu := UiKit.panel(kolom, Palet.KERTAS, 32, 24)
		var k := UiKit.kolom(kartu, 12)
		var atas := UiKit.baris(k, 12)
		var pengali := float(data.get("pengali_heboh", 1.0))
		var era := int(data.get("era_min", 1))
		var j := UiKit.label(atas, 22, Palet.TEKS_KERTAS_REDUP, Tema.font_ui(700), tr("UI_ERA_PENDEK") % era if era > 1 else "")
		j.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.pil(atas, tr("UI_HEBOH_KALI") % _desimal(pengali), Palet.ORANYE if pengali > 1.0 else Color("ece7f7"), Palet.TINTA, 22)
		var pola := UiKit.label(k, 26, Palet.TINTA, Tema.font_ketik(), HeadlineBuilder.susun(id, {}))
		pola.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var b := _tombol_beli(k, int(data.get("harga", 0)))
		b.pressed.connect(func() -> void: GameState.beli_template(id))
	if not ada:
		_kosong(kolom)


## Kantor & staf: lihat TokoKantor.
func _isi_kantor() -> void:
	var kolom := UiKit.kolom(null, 18)
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pasang(kolom)
	TokoKantor.isi(kolom, _tombol_beli)


func _pasang(c: Container) -> void:
	var m := UiKit.margin(null, 4, 8, 4, 32)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(c)
	_konten = m
	_gulir.add_child(m)


func _kosong(induk: Control) -> void:
	UiKit.label(induk, 26, Palet.TEKS_REDUP, Tema.font_ui(600), tr("UI_TOKO_KOSONG"))


func _belum_dimiliki(sumber: Dictionary, dimiliki: Array[String]) -> Array[String]:
	var hasil: Array[String] = []
	for id in sumber:
		var item: Dictionary = sumber[id]
		if not (id in dimiliki) and GameState.era_terbuka(item) and item.get("toko", true):
			hasil.append(id)
	hasil.sort_custom(func(a: String, b: String) -> bool:
		return int(sumber[a].get("harga", 0)) < int(sumber[b].get("harga", 0)))
	return hasil


func _desimal(x: float) -> String:
	var t := "%.1f" % x
	return t.replace(".", ",") if Bahasa.kode() == "id" else t
