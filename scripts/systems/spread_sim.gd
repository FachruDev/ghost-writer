class_name SpreadSim
extends RefCounted
## Simulasi penyebaran rumor tanpa node (ADR-0003). Posisi warga dalam koordinat kota 0..1.
## Tidak memancarkan sinyal; langkah() mengembalikan ringkasan untuk pemanggil.

enum Status { BELUM, PERCAYA, RAGU, KEBAL }

const MARGIN_AREA := 0.03

var posisi := PackedVector2Array()
var distrik_warga := PackedInt32Array()
var status := PackedInt32Array()
var warga_per_distrik: Array[PackedInt32Array] = []
## Waktu simulasi (detik) saat status tiap warga terakhir berubah; untuk animasi denyut.
var terakhir_berubah := PackedFloat32Array()
var jam := 0.0
## E12 mematikan pemulihan kebal.
var kebal_bisa_pulih := true

var _tetangga: Array[PackedInt32Array] = []
var _kerentanan := PackedFloat32Array()
var _rng: RandomNumberGenerator

# Keadaan rumor yang sedang menjalar
var _aktif := false
var _dengar := PackedByteArray()
var _percaya_rumor := PackedByteArray()
var _sisa_menular := PackedFloat32Array()
var _viral := PackedFloat32Array()
var _peluang_percaya := 0.0
var _waktu := 0.0
var _waktu_diam := 0.0
var _min_waktu := 0.0
var _lompatan := 0


func _init(distrik_list: Array = [], rng: RandomNumberGenerator = null) -> void:
	_rng = rng
	if distrik_list.is_empty():
		return
	for i in distrik_list.size():
		var d: Dictionary = distrik_list[i]
		_kerentanan.append(float(d.get("kerentanan", 1.0)))
		var area := area_distrik(d).grow(-MARGIN_AREA)
		var daftar := PackedInt32Array()
		for j in int(d.get("warga", 0)):
			daftar.append(posisi.size())
			posisi.append(Vector2(
				_rng.randf_range(area.position.x, area.end.x),
				_rng.randf_range(area.position.y, area.end.y)))
			distrik_warga.append(i)
			status.append(Status.BELUM)
		warga_per_distrik.append(daftar)
	_dengar.resize(posisi.size())
	_percaya_rumor.resize(posisi.size())
	_sisa_menular.resize(posisi.size())
	terakhir_berubah.resize(posisi.size())
	terakhir_berubah.fill(-100.0)
	_bangun_tetangga()


static func area_distrik(d: Dictionary) -> Rect2:
	var a: Array = d.get("area", [0.0, 0.0, 1.0, 1.0])
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


func ada_rumor_aktif() -> bool:
	return _aktif


func sedang_menular(i: int) -> bool:
	return _sisa_menular[i] > 0.0


func jumlah_status(distrik: int, s: Status) -> int:
	var n := 0
	for i in warga_per_distrik[distrik]:
		if status[i] == s:
			n += 1
	return n


## benih: {indeks_distrik: jumlah warga awal}. Mengembalikan jumlah warga awal yang percaya.
## lompatan: jumlah "teman online" acak se-kota yang dicoba tiap penular per tick (Medsos).
func mulai(benih: Dictionary, viral_per_distrik: PackedFloat32Array, peluang_percaya: float, lompatan: int = 0) -> int:
	_aktif = true
	_lompatan = lompatan
	_dengar.fill(0)
	_percaya_rumor.fill(0)
	_sisa_menular.fill(0.0)
	_viral = viral_per_distrik
	_peluang_percaya = peluang_percaya
	_waktu = 0.0
	_waktu_diam = 0.0
	_min_waktu = 0.0
	var total := _tanam(benih)
	if total == 0:
		_aktif = false
	return total


## Radio: tambah warga yang langsung percaya ke rumor yang sedang berjalan. Mengembalikan jumlahnya.
func suntik(benih: Dictionary) -> int:
	if not _aktif:
		return 0
	_waktu_diam = 0.0
	return _tanam(benih)


## Hentikan rumor yang sedang berjalan sekarang (mis. sebelum peta ditata ulang).
func paksa_selesai() -> void:
	_aktif = false
	_sisa_menular.fill(0.0)


## Rumor tidak boleh selesai sebelum `detik` lagi (selama siaran radio).
func tahan(detik: float) -> void:
	_min_waktu = maxf(_min_waktu, _waktu + detik)


func _tanam(benih: Dictionary) -> int:
	var total := 0
	for d in benih:
		var kandidat: Array[int] = []
		for i in warga_per_distrik[d]:
			if status[i] != Status.KEBAL and _dengar[i] == 0:
				kandidat.append(i)
		for n in mini(int(benih[d]), kandidat.size()):
			_percaya(kandidat.pop_at(_rng.randi_range(0, kandidat.size() - 1)))
			total += 1
	return total


