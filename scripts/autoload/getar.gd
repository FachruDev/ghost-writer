extends Node
## Getar ringan (haptic) di HP: saat headline dikirim, lebih kuat saat rumor dibongkar (stempel HOAKS).
## Bisa dimatikan lewat Pengaturan ("getar"). Di desktop Input.vibrate_handheld tidak berbuat apa-apa.

const KIRIM_MS := 30
const HOAKS_MS := 120


func _ready() -> void:
	Events.rumor_published.connect(func(_info: Dictionary) -> void: getar(KIRIM_MS))
	Events.feed_baru.connect(func(e: Dictionary) -> void:
		if e.get("jenis", "") == "hoaks":
			getar(HOAKS_MS))


## Mengembalikan true kalau getar dijalankan (untuk tes).
func getar(ms: int) -> bool:
	if not Pengaturan.ambil("getar"):
		return false
	Input.vibrate_handheld(ms)
	return true
