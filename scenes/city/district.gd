extends Control
## Satu distrik: kotak berwarna + titik warga digambar lewat _draw() (ADR-0001).
## Tap -> Events.distrik_dipilih.

const RADIUS_WARGA := 6.0
const RADIUS_MENULAR := 9.0

var distrik_id := ""
var indeks := 0
var area := Rect2()  # koordinat kota 0..1
var dipilih := false

var _data: Dictionary = {}
var _sim: SpreadSim
var _label: Label


func atur(data: Dictionary, idx: int, sim: SpreadSim) -> void:
	_data = data
	distrik_id = str(data.get("id", ""))
	indeks = idx
	area = SpreadSim.area_distrik(data)
	_sim = sim


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label = Label.new()
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.position = Vector2(10, 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	segarkan_nama()


func segarkan_nama() -> void:
	if _label:
		_label.text = Bahasa.teks(_data.get("nama", ""))


func _draw() -> void:
	var warna := Palet.emosi(str(_data.get("emosi_favorit", "netral")))
	draw_rect(Rect2(Vector2.ZERO, size), Color(warna, 0.16))
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE if dipilih else Color(warna, 0.5), false, 4.0 if dipilih else 2.0)
	if _sim == null:
		return
	var ukuran_kota := size / area.size
	for i in _sim.warga_per_distrik[indeks]:
		var p := _sim.posisi[i] * ukuran_kota - position
		var r := RADIUS_MENULAR if _sim.sedang_menular(i) else RADIUS_WARGA
		draw_circle(p, r, Palet.STATUS[_sim.status[i]])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Events.distrik_dipilih.emit(distrik_id)
		accept_event()
