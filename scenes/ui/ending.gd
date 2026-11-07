extends Control
## Layar ending kampanye akhir (0.6.0): judul, epilog satir (data/endings.json), statistik,
## lalu [Mulai Baru] atau [Lanjut Bermain]. Waktu permainan dijeda selama layar tampil.

const JEDA := &"ending"

var _hasil := ""
var _judul: Label
var _epilog: Label
var _statistik: GridContainer
var _sub: Label
var _tombol_baru: Button
var _tombol_lanjut: Button
var _yakin := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var redup := ColorRect.new()
	redup.color = Color(0, 0, 0, 0.8)
	redup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(redup)
	var tepi := MarginContainer.new()
	tepi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for sisi in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		tepi.add_theme_constant_override(sisi, 32)
	add_child(tepi)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", Palet.kotak(Palet.PANEL, Palet.AKSEN, 12))
	tepi.add_child(panel)
	var kotak := VBoxContainer.new()
	kotak.add_theme_constant_override("separation", 18)
	panel.add_child(kotak)
	_sub = _label(kotak, 20, Palet.AKSEN)
	_judul = _label(kotak, 40, Color.WHITE)
	_epilog = _label(kotak, 22, Palet.TEKS_REDUP)
	_epilog.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_statistik = GridContainer.new()
	_statistik.columns = 2
	_statistik.add_theme_constant_override("h_separation", 16)
	_statistik.add_theme_constant_override("v_separation", 6)
	kotak.add_child(_statistik)
	var tombol := HBoxContainer.new()
	tombol.add_theme_constant_override("separation", 12)
	kotak.add_child(tombol)
	_tombol_baru = _tombol(tombol, Palet.TEKS_REDUP)
	_tombol_baru.pressed.connect(_on_mulai_baru)
	_tombol_lanjut = _tombol(tombol, Palet.AKSEN)
	_tombol_lanjut.pressed.connect(_on_lanjut)
	Events.ending_tercapai.connect(tampilkan)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void:
		if visible:
			_isi())


func tampilkan(hasil: String) -> void:
	_hasil = hasil
	_yakin = false
	_isi()
	visible = true
	GameClock.jeda(JEDA)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


func _isi() -> void:
	var data: Dictionary = DataDB.endings.get(_hasil, {})
	_judul.text = Bahasa.teks(data.get("judul", ""))
	_epilog.text = Bahasa.teks(data.get("epilog", ""))
	_sub.text = tr("UI_ENDING")
	_tombol_baru.text = tr("UI_MULAI_BARU_YAKIN" if _yakin else "UI_MULAI_BARU")
	_tombol_lanjut.text = tr("UI_LANJUT_MAIN")
	for anak in _statistik.get_children():
		anak.queue_free()
	var stat := GameState.statistik
	var jam := roundi(GameState.waktu_main_detik / 60.0)
	_baris("UI_STAT_RUMOR", Bahasa.angka(int(stat["total_rumor"])))
	_baris("UI_STAT_UANG", Bahasa.angka(int(stat["total_uang"])))
	_baris("UI_STAT_TOKOH", "%d/%d" % [_tokoh_jatuh(), DataDB.tokoh.size()])
	_baris("UI_STAT_DIBONGKAR", Bahasa.angka(int(stat["total_dibongkar"])))
	_baris("UI_STAT_WAKTU", tr("UI_STAT_WAKTU_ISI") % [jam / 60, jam % 60])
	var terbaik: Variant = stat.get("rumor_terbaik")
	if terbaik is Dictionary:
		_baris("UI_STAT_TERBAIK", tr("UI_STAT_TERBAIK_ISI") % [
			HeadlineBuilder.susun(str(terbaik.get("template_id", "")), terbaik.get("kata_ids", {})),
			int(terbaik.get("warga_percaya", 0))])


func _tokoh_jatuh() -> int:
	var n := 0
	for t in DataDB.tokoh:
		if GameState.tokoh_reputasi.has(t["id"]) and int(GameState.tokoh_reputasi[t["id"]]) <= 0:
			n += 1
	return n


## Mulai Baru menghapus progres, jadi butuh dua kali tekan.
func _on_mulai_baru() -> void:
	if not _yakin:
		_yakin = true
		_tombol_baru.text = tr("UI_MULAI_BARU_YAKIN")
		return
	GameClock.lanjut(JEDA)
	SaveSystem.reset_progres()
	get_tree().reload_current_scene()


func _on_lanjut() -> void:
	visible = false
	GameClock.lanjut(JEDA)
	Events.ending_ditutup.emit()


func _baris(kunci: String, nilai: String) -> void:
	var k := _label(_statistik, 20, Palet.TEKS_REDUP)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.autowrap_mode = TextServer.AUTOWRAP_OFF
	k.text = tr(kunci)
	var v := _label(_statistik, 20, Color.WHITE)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.text = nilai


func _label(induk: Control, ukuran: int, warna: Color) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	induk.add_child(l)
	return l


func _tombol(induk: Control, warna: Color) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 60)
	Palet.gaya_tombol(b, warna)
	induk.add_child(b)
	return b
