class_name Economy
extends RefCounted
## Pendapatan dari rumor. Harga kata dan template ada di data JSON.


static func uang_dari_warga(jumlah_percaya: int) -> int:
	return jumlah_percaya * Balance.UANG_PER_WARGA
