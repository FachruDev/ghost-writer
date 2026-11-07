extends Lembar
## Lembar "Kampanye Akhir — mulai" (papan 15): aturan menang/kalah sebelum E12 dimulai.
## MULAI KAMPANYE -> Events.final_diminta (FinalController.mulai).

var _hantu: Hantu
var _intro: Label
var _menang: Label
var _kalah: Label
var _ulang: Label
var _mulai: Button
var _nanti: Button


func _init() -> void:
	aksen = Palet.PINK


func _bangun_isi() -> void:
	_hantu = Hantu.new()
	_hantu.custom_minimum_size = Vector2(0, 220)
	isi.add_child(_hantu)
	_intro = UiKit.label(isi, 26, Palet.TEKS_LEMBUT, Tema.font_ui(500))
	_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menang = _aturan(Palet.PINK, roundi(Balance.FINAL_TARGET_PERCAYA * 100.0))
	_kalah = _aturan(Palet.ABU_KEBAL, roundi(Balance.FINAL_BATAS_KEBAL * 100.0))
	_ulang = UiKit.label(isi, 22, Palet.TEKS_REDUP, Tema.font_ui(500))
	_ulang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mulai = UiKit.tombol_utama(isi, "")
	_mulai.pressed.connect(func() -> void:
		tutup()
		Events.final_diminta.emit())
	_nanti = UiKit.tombol(isi, "", Palet.PANEL_2, Palet.MALAM, 28, Tema.font_ui(700), 92)
	_nanti.pressed.connect(tutup)
	Events.layar_diminta.connect(func(nama: String) -> void:
		if nama == "final" and FinalController.bisa_mulai():
			buka())


func _aturan(warna: Color, persen: int) -> Label:
	var kotak := UiKit.panel(isi, Palet.MALAM, 32, 18)
	(kotak.get_theme_stylebox("panel") as StyleBoxFlat).border_color = warna
	(kotak.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(4)
	var h := UiKit.baris(kotak, 20)
	var angka := UiKit.pil(h, "%d%%" % persen, warna, Palet.TINTA, 36)
	(angka.get_child(0) as Label).add_theme_font_override("font", Tema.font_judul())
	angka.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := UiKit.label(h, 24, Palet.TEKS, Tema.font_ui(600))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _segarkan() -> void:
	judul.text = tr("UI_FINAL_JUDUL")
	_hantu.suasana = Hantu.Suasana.GIRANG
	_intro.text = tr("UI_FINAL_INTRO") % roundi(Balance.FINAL_TULAR_KEBAL_DETIK)
	_menang.text = "%s · %s" % [tr("UI_MENANG"), tr("UI_FINAL_MENANG_INFO") % roundi(Balance.FINAL_TARGET_PERCAYA * 100.0)]
	_kalah.text = "%s · %s" % [tr("UI_KALAH"), tr("UI_FINAL_KALAH_INFO") % [roundi(Balance.FINAL_BATAS_KEBAL * 100.0),
		roundi(Balance.FINAL_DURASI_DETIK / 60.0)]]
	_ulang.text = tr("UI_FINAL_BISA_ULANG")
	_mulai.text = tr("UI_MULAI_KAMPANYE")
	_nanti.text = tr("UI_NANTI")
