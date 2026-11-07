class_name Lembar
extends Control
## Dasar lembar bawah (bottom sheet): latar redup, panel naik dari bawah dengan gagang, judul,
## dan tombol tutup. Turunan mengisi `isi` di _bangun_isi() lalu memanggil buka()/tutup().
## Tinggi panel selalu = tinggi isinya (maks. TINGGI_MAKS layar, sisanya digulir), supaya label
## autowrap yang awalnya diukur dengan lebar 0 tidak membuat panel membengkak.

signal ditutup

## Bagian layar maksimum untuk lembar bawah; isi yang lebih tinggi digulir.
const TINGGI_MAKS := 0.9

## Warna garis atas panel (pink = aksi, kuning = dilema, cyan = kontrak).
var aksen := Color.TRANSPARENT
## Ketuk latar redup, tombol X, atau tombol Back Android untuk menutup.
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
var _gaya: StyleBoxFlat
var _kolom: VBoxContainer
var _gulir_isi: ScrollContainer


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
	_gaya = Palet.kotak(Palet.PANEL if not penuh else Palet.MALAM, Color.TRANSPARENT, 52)
	_gaya.corner_radius_bottom_left = 0
	_gaya.corner_radius_bottom_right = 0
	_gaya.content_margin_left = 28
	_gaya.content_margin_right = 28
	_gaya.content_margin_top = 16
	_gaya.content_margin_bottom = 36
	if aksen.a > 0.0:
		_gaya.border_color = aksen
		_gaya.border_width_top = 8
	_panel.add_theme_stylebox_override("panel", _gaya)
	add_child(_panel)
	if penuh:
		_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_gaya.set_corner_radius_all(0)
		_gaya.content_margin_top = 32
	else:
		_panel.anchor_left = 0.0
		_panel.anchor_right = 1.0
		_panel.anchor_top = 1.0
		_panel.anchor_bottom = 1.0
		_panel.offset_bottom = 0.0
		_panel.offset_transform_enabled = true
	_kolom = UiKit.kolom(_panel, 20)
	if not penuh:
		var gagang := Panel.new()
		gagang.custom_minimum_size = Vector2(80, 10)
		gagang.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		gagang.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gagang.add_theme_stylebox_override("panel", Palet.kotak(Palet.GARIS, Color.TRANSPARENT, 999))
		_kolom.add_child(gagang)
	var atas := UiKit.baris(_kolom, 16)
	judul = UiKit.label(atas, 48, Palet.TEKS, Tema.font_judul())
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	judul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutup = UiKit.tombol_ikon(atas, "tutup", tr("UI_TUTUP"))
	_tutup.pressed.connect(tutup)
	isi = UiKit.kolom(null, 20)
	if penuh:
		isi.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_kolom.add_child(isi)
	else:
		_gulir_isi = ScrollContainer.new()
		_gulir_isi.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_gulir_isi.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_kolom.add_child(_gulir_isi)
		isi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_gulir_isi.add_child(isi)
		isi.minimum_size_changed.connect(_sesuaikan_tinggi)
		_kolom.minimum_size_changed.connect(_sesuaikan_tinggi)
		resized.connect(_sesuaikan_tinggi)
	_bangun_isi()
	_tutup.visible = bisa_ditutup
	_terapkan_inset()


## Diisi turunan: tambahkan node ke `isi`.
func _bangun_isi() -> void:
	pass


## Dipanggil turunan sebelum tampil: isi ulang data terbaru.
func _segarkan() -> void:
	pass


## Tinggi panel = kepala + isi + tepi, dibatasi TINGGI_MAKS layar (sisanya digulir).
func _sesuaikan_tinggi() -> void:
	if penuh or _panel == null:
		return
	var kepala := _kolom.get_combined_minimum_size().y  # tanpa isi: ScrollContainer tidak menyumbang tinggi
	var tinggi := kepala + isi.get_combined_minimum_size().y + _gaya.content_margin_top + _gaya.content_margin_bottom
	var maks := size.y * TINGGI_MAKS if size.y > 0.0 else tinggi
	_panel.offset_top = -minf(tinggi, maks)


## Jarak aman notch/gestur Android: tepi atas layar penuh dan tepi bawah semua lembar.
func _terapkan_inset() -> void:
	var inset := UiKit.inset_aman(self)
	_gaya.content_margin_bottom = 36.0 + inset.y
	if penuh:
		_gaya.content_margin_top = 32.0 + inset.x


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
		if _gulir_isi:
			_gulir_isi.scroll_vertical = 0
		_sesuaikan_tinggi()
		# Geser relatif dari bawah layar ke posisinya; tidak bergantung pada posisi absolut panel.
		_panel.offset_transform_position = Vector2(0.0, maxf(-_panel.offset_top, 200.0))
		create_tween().tween_property(_panel, "offset_transform_position", Vector2.ZERO, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func tutup() -> void:
	if not visible:
		return
	visible = false
	if not jeda.is_empty():
		GameClock.lanjut(jeda)
	ditutup.emit()


## Tombol Back Android: tutup lembar ini kalau boleh. Mengembalikan true kalau lembar terbuka
## (Back dianggap sudah ditangani, termasuk dilema/ending yang wajib dijawab dulu).
func tangani_back() -> bool:
	if not visible:
		return false
	if bisa_ditutup:
		tutup()
	return true
