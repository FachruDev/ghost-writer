extends GdUnitTestSuite
## Peta jaringan berlapis (CHECKLIST 0.9.0, kinerja): latar statis di belakang, animasi di depan,
## posisi warga di-cache, dan atlas wajah memetakan tiap warga ke sel status × variasi yang benar.

var _main: Node


func before_test() -> void:
	SaveSystem.reset_progres()
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)


func after_test() -> void:
	SaveSystem.reset_progres()


func _bingkai(n := 3) -> void:
	for i in n:
		await get_tree().process_frame


func _peta() -> PetaJaringan:
	return _main.find_children("*", "PetaJaringan", true, false)[0]


func test_peta_punya_lapisan_latar_dan_animasi() -> void:
	var peta := _peta()
	var latar := peta.find_children("*", "PetaLatar", false, false)
	var animasi := peta.find_children("*", "PetaAnimasi", false, false)
	assert_int(latar.size()).is_equal(1)
	assert_int(animasi.size()).is_equal(1)
	assert_bool((latar[0] as Control).show_behind_parent).is_true()
	assert_int((animasi[0] as Control).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_posisi_warga_di_cache_dan_ikut_simulasi_baru() -> void:
	await _bingkai()
	var peta := _peta()
	assert_bool(peta.siap()).is_true()
	var sim: SpreadSim = _main.get_node("RumorController").sim
	assert_int(peta.posisi().size()).is_equal(sim.posisi.size())
	GameState.tambah_pengikut(900)
	GameState.uang = 50000
	for u in ["kantor", "gedung_media", "menara_server"]:
		assert_bool(GameState.beli_upgrade(u)).is_true()
	await _bingkai()
	var sim_baru: SpreadSim = _main.get_node("RumorController").sim
	assert_bool(peta.siap()).is_true()
	assert_int(peta.posisi().size()).is_equal(sim_baru.posisi.size())
	assert_int(peta.posisi().size()).is_greater(sim.posisi.size())


func test_atlas_satu_sel_per_status_dan_variasi() -> void:
	var atlas := AtlasWajah.new()
	add_child(atlas)
	atlas.siapkan(10.0)
	# Kulit (5) dan rambut (6) berulang tiap 30 warga: warga i dan i + 30 berwajah sama.
	assert_that(atlas.region(1, 7)).is_equal(atlas.region(1, 37))
	assert_that(atlas.region(1, 7)).is_not_equal(atlas.region(1, 8))
	assert_that(atlas.region(1, 7)).is_not_equal(atlas.region(2, 7))
	var sel := atlas.sel()
	assert_int(sel).is_greater_equal(ceili(10.0 * 1.9) * 2)
	var semua := {}
	for s in AtlasWajah.STATUS:
		for v in AtlasWajah.VARIASI:
			semua[atlas.region(s, v)] = true
	semua[atlas.region_cahaya()] = true
	assert_int(semua.size()).is_equal(AtlasWajah.STATUS * AtlasWajah.VARIASI + 1)
	for r in semua:
		assert_bool(Rect2(Vector2.ZERO, Vector2(atlas.size)).encloses(r)).is_true()
	atlas.queue_free()
