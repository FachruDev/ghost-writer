extends Control
## Layout portrait: HUD, peta kota, mesin tik, tangan kartu (struktur-project.md).
## Juga menghubungkan pengendali rumor, misi, event, dan save.

const HUD := preload("res://scenes/ui/hud.tscn")
const CITY := preload("res://scenes/city/city.tscn")
const DESK := preload("res://scenes/desk/desk.tscn")
const HAND := preload("res://scenes/hand/hand.tscn")
const SHOP := preload("res://scenes/ui/shop.tscn")

const UKURAN_FONT := 24
const RASIO := {"hud": 0.1, "city": 0.43, "desk": 0.27, "hand": 0.2}


func _ready() -> void:
	var tema := Theme.new()
	tema.default_font_size = UKURAN_FONT
	theme = tema
	var latar := ColorRect.new()
	latar.color = Palet.LATAR
	latar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(latar)
	var rumor := RumorController.new()
	rumor.name = "RumorController"
	add_child(rumor)
	var event := EventController.new()
	event.name = "EventController"
	event.sim = rumor.sim
	rumor.pengali_event = event.pengali_viral
	add_child(event)
	var misi := MissionController.new()
	misi.name = "MissionController"
	add_child(misi)
	SaveSystem.sumber_snapshot = rumor.snapshot_untuk_save
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
	kota.atur_sim(rumor.sim)
	_tambah(tata, DESK.instantiate(), RASIO["desk"])
	_tambah(tata, HAND.instantiate(), RASIO["hand"])
	add_child(SHOP.instantiate())


func _tambah(induk: Control, anak: Control, rasio: float) -> Control:
	anak.size_flags_vertical = Control.SIZE_EXPAND_FILL
	anak.size_flags_stretch_ratio = rasio
	induk.add_child(anak)
	return anak
