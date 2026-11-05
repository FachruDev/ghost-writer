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

var _tetangga: Array[PackedInt32Array] = []
var _kerentanan := PackedFloat32Array()
var _rng: RandomNumberGenerator

# Keadaan rumor yang sedang menjalar
var _aktif := false
var _dengar := PackedByteArray()
var _sisa_menular := PackedFloat32Array()
var _viral := PackedFloat32Array()
var _peluang_percaya := 0.0
var _waktu := 0.0
var _waktu_diam := 0.0


func _init(distrik_list: Array, rng: RandomNumberGenerator) -> void:
	_rng = rng
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
	_sisa_menular.resize(posisi.size())
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


## Memulai rumor di distrik target. Mengembalikan jumlah warga awal yang percaya.
func mulai(target: int, viral_per_distrik: PackedFloat32Array, peluang_percaya: float) -> int:
	_aktif = true
	_dengar.fill(0)
	_sisa_menular.fill(0.0)
	_viral = viral_per_distrik
	_peluang_percaya = peluang_percaya
	_waktu = 0.0
	_waktu_diam = 0.0
	var kandidat: Array[int] = []
	for i in warga_per_distrik[target]:
		if status[i] != Status.KEBAL:
			kandidat.append(i)
	var jumlah := mini(_rng.randi_range(Balance.WARGA_AWAL_MIN, Balance.WARGA_AWAL_MAKS), kandidat.size())
	for n in jumlah:
		var i: int = kandidat.pop_at(_rng.randi_range(0, kandidat.size() - 1))
		_percaya(i)
	if jumlah == 0:
		_aktif = false
	return jumlah


## Satu tick simulasi. Mengembalikan {"baru_dengar", "baru_percaya", "selesai"}.
func langkah(dt: float) -> Dictionary:
	_pulihkan_ragu(dt)
	if not _aktif:
		return {"baru_dengar": 0, "baru_percaya": 0, "selesai": false}
	_waktu += dt
	var baru_dengar := 0
	var baru_percaya := 0
	var penular := PackedInt32Array()
	for i in posisi.size():
		if _sisa_menular[i] > 0.0:
			penular.append(i)
	for i in penular:
		_sisa_menular[i] = maxf(0.0, _sisa_menular[i] - dt)
		for j in _tetangga[i]:
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
			else:
				_dengar[j] = 1
				status[j] = Status.RAGU
				_sisa_menular[j] = Balance.DURASI_MENULAR_RAGU_DETIK
	_waktu_diam = 0.0 if baru_dengar > 0 else _waktu_diam + dt
	var selesai := _waktu >= Balance.RUMOR_MAKS_DETIK \
		or _waktu_diam >= Balance.RUMOR_DIAM_DETIK \
		or not _masih_ada_penular()
	if selesai:
		_aktif = false
		_sisa_menular.fill(0.0)
	return {"baru_dengar": baru_dengar, "baru_percaya": baru_percaya, "selesai": selesai}


func _percaya(i: int) -> void:
	_dengar[i] = 1
	status[i] = Status.PERCAYA
	_sisa_menular[i] = Balance.DURASI_MENULAR_DETIK


func _masih_ada_penular() -> bool:
	for v in _sisa_menular:
		if v > 0.0:
			return true
	return false


func _pulihkan_ragu(dt: float) -> void:
	var p := Balance.RAGU_PULIH_PER_DETIK * dt
	for i in status.size():
		if status[i] == Status.RAGU and _rng.randf() < p:
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
