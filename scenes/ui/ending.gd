extends Lembar
## Layar ending kampanye akhir (papan 17/18): maskot, judul, epilog satir (data/endings.json),
## 6 kotak statistik, rumor terbaik, lalu [Mulai Baru] (tekan dua kali) atau [LANJUT MAIN].
## Waktu permainan dijeda selama layar tampil.

const JEDA := &"ending"

var _hasil := ""
var _judul: Label
var _hantu: Hantu
var _lencana: PanelContainer
var _epilog: Label
var _statistik: GridContainer
var _terbaik: PanelContainer
var _terbaik_judul: Label
var _terbaik_teks: Label
var _tombol_baru: Button
var _tombol_lanjut: Button
var _yakin := false


func _init() -> void:
	penuh = true
	bisa_ditutup = false
	jeda = JEDA


func _bangun_isi() -> void:
	judul.get_parent().visible = false
	var gulir := ScrollContainer.new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gulir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	isi.add_child(gulir)
	var k := UiKit.kolom(gulir, 16)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hantu = Hantu.new()
	_hantu.custom_minimum_size = Vector2(0, 240)
	k.add_child(_hantu)
	_lencana = UiKit.pil(k, "", Palet.KUNING, Palet.TINTA, 22)
	_lencana.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_judul = UiKit.label(k, 60, Palet.TEKS, Tema.font_judul())
	_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_judul.uppercase = true
	_judul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_judul.add_theme_constant_override("shadow_offset_x", 0)
	_judul.add_theme_constant_override("shadow_offset_y", 8)
	_epilog = UiKit.label(k, 25, Palet.TEKS_LEMBUT, Tema.font_ui(500))
	_epilog.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_statistik = GridContainer.new()
	_statistik.columns = 3
	_statistik.add_theme_constant_override("h_separation", 12)
	_statistik.add_theme_constant_override("v_separation", 12)
	k.add_child(_statistik)
	_terbaik = UiKit.panel(k, Palet.KERTAS, 24, 18)
	var kt := UiKit.kolom(_terbaik, 4)
	_terbaik_judul = UiKit.label(kt, 20, Palet.TEKS_KERTAS_REDUP, Tema.font_ui(700))
	_terbaik_teks = UiKit.label(kt, 24, Palet.TINTA, Tema.font_ketik())
	_terbaik_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var tombol := UiKit.baris(isi, 20)
	_tombol_baru = UiKit.tombol(tombol, "", Palet.PANEL_2, Palet.PANEL, 26, Tema.font_ui(700))
	_tombol_baru.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_baru.size_flags_stretch_ratio = 1.0
	_tombol_baru.pressed.connect(_on_mulai_baru)
	_tombol_lanjut = UiKit.tombol_utama(tombol, "")
	_tombol_lanjut.add_theme_font_size_override("font_size", 38)
	_tombol_lanjut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_lanjut.size_flags_stretch_ratio = 1.4
	_tombol_lanjut.pressed.connect(_on_lanjut)
	Events.ending_tercapai.connect(tampilkan)
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void:
		if visible:
			_isi())


func tampilkan(hasil: String) -> void:
	_hasil = hasil
	_yakin = false
	buka()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.6)


func _segarkan() -> void:
	_isi()


func _isi() -> void:
	var menang := _hasil == "menang"
	_redup.color = Color("2a1f4a") if menang else Color("1d1c26")
	(_panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color("2a1f4a") if menang else Color("1d1c26")
	var aksen := Palet.KUNING if menang else Color("c3cad8")
	_hantu.bermahkota = menang
	_hantu.suasana = Hantu.Suasana.GIRANG if menang else Hantu.Suasana.DIAM
	_hantu.modulate = Color.WHITE if menang else Color(0.8, 0.82, 0.88)
	(_lencana.get_child(0) as Label).text = tr("UI_ENDING")
	(_lencana.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = aksen
	var data: Dictionary = DataDB.endings.get(_hasil, {})
	_judul.text = Bahasa.teks(data.get("judul", ""))
	_judul.add_theme_color_override("font_color", Color.WHITE if menang else Color("c3cad8"))
	_judul.add_theme_color_override("font_shadow_color", Palet.PINK if menang else Color("3a3a4a"))
	_epilog.text = Bahasa.teks(data.get("epilog", ""))
	_tombol_baru.text = tr("UI_MULAI_BARU_YAKIN" if _yakin else "UI_MULAI_BARU")
	_tombol_lanjut.text = tr("UI_LANJUT_MAIN").to_upper()
	for anak in _statistik.get_children():
		_statistik.remove_child(anak)
		anak.queue_free()
	var stat := GameState.statistik
	var menit := roundi(GameState.waktu_main_detik / 60.0)
	_kotak(Bahasa.angka(int(stat["total_rumor"])), "UI_STAT_RUMOR", aksen)
	_kotak(Bahasa.angka(int(stat["total_uang"])), "UI_STAT_UANG", aksen)
	_kotak("%d/%d" % [_tokoh_jatuh(), DataDB.tokoh.size()], "UI_STAT_TOKOH", aksen)
	_kotak(Bahasa.angka(int(stat["total_dibongkar"])), "UI_STAT_DIBONGKAR", aksen)
	_kotak(tr("UI_STAT_WAKTU_ISI") % [menit / 60, menit % 60], "UI_STAT_WAKTU", aksen)
	_kotak(Bahasa.angka(GameState.pengikut), "UI_STAT_PENGIKUT", aksen)
	var terbaik: Variant = stat.get("rumor_terbaik")
	_terbaik.visible = terbaik is Dictionary
	if terbaik is Dictionary:
		_terbaik_judul.text = tr("UI_RUMOR_TERBAIK") % int(terbaik.get("warga_percaya", 0))
		_terbaik_teks.text = HeadlineBuilder.susun(str(terbaik.get("template_id", "")), terbaik.get("kata_ids", {}))


func _kotak(nilai: String, kunci: String, warna: Color) -> void:
	var p := UiKit.panel(_statistik, Color(Palet.PANEL, 0.9), 24, 14)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var k := UiKit.kolom(p, 2)
	var v := UiKit.label(k, 34, warna, Tema.font_judul(), nilai)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var l := UiKit.label(k, 19, Palet.TEKS_REDUP, Tema.font_ui(600), tr(kunci))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


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
		Palet.gaya_tombol(_tombol_baru, Palet.PINK, Palet.PINK_GELAP, Palet.TINTA, 28)
		return
	GameClock.lanjut(JEDA)
	SaveSystem.reset_progres()
	get_tree().reload_current_scene()


func _on_lanjut() -> void:
	tutup()
	Events.ending_ditutup.emit()
