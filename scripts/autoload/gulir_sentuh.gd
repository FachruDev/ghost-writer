extends Node
## Gulir seperti aplikasi HP biasa: geser jari dari mana saja di dalam daftar, termasuk di atas kartu dan tombol.
## Diadaptasi dari TouchScroll Cuan Quest, ditambah sumbu horizontal untuk tangan kartu.
##
## Masalah bawaan Godot: geser bawaan ScrollContainer hanya jalan kalau sentuhan jatuh di ScrollContainer atau
## anak ber-mouse_filter PASS; panel dan tombol (STOP) menahan sentuhan, jadi pemain harus menyentuh latar untuk
## menggulir. Autoload ini membaca sentuhan lebih dulu (_input). Begitu jari bergeser melewati ambang, daftar di
## bawah jari mengikuti jari 1:1, tekanan tombol yang sempat terjadi dibatalkan (tidak ikut terpencet), dan setelah
## jari diangkat daftar meluncur lalu melambat. Ketukan saat daftar meluncur hanya menghentikan luncuran.
## Geser bawaan dimatikan (scroll_deadzone) supaya tidak menggulir dua kali.

const SLOP := 12.0  # px layar game sebelum geseran dianggap gulir (di bawahnya tetap ketukan biasa)
const GESEKAN := 2.8  # perlambatan luncuran per detik (eksponensial); makin kecil makin jauh meluncur
const MIN_KIBAS := 120.0  # kecepatan minimal (px/detik) agar luncuran berjalan
const MAKS_KIBAS := 6000.0
const HENTI := 15.0  # luncuran berhenti di bawah kecepatan ini
const KETUK_HENTIKAN := 250.0  # ketukan saat meluncur secepat ini hanya menghentikan luncuran
const JENDELA_KECEPATAN := 100  # ms gerakan terakhir yang dipakai menghitung kecepatan kibasan
const DIAM_SEBELUM_ANGKAT := 80  # ms; jari diam selama ini sebelum diangkat = tidak meluncur
const BAWAAN_MATI := 1_000_000  # scroll_deadzone sebesar ini mematikan geser bawaan
const DEVICE_PALSU := 4747  # penanda kejadian palsu dari _batalkan_tekan (diabaikan autoload ini)
const JAUH := Vector2(-100000, -100000)  # posisi kejadian palsu untuk membatalkan tekanan tombol

var _tekan := false  # jari/tombol kiri sedang menekan
var _menyeret := false
var _telan := false  # tahan sisa kejadian sentuhan sampai tekanan berikutnya (setelah menggulir)
var _awal := Vector2.ZERO
var _gulir: ScrollContainer
var _vertikal := true  # sumbu gulir yang sedang diseret
var _jangkar := 0.0  # posisi jari (sumbu gulir) saat gulir mulai
var _jangkar_nilai := 0.0  # posisi gulir saat gulir mulai
var _sampel: Array[Vector2] = []  # (waktu ms, posisi jari di sumbu gulir) untuk kecepatan kibasan
var _luncur: ScrollContainer
var _luncur_vertikal := true
var _luncur_nilai := 0.0
var _kecepatan := 0.0  # px/detik, arah isi (positif = makin ke bawah/kanan daftar)
var _terpasang: Dictionary = {}  # ScrollContainer -> true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().root.find_children("*", "ScrollContainer", true, false):
		_on_node_added(node)


func _on_node_added(node: Node) -> void:
	if node is ScrollContainer:
		_siapkan.call_deferred(node)


func _siapkan(gulir: ScrollContainer) -> void:
	if not is_instance_valid(gulir) or _terpasang.has(gulir):
		return
	_terpasang[gulir] = true
	gulir.tree_exiting.connect(func() -> void: _terpasang.erase(gulir))
	gulir.scroll_deadzone = BAWAAN_MATI
	if gulir.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	if gulir.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		gulir.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		IndikatorGulir.pasang(gulir)


