extends Lembar
## "Selamat Datang Kembali" (papan 20): uang dari staf selama aplikasi tertutup (ADR-0003).
## Muncul sekali saat main memuat save dengan penghasilan offline; uang sudah masuk, AMBIL menutup.

var _hantu: Hantu
var _teks: Label
var _uang: Label
var _jam: Label
var _info: Label
var _ambil: Button


func _init() -> void:
	aksen = Palet.KUNING


func _bangun_isi() -> void:
	_hantu = Hantu.new()
	_hantu.suasana = Hantu.Suasana.GIRANG
	_hantu.custom_minimum_size = Vector2(0, 200)
	isi.add_child(_hantu)
	_teks = UiKit.label(isi, 28, Palet.TEKS_LEMBUT, Tema.font_ui(500))
	_teks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kotak := UiKit.panel(isi, Palet.MALAM, 32, 24)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 20)
	kotak.add_child(g)
	_uang = _angka(g, Palet.KUNING, "UI_UANG_KECIL")
	_jam = _angka(g, Palet.CYAN, "UI_KAMU_PERGI")
	_info = UiKit.label(isi, 22, Palet.TEKS_REDUP, Tema.font_ui(500))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ambil = UiKit.tombol_utama(isi, "", Palet.KUNING, Palet.KUNING_GELAP, Palet.TINTA)
	_ambil.pressed.connect(tutup)
	Events.feed_baru.connect(func(e: Dictionary) -> void:
		if str(e.get("jenis", "")) == "offline":
			set_meta("data", e)
			buka())


func _angka(induk: Control, warna: Color, kunci: String) -> Label:
	var k := UiKit.kolom(induk, 2)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := UiKit.label(k, 52, warna, Tema.font_judul())
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var l := UiKit.label(k, 22, Palet.TEKS_REDUP, Tema.font_ui(600), tr(kunci))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_meta("kunci", kunci)
	return v


func _segarkan() -> void:
	var e: Dictionary = get_meta("data", {})
	judul.text = tr("UI_SELAMAT_DATANG")
	_teks.text = tr("UI_STAF_BEKERJA")
	_uang.text = "+" + Bahasa.angka(int(e.get("uang", 0)))
	var jam := float(e.get("detik", 0)) / 3600.0
	var t := "%.1f" % jam
	_jam.text = tr("UI_JAM_PERGI") % (t.replace(".", ",") if Bahasa.kode() == "id" else t)
	_info.text = tr("UI_OFFLINE_INFO")
	_ambil.text = tr("UI_AMBIL")
