extends Control
## Peta kota: menata node distrik, lalu feed dan banner event di atasnya.
## Juga menampilkan angka uang yang melayang dari distrik.

const DISTRICT := preload("res://scenes/city/district.tscn")
const FEED := preload("res://scenes/city/feed.tscn")
const EVENT_BANNER := preload("res://scenes/city/event_banner.tscn")

var _distrik: Array[Control] = []
var _feed: Control
var _banner: Control


func _ready() -> void:
	clip_contents = true
	resized.connect(_tata)
	Events.warga_berubah.connect(_gambar_ulang)
	Events.distrik_dipilih.connect(_on_distrik_dipilih)
	Events.uang_dari_distrik.connect(_uang_melayang)
	Events.feed_baru.connect(func(e: Dictionary) -> void:
		if e.get("jenis", "") == "hoaks":
			_stempel_hoaks())
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void:
		for d in _distrik:
			d.segarkan_nama())


func atur_sim(sim: SpreadSim) -> void:
	for i in DataDB.districts.size():
		var node := DISTRICT.instantiate()
		node.atur(DataDB.districts[i], i, sim)
		add_child(node)
		_distrik.append(node)
	_feed = FEED.instantiate()
	add_child(_feed)
	_banner = EVENT_BANNER.instantiate()
	add_child(_banner)
	_tata()


func _tata() -> void:
	for d in _distrik:
		d.position = d.area.position * size
		d.size = d.area.size * size
		d.queue_redraw()
	if _feed:
		_feed.position = Vector2(8, size.y * 0.62)
		_feed.size = Vector2(size.x - 16, size.y * 0.36)
	if _banner:
		_banner.position = Vector2(size.x * 0.08, 8)
		_banner.size = Vector2(size.x * 0.84, 0)


func _gambar_ulang() -> void:
	for d in _distrik:
		d.queue_redraw()


func _on_distrik_dipilih(distrik_id: String) -> void:
	for d in _distrik:
		d.dipilih = d.distrik_id == distrik_id
		d.queue_redraw()


## Stempel HOAKS: skala 2 -> 1 sambil berputar sedikit, peta bergetar, lalu memudar.
func _stempel_hoaks() -> void:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = tr("UI_HOAKS") % ""
	l.add_theme_font_size_override("font_size", 64)
	l.add_theme_color_override("font_color", Palet.emosi("marah"))
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	l.reset_size()
	l.position = (size - l.size) / 2.0
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(2, 2)
	l.rotation = -0.25
	var t := create_tween()
	t.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "rotation", -0.12, 0.25)
	t.tween_interval(0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.4)
	t.tween_callback(l.queue_free)
	var asal := position
	var g := create_tween()
	for i in 4:
		g.tween_property(self, "position", asal + Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
	g.tween_property(self, "position", asal, 0.04)


func _uang_melayang(distrik: int, jumlah: int) -> void:
	if distrik < 0 or distrik >= _distrik.size():
		return
	var d := _distrik[distrik]
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.text = "+" + Bahasa.angka(jumlah)
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Palet.emosi("lucu"))
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.position = d.position + Vector2(randf_range(0.3, 0.7) * d.size.x, randf_range(0.3, 0.6) * d.size.y)
	add_child(l)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y - 50.0, 0.9).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)
