class_name PetaAnimasi
extends Control
## Lapisan animasi peta (di depan wajah warga): titik pink yang merambat, cincin denyut warga yang baru
## berubah, gelembung "!"/"?", dan cincin putus-putus distrik TARGET. Hanya lapisan ini yang digambar
## ulang tiap frame selama ada animasi; wajah dan garis di PetaJaringan tidak ikut digambar ulang.

const UMUR_GELEMBUNG := 2.5

var peta: PetaJaringan
var _font: Font
var _tekstur: Texture2D
var _cakram := Rect2()
var _skala := 1.0
var _lebar_teks := {}  # "!20" -> lebar piksel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font = Tema.font_ui(700)


func _draw() -> void:
	if peta == null or not peta.siap():
		return
	var sim := peta.sim()
	var layar := peta.posisi()
	var r := peta.jari()
	var dipilih := DataDB.district_index(peta.dipilih) if not peta.dipilih.is_empty() else -1
	if dipilih >= 0:
		_elips_putus(peta.rect_distrik(dipilih).grow(peta.r_cincin()), Palet.PINK)
	var atlas := peta.atlas()
	_tekstur = atlas.tekstur if atlas and atlas.cocok(r) else null
	if _tekstur:
		_cakram = atlas.region_cahaya()
		_skala = atlas.sel() / (AtlasWajah.JARI_CAHAYA * r)
	_denyut(sim, layar, r)
	for i in layar.size():
		var s := sim.status[i]
		if s != SpreadSim.Status.PERCAYA and s != SpreadSim.Status.RAGU:
			continue
		if sim.jam - sim.terakhir_berubah[i] > UMUR_GELEMBUNG:
			continue
		_gelembung(layar[i], r, s, absf(sin(peta.waktu() * 5.0 + i)) * r * 0.25)


## Sama dengan GambarWajah.gelembung, tapi lingkarannya dari atlas dan lebar teks di-cache.
func _gelembung(c: Vector2, r: float, status: int, naik: float) -> void:
	var b := maxf(9.0, r * 0.75)
	var p := c + Vector2(r * 0.85, -r * 1.25 - naik)
	var percaya := status == SpreadSim.Status.PERCAYA
	_titik(p, b, Palet.PINK if percaya else Palet.KUNING)
	var teks := "!" if percaya else "?"
	var ukuran := int(b * 1.5)
	var kunci := teks + str(ukuran)
	if not _lebar_teks.has(kunci):
		_lebar_teks[kunci] = _font.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x
	draw_string(_font, p + Vector2(-float(_lebar_teks[kunci]) / 2.0, ukuran * 0.36), teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran, GambarWajah.TINTA)


## Titik pink merambat dari warga yang sedang menular ke tetangganya, plus cincin denyut warga baru.
## Saat rumor server bisa ±100 warga menular sekaligus (±600 titik): titik diambil dari sel lingkaran
## putih di atlas wajah, bukan draw_circle (dulu ±20 ms/frame di desktop pada puncaknya).
func _denyut(sim: SpreadSim, layar: PackedVector2Array, r: float) -> void:
	var waktu := peta.waktu()
	for i in layar.size():
		if not sim.sedang_menular(i):
			continue
		var t := sim.tetangga(i)
		for k in mini(3, t.size()):
			var j := t[k]
			if sim.status[j] == SpreadSim.Status.KEBAL:
				continue
			var f := fmod(waktu * 1.6 + i * 0.137 + k * 0.33, 1.0)
			var p := layar[i].lerp(layar[j], f)
			_titik(p, r * 0.75, Color(Palet.PINK, 0.25))
			_titik(p, r * 0.38, Palet.PINK)
		var umur := sim.jam - sim.terakhir_berubah[i]
		if umur < Balance.DURASI_DENYUT_DETIK:
			var u := umur / Balance.DURASI_DENYUT_DETIK
			draw_arc(layar[i], r + 4.0 + u * r * 1.6, 0.0, TAU, 24, Color(Palet.STATUS[sim.status[i]], 1.0 - u), 3.0)


## Lingkaran penuh berjari-jari jari di p: potongan tekstur kalau atlas siap, kalau tidak draw_circle.
func _titik(p: Vector2, jari: float, warna: Color) -> void:
	if _tekstur == null:
		draw_circle(p, jari, warna)
		return
	var sisi := jari * _skala
	draw_texture_rect_region(_tekstur, Rect2(p - Vector2(sisi, sisi) / 2.0, Vector2(sisi, sisi)), _cakram, warna)


func _elips_putus(rg: Rect2, warna: Color) -> void:
	var c := rg.get_center()
	var rx := rg.size.x / 2.0
	var ry := rg.size.y / 2.0
	var langkah := 40
	var geser := peta.waktu() * 0.3
	for k in range(0, langkah, 2):
		var a0 := TAU * k / langkah + geser
		var a1 := TAU * (k + 1) / langkah + geser
		draw_line(c + Vector2(cos(a0) * rx, sin(a0) * ry), c + Vector2(cos(a1) * rx, sin(a1) * ry), warna, 4.0)
