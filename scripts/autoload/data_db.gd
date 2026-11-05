extends Node
## Memuat konten dari res://data/ saat start. Konten tidak berubah selama permainan.

const PATH_WORDS := "res://data/words.json"
const PATH_TEMPLATES := "res://data/templates.json"
const PATH_DISTRICTS := "res://data/districts.json"

var words: Dictionary = {}
var templates: Dictionary = {}
var districts: Array[Dictionary] = []


func _ready() -> void:
	words = _index(_muat(PATH_WORDS))
	templates = _index(_muat(PATH_TEMPLATES))
	districts.assign(_muat(PATH_DISTRICTS))


func get_word(id: String) -> Dictionary:
	return words.get(id, {})


func get_template(id: String) -> Dictionary:
	return templates.get(id, {})


func get_district(id: String) -> Dictionary:
	var i := district_index(id)
	return districts[i] if i >= 0 else {}


func district_index(id: String) -> int:
	for i in districts.size():
		if str(districts[i].get("id", "")) == id:
			return i
	return -1


func _muat(path: String) -> Array:
	var teks := FileAccess.get_file_as_string(path)
	if teks.is_empty():
		push_error("DataDB: gagal membaca %s" % path)
		return []
	var data: Variant = JSON.parse_string(teks)
	if not data is Array:
		push_error("DataDB: %s bukan array JSON" % path)
		return []
	return data


func _index(daftar: Array) -> Dictionary:
	var hasil := {}
	for item in daftar:
		if item is Dictionary and item.has("id"):
			hasil[str(item["id"])] = item
	return hasil
