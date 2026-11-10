extends Lembar
## Lembar "Tokoh Target" (papan 14): tiga tokoh fiktif dengan potret, reputasi, pertahanan, hadiah;
## yang sudah jatuh diberi stempel JATUH!. Di bawahnya status Kampanye Akhir.


## Potret tokoh sederhana: kepala, rambut/sanggul, kumis atau kacamata, setelan berwarna.
class Potret extends Control:
	var tokoh_id := ""
	var jatuh := false

	func _draw() -> void:
		var s := size.x / 72.0
		var gaya: Array = {"hartono": [Color("e8b48a"), Color("3b3f6e"), "botak"], "sasmita": [Color("ffd9b0"), Color("7c4deb"), "sanggul"],
			"bramantyo": [Color("c98c62"), Palet.MALAM, "klimis"]}.get(tokoh_id, [Color("e8b48a"), Palet.GARIS, ""])
		draw_style_box(Palet.kotak(Palet.PANEL_2 if jatuh else Palet.KUNING, Color.TRANSPARENT, int(20 * s)), Rect2(Vector2.ZERO, size))
		var badan := StyleBoxFlat.new()
		badan.bg_color = gaya[1]
		badan.corner_radius_top_left = int(18 * s)
		badan.corner_radius_top_right = int(18 * s)
		draw_style_box(badan, Rect2(Vector2(12, 52) * s, Vector2(48, 32) * s))
		var c := Vector2(36, 34) * s
		draw_circle(c, 18 * s, gaya[0])
		var tinta := Palet.TINTA
		match str(gaya[2]):
			"botak":
				draw_rect(Rect2(Vector2(24, 14) * s, Vector2(24, 4) * s), Color("b9b2da"))
				draw_rect(Rect2(Vector2(28, 40) * s, Vector2(16, 4) * s), Color("2b1b12"))
			"sanggul":
				draw_circle(Vector2(36, 12) * s, 10 * s, Color("2b1b12"))
				draw_rect(Rect2(Vector2(19, 15) * s, Vector2(34, 7) * s), Color("2b1b12"))
				draw_rect(Rect2(Vector2(21, 28) * s, Vector2(30, 9) * s), tinta, false, 2.5 * s)
			"klimis":
				draw_rect(Rect2(Vector2(17, 13) * s, Vector2(38, 9) * s), Color("120e26"))
		draw_rect(Rect2(Vector2(27, 30) * s, Vector2(4, 5) * s), tinta)
		draw_rect(Rect2(Vector2(41, 30) * s, Vector2(4, 5) * s), tinta)
		draw_line(Vector2(30, 47) * s, Vector2(42, 47) * s, tinta, 3 * s)
		if jatuh:
			draw_rect(Rect2(Vector2.ZERO, size), Color(Palet.MALAM, 0.45))


var _daftar: VBoxContainer
var _sub: Label
var _final: PanelContainer


func _bangun_isi() -> void:
	_sub = UiKit.label(isi, 24, Palet.TEKS_REDUP, Tema.font_ui(500))
	var petunjuk := UiKit.label(isi, 24, Palet.TEKS_LEMBUT, Tema.font_ui(500))
	petunjuk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	petunjuk.set_meta("kunci", "UI_TOKOH_PETUNJUK")
	_daftar = UiKit.kolom(isi, 16)
	_final = UiKit.panel(isi, Palet.PANEL, 32, 20)
	Events.layar_diminta.connect(func(nama: String) -> void:
		if nama == "tokoh":
			buka())
	Events.tokoh_berubah.connect(func() -> void:
		if visible:
			_segarkan())


func _segarkan() -> void:
	judul.text = tr("UI_TOKOH_JUDUL")
	(isi.get_child(1) as Label).text = tr("UI_TOKOH_PETUNJUK")
	for anak in _daftar.get_children() + _final.get_children():
		anak.get_parent().remove_child(anak)
		anak.queue_free()
	var jatuh := 0
	for t in DataDB.tokoh:
		var maks := int(t.get("reputasi", 1000))
		var rep := int(GameState.tokoh_reputasi.get(t["id"], maks))
		if rep <= 0:
			jatuh += 1
		_kartu(t, rep, maks)
	_sub.text = tr("UI_TOKOH_JATUH_N") % [jatuh, DataDB.tokoh.size()]
	var bisa := FinalController.bisa_mulai()
	(_final.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Palet.PINK if bisa else Palet.GARIS
	(_final.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(4)
	var h := UiKit.baris(_final, 18)
	if bisa:
		var b := UiKit.tombol_utama(h, tr("UI_FINAL_TOMBOL").to_upper())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			tutup()
			Events.layar_diminta.emit("final"))
		return
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(88, 88)
	tile.add_theme_stylebox_override("panel", Palet.kotak(Palet.PANEL_2, Color.TRANSPARENT, 24))
	h.add_child(tile)
	UiKit.ikon(tile, "gembok", 40, Palet.TEKS_REDUP)
	var k := UiKit.kolom(h, 2)
	k.alignment = BoxContainer.ALIGNMENT_CENTER
	UiKit.label(k, 28, Palet.TEKS, Tema.font_ui(700), tr("UI_FINAL_TOMBOL"))
	UiKit.label(k, 22, Palet.TEKS_REDUP, Tema.font_ui(500), tr("UI_FINAL_TERKUNCI"))


func _kartu(t: Dictionary, rep: int, maks: int) -> void:
	var jatuh := rep <= 0
	var kartu := UiKit.panel(_daftar, Palet.PANEL if not jatuh else Color("221b44"), 36, 20)
	if not jatuh:
		(kartu.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Color(Palet.KUNING, 0.5)
		(kartu.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(4)
	var h := UiKit.baris(kartu, 20)
	var p := Potret.new()
	p.tokoh_id = str(t["id"])
	p.jatuh = jatuh
	p.custom_minimum_size = Vector2(136, 160)
	h.add_child(p)
	if jatuh:
		var stempel := UiKit.pil(p, tr("UI_JATUH"), Color(Palet.MALAM, 0.9), Palet.PINK, 26)
		stempel.position = Vector2(6, 58)
		stempel.rotation = -0.25
	var k := UiKit.kolom(h, 8)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k.alignment = BoxContainer.ALIGNMENT_CENTER
	var nama := UiKit.label(k, 28, Palet.TEKS, Tema.font_ui(700), Bahasa.teks(t.get("nama", "")))
	nama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var r := UiKit.baris(k, 10)
	var b := UiKit.bar(r, Palet.KUNING, 16, Palet.MALAM)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.max_value = maks
	b.value = rep
	UiKit.label(r, 22, Color("ff8fb3") if jatuh else Palet.KUNING, Tema.font_ui(700),
		tr("UI_JATUH") if jatuh else "%s / %s" % [Bahasa.angka(rep), Bahasa.angka(maks)])
	var def := UiKit.baris(k, 8)
	var tipe := str(t.get("pertahanan", {}).get("tipe", ""))
	UiKit.pil(def, tr("UI_PERTAHANAN_" + tipe.to_upper()), Palet.PANEL_2, Palet.KUNING, 18).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var info := UiKit.label(def, 21, Palet.TEKS_LEMBUT, Tema.font_ui(500), Bahasa.teks(t.get("info", "")).get_slice(": ", 1))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hadiah: Dictionary = t.get("hadiah", {})
	UiKit.label(k, 21, Palet.HIJAU if jatuh else Palet.KUNING, Tema.font_ui(700),
		tr("UI_DIDAPAT" if jatuh else "UI_HADIAH") % [Bahasa.angka(int(hadiah.get("uang", 0))), int(hadiah.get("pengikut", 0))])
