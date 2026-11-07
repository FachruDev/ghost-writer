extends Lembar
## Layar "Naik Era" (papan 11): perayaan saat era naik di tengah permainan, daftar yang baru terbuka
## (saluran, staf, distrik, jumlah kata & template), jalur 4 era, dan syarat era berikutnya.

const UPGRADE_ERA := {2: "kantor", 3: "gedung_media", 4: "menara_server"}

var _era_dilihat := 0
var _hantu: Hantu
var _angka: Label
var _nama: Label
var _daftar: VBoxContainer
var _jalur: HFlowContainer
var _berikut: Label
var _ayo: Button


func _init() -> void:
	penuh = true


func _bangun_isi() -> void:
	isi.alignment = BoxContainer.ALIGNMENT_CENTER
	var lencana := UiKit.pil(isi, "", Palet.KUNING, Palet.TINTA, 26)
	lencana.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hantu = Hantu.new()
	_hantu.suasana = Hantu.Suasana.GIRANG
	_hantu.custom_minimum_size = Vector2(0, 260)
	isi.add_child(_hantu)
	_angka = UiKit.label(isi, 96, Palet.TEKS, Tema.font_judul())
	_angka.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_angka.add_theme_color_override("font_shadow_color", Palet.PINK)
	_angka.add_theme_constant_override("shadow_offset_y", 8)
	_angka.add_theme_constant_override("shadow_offset_x", 0)
	_nama = UiKit.label(isi, 34, Palet.TEKS, Tema.font_ui(600))
	_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kotak := UiKit.panel(isi, Palet.PANEL, 36, 24)
	_daftar = UiKit.kolom(kotak, 14)
	_jalur = HFlowContainer.new()
	_jalur.alignment = FlowContainer.ALIGNMENT_CENTER
	_jalur.add_theme_constant_override("h_separation", 10)
	_jalur.add_theme_constant_override("v_separation", 10)
	isi.add_child(_jalur)
	_berikut = UiKit.label(isi, 22, Palet.TEKS_REDUP, Tema.font_ui(500))
	_berikut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_berikut.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ayo = UiKit.tombol_utama(isi, "")
	_ayo.pressed.connect(tutup)
	_era_dilihat = GameState.era
	Events.era_berubah.connect(_on_era)
	judul.visible = false


## Hanya saat era benar-benar naik di tengah permainan (bukan saat memuat save).
func _on_era(era: int) -> void:
	if era > _era_dilihat and _era_dilihat > 0 and is_inside_tree():
		_era_dilihat = era
		buka.call_deferred()
	else:
		_era_dilihat = era


func _segarkan() -> void:
	var era := GameState.era
	(isi.get_child(0).get_child(0) as Label).text = tr("UI_NAIK_ERA")
	_angka.text = tr("UI_ERA_PENDEK") % era
	_nama.text = tr("UI_ERA_NAMA_%d" % clampi(era, 1, 4))
	for anak in _daftar.get_children() + _jalur.get_children():
		anak.get_parent().remove_child(anak)
		anak.queue_free()
	UiKit.label(_daftar, 22, Palet.TEKS_REDUP, Tema.font_ui(700), tr("UI_BARU_TERBUKA"))
	var warna := [Palet.KUNING, Palet.CYAN, Palet.PINK, Palet.HIJAU]
	var n := 0
	for teks in _terbuka(era):
		var h := UiKit.baris(_daftar, 16)
		var bulat := PanelContainer.new()
		bulat.custom_minimum_size = Vector2(44, 44)
		bulat.add_theme_stylebox_override("panel", Palet.kotak(warna[n % 4], Color.TRANSPARENT, 999))
		h.add_child(bulat)
		UiKit.ikon(bulat, "centang", 26, Palet.TINTA)
		var l := UiKit.label(h, 26, Palet.TEKS, Tema.font_ui(500), teks)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n += 1
	for e in range(1, 5):
		var b := UiKit.pil(_jalur, "%d · %s" % [e, tr("UI_ERA_NAMA_%d" % e)],
			Palet.KUNING if e == era else (Palet.PANEL_2 if e < era else Palet.MALAM),
			Palet.TINTA if e == era else (Palet.TEKS if e < era else Palet.TEKS_REDUP), 18)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var berikut := DataDB.get_upgrade(UPGRADE_ERA.get(era + 1, ""))
	if berikut.is_empty():
		_berikut.text = tr("UI_ERA_TERAKHIR")
	else:
		_berikut.text = tr("UI_ERA_BERIKUT") % [Bahasa.teks(berikut.get("nama", "")),
			Bahasa.angka(int(berikut.get("pengikut_min", 0))), Bahasa.angka(int(berikut.get("harga", 0)))]
	_ayo.text = tr("UI_AYO_KERJA")


## Daftar yang terbuka di era ini, dihitung dari data (bukan teks tetap).
func _terbuka(era: int) -> Array[String]:
	var hasil: Array[String] = []
	for s in DataDB.saluran():
		if int(s.get("era_min", 1)) == era:
			hasil.append(tr("UI_SALURAN_X") % Bahasa.teks(s.get("nama", "")))
	for id in DataDB.upgrades:
		var u := DataDB.get_upgrade(id)
		if str(u.get("jenis", "")) == "staf" and int(u.get("era_min", 1)) == era:
			hasil.append(tr("UI_STAF_BUKA"))
	if era == 3:
		hasil.append(tr("UI_KONTRAK_BUKA"))
	if era == 4 and not DataDB.tokoh.is_empty():
		hasil.append(tr("UI_TOKOH_BUKA"))
	var distrik: Array[String] = []
	for d in DataDB.districts:
		if int(d.get("era_min", 1)) == era:
			distrik.append(Bahasa.teks(d.get("nama", "")))
	if not distrik.is_empty():
		hasil.append(tr("UI_DISTRIK_BARU") % ", ".join(distrik))
	var kata := 0
	for id in DataDB.words:
		if int(DataDB.words[id].get("era_min", 1)) == era and DataDB.words[id].get("toko", true):
			kata += 1
	var template := 0
	for id in DataDB.templates:
		if int(DataDB.templates[id].get("era_min", 1)) == era:
			template += 1
	if kata > 0:
		hasil.append(tr("UI_N_KATA") % kata)
	if template > 0:
		hasil.append(tr("UI_N_TEMPLATE") % template)
	return hasil
