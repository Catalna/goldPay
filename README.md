# GoldPay

Prototipe konsep Android untuk membayar QRIS dengan konversi **emas digital yang disimulasikan**.

> **Bukan pembayaran sungguhan.** GoldPay tidak terhubung ke Pegadaian, PJP, bank, atau jaringan apa pun.
> Merchant tidak menerima dana, tidak ada emas yang dijual, dan tidak ada uang yang berpindah.
> Aplikasi ini tidak berafiliasi dengan Pegadaian.

## Apa yang nyata dan apa yang simulasi

| Nyata | Disimulasikan |
|---|---|
| Kamera dan decoding QR | Penjualan emas |
| Parser subset EMVCo/QRIS (byte-based) | Otorisasi pembayaran |
| Perhitungan konversi integer | Settlement QRIS dan notifikasi merchant |
| Pemotongan saldo demo lokal | Harga emas (angka tetap, bukan harga pasar) |
| Receipt dan riwayat lokal | — |

Tidak ada `INTERNET` di APK release; tidak ada analytics, login, KYC, atau API eksternal.

## Stack

- Flutter 3.50 / Dart 3.14, Android saja (`minSdk 24`, lihat D-46).
- `flutter_riverpod`, `go_router`, `mobile_scanner`, `image_picker` (fallback galeri),
  `shared_preferences`, `uuid`, `intl`.
- Font Plus Jakarta Sans dibundel dari `assets/fonts/` (SIL Open Font License, lihat `OFL.txt`).
  Tidak memakai `google_fonts`.

## Menjalankan

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d <device-id>
flutter build apk --release
apkanalyzer manifest permissions build\app\outputs\flutter-apk\app-release.apk
```

Perintah terakhir harus **tidak** menampilkan `android.permission.INTERNET`.

## Struktur

```text
docs/              spesifikasi dan keputusan (sumber kebenaran)
lib/domain/        pure Dart: parser, kalkulator, orchestrator
lib/data/          repository, codec, migrasi
lib/features/*/    presentation + application (controller Riverpod)
lib/core/          copy, formatter, result/failure, widget bersama
assets/fonts/      Plus Jakarta Sans + lisensi
assets/test_qris/  fixture QR F01–F10 (layar & cetak)
```

Mulai dari [`docs/README.md`](docs/README.md), lalu
[`docs/00_DECISION_LOG.md`](docs/00_DECISION_LOG.md). Jika dokumen saling bertentangan,
decision log yang menang. Aturan kerja: [`AGENTS.md`](AGENTS.md).

## Lisensi

Kode prototipe ini disediakan untuk keperluan demonstrasi konsep. Font Plus Jakarta Sans
dilisensikan terpisah di bawah SIL OFL 1.1 (`assets/fonts/OFL.txt`).
