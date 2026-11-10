# Godot — Current Best Practices (4.4 → 4.7.2)

Last verified: 2026-11-05

Hanya fitur yang relevan untuk game 2D GDScript portrait di Android.

## GDScript

- **Typed dictionary** — tipe key dan value bisa dideklarasikan, diatur di Inspector, dan nilai salah ditandai parser. (4.4) https://godotengine.org/releases/4.4/
- **Variadic arguments** (`...`) dan **`@abstract`** untuk class/method abstrak. (4.5) https://godotengine.org/releases/4.5/
- **Backtrace di build rilis** dan logger kustom; butuh *Debug > Settings > GDScript > Always Track Call Stacks*. (4.5) https://godotengine.org/releases/4.5/
- **`duplicate_deep()`** pada Array, Dictionary, Resource untuk kontrol salinan dalam. (4.5) https://godotengine.org/releases/4.5/
- **UID di mana-mana** — resource dirujuk lewat UID, jadi memindah file lebih jarang memutus referensi. Ctrl-drag resource ke script untuk `preload` lewat UID. (4.4/4.5)
- Override method bertipe return wajib `return` eksplisit. (4.7) — lihat [breaking-changes.md](breaking-changes.md)
- Urutan isi script dan penamaan: [GDScript style guide](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html). File `snake_case`.

## 2D, UI, animasi

- **2D batching** kini berlaku di semua backend; **shader instance uniform** untuk CanvasItem tanpa memecah batching. (4.4) https://godotengine.org/releases/4.4/
- **Animation markers** untuk lompat/loop sub-bagian animasi, juga di AnimationTree. (4.4)
- **`Tween.tween_await()`** menjeda tween sampai sinyal dipancarkan. (4.7) https://godotengine.org/releases/4.7/
- **`Control.offset_transform_*`** — geser/putar/skala Control tanpa diganggu container (cocok untuk animasi kartu). (4.7)
- **`Control.pivot_offset_ratio`**. (4.6) https://godotengine.org/releases/4.6/
- Fokus mouse dan keyboard dipisah: klik tombol tidak lagi memunculkan outline fokus. (4.6)
- `focus_behavior_recursive` / `mouse_behavior_recursive` untuk mematikan input satu subtree Control. (4.5)
- Garis `draw_line` tidak lagi diberi feather antialiasing — pakai lebar lebih tebal. (4.7)

## Android

- **16 KB page size** didukung bawaan sejak 4.5. https://godotengine.org/releases/4.5/
- **Edge-to-edge** export option. (4.5)
- **Swappy frame pacing** otomatis. (4.4) https://godotengine.org/releases/4.4/
- Splash screen bisa diatur di export options. (4.7) https://godotengine.org/releases/4.7/
- Detail SDK, Gradle, dan notifikasi aplikasi: [modules/android-export.md](modules/android-export.md)

## NOT SOURCEABLE

- Perubahan Tween di 4.4–4.6 — tidak disebut di halaman rilis yang dibaca.
- Perubahan khusus renderer Compatibility di 4.6/4.7 — lihat [modules/rendering.md](modules/rendering.md).
