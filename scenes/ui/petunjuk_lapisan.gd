class_name PetunjukLapisan
extends CanvasLayer
## Lapisan petunjuk sistem baru (CHECKLIST 0.9.0): kartu cyan berekor yang menunjuk sasarannya
## (bar kredibilitas & panas, tombol saluran di meja, cincin staf) dengan cincin sorot cyan, dan
## tombol Oke. Info dari Events.petunjuk_tampil (PetunjukController); Oke memancarkan
## Events.petunjuk_ditutup, yang wajib supaya petunjuk berikutnya bisa muncul.
## Selama ada lembar terbuka (Naik Era dan lembar saluran tidak menjeda waktu) kartu menunggu,
## jadi petunjuk baru tampil saat pemain benar-benar bisa melihatnya.

const KREDIBILITAS := &"petunjuk_kredibilitas"  # bar kredibilitas dan panas di HUD
const STAF := &"petunjuk_staf"  # pil cincin staf di HUD
const LAPIS := 19  # tepat di bawah lapisan tutorial
const TEPI := 24.0
const JARAK := 34.0  # jarak kartu dari sasaran, ruang untuk ekor
const EKOR := Vector2(40, 26)  # lebar alas, tinggi
const PERIODE := 1.4

var _info: Dictionary = {}
var _kanvas: Control
var _ekor: Control
var _kartu: PetunjukKartu
var _sasaran := Rect2()  # global; kosong = sasaran tidak ada di layar
var _di_atas := false  # kartu di atas sasaran (ekor di tepi bawah kartu)
var _tampak := false
var _menutup := false
var _t := 0.0
var _sorot := StyleBoxFlat.new()


func _ready() -> void:
	layer = LAPIS
	_kanvas = Control.new()
	_kanvas.theme = Tema.buat()  # tema tidak menurun melewati CanvasLayer
	_kanvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kanvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kanvas.visible = false
	_kanvas.draw.connect(_gambar_sorot)
	add_child(_kanvas)
	_kartu = PetunjukKartu.new()
	_kanvas.add_child(_kartu)
	_kartu.oke.connect(_tutup)
	# Ekor digambar di atas kartu supaya menyambung tanpa garis tepi kartu di alasnya.
	_ekor = Control.new()
	_ekor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ekor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ekor.draw.connect(_gambar_ekor)
	_kanvas.add_child(_ekor)
	_sorot.draw_center = false
	_sorot.anti_aliasing = true
	Events.petunjuk_tampil.connect(_tampilkan)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void:
		if not _info.is_empty():
			_kartu.atur(_info))
	# Lapisan yang dibuat belakangan: ambil petunjuk yang sedang aktif.
	var pengendali := get_parent().get_node_or_null("PetunjukController") as PetunjukController
	if pengendali and not pengendali.info().is_empty():
		_tampilkan(pengendali.info())


## Petunjuk yang sedang dipegang lapisan ({} = tidak ada).
func info() -> Dictionary:
	return _info


## Kartu benar-benar terlihat pemain (tidak tertutup lembar).
func tampak() -> bool:
	return _tampak


func _tampilkan(info: Dictionary) -> void:
	_info = info
	_menutup = false
	_tampak = false
	_kartu.atur(info)
	_kartu.visible = false
	_kanvas.visible = true


func _tutup() -> void:
	if _info.is_empty() or _menutup or not _tampak:
		return
	_menutup = true
	_kartu.hilang().finished.connect(func() -> void:
		_info = {}
		_tampak = false
		_kanvas.visible = false
		Events.petunjuk_ditutup.emit())


func _process(delta: float) -> void:
	if _info.is_empty():
		return
	_t = fmod(_t + delta, PERIODE)
	if _lembar_terbuka():
		_kartu.visible = false
		_tampak = false
		_sasaran = Rect2()
	else:
		_sasaran = _cari_sasaran()
		_letakkan()
		if not _tampak:
			_tampak = true
			_kartu.visible = true
			_kartu.muncul()
	_kanvas.queue_redraw()
	_ekor.queue_redraw()