## Di HP setiap sentuhan datang dua kali: sentuhan asli (ScreenTouch/ScreenDrag) dan tiruannya sebagai mouse
## (device DEVICE_ID_EMULATION) yang dipakai tombol. Logika gulir hanya membaca kejadian asli (sentuhan di HP,
## mouse di laptop); tiruannya cukup ikut ditahan selama menggulir agar tombol tidak menerimanya.
func _input(event: InputEvent) -> void:
	if event.device == DEVICE_PALSU:
		return  # pembatal tekanan dari _batalkan_tekan: biarkan sampai ke tombol
	var is_tombol: bool = event is InputEventScreenTouch \
			or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT)
	var is_seret: bool = event is InputEventScreenDrag \
			or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT)
	if not is_tombol and not is_seret:
		return
	if (event is InputEventScreenTouch or event is InputEventScreenDrag) and event.index != 0:
		return  # jari kedua diabaikan
	if event.device != InputEvent.DEVICE_ID_EMULATION:
		if is_tombol and event.pressed:
			_mulai(event.position)
		elif is_tombol:
			_lepas()
		else:
			_gerak(event.position)
	if _telan and not (is_tombol and event.pressed):
		get_viewport().set_input_as_handled()


func _mulai(pos: Vector2) -> void:
	var sedang_meluncur := _luncur != null and absf(_kecepatan) >= KETUK_HENTIKAN
	_luncur = null
	_tekan = true
	_menyeret = false
	_telan = false
	_awal = pos
	if sedang_meluncur:
		_batalkan_tekan()  # ketukan untuk menghentikan luncuran tidak ikut memencet kartu di bawahnya


func _gerak(pos: Vector2) -> void:
	if not _tekan:
		return
	if not _menyeret:
		var geser := pos - _awal
		if geser.length() < SLOP:
			return
		_tekan = false
		_vertikal = absf(geser.y) >= absf(geser.x)
		_gulir = gulir_di(_awal, _vertikal)
		if _gulir == null:
			return
		_tekan = true
		_menyeret = true
		_telan = true
		_batalkan_tekan()
		# Setter ini juga menghentikan geser bawaan yang sempat mulai.
		_gulir.scroll_vertical = _gulir.scroll_vertical
		_gulir.scroll_horizontal = _gulir.scroll_horizontal
		_jangkar = _sumbu(pos)
		_jangkar_nilai = _bar(_gulir, _vertikal).value
		_sampel.clear()
	if not is_instance_valid(_gulir):
		_tekan = false
		_menyeret = false
		return
	_atur(_gulir, _vertikal, _jangkar_nilai - (_sumbu(pos) - _jangkar))  # isi menempel di jari
	var kini := Time.get_ticks_msec()
	_sampel.append(Vector2(kini, _sumbu(pos)))
	while _sampel.size() > 2 and kini - _sampel[0].x > JENDELA_KECEPATAN:
		_sampel.pop_front()


func _lepas() -> void:
	if _menyeret and is_instance_valid(_gulir):
		var laju := _laju_lepas()
		if absf(laju) >= MIN_KIBAS:
			_luncur = _gulir
			_luncur_vertikal = _vertikal
			_luncur_nilai = _bar(_gulir, _vertikal).value
			_kecepatan = clampf(laju, -MAKS_KIBAS, MAKS_KIBAS)
	_tekan = false
	_menyeret = false


## Kecepatan jari selama ±0,1 detik terakhir; 0 jika jari sempat diam sebelum diangkat.
func _laju_lepas() -> float:
	if _sampel.size() < 2 or Time.get_ticks_msec() - _sampel[-1].x > DIAM_SEBELUM_ANGKAT:
		return 0.0
	var rentang := (_sampel[-1].x - _sampel[0].x) / 1000.0
	if rentang <= 0.0:
		return 0.0
	return -(_sampel[-1].y - _sampel[0].y) / rentang


func _process(delta: float) -> void:
	if _luncur == null:
		return
	if not is_instance_valid(_luncur) or not _luncur.is_visible_in_tree():
		_luncur = null
		return
	_luncur_nilai += _kecepatan * delta
	_kecepatan *= exp(-GESEKAN * delta)
	var ruang_luncur := ruang(_luncur, _luncur_vertikal)
	if _luncur_nilai <= 0.0 or _luncur_nilai >= ruang_luncur or absf(_kecepatan) < HENTI:
		_atur(_luncur, _luncur_vertikal, clampf(_luncur_nilai, 0.0, ruang_luncur))
		_luncur = null
	else:
		_atur(_luncur, _luncur_vertikal, _luncur_nilai)


