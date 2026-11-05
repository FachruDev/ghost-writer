class_name Mutasi
extends RefCounted
## Mutasi rumor: satu kata diganti kata lain dari slot yang sama (konsep-game.md).
## Kosmetik: skor rumor tidak berubah.


## kata_ids: {"slot": "kata_id"}. kata_per_slot: {"slot": Array[String] semua kata di slot itu}.
## Mengembalikan kata_ids baru, atau {} kalau tidak ada pengganti.
static func acak(kata_ids: Dictionary, kata_per_slot: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var slots := kata_ids.keys()
	if slots.is_empty():
		return {}
	var slot: String = slots[rng.randi_range(0, slots.size() - 1)]
	var calon: Array = []
	for id in kata_per_slot.get(slot, []):
		if id != kata_ids[slot]:
			calon.append(id)
	if calon.is_empty():
		return {}
	var hasil := kata_ids.duplicate()
	hasil[slot] = calon[rng.randi_range(0, calon.size() - 1)]
	return hasil
