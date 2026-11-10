extends GdUnitTestSuite
## GulirSentuh: seret jari di atas tombol/panel tetap menggulir daftar (sumbu vertikal dan horizontal),
## ketukan biasa tidak menggulir, sisa sentuhan seretan ditahan (tombol tidak terpencet), dan daftar
## di belakang lembar penutup tidak ikut tergulir. Kejadian dikirim langsung ke GulirSentuh._input:
## di runner headless gdUnit, push_input tidak sampai ke GUI (ketukan pun tidak memencet tombol).

var _induk: Control
var _daftar: ScrollContainer
var _tombol: Button
var _tangan: ScrollContainer


func before_test() -> void:
	_induk = auto_free(Control.new())
	_induk.size = Vector2(720, 1280)
	add_child(_induk)
	# Daftar vertikal berisi panel (STOP) dan tombol (STOP): dulu menahan geser bawaan.
	_daftar = ScrollContainer.new()
	_daftar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_daftar.position = Vector2(0, 0)
	_daftar.size = Vector2(720, 600)
	_induk.add_child(_daftar)
	var kolom := VBoxContainer.new()
	kolom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daftar.add_child(kolom)
	for i in 12:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(0, 150)
		kolom.add_child(panel)
		var b := Button.new()
		b.text = "Beli %d" % i
		panel.add_child(b)
		if i == 0:
			_tombol = b
	# Tangan kartu: hanya gulir horizontal.
	_tangan = ScrollContainer.new()
	_tangan.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tangan.position = Vector2(0, 800)
	_tangan.size = Vector2(720, 200)
	_induk.add_child(_tangan)
	var deret := HBoxContainer.new()
	_tangan.add_child(deret)
	for i in 10:
		var kartu := Button.new()
		kartu.custom_minimum_size = Vector2(160, 180)
		deret.add_child(kartu)
	for _f in 3:
		await get_tree().process_frame


func _tekan(pos: Vector2, ditekan: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = ditekan
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if ditekan else 0
	GulirSentuh._input(e)


func _geser(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	GulirSentuh._input(e)


func _seret(dari: Vector2, ke: Vector2, langkah := 8) -> void:
	_tekan(dari, true)
	for k in range(1, langkah + 1):
		_geser(dari.lerp(ke, float(k) / langkah))
	# Diam sebentar sebelum diangkat: tanpa luncuran, jadi posisi akhir bisa dicek pasti.
	await get_tree().create_timer(GulirSentuh.DIAM_SEBELUM_ANGKAT / 1000.0 + 0.05).timeout
	assert_bool(GulirSentuh._telan).is_true()  # sisa sentuhan (tiruan mouse untuk tombol) ditahan
	_tekan(ke, false)
	await get_tree().process_frame


func test_disiapkan_geser_bawaan_mati() -> void:
	assert_int(_daftar.scroll_deadzone).is_equal(GulirSentuh.BAWAAN_MATI)
	assert_int(_daftar.vertical_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_SHOW_NEVER)
	assert_int(_tangan.vertical_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)


func test_seret_dari_tombol_menggulir_daftar() -> void:
	var awal := _tombol.get_global_rect().get_center()
	await _seret(awal, awal - Vector2(0, 200))
	# Isi menempel di jari 1:1 sejak jari melewati ambang (langkah pertama 25 px jadi jangkar).
	assert_int(_daftar.scroll_vertical).is_between(170, 180)


func test_ketukan_tidak_menggulir_dan_tidak_ditahan() -> void:
	var pos := _tombol.get_global_rect().get_center()
	_tekan(pos, true)
	_geser(pos + Vector2(0, 4))  # gemetar jari di bawah ambang
	_tekan(pos + Vector2(0, 4), false)
	await get_tree().process_frame
	assert_int(_daftar.scroll_vertical).is_equal(0)
	assert_bool(GulirSentuh._telan).is_false()  # ketukan sampai ke tombol seperti biasa


func test_tangan_digulir_menyamping_dari_atas_kartu() -> void:
	var awal := Vector2(500, 900)
	await _seret(awal, awal - Vector2(240, 0))
	assert_int(_tangan.scroll_horizontal).is_between(205, 215)  # 240 - langkah pertama 30


func test_seret_vertikal_di_tangan_tidak_menggulir() -> void:
	assert_object(GulirSentuh.gulir_di(Vector2(500, 900), true)).is_null()
	assert_object(GulirSentuh.gulir_di(Vector2(500, 900), false)).is_same(_tangan)


func test_lembar_penutup_menghalangi_daftar_di_belakang() -> void:
	var tutup := ColorRect.new()
	tutup.size = Vector2(720, 1280)
	_induk.add_child(tutup)
	await get_tree().process_frame
	assert_object(GulirSentuh.gulir_di(Vector2(360, 300), true)).is_null()
	tutup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	assert_object(GulirSentuh.gulir_di(Vector2(360, 300), true)).is_same(_daftar)


func test_kibasan_meluncur_lalu_berhenti_di_batas() -> void:
	var awal := _tombol.get_global_rect().get_center() + Vector2(0, 300)
	_tekan(awal, true)
	for k in range(1, 6):
		_geser(awal - Vector2(0, 60 * k))
		await get_tree().create_timer(0.016).timeout
	_tekan(awal - Vector2(0, 300), false)
	var setelah_lepas := _daftar.scroll_vertical
	await get_tree().create_timer(0.3).timeout
	assert_int(_daftar.scroll_vertical).is_greater(setelah_lepas)
	assert_int(_daftar.scroll_vertical).is_less_equal(int(GulirSentuh.ruang(_daftar, true)))
