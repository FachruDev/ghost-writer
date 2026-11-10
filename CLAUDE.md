# Ghostwriter

Game satir portrait untuk Android (Godot). Desain di `docs/panduan/konsep-game.md`, roadmap di `docs/versi/1.0.0/mvp/mvp-v1.md`, keputusan arsitektur di `docs/architecture/adr-*.md`.

## Technology Stack

- **Engine**: Godot 4.7.2
- **Language**: GDScript
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

Konfigurasi proyek: `project.yaml` (utama) dan `.claude/docs/technical-preferences.md` (cermin).

## Engine Version Reference

Godot 4.7 berada di luar data latih yang bisa diandalkan. Cek referensi ini sebelum menyarankan API; kalau ragu, verifikasi di dokumentasi resmi 4.7.

<!-- ENGINE-REFERENCE-IMPORT: setup-engine rewrites the line below -->
@docs/engine-reference/godot/VERSION.md

## Aturan kode

- File script dan scene memakai `snake_case` (`word_card.tscn`, `rumor_scorer.gd`); class tetap `PascalCase`.
- Modular: satu tanggung jawab per script. Batas lunak ±300 baris per file; kalau lewat, pecah ke file baru.
- Ikuti ADR berstatus Accepted di `docs/architecture/`. ADR berstatus Proposed belum mengikat.
- Teks yang tampil ke pemain ada di file data (`res://data/`), bukan di kode.
