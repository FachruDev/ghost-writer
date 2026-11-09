# Ikon — Ghostwriter v1.0.0

Ikon UI dibuat sebagai **SVG** supaya tajam di semua kepadatan layar; Godot mengimpornya sebagai tekstur. Simpan di `res://assets/icons/`. Gaya: garis tebal sederhana, satu warna, mudah dikenali di ukuran 32 px.

## Ikon aplikasi (Android)

| ID | Isi | Ukuran | Versi | Status |
| --- | --- | --- | --- | --- |
| app_icon_main | Ikon utama (juga ikon jendela desktop), sudut membulat: `assets/ikon_app/ikon_192.png` | 192×192 | 0.2.0 (sementara), 0.9.0 (final) | Selesai |
| app_icon_adaptive_fg | Lapisan depan adaptive icon: Si Hantu Penulis (`ikon_depan.svg` → `ikon_depan_432.png`; usulan awal mesin tik + gelembung gosip jadi konsep C di kanvas) | 432×432 | 0.9.0 | Selesai |
| app_icon_adaptive_bg | Lapisan belakang adaptive icon: langit malam (`ikon_belakang.svg` → `ikon_belakang_432.png`) | 432×432 | 0.9.0 | Selesai |
| app_icon_monochrome | Versi satu warna (themed icon): siluet hantu (`ikon_mono.svg` → `ikon_mono_432.png`) | 432×432 | 0.9.0 | Selesai |
| store_icon | Ikon Play Store, kotak penuh: `assets/ikon_app/ikon_toko_512.png` (tidak ikut APK) | 512×512 | 1.0.0 | Selesai |

Simpan elemen penting adaptive icon di lingkaran tengah (sekitar 66% bidang) supaya tidak terpotong di bentuk ikon HP yang berbeda-beda.

Sumbernya SVG di `assets/ikon_app/` (desain: kanvas papan 21). PNG dibuat ulang dengan `tools/buat_ikon_splash.gd` (jalankan dengan jendela, bukan `--headless`, karena splash ikut dirender); preset Android menunjuk ke PNG 432 dan 192.

## Ikon dalam game

| ID | Arti | Versi | Status |
| --- | --- | --- | --- |
| ic_emo_lucu, ic_emo_takut, ic_emo_marah, ic_emo_iri, ic_emo_netral | Emosi kartu kata | 0.2.0 | Belum |
| ic_money | Uang | 0.2.0 | Belum |
| ic_follower | Pengikut | 0.2.0 | Belum |
| ic_cred | Kredibilitas | 0.2.0 | Belum |
| ic_heat | Heat | 0.2.0 | Belum |
| ic_ch_merpati, ic_ch_koran | Saluran awal | 0.2.0 | Belum |
| ic_event_modifier, ic_event_threat, ic_event_dilemma, ic_event_chance | Jenis event | 0.2.0 | Belum |
| ic_shop, ic_settings, ic_close | UI umum | 0.2.0 | Belum |
| ic_ch_radio | Saluran radio | 0.3.0 | Belum |
| ic_staff | Staf otomatis | 0.3.0 | Belum |
| ic_ch_medsos | Saluran medsos | 0.4.0 | Belum |
| ic_ch_server | Saluran server | 0.5.0 | Belum |
| ic_sound_on, ic_sound_off, ic_music, ic_vibrate | Pengaturan | 0.9.0 | Belum |
