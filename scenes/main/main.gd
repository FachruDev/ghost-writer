extends Control
## Layout portrait (kanvas papan 02): HUD, peta jaringan, lalu meja (kertas headline, tangan kartu,
## saluran + KIRIM). Lapisan di atasnya: lembar saluran, toko, ending, dst.
## Juga menghubungkan pengendali rumor, misi, event, dan save.

const HUD := preload("res://scenes/ui/hud.tscn")
const CITY := preload("res://scenes/city/city.tscn")
const DESK := preload("res://scenes/desk/desk.tscn")
const SALURAN := preload("res://scenes/desk/saluran_sheet.gd")
const LAPISAN := [
	preload("res://scenes/ui/dilema_sheet.gd"),
	preload("res://scenes/ui/tokoh_sheet.gd"),
	preload("res://scenes/ui/final_sheet.gd"),
	preload("res://scenes/ui/naik_era.gd"),
	preload("res://scenes/ui/offline_sheet.gd"),
	preload("res://scenes/ui/pengaturan_layar.gd"),
	preload("res://scenes/ui/tentang_layar.gd"),
]
const SHOP := preload("res://scenes/ui/shop.tscn")
const JUDUL := "res://scenes/ui/judul.tscn"
const ENDING := preload("res://scenes/ui/ending.tscn")
const TUTORIAL := preload("res://scenes/ui/tutorial_lapisan.gd")
const PETUNJUK := preload("res://scenes/ui/petunjuk_lapisan.gd")

## Tepi kiri-kanan isi layar (12 px kanvas).
const TEPI := 24


func _ready() -> void:
	SaveSystem.selesaikan_reset()
	theme = Tema.buat()
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
	rumor.pengali_rumor = event.pengali_rumor
	add_child(event)
	var staf := StaffController.new()
	staf.name = "StaffController"
	staf.pengali_rumor = event.pengali_rumor
	add_child(staf)
	Events.era_berubah.connect(func(era: int) -> void:
		if era > 1 and is_node_ready():
			Events.feed_baru.emit({"jenis": "era", "era": era}))
	var tokoh := TokohController.new()
	tokoh.name = "TokohController"
	rumor.tokoh = tokoh
	add_child(tokoh)
	var kontrak := CampaignController.new()
	kontrak.name = "CampaignController"
	kontrak.sim = rumor.sim
	add_child(kontrak)
	var final := FinalController.new()
	final.name = "FinalController"
	final.sim = rumor.sim
	add_child(final)
	var misi := MissionController.new()
	misi.name = "MissionController"
	add_child(misi)
	var tutorial := TutorialController.new()
	tutorial.name = "TutorialController"
	add_child(tutorial)
	var petunjuk := PetunjukController.new()
	petunjuk.name = "PetunjukController"
	add_child(petunjuk)
	SaveSystem.sumber_snapshot = rumor.snapshot_untuk_save
	var tata := VBoxContainer.new()
	tata.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tata.add_theme_constant_override("separation", 14)
	add_child(tata)
	var atas := UiKit.margin(tata, TEPI, 20 + roundi(UiKit.inset_aman(self).x), TEPI, 0)
	atas.add_child(HUD.instantiate())
	var bingkai_kota := UiKit.margin(tata, TEPI, 0, TEPI, 0)
	bingkai_kota.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var kota := CITY.instantiate()
	bingkai_kota.add_child(kota)
	kota.atur_sim(rumor.sim)
	tata.add_child(DESK.instantiate())
	add_child(SALURAN.new())
	for lapisan in LAPISAN:
		add_child(lapisan.new())
	add_child(SHOP.instantiate())
	add_child(ENDING.instantiate())
	add_child(TUTORIAL.new())  # CanvasLayer: selalu di atas lembar, termasuk toko
	add_child(PETUNJUK.new())  # CanvasLayer di bawah tutorial; menunggu lembar ditutup
	_umumkan_offline.call_deferred()


## Uang yang dikumpulkan staf selama aplikasi tertutup tampil sekali di feed.
func _umumkan_offline() -> void:
	var uang := int(SaveSystem.offline.get("uang", 0))
	if uang > 0:
		Events.feed_baru.emit({"jenis": "offline", "uang": uang, "detik": float(SaveSystem.offline["detik"])})
		SaveSystem.offline = {}


## Tombol Back Android (quit_on_go_back = false): tutup lapisan teratas dulu; kalau tidak ada,
## simpan lalu kembali ke layar judul.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_tombol_back()


func _tombol_back() -> void:
	for i in range(get_child_count() - 1, -1, -1):
		var lapisan := get_child(i) as Lembar
		if lapisan and lapisan.tangani_back():
			return
	SaveSystem.simpan()
	get_tree().change_scene_to_file(JUDUL)
