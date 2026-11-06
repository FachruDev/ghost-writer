class_name Palet
extends RefCounted
## Warna prototipe (kotak abu-abu). Diganti aset sungguhan di 0.3.0.

const LATAR := Color(0.11, 0.11, 0.13)
const PANEL := Color(0.17, 0.17, 0.20)
const TEKS_REDUP := Color(0.62, 0.62, 0.67)

const EMOSI := {
	"lucu": Color(0.88, 0.70, 0.23),
	"takut": Color(0.48, 0.36, 0.78),
	"marah": Color(0.82, 0.29, 0.36),
	"iri": Color(0.31, 0.64, 0.42),
	"netral": Color(0.42, 0.42, 0.46),
}

## Urutan sama dengan SpreadSim.Status: BELUM, PERCAYA, RAGU, KEBAL.
const STATUS := [
	Color(0.55, 0.55, 0.58),
	Color(0.88, 0.28, 0.28),
	Color(0.91, 0.77, 0.28),
	Color(0.29, 0.56, 0.88),
]


const AKSEN := Color(0.90, 0.36, 0.30)

## Warna meja per era sampai art tersedia: 1 kamar, 2 kantor.
const MEJA_ERA := {1: Color(0.17, 0.17, 0.20), 2: Color(0.24, 0.19, 0.14)}


static func emosi(nama: String) -> Color:
	return EMOSI.get(nama, EMOSI["netral"])


## Kotak polos berwarna untuk panel dan tombol prototipe.
static func kotak(warna: Color, tepi: Color = Color.TRANSPARENT, radius: int = 8) -> StyleBoxFlat:
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = warna
	gaya.border_color = tepi
	gaya.set_border_width_all(2 if tepi.a > 0.0 else 0)
	gaya.set_corner_radius_all(radius)
	gaya.set_content_margin_all(8)
	return gaya


## Gaya normal/hover/pressed/disabled untuk satu tombol.
static func gaya_tombol(tombol: Button, warna: Color) -> void:
	tombol.add_theme_stylebox_override("normal", kotak(warna.darkened(0.35), warna))
	tombol.add_theme_stylebox_override("hover", kotak(warna.darkened(0.15), warna))
	tombol.add_theme_stylebox_override("pressed", kotak(warna, warna.lightened(0.3)))
	tombol.add_theme_stylebox_override("focus", kotak(Color.TRANSPARENT, warna.lightened(0.3)))
	tombol.add_theme_stylebox_override("disabled", kotak(PANEL, PANEL.lightened(0.15)))
