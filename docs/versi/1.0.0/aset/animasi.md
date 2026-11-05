# Animasi — Ghostwriter v1.0.0

Sebagian besar animasi cukup memakai **Tween** (gerak, skala, warna, transparansi). `AnimationPlayer` dipakai untuk urutan yang lebih panjang seperti transisi era. Prinsipnya: setiap aksi pemain harus terlihat responnya dalam 0,1 detik.

| ID | Kapan | Cara di Godot | Durasi | Versi | Status |
| --- | --- | --- | --- | --- | --- |
| anim_typewriter | Headline diketik setelah KIRIM | `Label.visible_ratio` / `visible_characters` + SFX per huruf | 1–2 dtk | 0.2.0 | Selesai |
| anim_card_to_slot | Kartu dipilih | Tween posisi dari tangan ke slot + sedikit rotasi | 0,2 dtk | 0.2.0 | Selesai |
| anim_card_press | Kartu disentuh | Tween skala 1,0 → 0,95 → 1,0 | 0,1 dtk | 0.2.0 | Selesai |
| anim_citizen_pulse | Warga tertular | Lingkaran membesar & memudar di titik warga | 0,3 dtk | 0.2.0 | Selesai |
| anim_money_float | Uang masuk | Label "+Rp" naik dan memudar | 0,6 dtk | 0.2.0 | Selesai |
| anim_event_banner | Event mulai/selesai | Banner turun dari atas, naik saat selesai | 0,3 dtk | 0.2.0 | Selesai |
| anim_debunk_stamp | Pembongkar fakta beraksi | Stempel HOAKS skala 2 → 1 + getar layar kecil | 0,25 dtk | 0.2.0 | Selesai |
| anim_send_paper | Rumor dikirim | Kertas/merpati terbang dari meja ke peta | 0,5 dtk | 0.3.0 | Belum |
| anim_headline_mutate | Rumor bermutasi | Kata di feed berkedip lalu berganti | 0,4 dtk | 0.3.0 | Belum |
| anim_shop_open | Toko dibuka | Panel meluncur dari bawah | 0,25 dtk | 0.3.0 | Belum |
| anim_button_feedback | Semua tombol | Skala tekan + warna | 0,1 dtk | 0.3.0 | Belum |
| anim_staff_working | Staf otomatis menulis | Ikon staf mengetik kecil di HUD | loop | 0.4.0 | Belum |
| anim_era_transition | Naik era | Meja lama memudar, kamera naik, meja baru muncul | 2–3 dtk | 0.5.0 | Belum |
| anim_ending | Ending | Kota memudar ke abu-abu titik demi titik | 5–8 dtk | 0.6.0 | Belum |
| anim_tutorial_hand | Tutorial | Tangan menunjuk kartu/slot | loop | 0.9.0 | Belum |

**Aturan**

- Jangan menahan input selama animasi kecuali transisi era dan ending.
- Batasi jumlah animasi titik warga yang berjalan bersamaan (misalnya 30) supaya HP kelas bawah tetap lancar.
