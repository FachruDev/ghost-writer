class_name PetaJaringan
extends Control
## Peta kota "Jaringan Gosip" (kanvas Konsep A, papan 02/03/09): tiap warga digambar sebagai wajah,
## garis = tetangga (jalur tular), gugus distrik bercahaya warna emosi favoritnya.
## Posisi diambil dari SpreadSim lalu disusutkan ke pusat distrik supaya antar-gugus ada celah.
## Tap gugus -> Events.distrik_dipilih.
## Digambar ulang hanya saat status warga berubah, pilihan/bahasa/ukuran berubah, atau selama ada
## animasi (rumor menjalar, gelembung baru) — bukan setiap frame (hemat baterai HP kelas bawah).

const SUSUT := 0.78
const PAD := 16.0
const JARAK_GRID := 32.0
const GARIS_PER_WARGA := 2
const UMUR_GELEMBUNG := 2.5

var dipilih := "":
	set(v):
		dipilih = v
		queue_redraw()

var _sim: SpreadSim
var _waktu := 0.0
var _cahaya: GradientTexture2D
var _font: Font
var _gaya_label: StyleBoxFlat
var _jejak := 0  # hash status warga terakhir yang digambar
var _animasi_sampai := 0.0  # detik (jam dinding) sampai animasi gelembung selesai


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(TutorialSasaran.PETA)
	_font = Tema.font_ui(700)
	_gaya_label = Palet.kotak(Color(Palet.MALAM, 0.88), Color.TRANSPARENT, 999)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.5))
	g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.6, Color(1, 1, 1, 0.16))
	_cahaya = GradientTexture2D.new()
	_cahaya.gradient = g
	_cahaya.fill = GradientTexture2D.FILL_RADIAL
	_cahaya.fill_from = Vector2(0.5, 0.5)
	_cahaya.fill_to = Vector2(1.0, 0.5)
	_cahaya.width = 128
	_cahaya.height = 128
	Events.warga_berubah.connect(_on_warga_berubah)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: queue_redraw())
	resized.connect(queue_redraw)


func atur_sim(sim: SpreadSim) -> void:
	_sim = sim
	_jejak = 0
	queue_redraw()


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
	if _sim.ada_rumor_aktif() or Time.get_ticks_msec() / 1000.0 < _animasi_sampai:
		_waktu += delta
		queue_redraw()


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
	draw_style_box(Palet.kotak(Palet.PETA, Color.TRANSPARENT, 40), Rect2(Vector2.ZERO, size))
	var y := JARAK_GRID / 2.0
	while y < size.y:
		var x := JARAK_GRID / 2.0
		while x < size.x:
			draw_circle(Vector2(x, y), 2.0, Palet.PANEL_2)
			x += JARAK_GRID
		y += JARAK_GRID
	if _sim == null or _sim.posisi.is_empty():
		return
	var n := _sim.posisi.size()
	var d := _dalam()
	var r := clampf(sqrt(d.size.x * d.size.y * SUSUT * SUSUT / n) * 0.27, 6.0, 17.0)
	for i in DataDB.districts.size():
		_gambar_cahaya(i)
	var layar := PackedVector2Array()
	layar.resize(n)
	for i in n:
		layar[i] = _layar(_sim.posisi[i], _sim.distrik_warga[i])
	_gambar_garis(layar, r)
	_gambar_denyut(layar, r)
	for i in n:
		GambarWajah.gambar(self, layar[i], r, _sim.status[i], i)
	_gambar_gelembung(layar, r)
	for i in DataDB.districts.size():
		_gambar_label(i)


func _gambar_cahaya(i: int) -> void:
	var rg := _rect_gugus(i).grow(minf(size.x, size.y) * 0.08)
	var warna: Color = Palet.EMOSI_PETA.get(str(DataDB.districts[i].get("emosi_favorit", "netral")), Palet.GARIS)
	draw_texture_rect(_cahaya, rg, false, warna)
	if str(DataDB.districts[i].get("id", "")) == dipilih:
		_elips_putus(_rect_gugus(i).grow(r_cincin()), Palet.PINK)


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


## Titik pink merambat dari warga yang sedang menular ke tetangganya.
func _gambar_denyut(layar: PackedVector2Array, r: float) -> void:
	for i in layar.size():
		if not _sim.sedang_menular(i):
			continue
		var t := _sim.tetangga(i)
		for k in mini(3, t.size()):
			var j := t[k]
			if _sim.status[j] == SpreadSim.Status.KEBAL:
				continue
			var f := fmod(_waktu * 1.6 + i * 0.137 + k * 0.33, 1.0)
			var p := layar[i].lerp(layar[j], f)
			draw_circle(p, r * 0.75, Color(Palet.PINK, 0.25))
			draw_circle(p, r * 0.38, Palet.PINK)
		var umur := _sim.jam - _sim.terakhir_berubah[i]
		if umur < Balance.DURASI_DENYUT_DETIK:
			var u := umur / Balance.DURASI_DENYUT_DETIK
			draw_arc(layar[i], r + 4.0 + u * r * 1.6, 0.0, TAU, 24, Color(Palet.STATUS[_sim.status[i]], 1.0 - u), 3.0)


## Gelembung "!"/"?" hanya untuk warga yang baru berubah, supaya peta tidak penuh.
func _gambar_gelembung(layar: PackedVector2Array, r: float) -> void:
	for i in layar.size():
		var s := _sim.status[i]
		if s != SpreadSim.Status.PERCAYA and s != SpreadSim.Status.RAGU:
			continue
		if _sim.jam - _sim.terakhir_berubah[i] > UMUR_GELEMBUNG:
			continue
		GambarWajah.gelembung(self, layar[i], r, s, _font, absf(sin(_waktu * 5.0 + i)) * r * 0.25)


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


func _elips_putus(rg: Rect2, warna: Color) -> void:
	var c := rg.get_center()
	var rx := rg.size.x / 2.0
	var ry := rg.size.y / 2.0
	var langkah := 40
	for k in langkah:
		if k % 2 == 1:
			continue
		var a0 := TAU * k / langkah + _waktu * 0.3
		var a1 := TAU * (k + 1) / langkah + _waktu * 0.3
		draw_line(c + Vector2(cos(a0) * rx, sin(a0) * ry), c + Vector2(cos(a1) * rx, sin(a1) * ry), warna, 4.0)


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
