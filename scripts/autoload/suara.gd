extends Node
## Bus audio (Master, Music, SFX), musik latar, dan efek suara yang mendengarkan sinyal Events.
## Nama file mengikuti docs/versi/1.0.0/aset/suara.md dan musik.md.

const SFX := {
	"key": [preload("res://assets/sfx/sfx_type_key_1.wav"), preload("res://assets/sfx/sfx_type_key_2.wav"),
		preload("res://assets/sfx/sfx_type_key_3.wav")],
	"bell": [preload("res://assets/sfx/sfx_type_bell.wav")],
	"card_pick": [preload("res://assets/sfx/sfx_card_pick.ogg")],
	"card_place": [preload("res://assets/sfx/sfx_card_place.ogg")],
	"send": [preload("res://assets/sfx/sfx_send.ogg")],
	"coin": [preload("res://assets/sfx/sfx_coin.ogg")],
	"stamp": [preload("res://assets/sfx/sfx_debunk_stamp.ogg")],
	"alert": [preload("res://assets/sfx/sfx_event_alert.wav")],
	"alert_threat": [preload("res://assets/sfx/sfx_event_alert_threat.wav")],
	"click": [preload("res://assets/sfx/sfx_ui_click.wav")],
}
const MUSIK_ERA1 := preload("res://assets/music/mus_era1_kamar.ogg")

const JUMLAH_PEMUTAR := 8
const KOIN_MAKS_PER_DETIK := 4
const JEDA_KETUK := 0.09
const VOLUME_MUSIK_DB := -10.0
const VOLUME_SFX_DB := -4.0

var _pemutar: Array[AudioStreamPlayer] = []
var _berikut := 0
var _musik: AudioStreamPlayer
var _koin_detik_ini := 0
var _waktu_koin := 0.0


func _ready() -> void:
	_siapkan_bus("Music", VOLUME_MUSIK_DB)
	_siapkan_bus("SFX", VOLUME_SFX_DB)
	for i in JUMLAH_PEMUTAR:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pemutar.append(p)
	_musik = AudioStreamPlayer.new()
	_musik.bus = "Music"
	_musik.stream = MUSIK_ERA1  # loop diatur di mus_era1_kamar.ogg.import
	add_child(_musik)
	_musik.play()
	_hubungkan()
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	_musik.stop()
	for p in _pemutar:
		p.stop()


func putar(nama: String, variasi_pitch: float = 0.0) -> void:
	var daftar: Array = SFX.get(nama, [])
	if daftar.is_empty():
		return
	var p := _pemutar[_berikut]
	_berikut = (_berikut + 1) % _pemutar.size()
	p.stream = daftar[randi_range(0, daftar.size() - 1)]
	p.pitch_scale = 1.0 + randf_range(-variasi_pitch, variasi_pitch)
	p.play()


## Ketukan mesin tik selama headline diketik, lalu bel di akhir.
func ketik(durasi: float) -> void:
	var t := create_tween()
	for i in maxi(1, floori(durasi / JEDA_KETUK)):
		t.tween_callback(putar.bind("key", 0.05))
		t.tween_interval(JEDA_KETUK)
	t.tween_callback(putar.bind("bell"))


func _process(delta: float) -> void:
	_waktu_koin += delta
	if _waktu_koin >= 1.0:
		_waktu_koin = 0.0
		_koin_detik_ini = 0


func _hubungkan() -> void:
	Events.kartu_terbang.connect(func(_id: String, _dari: Vector2) -> void:
		putar("card_pick", 0.05)
		get_tree().create_timer(0.25).timeout.connect(putar.bind("card_place", 0.05)))
	Events.headline_diketik.connect(ketik)
	Events.rumor_published.connect(func(_i: Dictionary) -> void: putar("send"))
	Events.uang_dari_distrik.connect(func(_d: int, _j: int) -> void:
		if _koin_detik_ini < KOIN_MAKS_PER_DETIK:
			_koin_detik_ini += 1
			putar("coin", 0.08))
	Events.feed_baru.connect(func(e: Dictionary) -> void:
		if e.get("jenis", "") == "hoaks":
			putar("stamp"))
	Events.event_mulai.connect(func(info: Dictionary) -> void:
		putar("alert_threat" if info.get("jenis", "") == "ancaman" else "alert"))


## Bunyi klik untuk semua tombol UI, kecuali kartu kata yang punya bunyinya sendiri.
func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.is_in_group(&"tanpa_klik"):
		(node as BaseButton).pressed.connect(putar.bind("click"))


func _siapkan_bus(nama: String, volume_db: float) -> void:
	var idx := AudioServer.get_bus_index(nama)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, nama)
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, volume_db)
