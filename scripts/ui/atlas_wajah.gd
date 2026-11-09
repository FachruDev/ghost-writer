class_name AtlasWajah
extends SubViewport
## Atlas tekstur wajah warga untuk PetaJaringan. Tiap kombinasi status × variasi (kulit 5 × rambut 6)
## digambar sekali lewat GambarWajah ke SubViewport ini, dibaca jadi ImageTexture, lalu tiap warga
## cukup digambar sebagai satu potongan tekstur (dulu ±10 perintah gambar per wajah, ±18 ms untuk
## 260 warga di desktop). Dibuat ulang hanya kalau jari-jari wajah berubah (ukuran peta atau era).
## Satu sel tambahan berisi lingkaran putih untuk cahaya pink di belakang warga yang percaya; cahaya
## tidak ikut di sel wajah karena warna semi-transparan berubah saat dibaca dari viewport transparan.
## Di mode headless viewport tidak dirender: tekstur tetap null dan peta menggambar wajah langsung.

signal siap

const VARIASI := 30  # Palet.KULIT (5) × Palet.RAMBUT (6); idx % 30 menentukan keduanya
const STATUS := 4
const KOLOM := 12

var tekstur: Texture2D = null

var _r := -1.0
var _sel := 0
var _kanvas: Control
var _menunggu := false
var _gagal := false  # render untuk _r tidak menghasilkan gambar (headless); jangan dicoba ulang


func _ready() -> void:
	transparent_bg = true
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	_kanvas = Control.new()
	_kanvas.draw.connect(_gambar)
	add_child(_kanvas)


## Atlas siap dipakai untuk jari-jari r.
func cocok(r: float) -> bool:
	return tekstur != null and is_equal_approx(r, _r)


## Lebar/tinggi satu sel (piksel): cukup untuk cahaya 1,9 × r.
func sel() -> int:
	return _sel


func region(status: int, idx: int) -> Rect2:
	return _rect_sel(status * VARIASI + idx % VARIASI)


func region_cahaya() -> Rect2:
	return _rect_sel(STATUS * VARIASI)


## Minta atlas untuk jari-jari r; sinyal siap dipancarkan setelah dirender (satu frame kemudian).
func siapkan(r: float) -> void:
	if is_equal_approx(r, _r) and (tekstur != null or _menunggu or _gagal):
		return
	_r = r
	tekstur = null
	_gagal = false
	_sel = ceili(r * 1.9) * 2 + 4
	var jumlah := STATUS * VARIASI + 1
	size = Vector2i(_sel * KOLOM, _sel * ceili(float(jumlah) / KOLOM))
	_kanvas.size = Vector2(size)
	_kanvas.queue_redraw()
	render_target_update_mode = SubViewport.UPDATE_ONCE
	_menunggu = true
	await RenderingServer.frame_post_draw
	_menunggu = false
	if not is_equal_approx(r, _r) or not is_inside_tree():
		return
	var gambar := get_texture().get_image()
	if gambar == null or gambar.is_empty() or gambar.get_pixelv(_rect_sel(0).get_center()).a < 0.5:
		_gagal = true
		return  # headless / renderer dummy: tetap gambar langsung
	tekstur = ImageTexture.create_from_image(gambar)
	siap.emit()


func _rect_sel(k: int) -> Rect2:
	return Rect2((k % KOLOM) * _sel, (k / KOLOM) * _sel, _sel, _sel)


func _gambar() -> void:
	for s in STATUS:
		for v in VARIASI:
			GambarWajah.gambar(_kanvas, _rect_sel(s * VARIASI + v).get_center(), _r, s, v, 0.0)
	_kanvas.draw_circle(region_cahaya().get_center(), _r * 1.9, Color.WHITE)
