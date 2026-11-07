extends RefCounted
## Ringkasan hasil bot balancing (tools/sesi_bot.gd): waktu naik era, kampanye akhir, ekonomi.
## Mode final mencetak satu baris RACE saja.


static func cetak(daftar: Array, mode_final: bool) -> void:
	var k := daftar.size()
	var rata := func(f: Callable) -> float:
		var t := 0.0
		for l in daftar:
			t += float(f.call(l))
		return t / k
	var m5 := daftar.filter(func(l): return l["misi_akhir"] >= 5).map(func(l): return l["misi"].filter(func(x): return x[0] == 5)[0][1] / 60.0)
	var era2 := daftar.filter(func(l): return l["era2"] >= 0.0).map(func(l): return snappedf(l["era2"] / 60.0, 0.1))
	var staf := daftar.filter(func(l): return l["staf"] >= 0.0).map(func(l): return snappedf(l["staf"] / 60.0, 0.1))
	var era3 := daftar.filter(func(l): return l["era3"] >= 0.0).map(func(l): return snappedf(l["era3"] / 60.0, 0.1))
	var era4 := daftar.filter(func(l): return l["era4"] >= 0.0).map(func(l): return snappedf(l["era4"] / 60.0, 0.1))
	if mode_final:
		var menang := daftar.filter(func(l): return not l["akhir"].is_empty() and l["akhir"][0][0] == "menang").size()
		print("RACE: menang %d/%d | durasi detik %s | kebal_maks %s | rumor %s" % [menang, k,
			str(daftar.map(func(l): return "%s%d" % ["M" if not l["akhir"].is_empty() and l["akhir"][0][0] == "menang" else "K", l["akhir"][0][1] if not l["akhir"].is_empty() else -1])),
			str(daftar.map(func(l): return l["kebal_maks"])), str(daftar.map(func(l): return l["rumor"]))])
		return
	for l in daftar:
		print("FINAL seed %d: mulai %s | hasil %s" % [l["seed"], str(l["final"].map(func(x): return "@%.1f p%d%% k%d%%" % [x[0] / 60.0, x[1], x[2]])),
			str(l["akhir"].map(func(x): return "%s@%.1f" % [x[0], x[1] / 60.0]))])
		print("  kebal_maks %d%% | jejak %s" % [l["kebal_maks"], " ".join(l["jejak"].map(func(j): return "m%d:p%d/u%d/k%d/h%d" % j))])
	print("ERA4: menara server %d/%d @menit %s | tokoh jatuh=%.1f per sesi" % [era4.size(), k, str(era4), rata.call(func(l): return l["tokoh_jatuh"])])
	print("ERA3: gedung media %d/%d @menit %s | kontrak berhasil=%.1f gagal=%.1f per sesi" % [era3.size(), k, str(era3),
		rata.call(func(l): return l["kontrak_ok"]), rata.call(func(l): return l["kontrak_gagal"])])
	print("ERA2: sewa kantor %d/%d @menit %s | staf %d/%d @menit %s | dilema=%.1f per sesi" % [era2.size(), k, str(era2), staf.size(), k, str(staf), rata.call(func(l): return l["dilema"])])
	print("RINGKAS: misi5_selesai=%d/%d @menit %s | rumor=%.0f | bongkar=%.0f%% | heat_rata=%.0f | menit_heat>=70=%.1f | kred_min=%.0f | acak=%.1f | ancaman=%.1f | kartu=%.1f/40 | uang=%.0f" % [
		m5.size(), k, str(m5.map(func(x): return snappedf(x, 0.1))), rata.call(func(l): return l["rumor"]),
		100.0 * rata.call(func(l): return float(l["dibongkar"]) / maxf(1, l["rumor"])), rata.call(func(l): return l["heat_sum"] / maxf(1, l["n"])),
		rata.call(func(l): return l["heat_panas"] / 60.0), rata.call(func(l): return l["kred_min"]),
		rata.call(func(l): return l["event"].filter(func(e): return e[0] != "e_pembongkar_fakta").size()),
		rata.call(func(l): return l["event"].filter(func(e): return e[0] == "e_pembongkar_fakta").size()),
		rata.call(func(l): return l["kartu"]), rata.call(func(l): return l["uang"])])
