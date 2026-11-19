# AGENTS.md

Aturan kerja untuk siapa pun (manusia atau AI coding agent) yang mengubah proyek ini.
**Baca `docs/00_DECISION_LOG.md` lebih dulu.** Jika instruksi bertentangan dengan file itu,
`00_DECISION_LOG.md` yang menang.

## Proyek ini apa

Prototipe konsep Android (Flutter) untuk membayar QRIS dengan konversi emas digital **yang
disimulasikan**. Tidak ada dana, tidak ada jaringan, tidak ada afiliasi dengan Pegadaian.

## Batasan keras (jangan dilanggar)

1. **Tanpa network.** Tidak ada `http`, `dio`, `firebase`, analytics, atau API apa pun.
   `android.permission.INTERNET` dihapus dari manifest release.
2. **Tanpa `google_fonts`.** Font dari `assets/fonts/`.
3. **Tanpa uang sebagai `double`.** Rupiah = `int`; emas = `int` unit `0,0001 g`.
4. **Tanpa mengarang data merchant.** Tampilkan hanya field yang berhasil di-parse.
5. **Tanpa klaim palsu.** Dilarang: "lunas", "berhasil dibayar", "terverifikasi", "merchant menerima
   dana". Banner DEMO wajib tampil.
6. **Tanpa menyimpan payload QR**, PAN merchant, gambar, atau data pribadi.
7. **Hanya `completed_demo` yang dipersist.** `processing_demo` tidak pernah ditulis ke storage.
8. **Tanpa mengubah keputusan.** Jika butuh keputusan baru, tambahkan entri di
   `docs/00_DECISION_LOG.md` dan minta persetujuan — jangan mengarang.

## Struktur

```text
lib/domain/      pure Dart: parser, kalkulator, orchestrator, entities. TANPA impor Flutter.
lib/data/        repository SharedPreferences, codec, migrasi.
lib/features/*/  presentation + application (controller Riverpod).
lib/core/        constants (copy_id), formatters, result/failure, widget bersama.
docs/            spesifikasi. Sumber kebenaran.
assets/test_qris/ fixture QR.
```

Detail: `docs/03_SYSTEM_ARCHITECTURE.md`.

## Perintah

```powershell
flutter pub get
flutter analyze
flutter test
flutter test test/domain/qris
flutter test test/domain/pricing
flutter run -d <device-id>
flutter build apk --release
apkanalyzer manifest permissions build\app\outputs\flutter-apk\app-release.apk
```

Selalu jalankan `flutter analyze` dan test yang relevan **sebelum** melaporkan selesai. Lampirkan
output, bukan ringkasan.

## Konvensi kode

- Dart 3: gunakan `sealed class`, `final class`, pattern matching untuk `Result`.
- Flutter 3.47+: impor Material dari `package:material_ui/material_ui.dart`; `package:flutter/material.dart`
  sudah deprecated. Jangan mencampur keduanya.
- Domain tidak boleh `throw` untuk input pengguna; kembalikan `QrisFailure`/`Err`.
- Uang/emas: `int`. Pembulatan: `ceilDiv(a, b) => (a + b - 1) ~/ b`.
- Parser bekerja pada `Uint8List`; panjang TLV = **byte UTF-8**, bukan `String.length`.
- Semua teks UI dari `lib/core/constants/copy_id.dart`, selaras `docs/18_UI_COPY_ID.md`.
  Jangan menulis string literal di widget.
- Formatter hanya di `lib/core/formatters`.
- Nama metode transaksi tidak boleh menyiratkan pembayaran nyata (`simulateDemoPayment`, bukan `pay`).
- Tidak ada file di luar struktur yang disetujui tanpa alasan tertulis.

## Alur kerja

1. Baca `docs/00_DECISION_LOG.md` + dokumen milestone.
2. Inspeksi file yang ada; sebutkan file yang akan diubah.
3. Kerjakan **satu milestone** (`docs/15_IMPLEMENTATION_ROADMAP.md`).
4. Tambahkan/ubah test lebih dulu atau bersamaan.
5. Jalankan analyzer + test. Perbaiki sampai hijau.
6. Laporkan: file berubah, hasil perintah, hal yang belum selesai.

## Definition of Done (ringkas)

- Analyzer bersih, test lulus, fuzz parser lulus.
- F01–F10 sesuai `docs/19_TEST_QR_FIXTURES.md`.
- Angka gram yang tampil = unit yang dipotong.
- Konfirmasi ganda = satu transaksi; gagal = saldo utuh.
- Saldo/history konsisten setelah restart.
- APK release tanpa permission `INTERNET` (dibuktikan dengan output perintah).
- Tidak ada copy disclosure baru di luar `docs/18_UI_COPY_ID.md`.

## Commit

Format: `feat(scanner): ...`, `fix(parse): ...`, `test(pricing): ...`, `docs: ...`.
Satu commit = satu perubahan bermakna. Jangan commit `build/`, `.dart_tool/`, atau artefak APK.
