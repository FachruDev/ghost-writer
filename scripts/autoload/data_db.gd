extends Node
## Memuat konten dari res://data/ saat start. Konten tidak berubah selama permainan.

const PATH_WORDS := "res://data/words.json"
const PATH_TEMPLATES := "res://data/templates.json"
const PATH_DISTRICTS := "res://data/districts.json"
const PATH_UPGRADES := "res://data/upgrades.json"
const PATH_MISSIONS := "res://data/missions.json"
const PATH_EVENTS := "res://data/events.json"
const PATH_TOKOH := "res://data/tokoh.json"
const PATH_ENDINGS := "res://data/endings.json"

var words: Dictionary = {}
var templates: Dictionary = {}
## Distrik aktif untuk era sekarang, dengan "area" sesuai tata letak era itu (urutan = indeks simulasi).
var districts: Array[Dictionary] = []
## Semua distrik di data, termasuk yang baru terbuka di era berikutnya.
var semua_distrik: Array[Dictionary] = []
var upgrades: Dictionary = {}
var missions: Array[Dictionary] = []
var events: Array[Dictionary] = []
## Tokoh fiktif target besar (Era 4).
var tokoh: Array[Dictionary] = []
## Dua ending kampanye akhir, per id ("menang", "kalah").
var endings: Dictionary = {}


func _ready() -> void:
	words = _index(_muat(PATH_WORDS))
	templates = _index(_muat(PATH_TEMPLATES))
	semua_distrik.assign(_muat(PATH_DISTRICTS))
	upgrades = _index(_muat(PATH_UPGRADES))
	missions.assign(_muat(PATH_MISSIONS))
	events.assign(_muat(PATH_EVENTS))
	tokoh.assign(_muat(PATH_TOKOH))
	endings = _index(_muat(PATH_ENDINGS))
	atur_era(1)
	Events.era_berubah.connect(atur_era)


## Pilih distrik aktif dan tata letaknya untuk era. Memancarkan peta_berubah kalau ada yang berubah.
func atur_era(era: int) -> void:
	var baru: Array[Dictionary] = []
	for d in semua_distrik:
		if int(d.get("era_min", 1)) > era:
			continue
		var salinan := d.duplicate()
		var per_era: Dictionary = d.get("area_era", {})
		var terpakai := 0
		for kunci in per_era:
			if int(kunci) <= era and int(kunci) > terpakai:
				terpakai = int(kunci)
				salinan["area"] = per_era[kunci]
		baru.append(salinan)
	var berubah := str(baru.map(func(x: Dictionary) -> Array: return x["area"])) \
		!= str(districts.map(func(x: Dictionary) -> Array: return x["area"]))
	districts = baru
	if berubah:
		Events.peta_berubah.emit()


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
