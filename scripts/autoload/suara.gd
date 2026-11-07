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
	"carriage": [preload("res://assets/sfx/sfx_carriage_return.ogg")],
	"follower_up": [preload("res://assets/sfx/sfx_follower_up.wav")],
	"buy": [preload("res://assets/sfx/sfx_buy.ogg")],
	"error": [preload("res://assets/sfx/sfx_error.ogg")],
	"dilemma": [preload("res://assets/sfx/sfx_dilemma_choice.wav")],
	"notif": [preload("res://assets/sfx/sfx_notif.wav")],
	"era_up": [preload("res://assets/sfx/sfx_era_up.ogg")],
	"phone": [preload("res://assets/sfx/sfx_phone_ring.wav")],
}
## Musik per era; loop diatur di file .import masing-masing.
const MUSIK_ERA := {
	1: preload("res://assets/music/mus_era1_kamar.ogg"),
	2: preload("res://assets/music/mus_era2_kantor.mp3"),
	3: preload("res://assets/music/mus_era3_gedung.mp3"),
	4: preload("res://assets/music/mus_era4_server.mp3"),
}
## Layar ending: diputar sekali (tidak loop), lalu kembali ke musik era saat lanjut bermain.
const MUSIK_ENDING := preload("res://assets/music/mus_ending.ogg")
## Lapisan tegang di atas musik era selama ancaman (termasuk E12); loop diatur di .import.
const MUSIK_ANCAMAN := preload("res://assets/music/mus_threat.ogg")
const VOLUME_ANCAMAN_DB := -4.0
const SENYAP_DB := -40.0
const FADE_ANCAMAN := 1.5
## Event yang berbunyi telepon, bukan alarm.
const EVENT_TELEPON := ["e_wartawan"]
const KELIPATAN_PENGIKUT := 50
const DENGUNG_SERVER := preload("res://assets/sfx/sfx_server_hum.wav")
const VOLUME_DENGUNG_DB := -18.0

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
var _ambang_pengikut := 0
var _era_musik := 0
var _dengung: AudioStreamPlayer
var _ancaman: AudioStreamPlayer
var _ancaman_aktif := false
var _tween_ancaman: Tween


func _ready() -> void:
	_siapkan_bus("Music")
	_siapkan_bus("SFX")
	_terapkan_volume()
	Pengaturan.berubah.connect(func(_k: String) -> void: _terapkan_volume())
	for i in JUMLAH_PEMUTAR:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pemutar.append(p)
	_musik = AudioStreamPlayer.new()
	_musik.bus = "Music"
	add_child(_musik)
	_dengung = AudioStreamPlayer.new()
	_dengung.bus = "SFX"
	_dengung.stream = DENGUNG_SERVER
	_dengung.volume_db = VOLUME_DENGUNG_DB
	_dengung.finished.connect(_dengung.play)  # ambience berulang
	add_child(_dengung)
	_ancaman = AudioStreamPlayer.new()
	_ancaman.bus = "Music"
	_ancaman.stream = MUSIK_ANCAMAN
	_ancaman.volume_db = SENYAP_DB
	add_child(_ancaman)
	putar_musik_era(GameState.era)
	_ambang_pengikut = floori(float(GameState.pengikut) / KELIPATAN_PENGIKUT)
	_hubungkan()
	get_tree().node_added.connect(_on_node_added)


func _exit_tree() -> void:
	_musik.stop()
	_dengung.stop()
	_ancaman.stop()
	for p in _pemutar:
		p.stop()


func putar_musik_era(era: int) -> void:
	var lagu: AudioStream = MUSIK_ERA.get(era, MUSIK_ERA[1])
	if era == _era_musik and _musik.playing:
		return
	if _era_musik > 0 and era > _era_musik:
		putar("era_up")  # naik era saat bermain, bukan saat memuat save
	_era_musik = era
	_musik.stream = lagu
	_musik.play()
	if era >= 4 and not _dengung.playing:
		_dengung.play()
	elif era < 4:
		_dengung.stop()


func putar(nama: String, variasi_pitch: float = 0.0) -> void:
	var daftar: Array = SFX.get(nama, [])
	if daftar.is_empty():
		return
	var p := _pemutar[_berikut]
	_berikut = (_berikut + 1) % _pemutar.size()
	p.stream = daftar[randi_range(0, daftar.size() - 1)]
	p.pitch_scale = 1.0 + randf_range(-variasi_pitch, variasi_pitch)
	p.play()


