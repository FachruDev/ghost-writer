class_name PetunjukKartu
extends PanelContainer
## Kartu petunjuk sistem baru: ubin ikon sistem, teks singkat, dan tombol Oke. Garis cyan
## membedakannya dari gelembung tutorial yang kuning; ekor ke sasaran digambar PetunjukLapisan.
## Ketukan di kartu tidak tembus ke peta atau meja di bawahnya.

signal oke

const PAD := 20
const IKON := 76
const JARAK := 18

var _ubin: PanelContainer
var _gaya_ubin: StyleBoxFlat
var _ikon: TextureRect
var _teks: Label
var _tombol: Button
var _anim: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var gaya := Palet.kotak(Palet.PANEL, Palet.CYAN, 32)
	gaya.set_content_margin_all(PAD)
	gaya.shadow_color = Color(0, 0, 0, 0.35)
	gaya.shadow_size = 18
	gaya.shadow_offset = Vector2(0, 8)
	add_theme_stylebox_override("panel", gaya)
	var kolom := UiKit.kolom(self, 8)
	var baris := UiKit.baris(kolom, JARAK)
	_ubin = PanelContainer.new()
	_ubin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ubin.custom_minimum_size = Vector2(IKON, IKON)
	_ubin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_gaya_ubin = Palet.kotak(Palet.CYAN, Color.TRANSPARENT, 24)
	_gaya_ubin.set_content_margin_all(16)
	_gaya_ubin.border_width_bottom = 6
	_ubin.add_theme_stylebox_override("panel", _gaya_ubin)
	baris.add_child(_ubin)
	_ikon = UiKit.ikon(_ubin, "perisai", 40, Palet.TINTA)
	_teks = UiKit.label(baris, 26, Palet.TEKS, Tema.font_ui(600))
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_teks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tombol = UiKit.tombol(kolom, "", Palet.CYAN, Palet.CYAN_GELAP, 26, Tema.font_ui(700), 88)
	_tombol.size_flags_horizontal = Control.SIZE_SHRINK_END
	_tombol.custom_minimum_size.x = 200
	_tombol.pressed.connect(func() -> void: oke.emit())


## Isi kartu dari info Events.petunjuk_tampil (dipanggil ulang saat bahasa berganti).
func atur(info: Dictionary) -> void:
	var warna := Palet.CYAN
	var nama := "perisai"
	match str(info.get("sasaran", "")):
		"saluran":
			nama = str(info.get("nilai", ""))
			warna = Palet.saluran(nama)
		"staf":
			nama = "orang"
			warna = Palet.HIJAU
	_ikon.texture = UiKit.muat_ikon(nama)
	_gaya_ubin.bg_color = warna
	_gaya_ubin.border_color = warna.darkened(0.3)
	_teks.text = PetunjukController.teks(info)
	_tombol.text = tr("UI_TIP_OKE")


## Lebar tetap (piksel viewport); label diberi lebar minimum supaya tingginya diukur benar sejak awal.
func atur_lebar(lebar: float) -> void:
	custom_minimum_size.x = lebar
	_teks.custom_minimum_size.x = maxf(0.0, lebar - PAD * 2 - IKON - JARAK)


func muncul() -> void:
	if _anim:
		_anim.kill()
	scale = Vector2(0.8, 0.8)
	modulate.a = 0.0
	_anim = create_tween().set_parallel()
	_anim.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim.tween_property(self, "modulate:a", 1.0, 0.15)


func hilang() -> Tween:
	if _anim:
		_anim.kill()
	_anim = create_tween().set_parallel()
	_anim.tween_property(self, "scale", Vector2(0.85, 0.85), 0.15).set_ease(Tween.EASE_IN)
	_anim.tween_property(self, "modulate:a", 0.0, 0.15)
	return _anim
