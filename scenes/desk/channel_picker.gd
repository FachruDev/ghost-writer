extends HBoxContainer
## Pilihan saluran (Merpati, Koran, ...). Saluran terkunci menampilkan ambang pengikutnya.

var dipilih := "merpati"


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	Events.pengikut_berubah.connect(func(_p: int) -> void: _isi_ulang())
	Events.era_berubah.connect(func(_e: int) -> void: _isi_ulang())
	Events.kepemilikan_berubah.connect(_isi_ulang)
	Events.money_changed.connect(func(_u: int) -> void: _isi_ulang())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _isi_ulang())
	_isi_ulang()


func _isi_ulang() -> void:
	for anak in get_children():
		anak.queue_free()
	for s in DataDB.saluran():
		var id := str(s["id"])
		# Saluran era berikutnya belum ditampilkan supaya baris tidak penuh di awal permainan.
		if not GameState.era_terbuka(s):
			continue
		var terbuka := GameState.saluran_terbuka(id)
		var tombol := Button.new()
		tombol.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		tombol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tombol.custom_minimum_size = Vector2(0, 48)
		tombol.clip_text = true
		tombol.add_theme_font_size_override("font_size", 18)
		tombol.text = _label(s, terbuka)
		tombol.disabled = not terbuka
		Palet.gaya_tombol(tombol, Palet.AKSEN if id == dipilih else Palet.TEKS_REDUP)
		tombol.pressed.connect(_pilih.bind(id))
		add_child(tombol)


func _pilih(id: String) -> void:
	dipilih = id
	Events.saluran_dipilih.emit(id)
	_isi_ulang()


func _label(s: Dictionary, terbuka: bool) -> String:
	var nama := Bahasa.teks(s.get("nama", ""))
	if GameState.saluran_terkunci.has(str(s["id"])):
		return tr("UI_DIKUNCI") % nama
	if not terbuka and not GameState.era_terbuka(s):
		return tr("UI_TERKUNCI_ERA") % [nama, int(s.get("era_min", 1))]
	if not terbuka:
		return tr("UI_TERKUNCI") % [nama, int(s.get("pengikut_min", 0))]
	var biaya := int(s.get("biaya_kirim", 0))
	return nama if biaya == 0 else "%s %s" % [nama, Bahasa.angka(biaya)]
