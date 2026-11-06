# Event — Ghostwriter v1.0.0

Event membuat setiap sesi terasa berbeda: kota tidak diam menunggu rumor pemain, tetapi punya kejadiannya sendiri. Versi 1.0.0 menargetkan **12 event**, dengan **3 event sudah masuk di MVP (0.2.0)**.

## Cara kerja

Semua event adalah data di `res://data/events.json`, dijalankan oleh `scenes/main/event_controller.gd`. Menambah event baru cukup menambah satu entri JSON, kecuali event dengan efek khusus.

| Jenis | Cara muncul | Contoh |
| --- | --- | --- |
| Modifier | Acak, peluang dicek tiap N detik | Hari Pasar: distrik tertentu lebih mudah tertular |
| Ancaman | Dipicu kondisi (heat, kredibilitas) | Pembongkar Fakta muncul saat heat tinggi |
| Dilema | Acak, pemain memilih A atau B | Wartawan menawarkan diam asal dibayar |
| Peluang | Acak atau milestone | Dokumen bocor: kartu SUMBER langka sementara |

Aturan umum:

- Maksimal **1 event aktif** di satu waktu (kecuali ancaman yang dipicu kondisi).
- Jeda minimal antar event acak: 180 detik; ancaman (mis. Pembongkar Fakta) berjalan di jalur sendiri dengan jeda 120 detik dan tidak menimpa event acak (atur di `balance.gd`).
- Setiap event tampil sebagai **banner** di atas peta + ikon jenis event + sisa durasi.
- Event dilema **menjeda waktu** sampai pemain memilih.

## Format data

Teks yang tampil ke pemain (`nama`, `teks`, `pilihan[].label`) ditulis per bahasa sesuai [ADR-0004](../../../architecture/adr-0004-lokalisasi.md). Field `en` boleh kosong sampai 0.9.0. Durasi dan jeda dalam detik simulasi ([ADR-0003](../../../architecture/adr-0003-model-waktu.md)).

```json
{
  "id": "e_hari_pasar",
  "nama": {"id": "Hari Pasar", "en": "Market Day"},
  "jenis": "modifier",
  "era_min": 1,
  "pemicu": {"tipe": "acak", "peluang": 0.15},
  "durasi": 60,
  "teks": {"id": "Pasar Lama sedang ramai. Gosip menyebar lebih cepat di sana!",
           "en": "The Old Market is packed. Gossip spreads faster there!"},
  "efek": [{"tipe": "kerentanan_distrik", "distrik": "pasar_lama", "kali": 1.5}],
  "pilihan": []
}
```

Contoh event dilema (`pilihan` diisi):

```json
{
  "id": "e_wartawan",
  "nama": {"id": "Wartawan Penasaran", "en": "Curious Reporter"},
  "jenis": "dilema",
  "era_min": 2,
  "pemicu": {"tipe": "acak", "peluang": 0.08, "syarat": {"heat_min": 40}},
  "durasi": 0,
  "teks": {"id": "Seorang wartawan mencium jejakmu. Dia mau diam... asal ada imbalan.",
           "en": "A reporter has picked up your trail. They'll stay quiet... for a price."},
  "efek": [],
  "pilihan": [
    {"label": {"id": "Bayar dia", "en": "Pay up"}, "efek": [{"tipe": "uang", "nilai": -200}, {"tipe": "heat", "nilai": -30}]},
    {"label": {"id": "Abaikan", "en": "Ignore"}, "efek": [{"tipe": "heat", "nilai": 20}, {"tipe": "pengikut", "nilai": 50}]}
  ]
}
```

## Daftar event v1.0.0

| ID | Nama | Jenis | Era | Pemicu | Efek singkat | Masuk di versi | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E01 | Hari Pasar | Modifier | 1 | Acak | Kerentanan Pasar Lama ×1,5 selama 60 dtk | 0.2.0 (MVP) | Selesai |
| E02 | Ronda Malam | Modifier | 1 | Acak | Rumor emosi *takut* ×1,5 di Gang Sempit, emosi *lucu* ×0,7 | 0.2.0 (MVP) | Selesai |
| E03 | Pembongkar Fakta | Ancaman | 1 | Heat ≥ 70 | Warga di sekitar pembongkar jadi kebal; kredibilitas −10 | 0.2.0 (MVP) | Selesai |
| E04 | Pemilihan Ketua RT | Peluang | 1 | Milestone 300 pengikut (sekali) | Kartu calon fiktif Pak Darto dan Bu Wati masuk ke tangan; selama 90 dtk rumor tentang mereka bernilai ×2, heat ×1,5 | 0.3.0 | Selesai |
| E05 | Wartawan Penasaran | Dilema | 2 | Acak, heat ≥ 40 | Bayar (uang −, heat −) atau abaikan (heat +, pengikut +) | 0.3.0 | Selesai |
| E06 | Festival Kampung | Modifier | 2 | Acak | Semua distrik kerentanan ×1,2, uang per warga ×1,5 | 0.3.0 | Selesai |
| E07 | Dokumen Bocor | Peluang | 2 | Acak | Kartu SUMBER "dokumen bocor" (kred 3) gratis untuk 3 rumor | 0.4.0 | Belum |
| E08 | Viral Challenge | Modifier | 3 | Acak | Template lucu ×2 viral, tapi kredibilitas semua rumor −1 | 0.4.0 | Belum |
| E09 | Razia Hoaks | Ancaman | 3 | Kredibilitas < 30 | Saluran medsos dikunci 90 dtk, pengikut −5% | 0.4.0 | Belum |
| E10 | Rumor Tandingan | Ancaman | 3 | Acak | Media saingan menyebar rumor yang membuat warga "ragu" | 0.5.0 | Belum |
| E11 | Server Down | Dilema | 4 | Acak | Bayar perbaikan cepat atau kehilangan staf otomatis 120 dtk | 0.5.0 | Belum |
| E12 | Kota Tak Percaya Lagi | Ancaman (final) | 4 | Kampanye akhir dimulai | Kebal menyebar sendiri; pemain harus mencapai target sebelum kota "mati rasa" | 0.6.0 | Belum |

## Catatan desain

- Semua nama tokoh, partai, dan kandidat di event **fiktif**.
- Event ancaman adalah sumber ketegangan utama; jangan dibuat terlalu jarang.
- Saat balancing, catat seberapa sering tiap event muncul per sesi 15 menit (target: 2–4 event).
