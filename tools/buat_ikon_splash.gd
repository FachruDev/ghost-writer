extends SceneTree
## Membuat PNG ikon aplikasi dan boot splash dari sumbernya (kanvas desain papan 21–22):
## - assets/ikon_app/ikon_{depan,belakang,mono}.svg -> PNG 432 untuk adaptive icon Android,
##   ikon_192.png (ikon utama / jendela desktop, sudut membulat) dan ikon_toko_512.png (Play Store, kotak penuh)
## - boot splash 1080x1920: Si Hantu (scenes/ui/hantu.gd) + logo, digambar Godot dengan font game.
## Jalankan dengan jendela (bukan --headless), karena splash perlu dirender:
##   godot --path . -s res://tools/buat_ikon_splash.gd

const DIR := "res://assets/ikon_app/"
const KANVAS := 432.0
## Ikon utama dan Play Store tidak dipotong bentuk adaptive, jadi hantu diperbesar.
const ZOOM_PENUH := 1.25
const MALAM := Color("1a1530")


func _initialize() -> void:
	for nama in ["depan", "belakang", "mono"]:
		_simpan(_svg(nama, 1.0), "ikon_%s_432.png" % nama)
	var utama := _gabung(192, ZOOM_PENUH)
	_sudut_bulat(utama, 192 * 0.22)
	_simpan(utama, "ikon_192.png")
	_simpan(_gabung(512, ZOOM_PENUH), "ikon_toko_512.png")
	await _splash()
	quit()


func _svg(nama: String, skala: float) -> Image:
	var img := Image.new()
	var err := img.load_svg_from_string(FileAccess.get_file_as_string(DIR + "ikon_%s.svg" % nama), skala)
	if err != OK:
		push_error("SVG gagal dimuat: " + nama)
	return img


## Belakang + depan pada ukuran `ukuran`, lapisan depan diperbesar `zoom` dari tengah.
func _gabung(ukuran: int, zoom: float) -> Image:
	var hasil := _svg("belakang", ukuran / KANVAS)
	var depan := _svg("depan", ukuran / KANVAS * zoom)
	var geser := (depan.get_width() - ukuran) / 2
	hasil.blend_rect(depan, Rect2i(geser, geser, ukuran, ukuran), Vector2i.ZERO)
	return hasil


func _sudut_bulat(img: Image, r: float) -> void:
	var n := img.get_width()
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var dalam := Vector2(clampf(p.x, r, n - r), clampf(p.y, r, n - r))
			var a := clampf(r - p.distance_to(dalam) + 0.5, 0.0, 1.0)
			if a < 1.0:
				var c := img.get_pixel(x, y)
				c.a *= a
				img.set_pixel(x, y, c)


func _simpan(img: Image, nama: String) -> void:
	var path := DIR + nama
	if img.save_png(path) != OK:
		push_error("gagal menyimpan " + path)
		return
	print("tersimpan ", path, " ", img.get_size())


## Splash 720x1280 (satuan layar game) dirender di 1080x1920: latar malam polos (sama dengan
## boot_splash/bg_color, jadi pita atas-bawah di layar lebih tinggi tidak terlihat), cahaya lembut,
## hantu tepat di tengah (sama dengan splash sistem Android 12+), logo di atasnya.
func _splash() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 1920)
	vp.size_2d_override = Vector2i(720, 1280)
	vp.size_2d_override_stretch = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var latar := ColorRect.new()
	latar.color = MALAM
	latar.size = Vector2(720, 1280)
	vp.add_child(latar)
	var cahaya := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(Color("f4f1ff"), 0.16))
	g.set_color(1, Color(Color("f4f1ff"), 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 512
	tex.height = 512
	cahaya.texture = tex
	cahaya.size = Vector2(560, 560)
	cahaya.position = Vector2(360, 640) - cahaya.size / 2.0
	vp.add_child(cahaya)
	var hantu: Control = load("res://scenes/ui/hantu.gd").new()
	hantu.size = Vector2(240, 300)
	hantu.position = Vector2(360, 640) - hantu.size / 2.0 - Vector2(0, 5)  # pusat isi (60, 77.5) x2 di tengah layar
	vp.add_child(hantu)
	hantu.set_process(false)  # pose diam tanpa goyang
	var logo := Label.new()
	logo.text = "GHOSTWRITER"  # logo, sama di semua bahasa (UI_JUDUL_GAME)
	logo.add_theme_font_override("font", load("res://assets/fonts/LilitaOne-Regular.ttf"))
	logo.add_theme_font_size_override("font_size", 88)
	logo.add_theme_color_override("font_color", Color.WHITE)
	logo.add_theme_color_override("font_shadow_color", Color("ff3d7f"))
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 10)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.size = Vector2(720, 110)
	logo.position = Vector2(0, 330)
	vp.add_child(logo)
	for i in 6:
		await process_frame
	_simpan(vp.get_texture().get_image(), "splash.png")
