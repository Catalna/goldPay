# GoldPay — Documentation Pack

> **Prototype concept only.** GoldPay adalah konsep fitur untuk pengalaman Pegadaian Tring!, sedangkan
> dokumentasi ini menjelaskan demo Android mandiri. Prototipe ini bukan aplikasi resmi Pegadaian,
> tidak berafiliasi dengan Pegadaian, tidak menjual emas, dan tidak melakukan pembayaran QRIS.

## Vision

Pindai QRIS merchant dengan kamera ponsel, baca payload jika didukung, masukkan nominal jika tidak
tercantum, hitung emas yang diperlukan, konfirmasi transaksi yang disimulasikan, potong **saldo demo
lokal**, lalu hasilkan receipt dan riwayat.

## Batas MVP

- **Nyata:** kamera, decoding QR, parser subset EMV/QRIS, perhitungan konversi, pemotongan saldo demo,
  riwayat dan receipt lokal.
- **Disimulasikan:** penjualan emas, otorisasi pembayaran, settlement QRIS, notifikasi merchant.
- **Tidak ada:** API Pegadaian, integrasi PJP/bank, dana nyata, verifikasi merchant, harga langsung,
  login/KYC, optimasi likuiditas, split funding.

## Dokumen

| # | File | Isi |
|---|---|---|
| 00 | `00_DECISION_LOG.md` | **Keputusan final. Baca pertama. Menang atas dokumen lain.** |
| 01 | `01_PRODUCT_REQUIREMENTS.md` | PRD, persona, FR/NFR, kriteria penerimaan |
| 02 | `02_SCOPE_ASSUMPTIONS_CONSTRAINTS.md` | Scope, hal yang sengaja ditolak, asumsi |
| 03 | `03_SYSTEM_ARCHITECTURE.md` | Layer, folder, DI, ADR, batas error |
| 04 | `04_ANTIGRAVITY_FLUTTER_SETUP.md` | Setup Flutter, font, manifest, locale |
| 05 | `05_PHYSICAL_ANDROID_DEVICE_SETUP.md` | Perangkat fisik, izin, APK, bukti offline |
| 06 | `06_USER_JOURNEYS_AND_FLOWS.md` | Alur utama, statis/dinamis, fallback, gagal |
| 07 | `07_QRIS_PARSER_SPEC.md` | TLV berbasis byte, tag, CRC, kode error |
| 08 | `08_GOLD_CONVERSION_DEMO_TRANSACTION.md` | Satuan, rumus, pembulatan, quote, transaksi |
| 09 | `09_UI_UX_SCREEN_SPEC.md` | Design token, tipografi, wireframe, aksesibilitas |
| 10 | `10_DATA_MODEL_LOCAL_STORAGE.md` | Model, JSON, commit atomik, pemulihan |
| 11 | `11_TRANSACTION_STATE_MACHINE.md` | State, guard, crash matrix, idempotensi |
| 12 | `12_TESTING_QA_PLAN.md` | Unit, widget, fuzz, perangkat, checklist rilis |
| 13 | `13_LIVE_DEMO_SCRIPT.md` | Pre-flight, naskah 60–90 detik, fallback |
| 14 | `14_REGULATORY_RISK_DEMO_BOUNDARIES.md` | Risiko, area regulasi, guardrail |
| 15 | `15_IMPLEMENTATION_ROADMAP.md` | Milestone M0–M8 dan gate |
| 16 | `16_ANTIGRAVITY_PROMPT_GUIDE.md` | Prompt per milestone untuk AI |
| 17 | `17_BUSINESS_CASE_AND_SETTLEMENT.md` | Jalur settlement, ekonomi, FAQ penguji |
| 18 | `18_UI_COPY_ID.md` | **Semua teks UI. Satu sumber, tanpa variasi.** |
| 19 | `19_TEST_QR_FIXTURES.md` | Payload F01–F10 dengan CRC valid |

Urutan baca: **00 → 01 → 02 → 03**, lalu `AGENTS.md`, lalu dokumen spesifikasi saat mengerjakan
milestone terkait (lihat `15`).

## Baseline teknologi

Flutter + Dart, Riverpod (tanpa codegen), GoRouter, `mobile_scanner`, `intl`, `shared_preferences`,
`uuid`. Font Plus Jakarta Sans di-bundle sebagai asset. **Tanpa** `google_fonts`, tanpa HTTP/Firebase,
tanpa analytics. APK release tanpa permission `INTERNET`.

Periksa versi paket saat setup (`flutter pub add`); jangan menyalin pin versi dari dokumen.

## Prinsip kejujuran proyek

- Hasil scan bukan bukti QR valid, dapat dibayar, atau milik merchant tertentu.
- CRC adalah pemeriksaan integritas, bukan autentikasi.
- Transaksi demo tidak pernah berarti merchant dibayar. Banner DEMO wajib terlihat.
- Harga adalah simulasi. Konversi memakai harga buyback simulasi, bukan harga pasar.
- Tidak ada data pribadi, payload QR, atau gambar yang disimpan.
- Jangan memakai logo/aset Pegadaian atau mengklaim afiliasi.

## Struktur proyek yang diusulkan

```text
goldPay/                       # repo ini — root proyek Flutter
├── AGENTS.md                  # aturan kerja untuk AI & manusia
├── docs/                      # dokumentasi ini
├── assets/
│   ├── fonts/                 # Plus Jakarta Sans + OFL
│   └── test_qris/             # fixture QR (F01–F10, layar & cetak)
├── lib/                       # lihat 03_SYSTEM_ARCHITECTURE.md
├── test/                      # cermin lib/domain, lib/data
└── pubspec.yaml
```

## Bukti bawaan

- `assets/test_qris/` berisi 20 PNG (10 fixture × 2 ukuran) yang dibuat langsung dari payload di
  `19_TEST_QR_FIXTURES.md`. CRC sudah diverifikasi.
- `F03` sengaja memakai nama non-ASCII untuk menangkap bug `String.length` vs panjang byte UTF-8.

## Mulai

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d <device-id>
```

Lihat `04` dan `05` untuk setup lengkap, `15` untuk urutan pengerjaan, dan `13` untuk latihan demo.
