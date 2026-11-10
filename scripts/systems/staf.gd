class_name Staf
extends RefCounted
## Rumor abstrak staf otomatis (konsep-game.md, Era 2): tidak disimulasikan di peta.
## Rumus yang sama dipakai untuk penghasilan offline di 0.6.0.


## warga percaya ≈ warga_dasar × dipercaya_akhir × cocok_emosi(distrik target)
static func warga_percaya(skor: Dictionary, distrik: Dictionary, warga_dasar: float) -> int:
	var cocok := RumorScorer.cocok_emosi(str(skor["emosi"]), str(distrik.get("emosi_favorit", "netral")))
	return roundi(warga_dasar * float(skor["dipercaya_akhir"]) * cocok)
