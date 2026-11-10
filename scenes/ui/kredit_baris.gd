class_name KreditBaris
extends VBoxContainer
## Satu baris kredit di layar Tentang: judul karya, pembuat, sumber · lisensi, dan (kalau ada) tombol
## untuk membuka teks lisensinya. Teks lisensi baru dibangun saat pertama dibuka, dipecah per bagian
## supaya tidak ada satu Label raksasa.

var judul_teks := ""

var _bagian: Callable  # -> Array (String per bagian)
var _tombol: Button
var _kotak: PanelContainer
var _isi_kotak: VBoxContainer


func _init(judul: String, oleh: String, keterangan: String, bagian := Callable()) -> void:
	judul_teks = judul
	_bagian = bagian
	add_theme_constant_override("separation", 4)
	_teks(self, judul, 28, Palet.TEKS, 600)
	if not oleh.is_empty():
		_teks(self, oleh, 22, Palet.TEKS_LEMBUT, 500)
	if not keterangan.is_empty():
		_teks(self, keterangan, 22, Palet.TEKS_REDUP, 500)
	if not bagian.is_valid():
		return
	var jarak := Control.new()
	jarak.custom_minimum_size.y = 8
	add_child(jarak)
	_tombol = UiKit.tombol(self, TranslationServer.translate("UI_KREDIT_LISENSI"), Palet.PANEL_2, Palet.MALAM,
		22, Tema.font_ui(700), 88)
	_tombol.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tombol.mouse_filter = Control.MOUSE_FILTER_PASS  # seret jari tetap menggulir daftar
	_tombol.pressed.connect(alih)
	_kotak = UiKit.panel(self, Palet.MALAM, 24, 20)
	_kotak.visible = false
	_isi_kotak = UiKit.kolom(_kotak, 18)


func _teks(induk: Node, teks: String, ukuran: int, warna: Color, tebal: int) -> Label:
	var l := UiKit.label(induk, ukuran, warna, Tema.font_ui(tebal), teks)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func punya_lisensi() -> bool:
	return _kotak != null


func lisensi_terbuka() -> bool:
	return _kotak != null and _kotak.visible


## Buka/tutup teks lisensi.
func alih() -> void:
	if _kotak == null:
		return
	_kotak.visible = not _kotak.visible
	if _kotak.visible and _isi_kotak.get_child_count() == 0:
		for teks in _bagian.call():
			_teks(_isi_kotak, str(teks), 20, Palet.TEKS_LEMBUT, 400)
	_tombol.text = TranslationServer.translate("UI_KREDIT_SEMBUNYI" if _kotak.visible else "UI_KREDIT_LISENSI")


func teks_lisensi() -> PackedStringArray:
	var hasil := PackedStringArray()
	if _isi_kotak:
		for l in _isi_kotak.get_children():
			hasil.append((l as Label).text)
	return hasil


## Teks lisensi dari file yang ikut diekspor (mis. assets/fonts/OFL-*.txt).
static func dari_file(path: String) -> Callable:
	return func() -> Array: return [rapikan(FileAccess.get_file_as_string(path))]


## Lisensi Godot Engine, daftar komponen pihak ketiga di dalamnya, lalu teks lengkap tiap lisensi
## yang dipakai komponen itu (syarat MIT, BSD, Apache, FreeType, dll.).
static func lisensi_godot() -> Array:
	var hasil: Array = [rapikan(Engine.get_license_text())]
	var komponen := PackedStringArray()
	for c in Engine.get_copyright_info():
		if c["name"] == "Godot Engine":
			continue
		for p in c["parts"]:
			komponen.append("%s\n© %s\n%s" % [c["name"], "\n© ".join(p["copyright"]), p["license"]])
	hasil.append(TranslationServer.translate("UI_KREDIT_PIHAK_KETIGA") + "\n\n" + "\n\n".join(komponen))
	var teks := Engine.get_license_info()
	for nama in teks:
		hasil.append("%s\n\n%s" % [nama, rapikan(str(teks[nama]))])
	return hasil


## Teks lisensi dipatah tiap ±80 huruf. Baris panjang disambung dengan baris berikutnya supaya kalimat
## mengalir di layar sempit; baris kosong, garis "---", dan butir daftar tetap di barisnya sendiri.
static func rapikan(teks: String) -> String:
	var butir := RegEx.create_from_string("^(-|\\*|•|\\d+[.)]|\\([a-z0-9]+\\))")
	var hasil := PackedStringArray()
	var sambung := false
	for b in teks.replace("\r", "").strip_edges().split("\n"):
		var bersih := b.strip_edges()
		if sambung and not bersih.is_empty() and butir.search(bersih) == null:
			hasil[hasil.size() - 1] += " " + bersih
		else:
			hasil.append(bersih)
		sambung = bersih.length() >= 50 and not bersih.begins_with("-")
	return "\n".join(hasil)


## Hak cipta Godot Engine, satu baris per pemegang.
static func hak_cipta_godot() -> String:
	for c in Engine.get_copyright_info():
		if c["name"] == "Godot Engine":
			return "© " + "\n© ".join(c["parts"][0]["copyright"])
	return ""
