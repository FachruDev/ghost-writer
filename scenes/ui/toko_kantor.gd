class_name TokoKantor
extends RefCounted
## Tab "Kantor & staf" di toko (papan 05): kartu naik era dan rekrut staf, dengan status
## dimiliki / bisa dibeli / kurang pengikut / terkunci era. Dipisah dari shop.gd (batas ±300 baris).


## Kantor & staf: urutan dari upgrades.json; dimiliki / bisa dibeli / kurang pengikut / terkunci era.
static func isi(kolom: VBoxContainer, tombol_beli: Callable) -> void:
	var sebelumnya := ""
	for id in DataDB.upgrades:
		var u := DataDB.get_upgrade(id)
		if str(u.get("jenis", "")) == "saluran":
			continue
		var milik := GameState.punya_upgrade(id)
		var era_ok := GameState.era_terbuka(u)
		var pengikut_min := int(u.get("pengikut_min", 0))
		var kartu := UiKit.panel(kolom, Palet.PANEL if era_ok else Color.TRANSPARENT, 36, 22)
		if not era_ok:
			(kartu.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Palet.GARIS
			(kartu.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(4)
			kartu.modulate.a = 0.75
		elif not milik:
			(kartu.get_theme_stylebox("panel") as StyleBoxFlat).border_color = Palet.KUNING
			(kartu.get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(4)
		var h := UiKit.baris(kartu, 20)
		var tile := PanelContainer.new()
		tile.custom_minimum_size = Vector2(96, 96)
		tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tile.add_theme_stylebox_override("panel", Palet.kotak(Palet.HIJAU if milik else (Palet.KUNING if era_ok else Palet.GARIS), Color.TRANSPARENT, 28))
		h.add_child(tile)
		UiKit.ikon(tile, _ikon_upgrade(id, u), 48, Palet.TINTA)
		var k := UiKit.kolom(h, 6)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var atas := UiKit.baris(k, 10)
		UiKit.label(atas, 30, Palet.TEKS, Tema.font_ui(700), Bahasa.teks(u.get("nama", "")))
		if str(u.get("jenis", "")) == "era":
			UiKit.pil(atas, _t("UI_ERA_PENDEK") % int(u.get("era", 1)), Palet.HIJAU if milik else Palet.PANEL_2,
				Palet.TINTA if milik else Palet.KUNING, 18).size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var info := Bahasa.teks(u.get("info", ""))
		if not era_ok and not sebelumnya.is_empty():
			info = _t("UI_TERKUNCI_SETELAH") % sebelumnya
		var l := UiKit.label(k, 22, Palet.TEKS_LEMBUT, Tema.font_ui(500), info)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if era_ok and not milik and GameState.pengikut < pengikut_min:
			var syarat := UiKit.baris(k, 10)
			var b := UiKit.bar(syarat, Palet.CYAN, 14, Palet.MALAM)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			b.max_value = pengikut_min
			b.value = GameState.pengikut
			UiKit.label(syarat, 20, Palet.TEKS_REDUP, Tema.font_ui(600),
				_t("UI_SYARAT_PENGIKUT") % [Bahasa.angka(GameState.pengikut), Bahasa.angka(pengikut_min)])
		var kanan := UiKit.kolom(h, 0)
		kanan.alignment = BoxContainer.ALIGNMENT_CENTER
		if milik:
			UiKit.label(kanan, 24, Palet.HIJAU, Tema.font_ui(700), _t("UI_DIMILIKI"))
		elif GameState.upgrade_tersedia(id):
			var beli: Button = tombol_beli.call(kanan, int(u.get("harga", 0)))
			beli.text = Bahasa.angka(int(u.get("harga", 0)))
			beli.pressed.connect(func() -> void: GameState.beli_upgrade(id))
		else:
			UiKit.label(kanan, 24, Palet.TEKS_REDUP, Tema.font_ui(700), Bahasa.angka(int(u.get("harga", 0))))
		if str(u.get("jenis", "")) == "era":
			sebelumnya = Bahasa.teks(u.get("nama", ""))


static func _ikon_upgrade(id: String, u: Dictionary) -> String:
	if str(u.get("jenis", "")) == "staf":
		return "orang"
	return {2: "kantor", 3: "gedung", 4: "menara"}.get(int(u.get("era", 0)), "kantor") if id != "" else "kantor"


## tr() tidak tersedia di fungsi static; terjemahkan lewat TranslationServer.
static func _t(kunci: String) -> String:
	return str(TranslationServer.translate(kunci))
