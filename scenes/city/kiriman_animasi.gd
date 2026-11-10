class_name KirimanAnimasi
extends Node
## Animasi di atas peta saat rumor bergerak:
## - anim_send_paper: kertas terbang dari kertas headline di meja ke distrik benih rumor
## - staf: kertas hijau kecil dari cincin staf di HUD ke distrik kiriman staf
## - anim_money_float: "+N" muncul dari titik warga yang paling baru percaya di distrik itu
##   (dulu dari tengah gugus distrik); cadangan ke tengah distrik kalau belum ada yang percaya.
##   Uang dipancarkan per tick per distrik (rumor server: puluhan kali per detik), jadi jumlahnya
##   dikumpulkan per distrik dan tampil sebagai satu pil paling cepat tiap JEDA_PIL, maks MAKS_PIL.

## Koran/radio menanam benih di banyak distrik; kertas yang diterbangkan dibatasi.
const MAKS_KERTAS := 4
const NAIK := 56.0
## Detik minimal antar pil di satu distrik; uang di antaranya digabung ke pil berikutnya.
const JEDA_PIL := 0.5
## Pil yang boleh tampil bersamaan; sisanya menunggu dan ikut digabung.
const MAKS_PIL := 8

var peta: PetaJaringan
var kota: Control
var _staf_menunggu := false
var _antre: Dictionary = {}  # distrik -> uang yang belum ditampilkan
var _sejak: Dictionary = {}  # distrik -> detik sejak pil terakhir di distrik itu
var _pil_hidup := 0


func _ready() -> void:
	Events.rumor_published.connect(_on_kirim)
	Events.feed_baru.connect(func(e: Dictionary) -> void:
		if e.get("jenis", "") == "staf":
			_staf_menunggu = true)
	Events.uang_dari_distrik.connect(_on_uang)


## Kertas terbang lewat induk kota (tanpa clip_contents), top_level di atas meja.
func _induk_terbang() -> Node:
	return kota.get_parent() if kota.get_parent() else kota


func _global(lokal_peta: Vector2) -> Vector2:
	return peta.get_global_transform() * lokal_peta


func _on_kirim(info: Dictionary) -> void:
	var kertas := get_tree().get_first_node_in_group(KertasHeadline.GRUP) as Control
	if kertas == null or peta == null or not kertas.is_visible_in_tree():
		return
	var r := kertas.get_global_rect()
	var dari := Vector2(r.get_center().x, r.position.y + r.size.y * 0.3)
	var distrik: Array = info.get("distrik", [])
	for k in mini(distrik.size(), MAKS_KERTAS):
		var d := int(distrik[k])
		if d >= 0 and d < DataDB.districts.size():
			KertasTerbang.luncurkan(_induk_terbang(), dari, _global(peta.pusat_distrik(d)), Palet.PINK, 1.0, k * 0.08)


func _on_uang(distrik: int, jumlah: int) -> void:
	if peta == null or kota == null or distrik < 0 or distrik >= DataDB.districts.size():
		return
	if _staf_menunggu:
		_staf_menunggu = false
		var staf := get_tree().get_first_node_in_group(PetunjukLapisan.STAF) as Control
		if staf and staf.is_visible_in_tree():
			# Kiriman staf jarang (tiap 40 detik): kertas hijau terbang lalu pilnya langsung, tanpa antre.
			var titik := _titik_warga(distrik)
			KertasTerbang.luncurkan(_induk_terbang(), staf.get_global_rect().get_center(), titik, Palet.HIJAU, 0.6)
			_pil(titik + Vector2(randf_range(-10.0, 10.0), 0.0), jumlah, KertasTerbang.LAMA_TERBANG)
			return
	_antre[distrik] = int(_antre.get(distrik, 0)) + jumlah


func _process(delta: float) -> void:
	if peta == null or kota == null:
		return
	for d in _sejak.keys():
		_sejak[d] += delta
	for d in _antre.keys():
		if _pil_hidup >= MAKS_PIL:
			return
		if float(_sejak.get(d, JEDA_PIL)) < JEDA_PIL:
			continue
		var jumlah := int(_antre[d])
		_antre.erase(d)
		_sejak[d] = 0.0
		if d >= DataDB.districts.size():
			continue  # peta mengecil (tidak terjadi di permainan, berjaga saja)
		_pil(_titik_warga(d) + Vector2(randf_range(-10.0, 10.0), 0.0), jumlah, 0.0)


## Posisi global warga yang paling baru percaya di distrik (cadangan: tengah gugus distrik).
func _titik_warga(distrik: int) -> Vector2:
	var sim := peta.sim()
	var pos := peta.posisi()
	var pilih := -1
	var terbaru := -INF
	if sim and pos.size() == sim.status.size() and sim.terakhir_berubah.size() == sim.status.size():
		for i in sim.status.size():
			if sim.distrik_warga[i] == distrik and sim.status[i] == SpreadSim.Status.PERCAYA \
					and sim.terakhir_berubah[i] > terbaru:
				terbaru = sim.terakhir_berubah[i]
				pilih = i
	return _global(pos[pilih] if pilih >= 0 else peta.pusat_distrik(distrik))


## Pil kuning "+N": muncul memantul di atas titik, naik, lalu memudar.
func _pil(titik_global: Vector2, jumlah: int, tunda: float) -> void:
	var pil := UiKit.pil(kota, "+" + Bahasa.angka(jumlah), Palet.KUNING, Palet.TINTA, 20)
	_pil_hidup += 1
	pil.tree_exiting.connect(func() -> void: _pil_hidup -= 1)
	pil.reset_size()
	var lokal: Vector2 = kota.get_global_transform().affine_inverse() * titik_global
	pil.position = lokal - Vector2(pil.size.x / 2.0, pil.size.y + 8.0)
	pil.pivot_offset = Vector2(pil.size.x / 2.0, pil.size.y)
	pil.scale = Vector2(0.5, 0.5)
	pil.modulate.a = 0.0
	var t := pil.create_tween()
	if tunda > 0.0:
		t.tween_interval(tunda)
	t.tween_property(pil, "modulate:a", 1.0, 0.06)
	t.parallel().tween_property(pil, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(pil, "position:y", pil.position.y - NAIK, 0.8).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(pil, "modulate:a", 0.0, 0.4).set_delay(0.4)
	t.tween_callback(pil.queue_free)
