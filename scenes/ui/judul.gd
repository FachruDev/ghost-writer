extends Control
## Layar judul (papan 01): langit malam, logo GHOSTWRITER, Si Hantu Penulis dikelilingi warga yang
## sedang digosipi, lalu LANJUTKAN / MAIN, Main baru (tekan dua kali), Pengaturan, dan bahasa.

const MAIN := "res://scenes/main/main.tscn"
const PENGATURAN := preload("res://scenes/ui/pengaturan_layar.gd")


## Warga di sekeliling hantu, dihubungkan garis gosip putus-putus.
class Ilustrasi extends Control:
	var _t := 0.0
	const WARGA := [[0.13, 0.22, 1], [0.86, 0.18, 1], [0.17, 0.78, 2], [0.88, 0.7, 0], [0.04, 0.5, 3]]

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pusat := size * Vector2(0.5, 0.5)
		var font := Tema.font_ui(700)
		for k in WARGA.size():
			var w: Array = WARGA[k]
			var p := size * Vector2(w[0], w[1])
			var arah := (p - pusat).normalized()
			if k < 3:
				draw_dashed_line(pusat + arah * 110.0, p - arah * 40.0, Color(Palet.PINK, 0.8), 5.0, 14.0)
		for k in WARGA.size():
			var w: Array = WARGA[k]
			var naik := absf(sin(_t * (5.0 if w[2] == 1 else 2.5) + k)) * 6.0
			var p := size * Vector2(w[0], w[1]) - Vector2(0, naik)
			GambarWajah.gambar(self, p, 30.0, w[2], k + 1)
			GambarWajah.gelembung(self, p, 30.0, w[2], font, 0.0)


var _lanjut: Button
var _baru: Button
var _id: Button
var _en: Button
var _fiktif: Label
var _tagline: Label
var _yakin := false
var _ada_save := false


func _ready() -> void:
	theme = Tema.buat()
	var langit := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color("241c48"))
	g.set_color(1, Palet.MALAM)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	langit.texture = tex
	langit.stretch_mode = TextureRect.STRETCH_SCALE
	langit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	langit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(langit)
	var bulan := Panel.new()
	bulan.add_theme_stylebox_override("panel", Palet.kotak(Color("fff3c4"), Color.TRANSPARENT, 999))
	bulan.position = Vector2(520, 120)
	bulan.size = Vector2(108, 108)
	add_child(bulan)
	var kolom := UiKit.kolom(null, 24)
	kolom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(kolom)
	var inset := UiKit.inset_aman(self)
	var m := UiKit.margin(kolom, 40, 200 + roundi(inset.x), 40, 0)
	var atas := UiKit.kolom(m, 12)
	var logo := UiKit.label(atas, 88, Color.WHITE, Tema.font_judul(), tr("UI_JUDUL_GAME"))
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_color_override("font_shadow_color", Palet.PINK)
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 10)
	var pil := UiKit.pil(atas, "", Palet.KUNING, Palet.TINTA, 26)
	pil.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_tagline = pil.get_child(0)
	var panggung := Control.new()
	panggung.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kolom.add_child(panggung)
	var ilus := Ilustrasi.new()
	ilus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ilus.offset_left = 40
	ilus.offset_right = -40
	panggung.add_child(ilus)
	var hantu := Hantu.new()
	hantu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hantu.size = Vector2(240, 300)
	hantu.position = Vector2(-120, -150)
	hantu.set_anchor(SIDE_LEFT, 0.5)
	hantu.set_anchor(SIDE_TOP, 0.5)
	panggung.add_child(hantu)
	var bawah := UiKit.margin(kolom, 40, 0, 40, 48 + roundi(inset.y))
	var menu := UiKit.kolom(bawah, 24)
	_lanjut = UiKit.tombol_utama(menu, "", Palet.PINK, Palet.PINK_GELAP, Color.WHITE, 124)
	_lanjut.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN))
	var dua := UiKit.baris(menu, 24)
	_baru = UiKit.tombol(dua, "", Palet.PANEL_2, Palet.PANEL, 28, Tema.font_ui(700))
	_baru.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_baru.pressed.connect(_on_baru)
	var atur := UiKit.tombol(dua, "", Palet.PANEL_2, Palet.PANEL, 28, Tema.font_ui(700))
	atur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atur.set_meta("kunci", "UI_PENGATURAN_TOMBOL")
	atur.pressed.connect(func() -> void: Events.layar_diminta.emit("pengaturan"))
	var kaki := UiKit.baris(menu, 16)
	_fiktif = UiKit.label(kaki, 22, Palet.TEKS_REDUP, Tema.font_ui(500))
	_fiktif.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiktif.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id = UiKit.tombol(kaki, tr("UI_KODE_ID"), Palet.PANEL, Palet.PANEL, 24, Tema.font_ui(700), 88)
	_id.pressed.connect(func() -> void: Bahasa.atur("id"))
	_en = UiKit.tombol(kaki, tr("UI_KODE_EN"), Palet.PANEL, Palet.PANEL, 24, Tema.font_ui(700), 88)
	_en.pressed.connect(func() -> void: Bahasa.atur("en"))
	add_child(PENGATURAN.new())
	_ada_save = FileAccess.file_exists(SaveSystem.PATH) and int(GameState.statistik.get("total_rumor", 0)) > 0
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _segarkan())
	_segarkan()
	(dua.get_child(1) as Button).text = tr("UI_PENGATURAN_TOMBOL")
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: (dua.get_child(1) as Button).text = tr("UI_PENGATURAN_TOMBOL"))


func _segarkan() -> void:
	_tagline.text = tr("UI_TAGLINE")
	_lanjut.text = tr("UI_LANJUTKAN") if _ada_save else tr("UI_MAIN")
	_baru.visible = _ada_save
	_baru.text = tr("UI_MULAI_BARU_YAKIN") if _yakin else tr("UI_MAIN_BARU")
	_fiktif.text = tr("UI_FIKTIF")
	var id := Bahasa.kode() == "id"
	Palet.gaya_tombol(_id, Palet.KUNING if id else Palet.PANEL, Palet.KUNING_GELAP if id else Palet.PANEL, Palet.TINTA if id else Palet.TEKS, 22)
	Palet.gaya_tombol(_en, Palet.KUNING if not id else Palet.PANEL, Palet.KUNING_GELAP if not id else Palet.PANEL, Palet.TINTA if not id else Palet.TEKS, 22)


## Main baru menghapus progres: tekan dua kali.
func _on_baru() -> void:
	if not _yakin:
		_yakin = true
		_segarkan()
		return
	SaveSystem.reset_progres()
	get_tree().change_scene_to_file(MAIN)


## Tombol Back Android: tutup Pengaturan kalau terbuka, selain itu keluar dari game.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	for i in range(get_child_count() - 1, -1, -1):
		var lapisan := get_child(i) as Lembar
		if lapisan and lapisan.tangani_back():
			return
	get_tree().quit()
