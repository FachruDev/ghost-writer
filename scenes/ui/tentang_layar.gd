extends Lembar
## Layar Tentang (dibuka dari Pengaturan): maskot, nama game, ringkasan, dan versi, lalu kredit aset
## pihak ketiga dari data/kredit.json (huruf, musik, efek suara) dan Godot Engine. Teks lisensi OFL
## dan Godot (beserta komponen pihak ketiganya) bisa dibuka per baris. Aset buatan sendiri (jenis
## "proyek") tidak ditampilkan.

## Kelompok kredit berurutan: jenis di kredit.json -> kunci judul, ikon, warna ubin.
const KELOMPOK := [
	{"jenis": "font", "kunci": "UI_KREDIT_FONT", "ikon": "pena", "warna": Palet.CYAN},
	{"jenis": "musik", "kunci": "UI_KREDIT_MUSIK", "ikon": "musik", "warna": Palet.PINK},
	{"jenis": "suara", "kunci": "UI_KREDIT_SUARA", "ikon": "suara", "warna": Palet.KUNING},
]

var _gulir: ScrollContainer
var _konten: VBoxContainer


func _init() -> void:
	penuh = true


func _bangun_isi() -> void:
	_gulir = ScrollContainer.new()
	_gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	isi.add_child(_gulir)
	Events.layar_diminta.connect(func(n: String) -> void:
		if n == "tentang":
			buka())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void:
		if visible:
			_segarkan())


## Isi dibangun ulang tiap dibuka dan saat bahasa berganti (sedikit node, teks lisensi tetap malas).
func _segarkan() -> void:
	judul.text = tr("UI_TENTANG")
	if _konten:
		_gulir.remove_child(_konten)
		_konten.queue_free()
	_konten = UiKit.kolom(null, 24)
	_konten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gulir.add_child(_konten)
	_kepala()
	var kredit := UiKit.label(_konten, 24, Palet.TEKS_REDUP, Tema.font_ui(700), tr("UI_KREDIT").to_upper())
	kredit.custom_minimum_size.y = 40
	kredit.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	for k in KELOMPOK:
		var baris: Array[KreditBaris] = []
		for e in DataDB.kredit:
			if e.get("jenis") == k["jenis"]:
				baris.append(_baris_data(e))
		if not baris.is_empty():
			_kelompok(tr(k["kunci"]), k["ikon"], k["warna"], baris)
	var godot := KreditBaris.new("Godot Engine", KreditBaris.hak_cipta_godot(), tr("UI_KREDIT_GODOT_KET"),
		func() -> Array: return KreditBaris.lisensi_godot())
	_kelompok(tr("UI_KREDIT_MESIN"), "server", Palet.HIJAU, [godot])
	_gulir.scroll_vertical = 0


## Kartu pembuka: hantu + logo + slogan, ringkasan game, versi dan catatan fiksi.
func _kepala() -> void:
	var p := UiKit.panel(_konten, Palet.PANEL, 36, 28)
	var k := UiKit.kolom(p, 20)
	var atas := UiKit.baris(k, 20)
	var hantu := Hantu.new()
	hantu.custom_minimum_size = Vector2(128, 160)
	atas.add_child(hantu)
	var kanan := UiKit.kolom(atas, 12)
	kanan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kanan.alignment = BoxContainer.ALIGNMENT_CENTER
	var logo := UiKit.label(kanan, 60, Color.WHITE, Tema.font_judul(), tr("UI_JUDUL_GAME"))
	logo.add_theme_color_override("font_shadow_color", Palet.PINK)
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 6)
	var slogan := UiKit.pil(kanan, tr("UI_TAGLINE"), Palet.KUNING, Palet.TINTA, 22)
	slogan.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var ringkas := UiKit.label(k, 26, Palet.TEKS_LEMBUT, Tema.font_ui(500), tr("UI_TENTANG_ISI"))
	ringkas.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var versi := UiKit.label(k, 22, Palet.TEKS_REDUP, Tema.font_ui(500),
		tr("UI_VERSI") % str(ProjectSettings.get_setting("application/config/version")))
	versi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Kartu satu kelompok: ubin ikon berwarna + nama kelompok, lalu baris-baris kredit bergaris pemisah.
func _kelompok(nama: String, ikon: String, warna: Color, baris: Array) -> void:
	var p := UiKit.panel(_konten, Palet.PANEL, 36, 28)
	var k := UiKit.kolom(p, 20)
	var kepala := UiKit.baris(k, 16)
	var ubin := UiKit.panel(kepala, warna, 20, 12)
	ubin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiKit.ikon(ubin, ikon, 36, Palet.TINTA)
	var label := UiKit.label(kepala, 30, Palet.TEKS, Tema.font_ui(700), nama)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for i in baris.size():
		if i > 0:
			var garis := ColorRect.new()
			garis.color = Color(Palet.GARIS, 0.5)
			garis.custom_minimum_size.y = 2
			garis.mouse_filter = Control.MOUSE_FILTER_IGNORE
			k.add_child(garis)
		k.add_child(baris[i])


func _baris_data(e: Dictionary) -> KreditBaris:
	var oleh := str(e.get("oleh", ""))
	var ket: Array[String] = []
	for kunci in ["sumber", "lisensi"]:
		if not str(e.get(kunci, "")).is_empty():
			ket.append(str(e[kunci]))
	var lisensi := Callable()
	if e.has("teks_lisensi"):
		lisensi = KreditBaris.dari_file(str(e["teks_lisensi"]))
	return KreditBaris.new(str(e.get("judul", "")), tr("UI_KREDIT_OLEH") % oleh if not oleh.is_empty() else "",
		" · ".join(PackedStringArray(ket)), lisensi)


## Semua baris kredit yang sedang tampil (untuk tes).
func baris() -> Array[KreditBaris]:
	var hasil: Array[KreditBaris] = []
	if _konten:
		_kumpulkan(_konten, hasil)
	return hasil


func _kumpulkan(n: Node, hasil: Array[KreditBaris]) -> void:
	for c in n.get_children():
		if c is KreditBaris:
			hasil.append(c)
		else:
			_kumpulkan(c, hasil)