## Lapisan musik ancaman masuk/keluar pelan di atas musik era.
func atur_lapisan_ancaman(aktif: bool) -> void:
	if aktif == _ancaman_aktif:
		return
	_ancaman_aktif = aktif
	if _tween_ancaman:
		_tween_ancaman.kill()
	if aktif and not _ancaman.playing:
		_ancaman.volume_db = SENYAP_DB
		_ancaman.play()
	_tween_ancaman = create_tween()
	_tween_ancaman.tween_property(_ancaman, "volume_db", VOLUME_ANCAMAN_DB if aktif else SENYAP_DB, FADE_ANCAMAN)
	if not aktif:
		_tween_ancaman.tween_callback(_ancaman.stop)


func lapisan_ancaman_aktif() -> bool:
	return _ancaman_aktif


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
	Events.template_diganti.connect(putar.bind("carriage"))
	Events.dibeli.connect(putar.bind("buy"))
	Events.aksi_gagal.connect(putar.bind("error"))
	Events.dilema_dipilih.connect(func(_i: int) -> void: putar("dilemma"))
	Events.era_berubah.connect(putar_musik_era)
	Events.ending_tercapai.connect(func(_h: String) -> void:
		atur_lapisan_ancaman(false)
		_dengung.stop()
		_musik.stream = MUSIK_ENDING
		_musik.play())
	Events.ending_ditutup.connect(func() -> void:
		_era_musik = 0  # paksa ganti lagu tanpa stinger naik era
		putar_musik_era(GameState.era))
	Events.pengikut_berubah.connect(func(p: int) -> void:
		var ambang := floori(float(p) / KELIPATAN_PENGIKUT)
		if ambang > _ambang_pengikut:
			putar("follower_up")
		_ambang_pengikut = ambang)
	Events.kartu_terbang.connect(func(_id: String, _dari: Vector2) -> void:
		putar("card_pick", 0.05)
		get_tree().create_timer(0.25).timeout.connect(putar.bind("card_place", 0.05)))
	Events.headline_diketik.connect(ketik)
	Events.rumor_published.connect(func(info: Dictionary) -> void:
		putar("notif" if info.get("saluran_id", "") == "medsos" else "send"))
	Events.uang_dari_distrik.connect(func(_d: int, _j: int) -> void:
		if _koin_detik_ini < KOIN_MAKS_PER_DETIK:
			_koin_detik_ini += 1
			putar("coin", 0.08))
	Events.feed_baru.connect(func(e: Dictionary) -> void:
		if e.get("jenis", "") == "hoaks":
			putar("stamp"))
	Events.event_mulai.connect(func(info: Dictionary) -> void:
		if str(info.get("id", "")) in EVENT_TELEPON:
			putar("phone")
		else:
			putar("alert_threat" if info.get("jenis", "") == "ancaman" else "alert")
		atur_lapisan_ancaman(info.get("jenis", "") == "ancaman"))
	Events.event_tampil.connect(func(info: Dictionary) -> void:
		atur_lapisan_ancaman(info.get("jenis", "") == "ancaman"))
	Events.event_selesai.connect(func(_id: String) -> void: atur_lapisan_ancaman(false))


## Bunyi klik untuk semua tombol UI, kecuali kartu kata yang punya bunyinya sendiri.
func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.is_in_group(&"tanpa_klik"):
		(node as BaseButton).pressed.connect(putar.bind("click"))


## Volume bus = dasar (VOLUME_*_DB) + slider pengaturan (0..1, linear). 0 = bisu.
func _terapkan_volume() -> void:
	for pasangan in [["Music", VOLUME_MUSIK_DB, "musik"], ["SFX", VOLUME_SFX_DB, "sfx"]]:
		var idx := AudioServer.get_bus_index(pasangan[0])
		var v := float(Pengaturan.ambil(pasangan[2]))
		AudioServer.set_bus_mute(idx, v <= 0.001)
		AudioServer.set_bus_volume_db(idx, float(pasangan[1]) + linear_to_db(maxf(v, 0.001)))


func _siapkan_bus(nama: String) -> void:
	var idx := AudioServer.get_bus_index(nama)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, nama)
		AudioServer.set_bus_send(idx, "Master")
