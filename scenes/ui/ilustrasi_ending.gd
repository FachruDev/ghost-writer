class_name IlustrasiEnding
extends Control
## Art ending (kanvas papan 17/18):
## - menang "Imperium Kabar Burung": Si Hantu bermahkota bersinar di atas tumpukan koran, bintang
##   berkelip, dan hujan koran mini (anim_ending)
## - kalah "Kota Mati Rasa": hantu kelabu di garis cakrawala sepi, ditemani kucing oren yang
##   mengibaskan ekor (satu-satunya yang masih mendengarkan)

const TINGGI := 300.0
const KUCING := Color("ff8a3d")
const KELABU := Color("c3cad8")
const JUMLAH_KORAN := 16

var menang := true:
	set(v):
		menang = v
		_atur()
var _t := 0.0
var _hantu: Hantu
var _koran: Array[Vector4] = []  # x, y, kecepatan, fase putar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, TINGGI)
	_hantu = Hantu.new()
	add_child(_hantu)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for i in JUMLAH_KORAN:
		_koran.append(Vector4(rng.randf(), rng.randf() * TINGGI, rng.randf_range(50.0, 110.0), rng.randf() * TAU))
	resized.connect(_atur)
	_atur()


func _atur() -> void:
	if _hantu == null:
		return
	_hantu.bermahkota = menang
	_hantu.suasana = Hantu.Suasana.GIRANG if menang else Hantu.Suasana.DIAM
	_hantu.modulate = Color.WHITE if menang else Color(0.78, 0.8, 0.86, 0.9)
	_hantu.size = Vector2(150, 188) if menang else Vector2(128, 160)
	if menang:
		_hantu.position = Vector2(size.x / 2.0 - 75.0, 22.0)
	else:
		_hantu.position = Vector2(size.x / 2.0 - 190.0, TINGGI - 60.0 - 160.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	if menang:
		for i in _koran.size():
			var k := _koran[i]
			k.y += k.z * delta
			if k.y > TINGGI + 20.0:
				k.y = -20.0
				k.x = randf()
			_koran[i] = k
	queue_redraw()


func _draw() -> void:
	if menang:
		_gambar_menang()
	else:
		_gambar_kalah()


func _gambar_menang() -> void:
	var pusat := Vector2(size.x / 2.0, 130.0)
	for k in 6:
		draw_circle(pusat, 150.0 - k * 22.0, Color(Palet.KUNING, 0.05))
	# Tumpukan koran sebagai podium.
	for k in 3:
		var r := Rect2(size.x / 2.0 - 150.0 + k * 10.0, TINGGI - 70.0 + k * 18.0 - 36.0, 300.0 - k * 20.0, 30.0)
		_koran_lembar(r, Palet.KERTAS if k % 2 == 0 else Color("efe9da"), (k - 1) * 0.03)
	for b in [[Vector2(-220, 40), Palet.KUNING, 14.0, 0.0], [Vector2(210, 70), Palet.PINK, 18.0, 1.3],
			[Vector2(-170, 170), Palet.CYAN, 11.0, 2.1]]:
		var denyut := 0.6 + 0.4 * sin(_t * 4.0 + b[3])
		_bintang(Vector2(size.x / 2.0, 0.0) + b[0], float(b[2]) * denyut, Color(b[1], 0.35 + 0.65 * denyut))
	for k in _koran:
		var c := Vector2(k.x * size.x, k.y)
		draw_set_transform(c, sin(_t * 2.0 + k.w) * 0.6, Vector2.ONE)
		_koran_lembar(Rect2(-14.0, -10.0, 28.0, 20.0), Color(Palet.KERTAS, 0.85), 0.0)
		draw_set_transform(Vector2.ZERO)


func _gambar_kalah() -> void:
	var tanah := TINGGI - 60.0
	draw_rect(Rect2(size.x / 2.0 - 260.0, tanah, 520.0, 10.0), Color("3a3a4a"))
	# Kucing oren duduk di kanan, ekor dikibas.
	var c := Vector2(size.x / 2.0 + 120.0, tanah)
	var ekor := sin(_t * 3.9) * 0.4
	var pangkal := c + Vector2(-44.0, -16.0)
	draw_line(pangkal, pangkal + Vector2.from_angle(PI + 0.5 + ekor) * 44.0, KUCING, 12.0)
	draw_circle(pangkal + Vector2.from_angle(PI + 0.5 + ekor) * 44.0, 6.0, KUCING)
	_elips(c + Vector2(0.0, -34.0), Vector2(48.0, 34.0), KUCING)
	var kepala := c + Vector2(30.0, -78.0)
	draw_colored_polygon(PackedVector2Array([kepala + Vector2(-26, -14), kepala + Vector2(-18, -44), kepala + Vector2(-4, -22)]), KUCING)
	draw_colored_polygon(PackedVector2Array([kepala + Vector2(4, -22), kepala + Vector2(18, -44), kepala + Vector2(26, -14)]), KUCING)
	draw_circle(kepala, 30.0, KUCING)
	var kedip := 1.0 if fmod(_t, 3.2) > 0.15 else 0.2
	for x in [-11.0, 11.0]:
		_elips(kepala + Vector2(x, -4.0), Vector2(4.0, 6.0 * kedip), Palet.TINTA)
	draw_line(kepala + Vector2(-5, 9), kepala + Vector2(0, 12), Palet.TINTA, 3.0)
	draw_line(kepala + Vector2(0, 12), kepala + Vector2(5, 9), Palet.TINTA, 3.0)


func _koran_lembar(r: Rect2, warna: Color, miring: float) -> void:
	if miring != 0.0:
		draw_set_transform(r.get_center(), miring, Vector2.ONE)
		r.position = -r.size / 2.0
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = warna
	gaya.set_corner_radius_all(4)
	draw_style_box(gaya, r)
	var garis := maxi(1, int(r.size.y / 10.0))
	for i in garis:
		var y := r.position.y + 6.0 + i * (r.size.y - 10.0) / maxf(garis, 1)
		draw_line(Vector2(r.position.x + 6.0, y), Vector2(r.end.x - 6.0 - i * 6.0, y), Color(Palet.TINTA, 0.35), 2.0)
	if miring != 0.0:
		draw_set_transform(Vector2.ZERO)


func _elips(c: Vector2, r: Vector2, warna: Color) -> void:
	var titik := PackedVector2Array()
	for k in 20:
		titik.append(c + Vector2(cos(TAU * k / 20.0) * r.x, sin(TAU * k / 20.0) * r.y))
	draw_colored_polygon(titik, warna)


func _bintang(c: Vector2, r: float, warna: Color) -> void:
	var titik := PackedVector2Array()
	for k in 8:
		titik.append(c + Vector2.from_angle(k * TAU / 8.0 - PI / 2.0) * (r if k % 2 == 0 else r * 0.3))
	draw_colored_polygon(titik, warna)
