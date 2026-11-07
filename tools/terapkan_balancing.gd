extends SceneTree
## Terapkan spreadsheet balancing ke data game:
##   balancing/angka.csv (kunci,nilai,catatan)                 -> data/balance.json
##   balancing/harga.csv (id,jenis,harga,pengikut_min,catatan) -> harga di data/*.json
##     kolom "harga" = harga beli (kata, template, upgrade), biaya kirim (saluran),
##     atau reputasi awal (tokoh).
##
## Jalankan dari root proyek:
##   godot --headless --path . -s res://tools/terapkan_balancing.gd
## Nilai boleh berupa pecahan "1/60". Harga ditulis langsung ke teks JSON supaya format
## file data tidak berubah. Keluar dengan kode 1 kalau ada baris yang tidak dikenali.

const ANGKA := "res://balancing/angka.csv"
const HARGA := "res://balancing/harga.csv"
const BALANCE := "res://data/balance.json"
## jenis -> [file data, field harga]
const JENIS := {
	"kata": ["res://data/words.json", "harga"],
	"template": ["res://data/templates.json", "harga"],
	"upgrade": ["res://data/upgrades.json", "harga"],
	"saluran": ["res://data/upgrades.json", "biaya_kirim"],
	"tokoh": ["res://data/tokoh.json", "reputasi"],
}

var _galat := 0


func _initialize() -> void:
	_terapkan_angka()
	_terapkan_harga()
	print("terapkan_balancing: %s" % ("selesai" if _galat == 0 else "%d galat" % _galat))
	quit(1 if _galat > 0 else 0)


func _terapkan_angka() -> void:
	var baris := _baca_csv(ANGKA, ["kunci", "nilai"])
	var isi: Array[String] = []
	for b in baris:
		var nilai: Variant = _angka(str(b["nilai"]))
		if nilai == null:
			_salah("%s: nilai '%s' bukan angka" % [b["kunci"], b["nilai"]])
			continue
		isi.append('  "%s": %s' % [b["kunci"], JSON.stringify(nilai)])
	_tulis(BALANCE, "{\n%s\n}\n" % ",\n".join(isi))
	print("data/balance.json: %d angka" % isi.size())


func _terapkan_harga() -> void:
	var per_file := {}  # path -> {id: {field: nilai}}
	for b in _baca_csv(HARGA, ["id", "jenis", "harga"]):
		var jenis := str(b["jenis"])
		if not JENIS.has(jenis):
			_salah("%s: jenis '%s' tidak dikenal" % [b["id"], jenis])
			continue
		var path: String = JENIS[jenis][0]
		var ubah: Dictionary = per_file.get_or_add(path, {}).get_or_add(str(b["id"]), {})
		ubah[JENIS[jenis][1]] = _angka(str(b["harga"]))
		if jenis in ["upgrade", "saluran"] and not str(b.get("pengikut_min", "")).is_empty():
			ubah["pengikut_min"] = _angka(str(b["pengikut_min"]))
	for path in per_file:
		_tambal_file(path, per_file[path])


## Ganti nilai field di teks JSON (array objek) tanpa mengubah format lainnya.
func _tambal_file(path: String, ubah: Dictionary) -> void:
	var teks := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(teks)
	var rentang := _rentang_objek(teks)
	if not (data is Array) or rentang.size() != data.size():
		_salah("%s: bukan array objek" % path)
		return
	var hasil := ""
	var dari := 0
	var berubah := 0
	var dipakai := {}
	for i in data.size():
		var id := str(data[i].get("id", ""))
		var mulai: int = rentang[i].x
		var akhir: int = rentang[i].y
		var objek := teks.substr(mulai, akhir - mulai)
		if ubah.has(id):
			dipakai[id] = true
			for field in ubah[id]:
				var lama: Variant = data[i].get(field)
				var baru: Variant = ubah[id][field]
				if baru == null:
					_salah("%s.%s: nilai bukan angka" % [id, field])
					continue
				if lama == null:
					_salah("%s: tidak punya field %s" % [id, field])
					continue
				if float(lama) != float(baru):
					objek = _ganti_field(objek, field, JSON.stringify(baru))
					print("%s %s: %s -> %s" % [id, field, JSON.stringify(_rapi(lama)), JSON.stringify(baru)])
					berubah += 1
		hasil += teks.substr(dari, mulai - dari) + objek
		dari = akhir
	hasil += teks.substr(dari)
	for id in ubah:
		if not dipakai.has(id):
			_salah("%s: id '%s' tidak ada" % [path, id])
	if berubah > 0:
		_tulis(path, hasil)
	print("%s: %d nilai diubah" % [path.get_file(), berubah])


## Posisi [awal, akhir) tiap objek tingkat atas di array JSON, dengan memperhatikan string.
func _rentang_objek(teks: String) -> Array[Vector2i]:
	var hasil: Array[Vector2i] = []
	var dalam := 0
	var di_string := false
	var lolos := false
	var awal := 0
	for i in teks.length():
		var c := teks[i]
		if di_string:
			if lolos:
				lolos = false
			elif c == "\\":
				lolos = true
			elif c == "\"":
				di_string = false
			continue
		match c:
			"\"":
				di_string = true
			"{":
				if dalam == 0:
					awal = i
				dalam += 1
			"}":
				dalam -= 1
				if dalam == 0:
					hasil.append(Vector2i(awal, i + 1))
	return hasil


func _ganti_field(objek: String, field: String, nilai: String) -> String:
	var re := RegEx.create_from_string('("%s"\\s*:\\s*)-?[0-9.]+' % field)
	var m := re.search(objek)
	return objek.substr(0, m.get_start()) + m.get_string(1) + nilai + objek.substr(m.get_end())


func _baca_csv(path: String, wajib: Array) -> Array[Dictionary]:
	var hasil: Array[Dictionary] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_salah("tidak bisa membuka %s" % path)
		return hasil
	var kepala := f.get_csv_line()
	for k in wajib:
		if not (k in kepala):
			_salah("%s: kolom '%s' tidak ada" % [path, k])
			return hasil
	while not f.eof_reached():
		var sel := f.get_csv_line()
		if sel.size() < wajib.size() or sel[0].strip_edges().is_empty() or sel[0].begins_with("#"):
			continue
		var b := {}
		for k in kepala.size():
			b[kepala[k]] = sel[k].strip_edges() if k < sel.size() else ""
		hasil.append(b)
	return hasil


## "0.5", "300", atau pecahan "1/60". Bilangan bulat dikembalikan sebagai int. null kalau bukan angka.
func _angka(s: String) -> Variant:
	var nilai := 0.0
	if "/" in s:
		var bagian := s.split("/")
		if bagian.size() != 2 or not bagian[0].strip_edges().is_valid_float() \
				or not bagian[1].strip_edges().is_valid_float() or float(bagian[1]) == 0.0:
			return null
		nilai = float(bagian[0]) / float(bagian[1])
	elif s.is_valid_float():
		nilai = float(s)
	else:
		return null
	return _rapi(nilai)


func _rapi(v: Variant) -> Variant:
	return int(v) if float(v) == floorf(float(v)) else float(v)


func _tulis(path: String, teks: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_salah("tidak bisa menulis %s" % path)
		return
	f.store_string(teks)


func _salah(pesan: String) -> void:
	_galat += 1
	push_error("terapkan_balancing: " + pesan)
