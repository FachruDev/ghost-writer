class_name Lembar
extends Control
## Dasar lembar bawah (bottom sheet): latar redup, panel naik dari bawah dengan gagang, judul,
## dan tombol tutup. Turunan mengisi `isi` di _bangun_isi() lalu memanggil buka()/tutup().

signal ditutup

## Warna garis atas panel (pink = aksi, kuning = dilema, cyan = kontrak).
var aksen := Color.TRANSPARENT
## Ketuk latar redup atau tombol X untuk menutup.
var bisa_ditutup := true
## Kalau diisi, waktu permainan dijeda selama lembar terbuka.
var jeda: StringName = &""
## Layar penuh (toko, pengaturan) alih-alih lembar bawah.
var penuh := false

var isi: VBoxContainer
var judul: Label

var _panel: PanelContainer
var _redup: ColorRect
var _tutup: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_redup = UiKit.redup(self, 0.75 if not penuh else 1.0)
	if penuh:
		_redup.color = Palet.MALAM
	_redup.gui_input.connect(func(e: InputEvent) -> void:
		if bisa_ditutup and e is InputEventMouseButton and e.pressed:
			tutup())
	_panel = PanelContainer.new()
	var gaya := Palet.kotak(Palet.PANEL if not penuh else Palet.MALAM, Color.TRANSPARENT, 52)
	gaya.corner_radius_bottom_left = 0
	gaya.corner_radius_bottom_right = 0
	gaya.content_margin_left = 28
	gaya.content_margin_right = 28
	gaya.content_margin_top = 16
	gaya.content_margin_bottom = 36
	if aksen.a > 0.0:
		gaya.border_color = aksen
		gaya.border_width_top = 8
	_panel.add_theme_stylebox_override("panel", gaya)
	add_child(_panel)
	if penuh:
		_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		gaya.set_corner_radius_all(0)
		gaya.content_margin_top = 32
	else:
		_panel.anchor_left = 0.0
		_panel.anchor_right = 1.0
		_panel.anchor_top = 1.0
		_panel.anchor_bottom = 1.0
		_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var kolom := UiKit.kolom(_panel, 20)
	if not penuh:
		var gagang := Panel.new()
		gagang.custom_minimum_size = Vector2(80, 10)
		gagang.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		gagang.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gagang.add_theme_stylebox_override("panel", Palet.kotak(Palet.GARIS, Color.TRANSPARENT, 999))
		kolom.add_child(gagang)
	var atas := UiKit.baris(kolom, 16)
	judul = UiKit.label(atas, 48, Palet.TEKS, Tema.font_judul())
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutup = UiKit.tombol_ikon(atas, "tutup", tr("UI_TUTUP"))
	_tutup.pressed.connect(tutup)
	isi = UiKit.kolom(kolom, 20)
	isi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bangun_isi()
	_tutup.visible = bisa_ditutup


## Diisi turunan: tambahkan node ke `isi`.
func _bangun_isi() -> void:
	pass


## Dipanggil turunan sebelum tampil: isi ulang data terbaru.
func _segarkan() -> void:
	pass


func terbuka() -> bool:
	return visible


func buka() -> void:
	_tutup.visible = bisa_ditutup
	_segarkan()
	if not jeda.is_empty() and not visible:
		GameClock.jeda(jeda)
	visible = true
	move_to_front()
	_redup.modulate.a = 0.0
	create_tween().tween_property(_redup, "modulate:a", 1.0, 0.2)
	if not penuh:
		await get_tree().process_frame
		var akhir := _panel.position.y
		_panel.position.y = size.y
		create_tween().tween_property(_panel, "position:y", akhir, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func tutup() -> void:
	if not visible:
		return
	visible = false
	if not jeda.is_empty():
		GameClock.lanjut(jeda)
	ditutup.emit()
