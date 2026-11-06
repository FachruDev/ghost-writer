class_name RumorScorer
extends RefCounted
## Menghitung skor rumor dari template, kata, dan distrik. Rumus: docs/panduan/konsep-game.md.

const URUTAN_SLOT := ["subjek", "aksi", "tempat", "sumber"]


## kata_by_slot: {"subjek": <data kata>, ...}. distrik_list: urutan sama dengan DataDB.districts.
## kred_tambah: penyesuaian kredibilitas tiap kartu dari event (E08: -1), dibatasi minimal 0.
static func nilai(template: Dictionary, kata_by_slot: Dictionary, distrik_list: Array, kredibilitas: float,
		kred_tambah: int = 0) -> Dictionary:
	var jumlah_heboh := 0
	var jumlah_kred := 0
	for slot in kata_by_slot:
		var kata: Dictionary = kata_by_slot[slot]
		jumlah_heboh += int(kata.get("heboh", 0))
		jumlah_kred += maxi(0, int(kata.get("kred", 0)) + kred_tambah)
	var n := maxi(kata_by_slot.size(), 1)
	var heboh_total := jumlah_heboh * float(template.get("pengali_heboh", 1.0))
	var kred_rata := float(jumlah_kred) / n
	var emosi := emosi_dominan(kata_by_slot)
	var penalti := maxf(0.0, heboh_total - Balance.BATAS_HEBOH_AMAN) * Balance.PENALTI_PER_HEBOH
	var dipercaya := clampf(kred_rata / 3.0 - penalti, Balance.DIPERCAYA_MIN, Balance.DIPERCAYA_MAKS)
	var dipercaya_akhir := clampf(dipercaya * (0.5 + kredibilitas / 100.0), Balance.DIPERCAYA_MIN, Balance.DIPERCAYA_MAKS)
	var viral_per_distrik := PackedFloat32Array()
	for d in distrik_list:
		viral_per_distrik.append(heboh_total * cocok_emosi(emosi, str(d.get("emosi_favorit", "netral"))))
	return {
		"heboh_total": heboh_total,
		"kred_rata": kred_rata,
		"emosi": emosi,
		"dipercaya": dipercaya,
		"dipercaya_akhir": dipercaya_akhir,
		"viral_per_distrik": viral_per_distrik,
	}


static func cocok_emosi(emosi: String, favorit: String) -> float:
	if emosi == "netral" or favorit == "netral":
		return Balance.PENGALI_COCOK_NETRAL
	if emosi == favorit:
		return Balance.PENGALI_COCOK_SAMA
	if Balance.EMOSI_LAWAN.get(emosi, "") == favorit:
		return Balance.PENGALI_COCOK_LAWAN
	return Balance.PENGALI_COCOK_BEDA


## Emosi terbanyak menang; seri -> kartu paling heboh; masih seri -> slot paling awal.
static func emosi_dominan(kata_by_slot: Dictionary) -> String:
	var calon := {}  # emosi -> [jumlah, heboh_terbaik, slot_terbaik]
	for i in URUTAN_SLOT.size():
		var slot: String = URUTAN_SLOT[i]
		if not kata_by_slot.has(slot):
			continue
		var kata: Dictionary = kata_by_slot[slot]
		var emosi := str(kata.get("emosi", "netral"))
		if emosi == "netral":
			continue
		var heboh := int(kata.get("heboh", 0))
		if not calon.has(emosi):
			calon[emosi] = [0, -1, i]
		var c: Array = calon[emosi]
		c[0] += 1
		if heboh > c[1]:
			c[1] = heboh
			c[2] = i
	var terbaik := "netral"
	for emosi in calon:
		if terbaik == "netral" or _lebih_kuat(calon[emosi], calon[terbaik]):
			terbaik = emosi
	return terbaik


static func _lebih_kuat(a: Array, b: Array) -> bool:
	if a[0] != b[0]:
		return a[0] > b[0]
	if a[1] != b[1]:
		return a[1] > b[1]
	return a[2] < b[2]
