# Godot — Breaking Changes (4.3 → 4.7.2)

Last verified: 2026-11-05

Fokus: GDScript, core, 2D, UI, animasi, rendering, Android. Detail 3D/C#/XR hanya jika relevan.

## 4.3 → 4.4

Sumber: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.4.html

- `@export_file` yang diisi dari Inspector kini menyimpan path `uid://`, bukan `res://`. (4.5 menambah `@export_file_path` untuk path mentah.)
- `FileAccess.store_*` (store_string, store_line, store_buffer, …) kini mengembalikan `bool`, bukan `void` (kompatibel di GDScript).
- `OS.read_string_from_stdin` mendapat parameter `buffer_size` (tidak kompatibel di GDScript).
- `Curve` kini menegakkan rentang nilainya; titik di luar `[0, 1]` butuh `min_value`/`max_value`.
- `GraphEdit.frame_rect_changed`: `new_rect` dari `Vector2` → `Rect2`.
- `RenderingDevice.draw_list_begin`: banyak parameter dihapus.
- `VisualShaderNodeVec4Constant` input kini `Vector4`; konstanta lama perlu dibuat ulang.
- Android: event sensor tidak lagi aktif bawaan (Project Settings > Input Devices > Sensors).

## 4.4 → 4.5

Sumber: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html

- `Node.get_rpc_config` → `get_node_rpc_config`.
- `JSONRPC.set_scope` → `set_method`.
- `Resource.duplicate(true)` kini hanya menduplikasi resource internal; perilaku lama lewat `duplicate_deep(DEEP_DUPLICATE_ALL)`.
- `RenderingServer.instance_reset_physics_interpolation` dan `instance_set_interpolated` dihapus.
- `TileMapLayer.get_coords_for_body_rid()` berubah karena physics chunking bawaan; `physics_quadrant_size = 1` untuk perilaku 4.4.
- Region navigasi diperbarui asinkron secara bawaan (`navigation/world/region_use_async_iterations`).
- `RichTextLabel.add_image`/`update_image`: `size_in_percent` diganti `width_in_percent` + `height_in_percent` (lihat juga 4.7).
- `CanvasItem.draw_string` dan kerabatnya mendapat parameter opsional `oversampling` (kompatibel).

## 4.5 → 4.6

Sumber: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html

- Android: source set template ekspor mengikuti tata letak Android Studio (`android/build/src/` → `src/main/java/`, manifest dan assets ke `src/main/`). Template build kustom mungkin perlu dirombak.
- TSCN: `load_steps` tidak lagi ditulis; ID node unik disimpan. Kompatibel dua arah, tapi menyimpan ulang scene 4.5 menghasilkan diff besar (pakai Project > Tools > Upgrade Project Files).
- Glow: blend mode bawaan Soft Light → Screen (jauh lebih terang); `glow_intensity` 0.8 → 0.3 dan beberapa `glow_levels` berubah.
- `AnimationPlayer.assigned_animation`, `autoplay`, `current_animation` kini `StringName` (kompatibel di GDScript); `FileAccess.get_as_text` kehilangan parameter `skip_cr`.
- `AStar2D`/`AStarGrid2D` mengembalikan path kosong jika titik awal disabled/solid.
- Bawaan proyek baru: driver Windows D3D12; physics 3D Jolt.

## 4.6 → 4.7

Sumber: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html

- GDScript: mengubah elemen packed array tidak lagi memanggil setter properti array itu.
- GDScript: override method dengan tipe return kini mewarisi tipe itu dan butuh `return` eksplisit (`return null` bila perlu).
- `CanvasItem` tidak lagi menambah feather antialiasing saat menggambar garis (`draw_line` dll. tampak lebih tipis).
- Device ID mouse/keyboard: `0` → `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`.
- `AudioStreamPlayer.area_mask` bawaan 0 (nonaktif), bukan layer 1.
- `PhysicsServer2DExtension._body_set_shape_as_one_way_collision` mendapat parameter wajib `direction`.
- `Object.is_class` menerima `StringName`.
- `RichTextLabel`: `width_in_percent`/`height_in_percent` (bool) → `width_unit`/`height_unit` (`ImageUnit`); `UPDATE_WIDTH_IN_PERCENT` → `UPDATE_WIDTH_UNIT` (tidak kompatibel di GDScript).
- `AudioEffectSpectrumAnalyzer.tap_back_pos` dihapus.
- Bawaan proyek baru: `display/window/stretch/mode` = `canvas_items`, `stretch/aspect` = `expand`.

## 4.7 → 4.7.1 → 4.7.2

- 4.7.1: "no known incompatibilities" dengan 4.7. Perbaikan relevan: backspace soft keyboard Android, drag-and-drop layar sentuh, keyboard virtual tidak lagi terbuka sendiri saat popup muncul. https://godotengine.org/article/maintenance-release-godot-4-7-1/
- 4.7.2: "no known incompatibilities" dengan 4.7.1. Perbaikan relevan: input `BaseButton` dengan `enable_long_press_as_right_click`. Tidak ada perbaikan khusus Android/Compatibility yang tercantum. https://godotengine.org/article/maintenance-release-godot-4-7-2/

## NOT SOURCEABLE

- Perubahan khusus renderer Compatibility di 4.6/4.7 — tidak disebut di panduan migrasi maupun halaman rilis.
- Perubahan Tween di 4.4/4.5 — tidak disebut di halaman rilis yang dibaca.
