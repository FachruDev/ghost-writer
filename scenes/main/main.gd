extends Control
## Layout portrait: HUD, peta kota, mesin tik, tangan kartu (struktur-project.md).

const HUD := preload("res://scenes/ui/hud.tscn")
const CITY := preload("res://scenes/city/city.tscn")
const DESK := preload("res://scenes/desk/desk.tscn")
const HAND := preload("res://scenes/hand/hand.tscn")
const SHOP := preload("res://scenes/ui/shop.tscn")

const UKURAN_FONT := 24
const RASIO := {"hud": 0.08, "city": 0.45, "desk": 0.24, "hand": 0.23}


func _ready() -> void:
	var tema := Theme.new()
	tema.default_font_size = UKURAN_FONT
	theme = tema
	var latar := ColorRect.new()
	latar.color = Palet.LATAR
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var controller := RumorController.new()
	controller.name = "RumorController"
	add_child(controller)
	var tepi := MarginContainer.new()
	tepi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for sisi in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		tepi.add_theme_constant_override(sisi, 10)
	add_child(tepi)
	var tata := VBoxContainer.new()
	tata.add_theme_constant_override("separation", 8)
	tepi.add_child(tata)
	_tambah(tata, HUD.instantiate(), RASIO["hud"])
	var kota := _tambah(tata, CITY.instantiate(), RASIO["city"])
	kota.atur_sim(controller.sim)
	_tambah(tata, DESK.instantiate(), RASIO["desk"])
	_tambah(tata, HAND.instantiate(), RASIO["hand"])
	add_child(SHOP.instantiate())


func _tambah(induk: Control, anak: Control, rasio: float) -> Control:
	anak.size_flags_vertical = Control.SIZE_EXPAND_FILL
	anak.size_flags_stretch_ratio = rasio
	induk.add_child(anak)
	return anak
