extends Node
## Sinyal global supaya scene tidak saling memanggil langsung.

@warning_ignore("unused_signal")
signal money_changed(uang: int)
@warning_ignore("unused_signal")
signal kepemilikan_berubah
@warning_ignore("unused_signal")
signal kartu_dipilih(kata_id: String)
@warning_ignore("unused_signal")
signal distrik_dipilih(distrik_id: String)
@warning_ignore("unused_signal")
signal kirim_diminta(data: Dictionary)
@warning_ignore("unused_signal")
signal rumor_published(info: Dictionary)
@warning_ignore("unused_signal")
signal warga_berubah
@warning_ignore("unused_signal")
signal rumor_selesai(hasil: Dictionary)
@warning_ignore("unused_signal")
signal toko_diminta(buka: bool)