func _lembar_terbuka() -> bool:
	for anak in get_parent().get_children():
		var l := anak as Lembar
		if l and l.visible:
			return true
	return false


func _cari_sasaran() -> Rect2:
	var grup := KREDIBILITAS
	match str(_info.get("sasaran", "")):
		"saluran":
			grup = TutorialSasaran.SALURAN
		"staf":
			grup = STAF
	var hasil := Rect2()
	for n in get_tree().get_nodes_in_group(grup):
		var c := n as Control
		if c and c.is_visible_in_tree():
			hasil = c.get_global_rect() if not hasil.has_area() else hasil.merge(c.get_global_rect())
	return hasil


## Kartu di sisi sasaran yang lebih lega; tanpa sasaran, sedikit di atas tengah layar.
func _letakkan() -> void:
	var layar := _kanvas.size
	var inset := UiKit.inset_aman(_kanvas)
	var lebar := layar.x - TEPI * 2.0
	_kartu.atur_lebar(lebar)
	var tinggi := _kartu.get_combined_minimum_size().y
	_kartu.size = Vector2(lebar, tinggi)
	var atas := inset.x + TEPI
	var bawah := layar.y - inset.y - TEPI
	var y := (layar.y - tinggi) * 0.42
	if _sasaran.has_area():
		_di_atas = _sasaran.position.y - atas > bawah - _sasaran.end.y
		y = _sasaran.position.y - JARAK - tinggi if _di_atas else _sasaran.end.y + JARAK
	_kartu.position = Vector2(TEPI, clampf(y, atas, maxf(atas, bawah - tinggi)))
	# Kartu mengembang dari pangkal ekornya.
	_kartu.pivot_offset = Vector2(_x_ekor() - TEPI, tinggi if _di_atas else 0.0)


func _x_ekor() -> float:
	var r := _kartu.get_rect()
	return clampf(_sasaran.get_center().x, r.position.x + 56.0, r.end.x - 56.0)


## Cincin cyan di sekeliling sasaran plus denyut yang mengembang pelan.
func _gambar_sorot() -> void:
	if not _tampak or not _sasaran.has_area():
		return
	var q := _t / PERIODE
	var radius := minf(_sasaran.size.y / 2.0, 28.0)
	_cincin(_sasaran.grow(8.0), radius + 8.0, Palet.CYAN, 5.0)
	var g := 8.0 + 18.0 * q
	_cincin(_sasaran.grow(g), radius + g, Color(Palet.CYAN, 0.55 * (1.0 - q)), 4.0)


func _cincin(r: Rect2, radius: float, warna: Color, tebal: float) -> void:
	_sorot.border_color = warna
	_sorot.set_border_width_all(int(tebal))
	_sorot.set_corner_radius_all(int(minf(radius, minf(r.size.x, r.size.y) / 2.0)))
	_kanvas.draw_style_box(_sorot, r)


## Segitiga dari tepi kartu ke arah sasaran, dengan isi panel dan garis cyan yang menyambung.
func _gambar_ekor() -> void:
	if not _tampak or not _sasaran.has_area():
		return
	var r := _kartu.get_rect()
	var x := _x_ekor()
	var arah := 1.0 if _di_atas else -1.0  # +1 = ekor ke bawah
	var tepi := r.end.y if _di_atas else r.position.y
	var pangkal := tepi - arah * 5.0  # sedikit masuk ke kartu, menutupi garis tepinya
	var ujung := Vector2(x, tepi + arah * EKOR.y)
	var kiri := Vector2(x - EKOR.x / 2.0, pangkal)
	var kanan := Vector2(x + EKOR.x / 2.0, pangkal)
	var alfa := _kartu.modulate.a
	_ekor.draw_colored_polygon(PackedVector2Array([kiri, ujung, kanan]), Color(Palet.PANEL, alfa))
	var garis := Color(Palet.CYAN, alfa)
	_ekor.draw_polyline(PackedVector2Array([Vector2(kiri.x, tepi), ujung, Vector2(kanan.x, tepi)]), garis, 4.0, true)
