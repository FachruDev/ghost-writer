class_name Palet
extends RefCounted
## Warna "Kota Gosip Malam" (kanvas desain, papan 07 Panduan Gaya) dan pembuat StyleBox.
## Ukuran di kanvas dikali 2 = piksel Godot (artboard 360 px -> basis 720).

const MALAM := Color("1a1530")
const PANEL := Color("2a2350")
const PANEL_2 := Color("3a3170")
const GARIS := Color("5b4fa8")
const PETA := Color("221b44")
const KERTAS := Color("fffdf7")
const TINTA := Color("1a1530")
const TEKS := Color("f4f1ff")
const TEKS_REDUP := Color("b9b2da")
const TEKS_LEMBUT := Color("d6d0f0")
const TEKS_KERTAS_REDUP := Color("5e567f")

const PINK := Color("ff3d7f")
const PINK_GELAP := Color("c21e5c")
const KUNING := Color("ffc93c")
const KUNING_GELAP := Color("d99a0b")
const CYAN := Color("3dd9eb")
const CYAN_GELAP := Color("1a9bab")
const HIJAU := Color("34d399")
const HIJAU_GELAP := Color("13a06d")
const ORANYE := Color("ff6b3d")
const ABU_KEBAL := Color("8792a6")

## Nama lama dipakai beberapa scene; tetap ada supaya tidak putus.
const LATAR := MALAM
const AKSEN := PINK

const EMOSI := {
	"lucu": Color("ffc93c"),
	"takut": Color("7c4deb"),
	"marah": Color("ff6b3d"),
	"iri": Color("34d399"),
	"netral": Color("94a3b8"),
}
const EMOSI_GELAP := {
	"lucu": Color("d99a0b"),
	"takut": Color("5a2fc4"),
	"marah": Color("d1451a"),
	"iri": Color("13a06d"),
	"netral": Color("64748b"),
}
## Cahaya gugus distrik di peta (takut lebih terang dari kartu supaya terlihat di latar gelap).
const EMOSI_PETA := {
	"lucu": Color("ffc93c"),
	"takut": Color("9b7bff"),
	"marah": Color("ff6b3d"),
	"iri": Color("34d399"),
	"netral": Color("94a3b8"),
}

## Cincin wajah warga. Urutan sama dengan SpreadSim.Status: BELUM, PERCAYA, RAGU, KEBAL.
const STATUS := [GARIS, PINK, KUNING, ABU_KEBAL]

const KULIT := [Color("ffd9b0"), Color("e8b48a"), Color("c98c62"), Color("ffe3c9"), Color("d9a27a")]
const RAMBUT := [Color("2b1b12"), Color("5a3a22"), Color("120e26"), Color("7c4deb"), Color("3b8fd9"), Color("2b1b12")]

## Warna aksen per era untuk lencana HUD dan layar naik era.
const ERA := {1: KUNING, 2: CYAN, 3: PINK, 4: HIJAU}
## Latar panel meja per era.
const MEJA_ERA := {1: PANEL, 2: PANEL, 3: PANEL, 4: PANEL}


static func emosi(nama: String) -> Color:
	return EMOSI.get(nama, EMOSI["netral"])


static func emosi_gelap(nama: String) -> Color:
	return EMOSI_GELAP.get(nama, EMOSI_GELAP["netral"])


## Warna ubin saluran (Pilih Saluran, tombol saluran di meja).
static func saluran(id: String) -> Color:
	return {"merpati": KUNING, "koran": TEKS, "radio": ORANYE, "medsos": PINK, "server": CYAN}.get(id, TEKS_REDUP)


## Teks di atas warna emosi: tinta kecuali takut (ungu tua) yang memakai putih (kontras 4.5:1).
static func teks_di_atas(nama: String) -> Color:
	return Color.WHITE if nama == "takut" else TINTA


## Kotak polos berwarna. radius dalam piksel Godot.
static func kotak(warna: Color, tepi: Color = Color.TRANSPARENT, radius: int = 24) -> StyleBoxFlat:
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = warna
	gaya.border_color = tepi
	gaya.set_border_width_all(4 if tepi.a > 0.0 else 0)
	gaya.set_corner_radius_all(radius)
	gaya.set_content_margin_all(16)
	gaya.anti_aliasing = true
	return gaya


## Kotak "tebal": bayangan dalam di bawah (tombol, kartu, pil). tekan = versi saat ditekan.
static func tebal(warna: Color, bayang: Color, radius: int = 28, bawah: int = 10, tekan := false) -> StyleBoxFlat:
	var gaya := kotak(warna, Color.TRANSPARENT, radius)
	gaya.border_color = bayang
	gaya.border_width_bottom = 3 if tekan else bawah
	gaya.content_margin_top = 12.0 + (bawah - 3 if tekan else 0)
	gaya.content_margin_bottom = 12.0
	gaya.content_margin_left = 20.0
	gaya.content_margin_right = 20.0
	return gaya


## Gaya normal/hover/pressed/disabled/focus untuk satu tombol tebal.
static func gaya_tombol(tombol: Button, warna: Color, bayang: Color = Color.TRANSPARENT,
		teks: Color = Color.TRANSPARENT, radius: int = 28) -> void:
	if bayang.a == 0.0:
		bayang = warna.darkened(0.3)
	if teks.a == 0.0:
		teks = TINTA if warna.get_luminance() > 0.5 else TEKS
	tombol.add_theme_stylebox_override("normal", tebal(warna, bayang, radius))
	tombol.add_theme_stylebox_override("hover", tebal(warna.lightened(0.06), bayang, radius))
	tombol.add_theme_stylebox_override("pressed", tebal(warna, bayang, radius, 10, true))
	tombol.add_theme_stylebox_override("hover_pressed", tebal(warna, bayang, radius, 10, true))
	var mati := kotak(Color(PANEL_2, 0.6), Color.TRANSPARENT, radius)
	tombol.add_theme_stylebox_override("disabled", mati)
	var fokus := kotak(Color.TRANSPARENT, KUNING, radius)
	fokus.draw_center = false
	tombol.add_theme_stylebox_override("focus", fokus)
	for nama in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		tombol.add_theme_color_override(nama, teks)
	tombol.add_theme_color_override("font_disabled_color", TEKS_REDUP)
