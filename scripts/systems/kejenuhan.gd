class_name Kejenuhan
extends RefCounted
## Kata basi (konsep-game.md, bagian Kejenuhan kata): kata yang baru saja dipakai pemain kehilangan sebagian
## heboh-nya. Tiap pemakaian dalam JENUH_JENDELA rumor pemain terakhir mengurangi pengali heboh kata itu
## sebesar JENUH_PER_PAKAI, paling rendah JENUH_MIN. Pulih sendiri setelah kata itu tidak dipakai selama
## beberapa rumor. Rumor staf tidak dihitung. Kata ber-tag (tokoh, calon RT, dokumen bocor) tidak bisa basi:
## kata tokoh memang harus disebut berulang untuk menjatuhkan tokohnya.
## Murni: tidak membaca state; pemanggil memberi riwayat.

const SALURAN_STAF := "staf"


## Jumlah pemakaian tiap kata_id dalam JENUH_JENDELA rumor pemain terakhir. riwayat: GameState.riwayat_rumor.
static func hitung(riwayat: Array) -> Dictionary:
	var jumlah := {}
	var dilihat := 0
	for k in range(riwayat.size() - 1, -1, -1):
		if dilihat >= Balance.JENUH_JENDELA:
			break
		var entri: Dictionary = riwayat[k]
		if str(entri.get("saluran_id", "")) == SALURAN_STAF:
			continue
		dilihat += 1
		var kata_ids: Dictionary = entri.get("kata_ids", {})
		for slot in kata_ids:
			var id := str(kata_ids[slot])
			jumlah[id] = int(jumlah.get(id, 0)) + 1
	return jumlah


static func pengali(kali_dipakai: int) -> float:
	return maxf(Balance.JENUH_MIN, 1.0 - Balance.JENUH_PER_PAKAI * kali_dipakai)


## Pengali heboh untuk satu kata (data kata dari DataDB). Kata ber-tag tidak bisa basi.
static func pengali_kata(kata: Dictionary, jumlah: Dictionary) -> float:
	if str(kata.get("tag", "")) != "":
		return 1.0
	return pengali(int(jumlah.get(str(kata.get("id", "")), 0)))


## Salinan kata_by_slot dengan heboh tiap kata dikali pengali kejenuhannya; dipakai sebelum RumorScorer.nilai.
static func terapkan(kata_by_slot: Dictionary, jumlah: Dictionary) -> Dictionary:
	var hasil := {}
	for slot in kata_by_slot:
		var kata: Dictionary = kata_by_slot[slot]
		var p := pengali_kata(kata, jumlah)
		if p >= 1.0:
			hasil[slot] = kata
		else:
			var basi := kata.duplicate()
			basi["heboh"] = float(kata.get("heboh", 0)) * p
			hasil[slot] = basi
	return hasil
