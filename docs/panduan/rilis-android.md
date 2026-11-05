# Panduan Rilis Android — Ghostwriter

Langkah dari build sampai tayang di Play Store. Dipakai di versi 1.0.0, tetapi keystore dan pengumpulan tester sebaiknya disiapkan jauh sebelumnya.

**Build**

- [ ] Buat **release keystore** dan simpan cadangannya di dua tempat aman. Kehilangan keystore = tidak bisa update aplikasi
- [ ] Export sebagai **AAB** (Android App Bundle), bukan APK, untuk Play Store
- [ ] Pastikan **target SDK = API 36 (Android 16)**. Sejak 31 Agustus 2026, Google Play mewajibkan aplikasi baru dan update menargetkan API 36. Jika default versi Godot-mu lebih rendah, aktifkan *Use Gradle Build* dan atur target SDK secara manual
- [ ] Ikon aplikasi (adaptive icon), nama aplikasi, nomor versi `1.0.0`

**Play Console**

- [ ] Daftar akun developer Google Play (biaya sekali bayar US$25)
- [ ] Siapkan halaman privacy policy (bisa halaman sederhana di website sendiri)
- [ ] Isi kuesioner rating konten. Karena temanya satir politik, pastikan semua fiktif
- [ ] Store listing: deskripsi singkat dan panjang, minimal 2 screenshot portrait, feature graphic 1024×500

**Closed testing — rencanakan sejak awal**

Akun developer **personal** yang dibuat setelah 13 November 2023 wajib menjalankan closed test dengan **minimal 12 tester yang ikut terus-menerus selama 14 hari** sebelum bisa mengajukan akses produksi. Hitung sekitar 3 minggu untuk rilis pertama.

- [ ] Kumpulkan 15–25 tester sejak Fase 2 (teman kampus, komunitas Godot/gamedev Indonesia) supaya aman jika ada yang keluar
- [ ] Upload build ke track closed testing, bagikan link opt-in
- [ ] Setelah 14 hari, ajukan akses produksi, lalu kirim untuk review
