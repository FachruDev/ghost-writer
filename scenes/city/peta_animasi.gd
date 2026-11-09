class_name PetaAnimasi
extends Control
## Lapisan animasi peta (di depan wajah warga): titik pink yang merambat, cincin denyut warga yang baru
## berubah, gelembung "!"/"?", dan cincin putus-putus distrik TARGET. Hanya lapisan ini yang digambar
## ulang tiap frame selama ada animasi; wajah dan garis di PetaJaringan tidak ikut digambar ulang.

const UMUR_GELEMBUNG := 2.5

var peta: PetaJaringan
var _font: Font


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
	_denyut(sim, layar, r)
	for i in layar.size():
		var s := sim.status[i]
		if s != SpreadSim.Status.PERCAYA and s != SpreadSim.Status.RAGU:
			continue
		if sim.jam - sim.terakhir_berubah[i] > UMUR_GELEMBUNG:
			continue
		GambarWajah.gelembung(self, layar[i], r, s, _font, absf(sin(peta.waktu() * 5.0 + i)) * r * 0.25)


## Titik pink merambat dari warga yang sedang menular ke tetangganya, plus cincin denyut warga baru.
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
			draw_circle(p, r * 0.75, Color(Palet.PINK, 0.25))
			draw_circle(p, r * 0.38, Palet.PINK)
		var umur := sim.jam - sim.terakhir_berubah[i]
		if umur < Balance.DURASI_DENYUT_DETIK:
			var u := umur / Balance.DURASI_DENYUT_DETIK
			draw_arc(layar[i], r + 4.0 + u * r * 1.6, 0.0, TAU, 24, Color(Palet.STATUS[sim.status[i]], 1.0 - u), 3.0)


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
