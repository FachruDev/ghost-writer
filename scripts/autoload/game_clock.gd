extends Node
## Satu-satunya sumber waktu simulasi (ADR-0003). Logika permainan maju hanya lewat sinyal tick.

signal tick(dt: float)

## Pengali kecepatan; hanya untuk debug dan tes.
var kecepatan: float = 1.0
## Satu sumber acak untuk simulasi.
var rng := RandomNumberGenerator.new()

var _akumulator := 0.0
var _alasan_jeda: Dictionary = {}


func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	if sedang_jeda():
		return
	_akumulator += delta * kecepatan
	var n := 0
	while _akumulator >= Balance.SIM_TICK and n < Balance.MAKS_TICK_PER_FRAME:
		tick.emit(Balance.SIM_TICK)
		_akumulator -= Balance.SIM_TICK
		n += 1
	if _akumulator >= Balance.SIM_TICK:
		_akumulator = 0.0


func jeda(alasan: StringName) -> void:
	_alasan_jeda[alasan] = true


func lanjut(alasan: StringName) -> void:
	_alasan_jeda.erase(alasan)


func sedang_jeda() -> bool:
	return not _alasan_jeda.is_empty() or kecepatan <= 0.0


## Untuk tes headless: jalankan n tick tanpa _process.
func jalankan_tick(n: int) -> void:
	for i in n:
		tick.emit(Balance.SIM_TICK)


func atur_seed(nilai: int) -> void:
	rng.seed = nilai