## ScrollContainer yang menerima geseran di titik ini untuk sumbu itu: kontrol paling atas di bawah jari (urutan
## sama seperti GUI Godot), lalu naik ke induknya sampai ketemu daftar yang bisa digulir di sumbu itu. Lembar yang
## menutupi layar ikut menghalangi, jadi layar di belakangnya tidak tergulir. Tidak memakai
## gui_get_hovered_control(): di Android nilainya bisa kosong.
func gulir_di(pos: Vector2, vertikal: bool) -> ScrollContainer:
	var node: Node = _kontrol_di(pos)
	while node != null:
		if node is ScrollContainer:
			var mode: int = node.vertical_scroll_mode if vertikal else node.horizontal_scroll_mode
			if mode != ScrollContainer.SCROLL_MODE_DISABLED and ruang(node, vertikal) > 1.0:
				return node
		node = node.get_parent()
	return null


## Panjang yang bisa digulir (px) di sumbu itu.
static func ruang(gulir: ScrollContainer, vertikal: bool) -> float:
	var b := _bar(gulir, vertikal)
	return maxf(b.max_value - b.page, 0.0)


static func _bar(gulir: ScrollContainer, vertikal: bool) -> ScrollBar:
	return gulir.get_v_scroll_bar() if vertikal else gulir.get_h_scroll_bar()


func _atur(gulir: ScrollContainer, vertikal: bool, nilai: float) -> void:
	_bar(gulir, vertikal).value = clampf(nilai, 0.0, ruang(gulir, vertikal))


func _sumbu(pos: Vector2) -> float:
	return pos.y if _vertikal else pos.x


func _kontrol_di(pos: Vector2) -> Control:
	var akar: Array = []  # [layer, urutan, Control]
	_kumpulkan_akar(get_tree().root, 0, akar)
	akar.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0] if a[0] != b[0] else a[1] > b[1])
	for entri: Array in akar:
		var kena := _pilih(entri[2], pos)
		if kena != null:
			return kena
	return null


## Kontrol akar = Control yang induknya bukan Control. Yang belakangan di pohon / layer lebih tinggi digambar di atas.
func _kumpulkan_akar(node: Node, layer: int, keluar: Array) -> void:
	for anak in node.get_children():
		if anak is CanvasLayer:
			if anak.visible:
				_kumpulkan_akar(anak, anak.layer, keluar)
		elif anak is Window:
			continue
		elif anak is Control:
			if anak.is_visible_in_tree():
				keluar.append([layer, keluar.size(), anak])
		else:
			_kumpulkan_akar(anak, layer, keluar)


func _pilih(kontrol: Control, pos: Vector2) -> Control:
	if not kontrol.visible:
		return null
	var lokal := kontrol.get_global_transform_with_canvas().affine_inverse() * pos
	var di_dalam := Rect2(Vector2.ZERO, kontrol.size).has_point(lokal)
	if kontrol.clip_contents and not di_dalam:
		return null
	for i in range(kontrol.get_child_count(true) - 1, -1, -1):
		var anak := kontrol.get_child(i, true) as Control
		if anak != null and not anak.top_level:
			var kena := _pilih(anak, pos)
			if kena != null:
				return kena
	if di_dalam and kontrol.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return kontrol
	return null


## Membatalkan tekanan tombol/kontrol yang sempat terjadi: gerakan palsu ke luar layar (tombol mencatat "jari
## sudah keluar") lalu lepasan palsu di sana, jadi tombol tidak terpencet. Dikirim dalam koordinat lokal agar
## posisinya tidak ikut diskalakan layar HP, dan diberi device khusus agar autoload ini tidak membacanya sebagai jari.
func _batalkan_tekan() -> void:
	_kirim_batal.call_deferred()


func _kirim_batal() -> void:
	var pergi := InputEventMouseMotion.new()
	pergi.device = DEVICE_PALSU
	pergi.position = JAUH
	pergi.global_position = JAUH
	pergi.button_mask = MOUSE_BUTTON_MASK_LEFT
	var lepas := InputEventMouseButton.new()
	lepas.device = DEVICE_PALSU
	lepas.button_index = MOUSE_BUTTON_LEFT
	lepas.pressed = false
	lepas.position = JAUH
	lepas.global_position = JAUH
	get_viewport().push_input(pergi, true)
	get_viewport().push_input(lepas, true)
