extends PanelContainer
## Banner event di atas peta (papan 06/09): modifier kuning, peluang cyan, ancaman pink, dengan ikon,
## nama, sisa detik, dan teks. Event dengan pilihan (dilema, kontrak) ditangani DilemaSheet.

const IKON := {
	"e_hari_pasar": "toko", "e_ronda_malam": "takut", "e_pembongkar_fakta": "kaca_pembesar",
	"e_pemilihan_rt": "orang", "e_festival": "lucu", "e_dokumen_bocor": "koran", "e_viral_challenge": "medsos",
	"e_razia_hoaks": "gembok", "e_rumor_tandingan": "medsos", "e_kota_tak_percaya": "perisai",
}
const IKON_JENIS := {"modifier": "api", "peluang": "mahkota", "ancaman": "kaca_pembesar"}

## Deskripsi event dilipat setelah beberapa detik supaya peta tidak tertutup lama.
const DETIK_LIPAT := 4.0

var _info: Dictionary = {}
var _lipat: Tween
var _tile: PanelContainer
var _ikon: TextureRect
var _judul: Label
var _teks: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UiKit.baris(self, 16)
	_tile = PanelContainer.new()
	_tile.custom_minimum_size = Vector2(64, 64)
	_tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tile.add_theme_stylebox_override("panel", Palet.kotak(Palet.MALAM, Color.TRANSPARENT, 24))
	h.add_child(_tile)
	_ikon = UiKit.ikon(_tile, "api", 36, Palet.KUNING)
	var k := UiKit.kolom(h, 2)
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_judul = UiKit.label(k, 24, Palet.TINTA, Tema.font_ui(700))
	_judul.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_teks = UiKit.label(k, 20, Palet.TINTA, Tema.font_ui(500))
	_teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	visible = false
	Events.event_mulai.connect(_on_mulai)
	Events.event_tampil.connect(_on_mulai)
	Events.event_sisa.connect(_on_sisa)
	Events.event_selesai.connect(func(_id: String) -> void: _tutup())
	Bahasa.bahasa_berubah.connect(func(_k: String) -> void: _on_sisa(float(_info.get("sisa", 0.0))))


func _on_mulai(info: Dictionary) -> void:
	if not info.get("pilihan", []).is_empty():
		_tutup()
		return
	_info = info.duplicate()
	_info["sisa"] = float(info.get("durasi", 0.0))
	var jenis := str(info.get("jenis", "modifier"))
	var warna: Color = {"modifier": Palet.KUNING, "peluang": Palet.CYAN, "ancaman": Palet.PINK}.get(jenis, Palet.KUNING)
	var bayang: Color = {"modifier": Palet.KUNING_GELAP, "peluang": Palet.CYAN_GELAP, "ancaman": Palet.PINK_GELAP}.get(jenis, Palet.KUNING_GELAP)
	var gaya := Palet.tebal(warna, bayang, 32, 10)
	gaya.content_margin_left = 12
	gaya.content_margin_right = 18
	gaya.content_margin_top = 10
	gaya.content_margin_bottom = 14
	add_theme_stylebox_override("panel", gaya)
	_ikon.texture = UiKit.muat_ikon(IKON.get(str(info.get("id", "")), IKON_JENIS.get(jenis, "api")))
	_ikon.modulate = warna
	_on_sisa(_info["sisa"])
	_teks.visible = true
	if _lipat:
		_lipat.kill()
	_lipat = create_tween()
	_lipat.tween_interval(DETIK_LIPAT)
	_lipat.tween_callback(func() -> void:
		_teks.visible = false
		reset_size())
	visible = true
	modulate.a = 0.0
	scale = Vector2(1.0, 0.6)
	pivot_offset = Vector2(size.x / 2.0, 0.0)
	var t := create_tween().set_parallel()
	t.tween_property(self, "modulate:a", 1.0, 0.25)
	t.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_sisa(sisa: float) -> void:
	if _info.is_empty():
		return
	_info["sisa"] = sisa
	var nama := Bahasa.teks(_info.get("nama", ""))
	_judul.text = "%s · %s" % [nama, tr("UI_SISA_DETIK") % ceili(sisa)] if sisa > 0.0 else nama
	_teks.text = Bahasa.teks(_info.get("teks", ""))


func _tutup() -> void:
	if not visible:
		_info = {}
		return
	_info = {}
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: visible = false)
