class_name Konsekuensi
extends RefCounted
## Rumus heat, pembongkaran, kredibilitas, dan pengikut (konsep-game.md, bagian Konsekuensi).
## Murni: tidak mengubah state; pemanggil yang menerapkan hasilnya.


static func heat_kirim(skor: Dictionary, pengali_heat: float) -> float:
	return float(skor["heboh_total"]) * (Balance.HEAT_FAKTOR_KIRIM - float(skor["dipercaya_akhir"])) * pengali_heat


static func peluang_bongkar(dipercaya_akhir: float, heat: float) -> float:
	return (1.0 - dipercaya_akhir) * (Balance.BONGKAR_DASAR + heat / 100.0 * Balance.BONGKAR_DARI_HEAT)


static func pengikut_dari_warga(warga_percaya: int) -> int:
	return floori(float(warga_percaya) / Balance.WARGA_PER_PENGIKUT)


## Hasil akhir rumor. rng dipakai untuk satu lemparan pembongkaran.
## Mengembalikan delta yang harus diterapkan: {"dibongkar", "kredibilitas", "heat", "pengikut"}.
## paksa_bongkar: pertahanan tokoh (Pengacara) membongkar rumor apa pun hasil lemparannya.
static func akhir_rumor(skor: Dictionary, warga_percaya: int, heat: float, rng: RandomNumberGenerator,
		paksa_bongkar: bool = false) -> Dictionary:
	var dipercaya := float(skor["dipercaya_akhir"])
	var lemparan := rng.randf()  # tetap dilempar supaya urutan acak sama dengan atau tanpa paksaan
	var dibongkar := paksa_bongkar or lemparan < peluang_bongkar(dipercaya, heat)
	if dibongkar:
		return {
			"dibongkar": true,
			"kredibilitas": -(Balance.KRED_TURUN_DIBONGKAR + float(skor["heboh_total"])),
			"heat": Balance.HEAT_DIBONGKAR,
			"pengikut": 0,
		}
	return {
		"dibongkar": false,
		"kredibilitas": Balance.KRED_NAIK if dipercaya >= Balance.KRED_NAIK_MIN_DIPERCAYA else 0.0,
		"heat": 0.0,
		"pengikut": pengikut_dari_warga(warga_percaya),
	}
