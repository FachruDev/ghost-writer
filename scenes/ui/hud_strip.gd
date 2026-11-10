class_name HudStrip
extends Button
## Strip utama HUD (papan 02/09): satu hal terpenting — kampanye akhir berjalan > siap > tokoh > misi.
## Ditekan: buka lapisan terkait ("tokoh" atau "final") lewat Events.layar_diminta.

var _aksi := ""
var _tag: PanelContainer
var _teks: Label
var _bar: ProgressBar
var _angka: Label
var _panah: TextureRect


func _ready() -> void:
	custom_minimum_size = Vector2(0, 88)
	for nama in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var g := Palet.kotak(Palet.PANEL if nama != "pressed" else Palet.PANEL_2, Color.TRANSPARENT, 20)
		g.set_content_margin_all(10)
		if nama == "focus":
			g.draw_center = false
			g.border_color = Palet.KUNING
			g.set_border_width_all(3)
		add_theme_stylebox_override(nama, g)
	pressed.connect(func() -> void:
		if not _aksi.is_empty():
			Events.layar_diminta.emit(_aksi))
	var isi := UiKit.baris(null, 12)
	isi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(isi)
	_tag = UiKit.pil(isi, "", Palet.KUNING)
	_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_teks = UiKit.label(isi, 24, Palet.TEKS, Tema.font_ui(600))
	_teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_teks.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_bar = UiKit.bar(isi, Palet.KUNING, 14, Palet.MALAM)
	_bar.custom_minimum_size = Vector2(120, 14)
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_angka = UiKit.label(isi, 24, Palet.KUNING, Tema.font_ui(700))
	_angka.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_panah = UiKit.ikon(isi, "kanan", 28, Palet.TEKS_REDUP)


## info_final: data Events.final_data ({} = kampanye akhir tidak berjalan).
func segarkan(info_final: Dictionary) -> void:
	_aksi = ""
	_bar.visible = false
	_panah.visible = false
	_angka.text = ""
	if not info_final.is_empty():
		_isi_tag(tr("UI_FINAL_TAG"), Palet.PINK)
		_teks.text = tr("UI_FINAL_STRIP") % [roundi(float(info_final["percaya"]) * 100.0), roundi(float(info_final["kebal"]) * 100.0)]
		var sisa := int(info_final.get("sisa", 0))
		_angka.text = "%d:%02d" % [sisa / 60, sisa % 60]
		_angka.add_theme_color_override("font_color", Palet.PINK if sisa <= 60 else Palet.TEKS)
		return
	if FinalController.bisa_mulai():
		_isi_tag(tr("UI_FINAL_TAG"), Palet.PINK)
		_teks.text = tr("UI_FINAL_ULANG" if GameState.hasil_akhir == "kalah" else "UI_FINAL_SIAP")
		_aksi = "final"
		_panah.visible = true
		return
	if GameState.hasil_akhir == "menang":
		_isi_tag(tr("UI_FINAL_TAG"), Palet.HIJAU)
		_teks.text = tr("UI_FINAL_BEBAS")
		return
	if not GameState.tokoh_reputasi.is_empty():
		_tokoh()
		return
	var misi := MissionController.misi_aktif()
	if misi.is_empty():
		_tag.visible = false
		_teks.text = tr("UI_MISI_HABIS")
		return
	_isi_tag(tr("UI_MISI_KE") % [GameState.misi_idx + 1, DataDB.missions.size()], Palet.KUNING)
	_teks.text = Bahasa.teks(misi.get("teks", ""))
	var uang := int(misi.get("hadiah", {}).get("uang", 0))
	_angka.text = "+%s" % Bahasa.angka(uang) if uang > 0 else ""
	_angka.add_theme_color_override("font_color", Palet.KUNING)


func _tokoh() -> void:
	var jatuh := 0
	var sasaran: Dictionary = {}
	for t in DataDB.tokoh:
		var rep := int(GameState.tokoh_reputasi.get(t["id"], int(t.get("reputasi", 0))))
		if rep <= 0:
			jatuh += 1
		elif sasaran.is_empty():
			sasaran = t
	_isi_tag(tr("UI_TOKOH_KE") % [jatuh, DataDB.tokoh.size()], Palet.KUNING)
	_aksi = "tokoh"
	_panah.visible = true
	if sasaran.is_empty():
		_teks.text = tr("UI_TOKOH_SEMUA_JATUH")
		return
	var rep := int(GameState.tokoh_reputasi.get(sasaran["id"], 0))
	_teks.text = Bahasa.teks(sasaran.get("nama", ""))
	_bar.visible = true
	_bar.max_value = float(sasaran.get("reputasi", 1000))
	_bar.value = rep
	_angka.text = Bahasa.angka(rep)
	_angka.add_theme_color_override("font_color", Palet.KUNING)


func _isi_tag(teks: String, warna: Color) -> void:
	_tag.visible = true
	(_tag.get_child(0) as Label).text = teks
	(_tag.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = warna
