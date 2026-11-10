extends Control
## Peta kota: jaringan wajah warga (PetaJaringan), lalu feed dan banner event di atasnya.
## Juga menampilkan stempel HOAKS; kertas terbang dan uang dari titik warga diurus KirimanAnimasi.

const FEED := preload("res://scenes/city/feed.tscn")
const EVENT_BANNER := preload("res://scenes/city/event_banner.tscn")
## Kertas headline menumpuk 36 px di bawah peta; feed naik supaya tetap terlihat.
const JARAK_BAWAH := 56.0

var _peta: PetaJaringan
var _feed: Control
var _banner: Control
var _memudar: KotaMemudar


func _ready() -> void:
	clip_contents = true
	resized.connect(_tata)
	Events.distrik_dipilih.connect(func(id: String) -> void:
		if _peta:
			_peta.dipilih = id)
	Events.feed_baru.connect(func(e: Dictionary) -> void:
		if e.get("jenis", "") == "hoaks":
			_stempel_hoaks())
	Events.ending_tercapai.connect(func(hasil: String) -> void:
		if _peta and _peta.siap():
			_memudar = KotaMemudar.mulai(_peta, hasil))
	Events.ending_ditutup.connect(func() -> void:
		if is_instance_valid(_memudar):
			_memudar.queue_free())


func atur_sim(sim: SpreadSim) -> void:
	_peta = PetaJaringan.new()
	_peta.name = "Peta"
	add_child(_peta)
	_peta.atur_sim(sim)
	Events.sim_diganti.connect(func(s: SpreadSim) -> void: _peta.atur_sim(s))
	_feed = FEED.instantiate()
	add_child(_feed)
	_banner = EVENT_BANNER.instantiate()
	add_child(_banner)
	var animasi := KirimanAnimasi.new()
	animasi.name = "KirimanAnimasi"
	animasi.peta = _peta
	animasi.kota = self
	add_child(animasi)
	_tata()


func _tata() -> void:
	if _peta:
		_peta.position = Vector2.ZERO
		_peta.size = size
	if _feed:
		_feed.position = Vector2(16, size.y - _feed.size.y - JARAK_BAWAH)
		_feed.size.x = size.x - 32
	if _banner:
		_banner.position = Vector2(16, 16)
		_banner.size = Vector2(size.x - 32, 0)


## Stempel HOAKS: skala 2 -> 1 sambil berputar sedikit, peta bergetar, lalu memudar.
func _stempel_hoaks() -> void:
	var stempel := PanelContainer.new()
	stempel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gaya := Palet.kotak(Color(Palet.KERTAS, 0.92), Palet.PINK, 20)
	gaya.set_border_width_all(8)
	gaya.content_margin_left = 28
	gaya.content_margin_right = 28
	stempel.add_theme_stylebox_override("panel", gaya)
	UiKit.label(stempel, 80, Color("e0245e"), Tema.font_judul(), tr("UI_HOAKS") % "")
	add_child(stempel)
	stempel.reset_size()
	stempel.position = (size - stempel.size) / 2.0
	stempel.pivot_offset = stempel.size / 2.0
	stempel.scale = Vector2(2, 2)
	stempel.rotation = -0.25
	var t := create_tween()
	t.tween_property(stempel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(stempel, "rotation", -0.2, 0.2)
	t.tween_interval(1.0)
	t.tween_property(stempel, "modulate:a", 0.0, 0.4)
	t.tween_callback(stempel.queue_free)
	var asal := position
	var g := create_tween()
	for i in 4:
		g.tween_property(self, "position", asal + Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
	g.tween_property(self, "position", asal, 0.04)
