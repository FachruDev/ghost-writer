# ADR-0001: Renderer Compatibility (GLES3)

## Status
Proposed

## Date
2026-11-05

## Last Verified
2026-11-05

## Decision Makers
Pengembang (FchDxCode), dengan Claude

## Summary
Ghostwriter perlu satu renderer tetap sebelum setup project, karena `project.godot` masih memakai `mobile` (Vulkan) sementara checklist menyebut Compatibility lebih aman. Diputuskan: renderer **Compatibility (OpenGL ES 3.0)** untuk semua platform, karena game ini 2D flat dan butuh jangkauan HP Android seluas mungkin.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7 |
| **Domain** | Rendering |
| **Layer** | Foundation |
| **Knowledge Risk** | MEDIUM — `docs/engine-reference/` belum ada; Godot 4.7 tidak bisa diverifikasi dari pengetahuan model saja |
| **References Consulted** | [Overview of renderers (4.7)](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html), [Maintenance release 4.5.2](https://godotengine.org/article/maintenance-release-godot-4-5-2/) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Shader `canvas_item` dan efek animasi yang direncanakan berjalan sama di build Android Compatibility; ±300 titik warga tetap lancar di HP kelas bawah |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | None |
| **Blocks** | Setup (sebelum 0.1.0): pengaturan renderer di Project Settings dan ekspor Android pertama |
| **Ordering Note** | Putuskan sebelum shader, partikel, atau efek visual pertama dibuat; ganti renderer setelahnya bisa memaksa menulis ulang efek |

## Context

### Problem Statement
`project.godot` dibuat dengan renderer `mobile` (Vulkan), sementara `CHECKLIST.md` menyebut "Mobile atau Compatibility". Keputusan ini menentukan efek visual apa yang boleh dipakai dan HP mana yang didukung, jadi harus tetap sebelum kode visual pertama ditulis.

### Constraints
- Game 2D flat portrait: kartu, ikon, titik warga, panel UI (`konsep-game.md`)
- Target Android, PC menyusul
- Dikerjakan solo paruh waktu; tidak ada waktu untuk men-debug masalah driver per perangkat
- Pasar Indonesia: banyak pemain casual memakai HP menengah ke bawah

### Requirements
- Harus jalan stabil di minimal 2 HP berbeda, satu kelas bawah (`CHECKLIST.md` 0.9.0)
- Harus mendukung semua animasi di `aset/animasi.md`: Tween, AnimationPlayer, sprite animation, shader `canvas_item`
- Harus mampu menggambar ratusan titik warga yang berdenyut tanpa lag

## Decision

Pakai renderer **Compatibility** untuk desktop dan mobile.

Pengaturan di `project.godot`:

```
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
```

`rendering_device/driver.windows="d3d12"` dan `3d/physics_engine="Jolt Physics"` tidak relevan untuk game 2D ini dan boleh dihapus.

### Architecture Diagram
```
Scene 2D (Control / Node2D / _draw)
        │
   CanvasItem + shader canvas_item
        │
Renderer Compatibility ── OpenGL ES 3.0 (Android) / OpenGL 3.3 (PC)
```

### Key Interfaces
None — keputusan ini tidak membuat API kode. Yang dibuat adalah batasan fitur di bawah.

### Implementation Guidelines
- Kode visual **must** bekerja di Compatibility; uji di HP sungguhan, bukan hanya di editor PC.
- Shader **must** berupa `shader_type canvas_item` dan **must never** memakai compute shader atau `RenderingDevice`.
- **Must never** bergantung pada MSAA 2D atau HDR 2D; untuk tepi halus, pakai aset SVG/tekstur dengan filter linear.
- Partikel **should** memakai `CPUParticles2D`; `GPUParticles2D` hanya jika sudah diuji di HP kelas bawah.
- Titik warga **must** digambar lewat `_draw()` satu node per distrik (atau MultiMesh) setelah jumlahnya lebih dari ±100, bukan satu node per warga.
- Glow atau efek post-process **must** diuji di Android sebelum dipakai di gameplay.

## Alternatives Considered

- **Mobile (Vulkan)** — dapat MSAA 2D, HDR 2D, glow lebih kaya. Ditolak: tidak ada efek yang direncanakan yang membutuhkannya, dan Vulkan punya riwayat masalah driver di Android (HP sebelum ±2020 dan HP murah).
- **Mobile + fallback otomatis ke OpenGL3** — mencoba Vulkan, jatuh ke GLES3 jika tidak didukung. Ditolak: dua jalur render berarti setiap efek harus diuji dua kali, dan fallback tidak menangkap driver yang mendukung Vulkan tapi bermasalah.

## Consequences

### Positive
- Jalan di hampir semua HP Android yang masih dipakai, lancar juga di HP baru
- Lebih ringan dan hemat baterai untuk game yang dibuka lama
- Satu jalur render untuk diuji

### Negative
- Tidak ada MSAA 2D dan HDR 2D
- Fitur render baru Godot biasanya masuk ke Mobile/Forward+ lebih dulu

## Risks
- **Efek yang diinginkan nanti ternyata butuh Mobile.** Mitigasi: uji setiap efek baru di Android sejak dibuat; kalau benar-benar perlu, tulis ADR baru yang menggantikan ADR ini sebelum efek itu dipakai.
- **Tanpa engine-reference, detail fitur 4.7 belum terverifikasi.** Mitigasi: jalankan `/setup-engine` lalu cek ulang ADR ini (perbarui Last Verified).
- **Bug Compatibility di versi Godot lama.** Mitigasi: pakai rilis patch 4.7 terbaru (4.5.2 sudah membawa perbaikan crash Compatibility).

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| konsep-game.md (belum ada GDD) | Gaya visual 2D flat: ikon, kartu, titik warga | Compatibility mendukung seluruh rendering 2D yang dibutuhkan |
| aset/animasi.md | Animasi mesin tik, kartu ke slot, denyut warga, banner | Semua berbasis Tween/AnimationPlayer/`canvas_item`, tersedia di Compatibility |
| CHECKLIST.md 0.9.0 | Tanpa crash di 2+ HP, satu kelas bawah | Renderer dengan dukungan hardware paling luas |

## Performance Implications
- **CPU**: Netral; beban terbesar ada di `SpreadSim`, bukan renderer
- **Memory**: Lebih kecil dari Mobile
- **Load Time**: Lebih cepat; tidak ada kompilasi pipeline Vulkan
- **Network**: Tidak berlaku

## Migration Plan
Belum ada kode. Ganti dua pengaturan di `project.godot` (atau lewat Project Settings → Rendering → Renderer), lalu restart editor.

## Validation Criteria
- APK debug terpasang dan jalan di HP sendiri dan satu HP kelas bawah
- ±300 titik warga berdenyut dengan frame rate stabil (target 60 fps, minimal 30 fps di HP kelas bawah)
- Semua animasi 0.2.0 tampil sama di editor PC dan di HP

## Related
- [konsep-game.md](../panduan/konsep-game.md) — keputusan teknis (perlu diubah dari "renderer Mobile" ke "Compatibility")
- [CHECKLIST.md](../versi/1.0.0/mvp/CHECKLIST.md) — Setup, 0.9.0 Teknis
- [aset/animasi.md](../versi/1.0.0/aset/animasi.md)
