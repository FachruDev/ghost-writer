extends Lembar
## Layar Pengaturan (papan 19): volume musik & efek suara, getar, bahasa, hapus progres (tekan dua kali),
## tombol ke layar Tentang & kredit, versi. Nilai disimpan autoload Pengaturan di user://settings.cfg
## (tidak ikut terhapus saat reset). Isi digulir kalau layar terlalu pendek (notch, 16:9).

var _musik: HSlider
var _sfx: HSlider
var _angka_musik: Label
var _angka_sfx: Label
var _getar: CheckButton
var _id: Button
var _en: Button
var _hapus: Button
var _tentang: Button
var _wadah: VBoxContainer
var _yakin := false
var _label: Dictionary = {}  # kunci teks -> Label


func _init() -> void:
	penuh = true


func _bangun_isi() -> void:
	var gulir := ScrollContainer.new()
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	isi.add_child(gulir)
	_wadah = UiKit.kolom(gulir, 20)
	_wadah.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Setinggi area gulir supaya pengisi mendorong Tentang & versi ke bawah; kalau isi lebih tinggi, digulir.
	gulir.resized.connect(func() -> void: _wadah.custom_minimum_size.y = gulir.size.y)
	var suara := _kartu("UI_SUARA")
	_musik = _slider(suara, "UI_MUSIK", "musik")
	_angka_musik = _musik.get_meta("angka")
	_sfx = _slider(suara, "UI_SFX", "sfx")
	_angka_sfx = _sfx.get_meta("angka")
	var baris_getar := UiKit.baris(suara, 16)
	var k := UiKit.kolom(baris_getar, 2)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label["UI_GETAR"] = UiKit.label(k, 30, Palet.TEKS, Tema.font_ui(600))
	_label["UI_GETAR_INFO"] = UiKit.label(k, 22, Palet.TEKS_REDUP, Tema.font_ui(500))
	_getar = CheckButton.new()
	_getar.custom_minimum_size = Vector2(120, 88)
	_getar.toggled.connect(func(v: bool) -> void: Pengaturan.atur("getar", v))
	var nyala := _tekstur_saklar(true)
	var mati := _tekstur_saklar(false)
	for nama in ["checked", "checked_mirrored"]:
		_getar.add_theme_icon_override(nama, nyala)
	for nama in ["unchecked", "unchecked_mirrored"]:
		_getar.add_theme_icon_override(nama, mati)
	for nama in ["normal", "hover", "pressed", "hover_pressed"]:
		_getar.add_theme_stylebox_override(nama, StyleBoxEmpty.new())
	baris_getar.add_child(_getar)
	var bahasa := UiKit.panel(_wadah, Palet.PANEL, 36, 28)
	var hb := UiKit.baris(bahasa, 16)
	_label["UI_BAHASA_JUDUL"] = UiKit.label(hb, 30, Palet.TEKS, Tema.font_ui(600))
	_label["UI_BAHASA_JUDUL"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label["UI_BAHASA_JUDUL"].vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_id = UiKit.tombol(hb, tr("UI_NAMA_ID"), Palet.PANEL_2, Palet.MALAM, 26, Tema.font_ui(700), 88)
	_id.pressed.connect(func() -> void: Bahasa.atur("id"))
	_en = UiKit.tombol(hb, tr("UI_NAMA_EN"), Palet.PANEL_2, Palet.MALAM, 26, Tema.font_ui(700), 88)
	_en.pressed.connect(func() -> void: Bahasa.atur("en"))
	var progres := _kartu("UI_PROGRES")
	_label["UI_PROGRES_INFO"] = UiKit.label(progres, 24, Palet.TEKS_LEMBUT, Tema.font_ui(500))
	_label["UI_PROGRES_INFO"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hapus = UiKit.tombol(progres, "", Palet.MALAM, Palet.PINK, 26, Tema.font_ui(700), 96)
	_hapus.pressed.connect(_on_hapus)
	var jarak := Control.new()
	jarak.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_wadah.add_child(jarak)
	var tentang := UiKit.kolom(_wadah, 12)
	_tentang = UiKit.tombol(tentang, "", Palet.PANEL_2, Palet.PANEL, 28, Tema.font_ui(700), 96)
	_tentang.pressed.connect(func() -> void: Events.layar_diminta.emit("tentang"))
	_label["UI_VERSI"] = UiKit.label(tentang, 22, Palet.TEKS_REDUP, Tema.font_ui(500))
	_label["UI_VERSI"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label["UI_VERSI"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Events.layar_diminta.connect(func(n: String) -> void:
		if n == "pengaturan":
			buka())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void:
		if visible:
			_segarkan())


func _kartu(kunci: String) -> VBoxContainer:
	var p := UiKit.panel(_wadah, Palet.PANEL, 36, 28)
	var k := UiKit.kolom(p, 18)
	_label[kunci] = UiKit.label(k, 24, Palet.TEKS_REDUP, Tema.font_ui(700))
	return k


func _slider(induk: Control, kunci: String, nama: String) -> HSlider:
	var k := UiKit.kolom(induk, 6)
	var atas := UiKit.baris(k, 8)
	_label[kunci] = UiKit.label(atas, 30, Palet.TEKS, Tema.font_ui(600))
	_label[kunci].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var angka := UiKit.label(atas, 28, Palet.KUNING, Tema.font_ui(700))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(0, 64)
	var jalur := Palet.kotak(Palet.MALAM, Color.TRANSPARENT, 12)
	jalur.content_margin_top = 10
	jalur.content_margin_bottom = 10
	var isi_jalur := Palet.kotak(Palet.KUNING, Color.TRANSPARENT, 12)
	isi_jalur.content_margin_top = 10
	isi_jalur.content_margin_bottom = 10
	s.add_theme_stylebox_override("slider", jalur)
	s.add_theme_stylebox_override("grabber_area", isi_jalur)
	s.add_theme_stylebox_override("grabber_area_highlight", isi_jalur)
	var bulat := _tekstur_bulat(52, Palet.KUNING, Palet.KUNING_GELAP)
	s.add_theme_icon_override("grabber", bulat)
	s.add_theme_icon_override("grabber_highlight", bulat)
	s.value_changed.connect(func(v: float) -> void:
		Pengaturan.atur(nama, v)
		angka.text = "%d%%" % roundi(v * 100.0))
	k.add_child(s)
	s.set_meta("angka", angka)
	return s


## Saklar besar (112×64): jalur bulat hijau/gelap + kenop putih, digambar ke Image.
static func _tekstur_saklar(nyala: bool) -> ImageTexture:
	var w := 112
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var jalur := Palet.HIJAU if nyala else Palet.MALAM
	var tepi := Palet.HIJAU_GELAP if nyala else Palet.GARIS
	var r := h / 2.0
	var kenop := Vector2(w - r if nyala else r, r)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, r, w - r)
			var jarak := p.distance_to(Vector2(cx, r))
			var warna := Color.TRANSPARENT
			if jarak <= r:
				warna = tepi if jarak > r - 4.0 else jalur
			if p.distance_to(kenop) <= r - 9.0:
				warna = Palet.TEKS
			img.set_pixel(x, y, warna)
	return ImageTexture.create_from_image(img)


## Ikon pegangan slider: lingkaran tebal digambar ke Image (tanpa file aset).
static func _tekstur_bulat(d: int, warna: Color, bayang: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d / 2.0
	for y in d:
		for x in d:
			var jarak := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			if jarak <= r - 1.0:
				img.set_pixel(x, y, bayang if y > d * 0.72 else warna)
			elif jarak <= r:
				img.set_pixel(x, y, Color(warna, r - jarak))
	return ImageTexture.create_from_image(img)


func _segarkan() -> void:
	judul.text = tr("UI_PENGATURAN")
	_tentang.text = tr("UI_TENTANG_TOMBOL")
	for kunci in _label:
		if kunci == "UI_VERSI":
			_label[kunci].text = tr(kunci) % str(ProjectSettings.get_setting("application/config/version"))
		else:
			_label[kunci].text = tr(kunci)
	_musik.set_value_no_signal(float(Pengaturan.ambil("musik")))
	_sfx.set_value_no_signal(float(Pengaturan.ambil("sfx")))
	_angka_musik.text = "%d%%" % roundi(_musik.value * 100.0)
	_angka_sfx.text = "%d%%" % roundi(_sfx.value * 100.0)
	_getar.set_pressed_no_signal(bool(Pengaturan.ambil("getar")))
	var id := Bahasa.kode() == "id"
	Palet.gaya_tombol(_id, Palet.KUNING if id else Palet.PANEL_2, Palet.KUNING_GELAP if id else Palet.MALAM, Palet.TINTA if id else Palet.TEKS, 24)
	Palet.gaya_tombol(_en, Palet.KUNING if not id else Palet.PANEL_2, Palet.KUNING_GELAP if not id else Palet.MALAM, Palet.TINTA if not id else Palet.TEKS, 24)
	_yakin = false
	_atur_hapus()


func _atur_hapus() -> void:
	_hapus.text = tr("UI_HAPUS_YAKIN") if _yakin else tr("UI_HAPUS_PROGRES")
	Palet.gaya_tombol(_hapus, Palet.PINK if _yakin else Palet.MALAM, Palet.PINK_GELAP if _yakin else Palet.PINK,
		Palet.TINTA if _yakin else Color("ff8fb3"), 28)


## Hapus progres butuh dua kali tekan; pengaturan tetap.
func _on_hapus() -> void:
	if not _yakin:
		_yakin = true
		_atur_hapus()
		return
	tutup()
	SaveSystem.reset_progres()
	get_tree().reload_current_scene()
