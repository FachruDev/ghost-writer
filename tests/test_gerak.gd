extends GdUnitTestSuite
## Animasi & art (CHECKLIST 0.3.0–0.9.0): umpan balik tombol, layar penuh meluncur, kertas terbang,
## uang dari titik warga, kedip mutasi di feed, meja per era + transisi, Naik Era menunggu transisi,
## dan ending menunggu kota memudar titik demi titik.

var _main: Node


func before_test() -> void:
	SaveSystem.reset_progres()
	_main = auto_free(load("res://scenes/main/main.tscn").instantiate())
	add_child(_main)
	GameState.statistik["tutorial_lewat"] = true
	Events.tutorial_dilewati.emit()


func after_test() -> void:
	for nama in [&"toko", &"ending", &"dilema", &"kontrak"]:
		GameClock.lanjut(nama)
	SaveSystem.reset_progres()


func _bingkai(n := 3) -> void:
	for i in n:
		await get_tree().process_frame


func _detik(d: float) -> void:
	await get_tree().create_timer(d).timeout


func _anak(akhiran: String) -> Node:
	for n in _main.get_children():
		if n.get_script() and str(n.get_script().resource_path).ends_with(akhiran):
			return n
	return null


func _peta() -> PetaJaringan:
	return _main.find_child("Peta", true, false) as PetaJaringan


func test_tombol_mengecil_saat_ditekan_lalu_kembali() -> void:
	var b := UiKit.tombol(_main, "Uji")
	await _bingkai()
	b.button_down.emit()
	await _detik(0.12)
	assert_float(b.scale.x).is_less(1.0)
	b.button_up.emit()
	await _detik(0.25)
	assert_float(b.scale.x).is_equal_approx(1.0, 0.01)


func test_layar_penuh_meluncur_naik_saat_dibuka() -> void:
	Events.toko_diminta.emit(true)
	var toko := _anak("shop.gd") as Lembar
	assert_float(toko._panel.offset_transform_position.y).is_greater(0.0)
	await _detik(Lembar.LAMA_BUKA + 0.1)
	assert_float(toko._panel.offset_transform_position.y).is_equal_approx(0.0, 0.5)
	assert_float(toko._panel.modulate.a).is_equal_approx(1.0, 0.01)


func test_kertas_terbang_mendarat_lalu_hilang() -> void:
	var k := KertasTerbang.luncurkan(_main, Vector2(100, 900), Vector2(400, 300))
	await _detik(KertasTerbang.LAMA_TERBANG + 0.05)
	assert_bool(is_instance_valid(k)).is_true()
	assert_vector(k.global_position).is_equal_approx(Vector2(400, 300), Vector2(1, 1))
	await _detik(KertasTerbang.LAMA_RIAK + 0.1)
	assert_bool(is_instance_valid(k)).is_false()


func test_uang_muncul_dari_warga_yang_paling_baru_percaya() -> void:
	await _bingkai(5)
	var peta := _peta()
	var sim := peta.sim()
	var calon: Array[int] = []
	for i in sim.status.size():
		if sim.distrik_warga[i] == 0:
			calon.append(i)
	sim.status[calon[0]] = SpreadSim.Status.PERCAYA
	sim.terakhir_berubah[calon[0]] = 5.0
	sim.status[calon[1]] = SpreadSim.Status.PERCAYA
	sim.terakhir_berubah[calon[1]] = 9.0  # paling baru
	var animasi := _main.find_child("KirimanAnimasi", true, false) as KirimanAnimasi
	var harap := peta.get_global_transform() * peta.posisi()[calon[1]]
	assert_vector(animasi._titik_warga(0)).is_equal_approx(harap, Vector2(0.5, 0.5))


## Rumor server memancarkan uang puluhan kali per detik: per distrik digabung jadi satu pil (jumlah
## totalnya tetap), dan pil yang tampil bersamaan dibatasi.
func test_uang_digabung_per_distrik_dan_pil_dibatasi() -> void:
	await _bingkai(5)
	var animasi := _main.find_child("KirimanAnimasi", true, false) as KirimanAnimasi
	var kota := animasi.kota
	var sebelum := kota.get_child_count()
	for k in 30:
		Events.uang_dari_distrik.emit(0, 2)
	await _bingkai(2)
	var pil_baru: Array = kota.get_children().slice(sebelum)
	assert_int(pil_baru.size()).is_equal(1)
	assert_str((pil_baru[0].find_children("*", "Label", true, false)[0] as Label).text).is_equal("+" + Bahasa.angka(60))
	for k in 40:
		for d in DataDB.districts.size():
			Events.uang_dari_distrik.emit(d, 1)
		await _bingkai(1)
	assert_int(animasi._pil_hidup).is_less_equal(KirimanAnimasi.MAKS_PIL)
	assert_int(kota.get_child_count() - sebelum).is_less_equal(KirimanAnimasi.MAKS_PIL)


func test_feed_mutasi_berkedip_dari_headline_asli_ke_mutasi() -> void:
	var kata := {"subjek": "pak_rt", "aksi": "menari_malam", "tempat": "pasar", "sumber": "tetangga"}
	var mutasi := kata.duplicate()
	mutasi["subjek"] = "bu_lurah"
	Events.feed_baru.emit({"jenis": "rumor", "template_id": "t_dasar", "kata_ids": kata})
	Events.feed_baru.emit({"jenis": "mutasi", "template_id": "t_dasar", "kata_ids": mutasi})
	var feed := _main.find_child("Feed", true, false)
	if feed == null:
		for n in _main.find_children("*", "VBoxContainer", true, false):
			if n.has_method("_kedip_mutasi"):
				feed = n
	var label := feed.get_child(feed.get_child_count() - 1).get_child(0).get_child(1) as Label
	assert_str(label.text).contains(HeadlineBuilder.susun("t_dasar", kata))
	await _detik(0.5)
	assert_str(label.text).is_equal(tr("UI_MUTASI") % HeadlineBuilder.susun("t_dasar", mutasi))


func test_meja_berganti_era_lewat_transisi_dan_naik_era_menunggu() -> void:
	await _bingkai()
	var meja := _main.find_children("*", "MejaEra", true, false)[0] as MejaEra
	assert_int(meja.era()).is_equal(1)
	GameState.era = 2
	Events.era_berubah.emit(2)
	await _bingkai()
	assert_float(meja._p).is_less(1.0)
	var naik := _anak("naik_era.gd") as Lembar
	assert_bool(naik.visible).is_false()  # meja berganti dulu
	await _detik(MejaEra.LAMA_TRANSISI + 0.1)
	assert_float(meja._p).is_equal(1.0)
	assert_int(meja.era()).is_equal(2)
	assert_object(meja._gaya_kaki.bg_color).is_equal(Palet.MEJA_ERA[2])
	assert_int(meja._hiasan.era).is_equal(2)
	assert_bool(naik.visible).is_true()


func test_ending_menunggu_kota_memudar() -> void:
	await _bingkai(5)
	Events.ending_tercapai.emit("kalah")
	var ending := _main.get_node("Ending")
	assert_bool(ending.visible).is_true()  # sudah menahan ketukan dan menjeda waktu
	assert_float(ending.modulate.a).is_equal(0.0)
	assert_int(_main.find_children("*", "KotaMemudar", true, false).size()).is_equal(1)
	assert_bool(ending._ilustrasi.menang).is_false()
	await _detik(KotaMemudar.LAMA + 0.9)
	assert_float(ending.modulate.a).is_equal_approx(1.0, 0.01)
