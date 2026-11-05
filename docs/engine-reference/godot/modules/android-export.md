# Godot 4.7 — Android Export, Portrait, App Lifecycle

Last verified: 2026-11-05

## Toolchain

Sumber: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

- JDK: OpenJDK 17 (versi lebih tinggi didukung)
- Halaman docs menyebut: Platform-Tools ≥ 35.0.0, Build-Tools 35.0.1, SDK Platform 35, Command-line Tools terbaru, CMake 3.10.2.4988404, NDK r28b
- Konfigurasi build di source 4.7-stable berbeda (kemungkinan docs belum diperbarui): `minSdk 24`, `targetSdk 36`, `compileSdk 36`, buildTools `36.1.0`, NDK `29.0.14206865`, Java 17, AGP 8.6.1. https://raw.githubusercontent.com/godotengine/godot/4.7-stable/platform/android/java/app/config.gradle
- NOT SOURCEABLE — nilai bawaan `gradle_build/min_sdk` dan `target_sdk` di export preset, tidak disebut di https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html

## Gradle & AAB

Sumber: https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html

- APK siap pakai tidak butuh Gradle. **AAB butuh Gradle build**: pasang Android Build Template (membuat `res://android/build`) lalu aktifkan "Gradle Build" di export preset.
- Play Store wajib AAB (sejak Agustus 2021) dan keystore rilis; matikan "Export With Debug".
- 4.6: template source set pindah ke tata letak Android Studio (`src/main/java/`). https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html

## Google Play: target API & 16 KB

- Target API: mulai 31 Agustus 2026 app baru dan update wajib target API 36+ (perpanjangan sampai 1 November 2026). https://developer.android.com/google/play/requirements/target-sdk
- 16 KB page size: wajib untuk app yang menargetkan Android 15+ di perangkat 64-bit. Halaman Android saat ini menyebut update tanpa dukungan 16 KB tidak bisa dirilis mulai 1 Februari 2027. https://developer.android.com/guide/practices/page-sizes
- Godot: "supports this feature out of the box" sejak 4.5 (https://godotengine.org/releases/4.5/; issue https://github.com/godotengine/godot/issues/106313 ditutup lewat PR #106358). Untuk 4.7 ini **disimpulkan** dari 4.5, tidak dikonfirmasi eksplisit di halaman rilis 4.7.
- Biarkan `gradle_build/compress_native_libraries` = `false` untuk Play Store. https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html
- Cara cek AAB: `bundletool dump config --bundle=<app.aab> | grep alignment` → harus `PAGE_ALIGNMENT_16K`; untuk APK: `zipalign -c -P 16 -v 4 app.apk`. https://developer.android.com/guide/practices/page-sizes

## Portrait

Sumber: https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html dan https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

- Rekomendasi docs untuk mobile portrait: base 720×1280, orientation `portrait`, stretch mode `canvas_items`, aspect `expand`.
- `display/window/handheld/orientation` bawaan `0`; nilai int untuk portrait: NOT SOURCEABLE (atur lewat editor).
- Bawaan proyek **baru** sejak 4.7: stretch `canvas_items` + aspect `expand`. https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- Safe area: `DisplayServer.get_display_safe_area()` → `Rect2i` area layar yang tidak terhalang; hanya Android/iOS. `get_display_cutouts()` hanya Android. https://docs.godotengine.org/en/4.7/classes/class_displayserver.html

## App lifecycle (notifikasi)

Sumber: https://docs.godotengine.org/en/4.7/classes/class_node.html

| Notifikasi | Platform |
|------------|----------|
| `NOTIFICATION_APPLICATION_PAUSED` (2015) | Android, iOS — iOS memberi ±5 detik; batas waktu Android NOT SOURCEABLE |
| `NOTIFICATION_APPLICATION_RESUMED` (2014) | Android, iOS |
| `NOTIFICATION_APPLICATION_FOCUS_OUT` / `FOCUS_IN` | Desktop dan mobile |
| `NOTIFICATION_WM_GO_BACK_REQUEST` (1007) | Hanya Android (tombol Back) |
| `NOTIFICATION_WM_CLOSE_REQUEST` (1006) | Hanya desktop |

## File & save (dipakai ADR-0002)

- `DirAccess.rename()` menimpa file tujuan yang ada; `rename_absolute()` dan `remove_absolute()` tersedia sebagai versi statis. https://docs.godotengine.org/en/4.7/classes/class_diraccess.html
- `FileAccess.open()` mengembalikan `null` jika gagal; `get_open_error()` untuk detail; flush otomatis saat file ditutup; `flush()` tersedia. https://docs.godotengine.org/en/4.7/classes/class_fileaccess.html
- `JSON.parse_string()` mengembalikan `null` jika gagal; `JSON.stringify()` mengubah semua angka jadi float. https://docs.godotengine.org/en/4.7/classes/class_json.html
- `Time.get_unix_time_from_system()` → detik Unix UTC (float); `get_datetime_string_from_system()` waktu lokal kecuali `utc = true`. https://docs.godotengine.org/en/4.7/classes/class_time.html
- `RandomNumberGenerator.state` boleh disalin untuk memulihkan/menduplikasi RNG; set `seed` dulu, lalu `state`. https://docs.godotengine.org/en/4.7/classes/class_randomnumbergenerator.html