## Satu tick simulasi. Mengembalikan {"baru_dengar", "baru_percaya", "percaya_per_distrik", "selesai"}.
func langkah(dt: float) -> Dictionary:
	jam += dt
	_pulihkan(dt)
	var per_distrik := PackedInt32Array()
	per_distrik.resize(warga_per_distrik.size())
	if not _aktif:
		return {"baru_dengar": 0, "baru_percaya": 0, "percaya_per_distrik": per_distrik, "selesai": false}
	_waktu += dt
	var baru_dengar := 0
	var baru_percaya := 0
	var penular := PackedInt32Array()
	for i in posisi.size():
		if _sisa_menular[i] > 0.0:
			penular.append(i)
	for i in penular:
		_sisa_menular[i] = maxf(0.0, _sisa_menular[i] - dt)
		var sasaran := _tetangga[i]
		if _lompatan > 0:
			sasaran = sasaran.duplicate()
			for k in _lompatan:
				sasaran.append(_rng.randi_range(0, posisi.size() - 1))
		for j in sasaran:
			if _dengar[j] == 1 or status[j] == Status.KEBAL:
				continue
			var d := distrik_warga[j]
			if _rng.randf() >= _viral[d] * _kerentanan[d] * Balance.PELUANG_TULAR_DASAR:
				continue
			baru_dengar += 1
			var p := _peluang_percaya
			if status[j] == Status.RAGU:
				p *= Balance.PENGALI_PERCAYA_RAGU
			if _rng.randf() < p:
				_percaya(j)
				baru_percaya += 1
				per_distrik[d] += 1
			else:
				_dengar[j] = 1
				_ubah(j, Status.RAGU)
				_sisa_menular[j] = Balance.DURASI_MENULAR_RAGU_DETIK
	_waktu_diam = 0.0 if baru_dengar > 0 else _waktu_diam + dt
	var selesai := _waktu >= Balance.RUMOR_MAKS_DETIK \
		or (_waktu >= _min_waktu and (_waktu_diam >= Balance.RUMOR_DIAM_DETIK or not _masih_ada_penular()))
	if selesai:
		_aktif = false
		_sisa_menular.fill(0.0)
	return {"baru_dengar": baru_dengar, "baru_percaya": baru_percaya, "percaya_per_distrik": per_distrik, "selesai": selesai}


## Rumor dibongkar: sebagian warga yang percaya rumor terakhir jadi kebal. Mengembalikan jumlahnya.
func kebalkan_rumor(persen: float) -> int:
	var n := 0
	for i in posisi.size():
		if _percaya_rumor[i] == 1 and status[i] == Status.PERCAYA and _rng.randf() < persen:
			_ubah(i, Status.KEBAL)
			n += 1
	return n


## Pembongkar fakta: semua warga dalam radius (koordinat kota) jadi kebal.
func kebalkan_sekitar(pusat: Vector2, radius: float) -> int:
	var n := 0
	for i in posisi.size():
		if status[i] != Status.KEBAL and posisi[i].distance_to(pusat) <= radius:
			_ubah(i, Status.KEBAL)
			n += 1
	return n


## Membangkitkan status warga dari jumlah tersimpan (ADR-0002: posisi tidak disimpan).
func terapkan_jumlah(distrik: int, percaya: int, ragu: int, kebal: int) -> void:
	var urut: Array = Array(warga_per_distrik[distrik])
	urut.shuffle()
	for k in urut.size():
		var s := Status.BELUM
		if k < percaya:
			s = Status.PERCAYA
		elif k < percaya + ragu:
			s = Status.RAGU
		elif k < percaya + ragu + kebal:
			s = Status.KEBAL
		status[urut[k]] = s


## Salinan lengkap termasuk state RNG, untuk proyeksi saat menyimpan (ADR-0003).
func duplikat() -> SpreadSim:
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng.seed
	rng.state = _rng.state
	var s := SpreadSim.new([], rng)
	for nama in ["posisi", "distrik_warga", "status", "terakhir_berubah", "jam", "kebal_bisa_pulih",
			"_tetangga", "_kerentanan", "_aktif", "_dengar", "_percaya_rumor", "_sisa_menular",
			"_viral", "_peluang_percaya", "_waktu", "_waktu_diam", "_min_waktu", "_lompatan"]:
		var v: Variant = get(nama)
		s.set(nama, v.duplicate() if v is Array or v is PackedByteArray or v is PackedInt32Array \
			or v is PackedFloat32Array or v is PackedVector2Array else v)
	s.warga_per_distrik = warga_per_distrik
	return s


## Jalankan sampai rumor selesai. Mengembalikan total warga baru yang percaya.
func jalankan_sampai_selesai(batas_tick: int) -> int:
	var total := 0
	var n := 0
	while _aktif and n < batas_tick:
		total += int(langkah(Balance.SIM_TICK)["baru_percaya"])
		n += 1
	return total


func rng() -> RandomNumberGenerator:
	return _rng


func _percaya(i: int) -> void:
	_dengar[i] = 1
	_percaya_rumor[i] = 1
	_ubah(i, Status.PERCAYA)
	_sisa_menular[i] = Balance.DURASI_MENULAR_DETIK


## Ubah status satu warga dari luar (event), termasuk penanda untuk animasi denyut.
func ubah_status(i: int, s: Status) -> void:
	_ubah(i, s)


func _ubah(i: int, s: Status) -> void:
	status[i] = s
	terakhir_berubah[i] = jam


func _masih_ada_penular() -> bool:
	for v in _sisa_menular:
		if v > 0.0:
			return true
	return false


func _pulihkan(dt: float) -> void:
	var p_ragu := Balance.RAGU_PULIH_PER_DETIK * dt
	var p_kebal := Balance.KEBAL_PULIH_PER_DETIK * dt if kebal_bisa_pulih else 0.0
	for i in status.size():
		if status[i] == Status.RAGU and _sisa_menular[i] <= 0.0 and _rng.randf() < p_ragu:
			status[i] = Status.BELUM
		elif status[i] == Status.KEBAL and _rng.randf() < p_kebal:
			status[i] = Status.BELUM


func _bangun_tetangga() -> void:
	for i in posisi.size():
		var jarak: Array = []
		for j in posisi.size():
			if j != i:
				jarak.append([posisi[i].distance_squared_to(posisi[j]), j])
		jarak.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var t := PackedInt32Array()
		for k in mini(Balance.TETANGGA_PER_WARGA, jarak.size()):
			t.append(jarak[k][1])
		_tetangga.append(t)
