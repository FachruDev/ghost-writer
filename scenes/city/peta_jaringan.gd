class_name PetaJaringan
extends Control
## Peta kota "Jaringan Gosip" (kanvas Konsep A, papan 02/03/09): tiap warga digambar sebagai wajah,
## garis = tetangga (jalur tular), gugus distrik bercahaya warna emosi favoritnya.
## Posisi diambil dari SpreadSim lalu disusutkan ke pusat distrik supaya antar-gugus ada celah.
## Tap gugus -> Events.distrik_dipilih.
## Tiga lapisan supaya peta tidak digambar ulang penuh tiap frame (Era 4 dulu ±30 ms/frame di desktop):
##   PetaLatar (di belakang): kotak, grid, cahaya distrik; hanya saat ukuran/susunan distrik berubah.
##   node ini: garis tetangga, wajah warga, label distrik; hanya saat status warga, pilihan, bahasa,
##     atau ukuran berubah.
##   PetaAnimasi (di depan): denyut, gelembung, cincin TARGET; tiap frame selama ada animasi.

const SUSUT := 0.78
const PAD := 16.0
const JARAK_GRID := 32.0
const GARIS_PER_WARGA := 2
const UMUR_GELEMBUNG := PetaAnimasi.UMUR_GELEMBUNG

var dipilih := "":
	set(v):
		dipilih = v
		queue_redraw()
		if _animasi:
			_animasi.queue_redraw()

var _sim: SpreadSim
var _waktu := 0.0
var _font: Font
var _gaya_label: StyleBoxFlat
var _jejak := 0  # hash status warga terakhir yang digambar
var _animasi_sampai := 0.0  # detik (jam dinding) sampai animasi gelembung selesai
var _beranimasi := false
var _latar: PetaLatar
var _animasi: PetaAnimasi
var _atlas: AtlasWajah
## Posisi layar tiap warga dan jari-jari wajah; dihitung ulang saat ukuran atau simulasi berganti.
var _posisi := PackedVector2Array()
var _ukuran_posisi := Vector2.ZERO
var _r := 10.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(TutorialSasaran.PETA)
	_font = Tema.font_ui(700)
	_gaya_label = Palet.kotak(Color(Palet.MALAM, 0.88), Color.TRANSPARENT, 999)
	_latar = PetaLatar.new()
	_latar.peta = self
	add_child(_latar)
	_animasi = PetaAnimasi.new()
	_animasi.peta = self
	add_child(_animasi)
	_atlas = AtlasWajah.new()
	_atlas.siap.connect(queue_redraw)
	add_child(_atlas)
	Events.warga_berubah.connect(_on_warga_berubah)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: queue_redraw())
	resized.connect(_gambar_ulang_semua)


func atur_sim(sim: SpreadSim) -> void:
	_sim = sim
	_jejak = 0
	_posisi.clear()
	_gambar_ulang_semua()


func _gambar_ulang_semua() -> void:
	queue_redraw()
	if _latar:
		_latar.queue_redraw()
		_animasi.queue_redraw()


## Data untuk lapisan PetaLatar dan PetaAnimasi.
func sim() -> SpreadSim:
	return _sim


func posisi() -> PackedVector2Array:
	return _posisi


func jari() -> float:
	return _r


func waktu() -> float:
	return _waktu


## Atlas wajah (juga punya sel lingkaran putih untuk titik animasi); bisa belum siap.
func atlas() -> AtlasWajah:
	return _atlas


## Posisi layar warga siap dipakai (simulasi ada dan peta cukup besar untuk digambar).
func siap() -> bool:
	if _sim == null or _sim.posisi.is_empty():
		return false
	var d := _dalam()
	if d.size.x <= 0.0 or d.size.y <= 0.0:
		return false  # peta lebih kecil dari tepinya: sqrt di bawah akan NaN
	var n := _sim.posisi.size()
	if _posisi.size() != n or _ukuran_posisi != size:
		_ukuran_posisi = size
		_r = clampf(sqrt(d.size.x * d.size.y * SUSUT * SUSUT / n) * 0.27, 6.0, 17.0)
		_posisi.resize(n)
		for i in n:
			_posisi[i] = _layar(_sim.posisi[i], _sim.distrik_warga[i])
	return true


## warga_berubah dipancarkan tiap tick; gambar ulang hanya kalau ada status yang benar-benar berubah.
func _on_warga_berubah() -> void:
	if _sim == null:
		return
	var h := hash(_sim.status)
	if h != _jejak:
		_jejak = h
		_animasi_sampai = Time.get_ticks_msec() / 1000.0 + UMUR_GELEMBUNG
		queue_redraw()


func _process(delta: float) -> void:
	if _sim == null:
		return
	var aktif := _sim.ada_rumor_aktif() or Time.get_ticks_msec() / 1000.0 < _animasi_sampai
	if aktif:
		_waktu += delta
	# Satu gambar ulang lagi setelah animasi selesai supaya gelembung terakhir hilang.
	if aktif or _beranimasi:
		_animasi.queue_redraw()
	_beranimasi = aktif


## Pusat gugus distrik dalam koordinat lokal (dipakai untuk uang melayang).
func pusat_distrik(i: int) -> Vector2:
	return _rect_gugus(i).get_center()


## Kotak gugus distrik dalam koordinat lokal (cincin sorot tutorial).
func rect_distrik(i: int) -> Rect2:
	return _rect_gugus(i)


func _dalam() -> Rect2:
	return Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2.0)


func _area(i: int) -> Rect2:
	return SpreadSim.area_distrik(DataDB.districts[i]) if i < DataDB.districts.size() else Rect2()


