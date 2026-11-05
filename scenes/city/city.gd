extends Control
## Peta kota: menata node distrik sesuai area di districts.json dan meneruskan pembaruan.

const DISTRICT := preload("res://scenes/city/district.tscn")

var _distrik: Array[Control] = []


func _ready() -> void:
	clip_contents = true
	resized.connect(_tata)
	Events.warga_berubah.connect(_gambar_ulang)
	Events.distrik_dipilih.connect(_on_distrik_dipilih)
	Bahasa.bahasa_berubah.connect(func(_kode: String) -> void:
		for d in _distrik:
			d.segarkan_nama())


func atur_sim(sim: SpreadSim) -> void:
	for i in DataDB.districts.size():
		var node := DISTRICT.instantiate()
		node.atur(DataDB.districts[i], i, sim)
		add_child(node)
		_distrik.append(node)
	_tata()


func _tata() -> void:
	for d in _distrik:
		d.position = d.area.position * size
		d.size = d.area.size * size
		d.queue_redraw()


func _gambar_ulang() -> void:
	for d in _distrik:
		d.queue_redraw()


func _on_distrik_dipilih(distrik_id: String) -> void:
	for d in _distrik:
		d.dipilih = d.distrik_id == distrik_id
		d.queue_redraw()
