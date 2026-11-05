extends Node
## Memuat konten dari res://data/ saat start. Konten tidak berubah selama permainan.

const PATH_WORDS := "res://data/words.json"
const PATH_TEMPLATES := "res://data/templates.json"
const PATH_DISTRICTS := "res://data/districts.json"
const PATH_UPGRADES := "res://data/upgrades.json"
const PATH_MISSIONS := "res://data/missions.json"
const PATH_EVENTS := "res://data/events.json"

var words: Dictionary = {}
var templates: Dictionary = {}
var districts: Array[Dictionary] = []
var upgrades: Dictionary = {}
var missions: Array[Dictionary] = []
var events: Array[Dictionary] = []


func _ready() -> void:
	words = _index(_muat(PATH_WORDS))
	templates = _index(_muat(PATH_TEMPLATES))
	districts.assign(_muat(PATH_DISTRICTS))
	upgrades = _index(_muat(PATH_UPGRADES))
	missions.assign(_muat(PATH_MISSIONS))
	events.assign(_muat(PATH_EVENTS))


func get_upgrade(id: String) -> Dictionary:
	return upgrades.get(id, {})


## Saluran sesuai urutan di upgrades.json.
func saluran() -> Array[Dictionary]:
	var hasil: Array[Dictionary] = []
	for id in upgrades:
		if str(upgrades[id].get("jenis", "")) == "saluran":
			hasil.append(upgrades[id])
	return hasil


func kata_per_slot(slot: String) -> Array[String]:
	var hasil: Array[String] = []
	for id in words:
		if str(words[id].get("slot", "")) == slot:
			hasil.append(id)
	return hasil


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
