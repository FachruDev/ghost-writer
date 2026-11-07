extends GdUnitTestSuite
## Suara yang terikat ke event: lapisan musik ancaman dan dering telepon (EVENT.md).


func after_test() -> void:
	Suara.atur_lapisan_ancaman(false)


func test_lapisan_ancaman_ikut_event_ancaman() -> void:
	Events.event_mulai.emit({"id": "e_pembongkar_fakta", "jenis": "ancaman"})
	assert_bool(Suara.lapisan_ancaman_aktif()).is_true()
	# Ancaman selesai tapi event acak masih tampil: lapisan berhenti.
	Events.event_tampil.emit({"id": "e_hari_pasar", "jenis": "modifier"})
	assert_bool(Suara.lapisan_ancaman_aktif()).is_false()
	Events.event_mulai.emit({"id": "e_kota_tak_percaya", "jenis": "ancaman"})
	Events.event_selesai.emit("e_kota_tak_percaya")
	assert_bool(Suara.lapisan_ancaman_aktif()).is_false()


func test_musik_ancaman_berulang_dan_telepon_ada() -> void:
	assert_bool((Suara.MUSIK_ANCAMAN as AudioStreamOggVorbis).loop).is_true()
	assert_array(Suara.SFX["phone"]).is_not_empty()
	assert_bool(DataDB.events.any(func(e: Dictionary) -> bool: return e["id"] in Suara.EVENT_TELEPON)).is_true()
