# Godot — Deprecated / Renamed APIs (4.3 → 4.7.2)

Last verified: 2026-11-05

Jangan pakai kolom kiri; pakai kolom kanan.

| Don't use | Use instead | Since | Source |
|-----------|-------------|-------|--------|
| `@export_file` bila butuh path `res://` mentah | `@export_file_path` | 4.5 | [4.4 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.4.html) |
| `Node.get_rpc_config()` | `Node.get_node_rpc_config()` | 4.5 | [4.5 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html) |
| `JSONRPC.set_scope()` | `JSONRPC.set_method()` | 4.5 | [4.5 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html) |
| `Resource.duplicate(true)` untuk salinan dalam penuh | `Resource.duplicate_deep(DEEP_DUPLICATE_ALL)` | 4.5 | [4.5 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html) |
| `RenderingServer.instance_set_interpolated()` / `instance_reset_physics_interpolation()` | NOT SOURCEABLE — pengganti tidak disebut di panduan 4.5 | 4.5 | [4.5 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html) |
| `RichTextLabel.add_image(..., size_in_percent)` | `width_unit` / `height_unit` (`RichTextLabel.ImageUnit`) | 4.7 | [4.7 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html) |
| `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` | `UPDATE_WIDTH_UNIT` | 4.7 | [4.7 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html) |
| Membandingkan `InputEvent.device == 0` untuk mouse/keyboard | `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`, atau cek tipe event | 4.7 | [4.7 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html) |
| `FileAccess.get_as_text(skip_cr)` | `FileAccess.get_as_text()` | 4.6 | [4.6 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html) |
| `Control.accessibility_live` bertipe `DisplayServer.AccessibilityLiveMode` | `AccessibilityServer.AccessibilityLiveMode` | 4.7 | [4.7 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html) |
| `AudioEffectSpectrumAnalyzer.tap_back_pos` | dihapus, tanpa pengganti | 4.7 | [4.7 guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html) |

NOT SOURCEABLE — daftar deprecation resmi terpisah tidak ada di panduan migrasi 4.4–4.7; tabel ini hanya memuat rename yang disebut di panduan.
