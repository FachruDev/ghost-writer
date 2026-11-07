class_name Economy
extends RefCounted
## Pendapatan dari rumor dan penghasilan offline. Harga kata dan template ada di data JSON.


static func uang_dari_warga(jumlah_percaya: int) -> int:
	return jumlah_percaya * Balance.UANG_PER_WARGA


## Laju pasif dari staf otomatis (ADR-0003): rumus tertutup, bukan simulasi. 0 kalau belum ada staf.
## cfg_staf = data upgrade staf (jeda_detik, warga_dasar).
static func laju_pasif_per_detik(punya_staf: bool, cfg_staf: Dictionary) -> float:
	if not punya_staf or cfg_staf.is_empty():
		return 0.0
	var warga := float(cfg_staf.get("warga_dasar", 8)) * Balance.OFFLINE_DIPERCAYA_RATA
	return warga * Balance.UANG_PER_WARGA / maxf(float(cfg_staf.get("jeda_detik", 40)), 1.0)


## Detik offline yang dihitung: selisih jam dibatasi 0..OFFLINE_MAKS_DETIK (jam mundur = 0).
static func detik_offline(disimpan_unix: float, sekarang_unix: float) -> float:
	return clampf(sekarang_unix - disimpan_unix, 0.0, Balance.OFFLINE_MAKS_DETIK)


static func uang_offline(laju_per_detik: float, detik: float) -> int:
	return floori(laju_per_detik * detik * Balance.OFFLINE_PENGALI)
