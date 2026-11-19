# 15 — Implementation Roadmap

> Aturan: satu milestone = satu sesi kerja, satu gate yang bisa dibuktikan. Jangan lanjut sebelum
> gate lulus. Estimasi dalam hari kerja efektif.

## M0 — Lingkungan dan konfirmasi keputusan (0,5 hari)

**Deliverable**

- Flutter stable, Android SDK, perangkat terdeteksi.
- `flutter doctor -v` bersih untuk Android.
- Repo diinisialisasi **di folder proyek**, bukan di folder home.
- `00_DECISION_LOG.md` dibaca dan disetujui.

**Gate:** `flutter devices` menampilkan perangkat fisik; starter app berjalan di perangkat.

## M1 — Scaffold, token, dan copy (1 hari)

**Deliverable**

- Struktur folder sesuai `03_SYSTEM_ARCHITECTURE.md`.
- `tokens.dart`, `theme.dart` (Plus Jakarta Sans dari `assets/fonts/`).
- `copy_id.dart` lengkap mengacu `18_UI_COPY_ID.md`.
- Router + Home (saldo statis, harga simulasi, banner DEMO).

**Gate:** `flutter analyze` bersih; Home tampil di perangkat; tidak ada `google_fonts` di
`pubspec.yaml`; text scale 1,3 tidak overflow.

## M2 — Scanner (1 hari)

**Deliverable**

- `mobile_scanner` dengan `autoStart: false`, `DetectionSpeed.noDuplicates`.
- Izin kamera + layar penolakan + jalur pengaturan.
- Lifecycle (`WidgetsBindingObserver`), stop setelah satu hasil.
- Torch, cancel, error kamera.

**Gate:** satu QR terbaca tepat satu kali; kamera berhenti saat back; tidak ada kamera aktif di
background.

## M3 — Parser dan fixture (2 hari)

**Deliverable**

- `crc16.dart`, `tlv.dart`, `qris_parser.dart` (pure Dart, byte-based).
- `QrisSuccess`/`QrisFailure`, sanitasi, tip/fee, issuer GUI.
- Unit test F01–F10 + fuzz 10.000.

**Gate:** seluruh test parser lulus; F03 membuktikan penanganan byte; fuzz tanpa exception.

## M4 — Review QR, nominal, fallback (1 hari)

**Deliverable**

- Layar review: merchant/kota/penerbit/jenis/CRC/warning.
- Statis: input nominal berformat; dinamis: read-only.
- Jalur galeri (`analyzeImage`) dan tempel payload di Demo Settings.
- Label sumber (kamera/galeri/tempel).

**Gate:** F01 dan F02 masing-masing sampai ke layar review dengan perilaku nominal yang benar;
fallback menghasilkan `source` yang tepat.

## M5 — Quote, presisi, kedaluwarsa (1,5 hari)

**Deliverable**

- `GoldConversionCalculator` (integer, `ceilDiv`).
- Quote 5 menit + status `expired` + refresh.
- Validasi saldo/min/max + kekurangan dalam Rp dan gram.
- Baris biaya QR, harga buyback, pembulatan, sisa saldo.

**Gate:** property test ceil lulus; contoh 150.000 → 1.021 unit; angka tampil = unit tersimpan;
konfirmasi diblokir saat kedaluwarsa.

## M6 — Transaksi dan penyimpanan (2 hari)

**Deliverable**

- `PrefsDemoRepository` + `DemoStateCodec`.
- Commit: `_prev` → main → readback → update state.
- Lock, `attemptId`, dedupe.
- Toggle gagal simulasi.
- Uji crash matrix (`11_TRANSACTION_STATE_MACHINE.md` §5).

**Gate:** konfirmasi ganda = satu record; gagal = saldo utuh; rusak `main` pulih dari `_prev`.

## M7 — Receipt, history, reset, saldo (1 hari)

**Deliverable**

- Result/receipt dari record tersimpan.
- History + detail + empty state.
- Reset dengan konfirmasi; tambah saldo demo.
- Settings lengkap dengan label "kontrol demo".

**Gate:** restart mempertahankan saldo/history; reset benar; 201 transaksi → 200 tersimpan.

## M8 — QA, bukti, dan rilis (1,5 hari)

**Deliverable**

- `flutter analyze` + seluruh test lulus.
- Bukti tanpa permission `INTERNET`.
- Matriks perangkat + mode pesawat.
- APK release + QR cetak + latihan 2×.

**Gate:** checklist `12_TESTING_QA_PLAN.md` §12 tercentang dengan bukti (perintah + output), dan
`13_LIVE_DEMO_SCRIPT.md` dijalankan penuh tanpa intervensi.

## Ringkasan

| Milestone | Hari | Risiko utama |
|---|---|---|
| M0 | 0,5 | Toolchain/device |
| M1 | 1 | Font/locale |
| M2 | 1 | Lifecycle kamera |
| M3 | 2 | Salah tafsir panjang TLV |
| M4 | 1 | State nominal statis vs dinamis |
| M5 | 1,5 | Presisi/pembulatan |
| M6 | 2 | Konsistensi commit |
| M7 | 1 | Konsistensi receipt vs record |
| M8 | 1,5 | Waktu & pencahayaan venue |
| **Total** | **± 11,5** | |

## Definition of Done

Prototipe selesai ketika:

1. Pemindaian kamera nyata bekerja di perangkat target.
2. F01–F10 berperilaku sesuai `19_TEST_QR_FIXTURES.md`.
3. Konversi integer konsisten, angka tampil = angka potong.
4. Hanya transaksi sukses yang tersimpan; tidak ada pending menggantung.
5. Saldo dan history bertahan setelah restart dan tidak pernah tidak sinkron.
6. Receipt dan history menyatakan DEMO serta merchant belum dibayar.
7. APK release terbukti tanpa permission `INTERNET`.
8. Fallback galeri/tempel berfungsi dan diberi label sumber.
9. Seluruh test lulus dengan output yang disimpan.
10. Demo dilatih 2× dan berjalan 60–90 detik.
