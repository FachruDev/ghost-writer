extends CanvasLayer
## Lapisan tutorial (CHECKLIST 0.9.0): tangan yang mengetuk sasaran, cincin sorot kuning, dan
## gelembung Si Hantu (langkah, teks, Lewati). Hanya tampilan: langkahnya dari
## Events.tutorial_langkah (TutorialController), node sasarannya dicari lewat grup (TutorialSasaran).
## Tidak menghalangi permainan: semua ketukan tembus kecuali tombol Lewati.
## CanvasLayer supaya tetap di atas toko (Lembar.buka() memindahkan lembar ke paling depan).

const LAPIS := 20
const JARAK := 24.0  # jarak gelembung dari zona sasaran
const TEPI := 24.0
const LAMA_SELESAI := 3.0

var _info: Dictionary = {}
var _sasaran: Dictionary = {}
var _kanvas: Control
var _tangan: TanganTunjuk
var _gelembung: TutorialGelembung
var _sorot := StyleBoxFlat.new()
var _digulir := 0  # instance id sasaran yang sudah digulir ke layar
var _t := 0.0


func _ready() -> void:
	layer = LAPIS
	_kanvas = Control.new()
	_kanvas.theme = Tema.buat()  # tema tidak menurun melewati CanvasLayer
	_kanvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kanvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_kanvas.visible = false
	_kanvas.draw.connect(_gambar_sorot)
	add_child(_kanvas)
	_tangan = TanganTunjuk.new()
	_tangan.visible = false
	_kanvas.add_child(_tangan)
	_gelembung = TutorialGelembung.new()
	_kanvas.add_child(_gelembung)
	_gelembung.dilewati.connect(func() -> void: Events.tutorial_dilewati.emit())
	_sorot.draw_center = false
	_sorot.anti_aliasing = true
	Events.tutorial_langkah.connect(_on_langkah)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _gelembung.segarkan_teks())


func _on_langkah(info: Dictionary) -> void:
	var lama := _info
	_info = info
	_digulir = 0
	if not info.is_empty():
		_gelembung.tampilkan(info)
		_kanvas.visible = true
		return
	var tamat := int(lama.get("langkah", 0)) == TutorialController.JUMLAH_LANGKAH \
		and TutorialController.selesai(GameState) and not bool(GameState.statistik.get("tutorial_lewat", false))
	if not tamat:
		_kanvas.visible = false
		return
	_gelembung.rayakan()
	_kanvas.visible = true
	var t := create_tween()
	t.tween_interval(LAMA_SELESAI)
	t.tween_callback(func() -> void:
		if _info.is_empty():
			_kanvas.visible = false)


func _process(delta: float) -> void:
	if not _kanvas.visible:
		return
	_t = fmod(_t + delta, TanganTunjuk.PERIODE)
	_sasaran = {} if _info.is_empty() else TutorialSasaran.cari(get_tree(), _info)
	var node: Control = _sasaran.get("node")
	# Lembar lain (dilema, tokoh, pengaturan, ...) menutupi sasaran: diam dulu sampai ditutup.
	var lembar := _lembar_teratas()
	var tertutup := not _info.is_empty() and lembar != null and (node == null or not lembar.is_ancestor_of(node))
	_gelembung.visible = not tertutup
	_tangan.visible = node != null and not tertutup and TutorialSasaran.terlihat(node)
	var zona := Rect2()
	if _tangan.visible:
		var r: Rect2 = _sasaran["rect"]
		_tangan.cermin = r.get_center().x > _kanvas.size.x * 0.6
		var di_bawah := r.get_center().y > _kanvas.size.y - 220.0
		_tangan.miring = TanganTunjuk.MIRING_BAWAH if di_bawah else TanganTunjuk.MIRING
		# Dekat tepi bawah: ujung jari sedikit di atas tengah supaya badan tangan tidak terpotong layar.
		_tangan.position = Vector2(r.get_center().x, r.position.y + r.size.y * (0.35 if di_bawah else 0.5))
		var batas := _tangan.batas()
		batas.position += _tangan.position
		zona = (_sasaran["zona"] as Rect2).merge(batas)
		if lembar and not lembar.penuh:  # sasaran di lembar bawah (saluran): judulnya jangan tertutup
			zona = zona.merge(lembar.judul.get_global_rect().grow(40.0))
	elif node != null and not tertutup:
		_gulir_sekali(node)
	_letakkan_gelembung(zona)
	_kanvas.queue_redraw()


## Lembar yang terbuka paling depan (Lembar.buka() memindahkannya ke anak terakhir main).
func _lembar_teratas() -> Lembar:
	var induk := get_parent()
	for i in range(induk.get_child_count() - 1, -1, -1):
		var l := induk.get_child(i) as Lembar
		if l and l.visible:
			return l
	return null


## Sasaran di luar bagian gulir yang tampak (mis. kartu toko di bawah): gulir sekali ke sana.
func _gulir_sekali(node: Control) -> void:
	if node.get_instance_id() == _digulir:
		return
	_digulir = node.get_instance_id()
	var g := TutorialSasaran.gulir_induk(node)
	if g:
		await get_tree().process_frame
		if is_instance_valid(g) and is_instance_valid(node):
			g.ensure_control_visible(node)


## Gelembung di sisi zona sasaran yang lebih lega; tanpa sasaran, sedikit di atas tengah layar.
func _letakkan_gelembung(zona: Rect2) -> void:
	var layar := _kanvas.size
	var inset := UiKit.inset_aman(_kanvas)
	var lebar := layar.x - TEPI * 2.0
	_gelembung.atur_lebar(lebar)
	var tinggi := _gelembung.get_combined_minimum_size().y
	_gelembung.size = Vector2(lebar, tinggi)
	_gelembung.pivot_offset = _gelembung.size / 2.0
	var atas := inset.x + TEPI
	var bawah := layar.y - inset.y - TEPI
	var y := (layar.y - tinggi) * 0.42
	if zona.has_area():
		var lega_atas := zona.position.y - atas
		var lega_bawah := bawah - zona.end.y
		y = zona.position.y - JARAK - tinggi if lega_atas >= lega_bawah else zona.end.y + JARAK
	_gelembung.position = Vector2(TEPI, clampf(y, atas, maxf(atas, bawah - tinggi)))


## Cincin kuning di sekeliling sasaran plus denyut yang mengembang seirama ketukan tangan.
func _gambar_sorot() -> void:
	if not _tangan.visible or _sasaran.is_empty():
		return
	var r: Rect2 = _sasaran["rect"]
	var radius: float = _sasaran.get("radius", 28.0)
	var q := _t / TanganTunjuk.PERIODE
	_cincin(r.grow(8.0), radius + 8.0, Palet.KUNING, 6.0)
	var g := 8.0 + 20.0 * q
	_cincin(r.grow(g), radius + g, Color(Palet.KUNING, 0.6 * (1.0 - q)), 4.0)


func _cincin(r: Rect2, radius: float, warna: Color, tebal: float) -> void:
	_sorot.border_color = warna
	_sorot.set_border_width_all(int(tebal))
	_sorot.set_corner_radius_all(int(minf(radius, minf(r.size.x, r.size.y) / 2.0)))
	_kanvas.draw_style_box(_sorot, r)
