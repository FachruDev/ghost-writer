extends GdUnitTestSuite
## Event acak Era 1 (EVENT.md): E13 Arisan Kompleks dan E14 Mati Lampu ditambah di 0.9.0 supaya
## 15 menit pertama tidak hanya berganti-ganti Hari Pasar dan Ronda Malam.

const IDS := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}
const ACAK_ERA1 := ["e_hari_pasar", "e_ronda_malam", "e_arisan", "e_mati_lampu"]

var _main: Node


func before_test() -> void:
	SaveSystem.reset_progres()
	GameClock.atur_seed(11)
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)


func after_test() -> void:
	SaveSystem.reset_progres()


func _event(id: String) -> Dictionary:
	for e in DataDB.events:
		if str(e["id"]) == id:
			return e
	return {}


func test_arisan_menguatkan_rumor_iri_di_kompleks_hijau() -> void:
	var ec := _main.get_node("EventController")
	ec._mulai(_event("e_arisan"))
	var kompleks := DataDB.district_index("kompleks_hijau")
	var pasar := DataDB.district_index("pasar_lama")
	assert_float(ec.pengali_viral(kompleks, "iri")).is_equal_approx(1.8, 0.001)
	assert_float(ec.pengali_viral(kompleks, "lucu")).is_equal_approx(1.2, 0.001)
	assert_float(ec.pengali_viral(pasar, "iri")).is_equal_approx(1.0, 0.001)
	assert_float(float(ec.pengali_rumor(IDS)["uang"])).is_equal_approx(1.0, 0.001)


func test_mati_lampu_gosip_cepat_tapi_uang_separuh() -> void:
	var ec := _main.get_node("EventController")
	ec._mulai(_event("e_mati_lampu"))
	for d in DataDB.districts.size():
		assert_float(ec.pengali_viral(d, "takut")).is_equal_approx(1.25, 0.001)
	assert_float(float(ec.pengali_rumor(IDS)["uang"])).is_equal_approx(0.5, 0.001)


## Pengecekan event acak berulang di Era 1: keempat event bisa terpilih, tidak ada yang mendominasi.
func test_keempat_event_acak_era_1_muncul() -> void:
	var ec := _main.get_node("EventController")
	var hitung := {}
	for i in 400:
		ec._aktif = {}
		ec._sejak_event = 999.0
		ec._cek_acak()
		var id := str(ec._aktif.get("id", ""))
		if not id.is_empty():
			hitung[id] = int(hitung.get(id, 0)) + 1
	assert_array(hitung.keys()).contains_exactly_in_any_order(ACAK_ERA1)
	var total := 0
	for id in hitung:
		total += int(hitung[id])
	for id in hitung:
		assert_float(float(hitung[id]) / total).is_between(0.12, 0.40)
