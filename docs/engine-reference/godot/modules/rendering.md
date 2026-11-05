# Godot 4.7 — Rendering (Compatibility focus)

Last verified: 2026-11-05

Sumber utama: https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html

## Compatibility vs Mobile untuk 2D

| Fitur | Compatibility | Mobile | Sumber |
|-------|---------------|--------|--------|
| Rendering 2D / game 2D | Ya | Ya | renderers.html |
| MSAA 2D | **Tidak** | Ya | renderers.html |
| HDR 2D Viewport | **Tidak** (RGBA8, LDR) | Ya | renderers.html |
| Glow | Ya | Ya | renderers.html |
| Compute shader | **Tidak** | Ya | renderers.html |
| Particle trails, particle SDF collision | **Tidak** (tidak disebut apakah berlaku untuk 2D) | Ya | renderers.html |
| GPUParticles2D | NOT SOURCEABLE — tidak disebut di renderers.html | | |
| Batas canvas_item shader, batas lampu 2D | NOT SOURCEABLE — tabel lampu di renderers.html hanya untuk 3D | | |

## Fallback otomatis

- Sejak 4.4, Forward+ dan Mobile otomatis turun ke Compatibility di perangkat tanpa Vulkan/D3D12/Metal. https://godotengine.org/releases/4.4/
- Setting: `rendering/rendering_device/fallback_to_opengl3`, bawaan `true`. Deskripsinya hanya menyebut Forward+, bukan Mobile. https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

## Setting renderer

- `rendering/renderer/rendering_method` — bawaan `forward_plus`
- `rendering/renderer/rendering_method.mobile` — bawaan `mobile`
- Proyek ini (ADR-0001): keduanya `gl_compatibility`.

Sumber: https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html

## Perubahan versi yang relevan

- 4.6: glow bawaan Soft Light → Screen, `glow_intensity` 0.8 → 0.3. https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.7: `CanvasItem` tidak lagi menambah feather antialiasing pada garis. https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- NOT SOURCEABLE — perubahan khusus Compatibility di 4.6/4.7, tidak disebut di panduan migrasi maupun halaman rilis.