## Titik kota (0..1) -> layar, disusutkan ke pusat distriknya.
func _layar(p: Vector2, distrik: int) -> Vector2:
	var c := _area(distrik).get_center()
	var q := c + (p - c) * SUSUT
	var d := _dalam()
	return d.position + q * d.size


func _rect_gugus(i: int) -> Rect2:
	var a := _area(i)
	var d := _dalam()
	var ukuran := a.size * SUSUT * d.size
	var pusat := d.position + a.get_center() * d.size
	return Rect2(pusat - ukuran / 2.0, ukuran)


func _draw() -> void:
	if not siap():
		return
	_gambar_garis(_posisi, _r)
	_gambar_wajah()
	for i in DataDB.districts.size():
		_gambar_label(i)


## Wajah dari atlas tekstur (satu potongan per warga); sebelum atlas siap, digambar langsung.
func _gambar_wajah() -> void:
	_atlas.siapkan(_r)
	if not _atlas.cocok(_r):
		for i in _posisi.size():
			GambarWajah.gambar(self, _posisi[i], _r, _sim.status[i], i)
		return
	var t := _atlas.tekstur
	var ukuran := Vector2(_atlas.sel(), _atlas.sel())
	var cahaya := _atlas.region_cahaya()
	var warna_cahaya := Color(Palet.PINK, 0.16)
	for i in _posisi.size():
		if _sim.status[i] == SpreadSim.Status.PERCAYA:
			draw_texture_rect_region(t, Rect2((_posisi[i] - ukuran / 2.0).round(), ukuran), cahaya, warna_cahaya)
	for i in _posisi.size():
		draw_texture_rect_region(t, Rect2((_posisi[i] - ukuran / 2.0).round(), ukuran), _atlas.region(_sim.status[i], i))


func r_cincin() -> float:
	return 14.0 + sin(_waktu * 4.0) * 3.0


func _gambar_garis(layar: PackedVector2Array, r: float) -> void:
	var tebal := maxf(2.0, r * 0.16)
	for i in layar.size():
		var t := _sim.tetangga(i)
		for k in mini(GARIS_PER_WARGA, t.size()):
			var j := t[k]
			if layar[i].distance_squared_to(layar[j]) < 1.0:
				continue
			var a := _sim.status[i]
			var b := _sim.status[j]
			var tular := _ikut(a) and _ikut(b)
			if _sim.distrik_warga[i] != _sim.distrik_warga[j]:
				draw_dashed_line(layar[i], layar[j], Color(Palet.PINK, 0.5) if tular else Color(Palet.TEKS_REDUP, 0.45), tebal, 8.0)
			else:
				draw_line(layar[i], layar[j], Color(Palet.PINK, 0.55) if tular else Color(Palet.GARIS, 0.55), tebal)


func _gambar_label(i: int) -> void:
	var data: Dictionary = DataDB.districts[i]
	var total := _sim.warga_per_distrik[i].size()
	var p := _sim.jumlah_status(i, SpreadSim.Status.PERCAYA)
	var nama := Bahasa.teks(data.get("nama", ""))
	var persen := "%d%%" % roundi(100.0 * p / maxi(total, 1))
	var ukuran := 20 if DataDB.districts.size() <= 3 else 18
	var lebar_nama := _font.get_string_size(nama, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	var lebar_persen := _font.get_string_size(persen, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	var lebar := 14.0 + 10.0 + lebar_nama + 8.0 + lebar_persen + 14.0
	var rg := _rect_gugus(i)
	var kotak := Rect2(Vector2(rg.get_center().x - lebar / 2.0, rg.position.y - ukuran - 8.0), Vector2(lebar, ukuran + 12.0))
	kotak.position.x = clampf(kotak.position.x, 6.0, size.x - lebar - 6.0)
	kotak.position.y = maxf(kotak.position.y, 6.0)
	draw_style_box(_gaya_label, kotak)
	var warna: Color = Palet.EMOSI_PETA.get(str(data.get("emosi_favorit", "netral")), Palet.GARIS)
	var tengah := kotak.position.y + kotak.size.y / 2.0
	draw_circle(Vector2(kotak.position.x + 19.0, tengah), 7.0, warna)
	var dasar := tengah + ukuran * 0.36
	draw_string(_font, Vector2(kotak.position.x + 34.0, dasar), nama, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Palet.TEKS)
	draw_string(_font, Vector2(kotak.position.x + 42.0 + lebar_nama, dasar), persen, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Color("ff8fb3"))
	if str(data.get("id", "")) == dipilih:
		_pin_target(Vector2(kotak.end.x - 4.0, kotak.position.y))


func _pin_target(p: Vector2) -> void:
	var teks := tr("UI_TARGET_TAG")
	var ukuran := 16
	var lebar := _font.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x + 20.0
	var kotak := Rect2(p + Vector2(-lebar + 6.0, -14.0), Vector2(lebar, 26.0))
	draw_style_box(Palet.tebal(Palet.PINK, Palet.PINK_GELAP, 999, 4), kotak)
	draw_string(_font, kotak.position + Vector2(10, 19), teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, Palet.TINTA)


func _ikut(s: int) -> bool:
	return s == SpreadSim.Status.PERCAYA or s == SpreadSim.Status.RAGU


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var p: Vector2 = event.position
	var terbaik := -1
	var jarak := INF
	for i in DataDB.districts.size():
		var rg := _rect_gugus(i).grow(12.0)
		if rg.has_point(p):
			terbaik = i
			break
		var dd := rg.get_center().distance_to(p)
		if dd < jarak:
			jarak = dd
			terbaik = i
	if terbaik >= 0:
		Events.distrik_dipilih.emit(str(DataDB.districts[terbaik].get("id", "")))
		accept_event()
