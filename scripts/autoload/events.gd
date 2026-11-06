extends Node
## Sinyal global supaya scene tidak saling memanggil langsung.

@warning_ignore("unused_signal")
signal money_changed(uang: int)
@warning_ignore("unused_signal")
signal pengikut_berubah(pengikut: int)
@warning_ignore("unused_signal")
signal reputasi_berubah
@warning_ignore("unused_signal")
signal kepemilikan_berubah
@warning_ignore("unused_signal")
signal kartu_dipilih(kata_id: String)
@warning_ignore("unused_signal")
signal kartu_terbang(kata_id: String, dari: Vector2)
@warning_ignore("unused_signal")
signal distrik_dipilih(distrik_id: String)
@warning_ignore("unused_signal")
signal saluran_dipilih(saluran_id: String)
@warning_ignore("unused_signal")
signal kirim_diminta(data: Dictionary)
@warning_ignore("unused_signal")
signal headline_diketik(durasi: float)
@warning_ignore("unused_signal")
signal rumor_published(info: Dictionary)
@warning_ignore("unused_signal")
signal warga_berubah
@warning_ignore("unused_signal")
signal uang_dari_distrik(distrik: int, jumlah: int)
@warning_ignore("unused_signal")
signal rumor_selesai(hasil: Dictionary)
@warning_ignore("unused_signal")
signal feed_baru(entri: Dictionary)
@warning_ignore("unused_signal")
signal misi_berubah
@warning_ignore("unused_signal")
signal event_mulai(info: Dictionary)
@warning_ignore("unused_signal")
signal event_sisa(sisa_detik: float)
## Banner menampilkan ulang event yang masih berjalan (tanpa bunyi alert).
@warning_ignore("unused_signal")
signal event_tampil(info: Dictionary)
@warning_ignore("unused_signal")
signal event_selesai(event_id: String)
@warning_ignore("unused_signal")
signal toko_diminta(buka: bool)
@warning_ignore("unused_signal")
signal era_berubah(era: int)
## Distrik aktif atau tata letaknya berubah (DataDB.districts sudah diperbarui).
@warning_ignore("unused_signal")
signal peta_berubah
## Simulasi dibangun ulang untuk peta baru.
@warning_ignore("unused_signal")
signal sim_diganti(sim: SpreadSim)
## Teks progres kontrak kampanye untuk HUD ("" = tidak ada kontrak).
@warning_ignore("unused_signal")
signal kontrak_berubah(teks: String)
## Minta EventController memulai ancaman tertentu (mis. pertahanan tokoh Bramantyo).
@warning_ignore("unused_signal")
signal ancaman_diminta(event_id: String)
## Reputasi tokoh berubah atau tokoh jatuh.
@warning_ignore("unused_signal")
signal tokoh_berubah
@warning_ignore("unused_signal")
signal template_diganti
@warning_ignore("unused_signal")
signal dibeli
@warning_ignore("unused_signal")
signal aksi_gagal
@warning_ignore("unused_signal")
signal dilema_dipilih(indeks: int)
