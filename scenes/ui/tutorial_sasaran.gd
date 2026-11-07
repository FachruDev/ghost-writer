class_name TutorialSasaran
extends RefCounted
## Mencari node yang ditunjuk tutorial (isi Events.tutorial_langkah) lewat grup, supaya logika dan
## lapisan tutorial tidak perlu mengenal isi meja, HUD, peta, atau toko.
## Hasil cari(): {"node": Control, "rect": Rect2 global, "radius": sudut cincin sorot,
## "zona": Rect2 global yang tidak boleh ditutupi gelembung}; {} kalau sasaran belum ada di layar.

const MEJA := &"tutorial_meja"
const HUD := &"tutorial_hud"
const KARTU := &"tutorial_kartu"
const PETA := &"tutorial_peta"
const SALURAN := &"tutorial_saluran"
const SALURAN_OPSI := &"tutorial_saluran_opsi"  # baris lembar saluran yang bisa dipakai; meta "dipilih"
const SALURAN_PAKAI := &"tutorial_saluran_pakai"
const KIRIM := &"tutorial_kirim"
const TOKO := &"tutorial_toko"
const KARTU_TOKO := &"tutorial_kartu_toko"  # kartu toko; meta "kata_id"
const BELI := &"tutorial_beli"  # tombol Beli di dalam kartu toko
const TAB_KATA := &"tutorial_tab_kata"
const FILTER_SEMUA := &"tutorial_filter_semua"


static func cari(tree: SceneTree, info: Dictionary) -> Dictionary:
	match str(info.get("sasaran", "")):
		"kartu":
			return _hasil(_kartu_terkiri(tree), _rect(_satu(tree, MEJA)), 24.0)
		"distrik":
			return _distrik(tree)
		"saluran":
			return _saluran(tree)
		"kirim":
			return _hasil(_satu(tree, KIRIM), _rect(_satu(tree, MEJA)))
		"toko":
			return _hasil(_satu(tree, TOKO), _rect(_satu(tree, HUD)))
		"beli":
			return _beli(tree, str(info.get("kata_id", "")))
	return {}


## ScrollContainer terdekat di atas node (tangan kartu, daftar toko, isi lembar).
static func gulir_induk(c: Node) -> ScrollContainer:
	var n := c.get_parent()
	while n:
		if n is ScrollContainer:
			return n
		n = n.get_parent()
	return null


## Pusat node berada di bagian ScrollContainer yang tampak (bukan tergulir keluar).
static func terlihat(c: Control) -> bool:
	var g := gulir_induk(c)
	return g == null or g.get_global_rect().has_point(c.get_global_rect().get_center())


static func _satu(tree: SceneTree, grup: StringName) -> Control:
	for n in tree.get_nodes_in_group(grup):
		var c := n as Control
		if c and c.is_visible_in_tree():
			return c
	return null


static func _rect(c: Control) -> Rect2:
	return c.get_global_rect() if c else Rect2()


static func _hasil(c: Control, zona: Rect2, radius := 28.0) -> Dictionary:
	if c == null:
		return {}
	var r := c.get_global_rect()
	return {"node": c, "rect": r, "radius": radius, "zona": r.merge(zona) if zona.has_area() else r}


## Kartu paling kiri yang tampak di tangan (tangan bisa digeser ke samping).
static func _kartu_terkiri(tree: SceneTree) -> Control:
	var terbaik: Control = null
	for n in tree.get_nodes_in_group(KARTU):
		var c := n as Control
		if c == null or not c.is_visible_in_tree() or not terlihat(c):
			continue
		if terbaik == null or c.global_position.x < terbaik.global_position.x:
			terbaik = c
	return terbaik


## Distrik pertama di peta; cincin sorotnya bulat mengikuti gugus wajah. Zona ikut mencakup meja,
## supaya gelembung naik ke atas peta dan headline tetap terbaca.
static func _distrik(tree: SceneTree) -> Dictionary:
	var peta := _satu(tree, PETA) as PetaJaringan
	if peta == null or DataDB.districts.is_empty():
		return {}
	var r := peta.get_global_transform() * peta.rect_distrik(0)
	var meja := _rect(_satu(tree, MEJA))
	return {"node": peta, "rect": r, "radius": minf(r.size.x, r.size.y) / 2.0, "zona": r.merge(meja) if meja.has_area() else r}


## Lembar saluran terbuka: tunjuk saluran yang bisa dipakai, lalu tombol Pakai. Tertutup: tombol saluran.
static func _saluran(tree: SceneTree) -> Dictionary:
	var pakai := _satu(tree, SALURAN_PAKAI)
	if pakai == null:
		return _hasil(_satu(tree, SALURAN), _rect(_satu(tree, MEJA)))
	var zona := pakai.get_global_rect()
	var pertama: Control = null
	var dipilih := false
	for n in tree.get_nodes_in_group(SALURAN_OPSI):
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		zona = zona.merge(c.get_global_rect())
		dipilih = dipilih or bool(c.get_meta("dipilih", false))
		if pertama == null:
			pertama = c
	return _hasil(pakai if dipilih or pertama == null else pertama, zona, 32.0)


## Toko: tombol Beli pada kartu kata_id. Kalau kartunya tersembunyi filter slot, tunjuk filter
## "Semua"; kalau tab lain yang terbuka, tunjuk tab Kata.
static func _beli(tree: SceneTree, kata_id: String) -> Dictionary:
	for n in tree.get_nodes_in_group(KARTU_TOKO):
		var kartu := n as Control
		if kartu == null or not kartu.is_visible_in_tree() or str(kartu.get_meta("kata_id", "")) != kata_id:
			continue
		for b in tree.get_nodes_in_group(BELI):
			if kartu.is_ancestor_of(b):
				return _hasil(b as Control, kartu.get_global_rect(), 24.0)
	var semua := _satu(tree, FILTER_SEMUA)
	if semua:
		return _hasil(semua, Rect2())
	return _hasil(_satu(tree, TAB_KATA), Rect2())
