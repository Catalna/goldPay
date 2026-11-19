# 16 — Panduan Prompt untuk Coding AI

> Tujuan: mencegah AI menghasilkan monolit, mengarang data merchant, menambah backend, atau
> menyalin versi paket yang sudah usang.

## 1. Aturan kerja

1. Selalu mulai dengan: "Baca `docs/00_DECISION_LOG.md`, `AGENTS.md`, dan dokumen yang relevan.
   Jangan mengubah keputusan di sana."
2. Minta AI **memeriksa file sebelum mengedit** dan menyebutkan file yang akan diubah.
3. Satu prompt = satu milestone. Jangan gabungkan dua milestone.
4. Wajib menjalankan `flutter analyze` dan test terkait, lalu melaporkan **output asli**.
5. Larang penambahan dependency tanpa persetujuan.
6. Larang pembuatan file di luar struktur di `03_SYSTEM_ARCHITECTURE.md`.
7. Minta AI menyebutkan hal yang belum selesai, bukan hanya yang berhasil.

## 2. Prompt instruksi proyek (tempel di awal sesi)

> Kamu adalah asisten Flutter/Dart untuk GoldPay, prototipe konsep Android mandiri (bukan aplikasi
> Pegadaian, tidak berafiliasi). Sebelum menulis kode, baca `docs/00_DECISION_LOG.md`, `AGENTS.md`,
> `docs/03_SYSTEM_ARCHITECTURE.md`, dan dokumen spesifikasi untuk milestone ini.
>
> Batasan keras: tanpa backend, tanpa network call, tanpa `google_fonts`, tanpa analytics, tanpa
> `INTERNET` permission di manifest release. Domain (`lib/domain`) harus pure Dart, tanpa impor
> Flutter. Uang = `int` rupiah; emas = `int` unit `0,0001 g`; pembulatan ceil. Hanya transaksi
> `completed_demo` yang disimpan. Jangan pernah mengarang nama/kota merchant. Jangan memakai kata
> "lunas", "berhasil dibayar", atau "terverifikasi". Semua teks UI berasal dari `copy_id.dart`.
>
> Bekerja dalam langkah kecil, jelaskan file yang berubah, jalankan `flutter analyze` dan test, dan
> laporkan hasil apa adanya. Jika menemukan keputusan yang belum ada di `00_DECISION_LOG.md`,
> berhenti dan tanyakan — jangan mengarang keputusan baru.

## 3. Prompt per milestone

### Prompt 0 — Audit lingkungan
> Periksa Flutter, Dart, Android SDK, dan perangkat. Jalankan `flutter doctor -v` dan
> `flutter devices`. Jangan menulis kode fitur. Laporkan setup yang terverifikasi dan penghambat,
> beserta perintahnya.

### Prompt 1 — Scaffold, token, copy
> Buat struktur folder sesuai `docs/03_SYSTEM_ARCHITECTURE.md`, `tokens.dart`, `theme.dart`
> (Plus Jakarta Sans dari `assets/fonts/`), `copy_id.dart` sesuai `docs/18_UI_COPY_ID.md`, router,
> dan Home dengan saldo statis. Jangan menambahkan dependency selain yang ada di `D-*`. Jangan
> memakai `google_fonts`. Jalankan analyzer dan laporkan.

### Prompt 2 — Scanner
> Implementasikan scanner memakai `mobile_scanner` versi kompatibel terbaru: `autoStart: false`,
> `DetectionSpeed.noDuplicates`, flag `_handled`, stop setelah satu hasil, lifecycle
> `WidgetsBindingObserver`, izin kamera + jalur pengaturan, torch, dan layar error. Belum ada
> parsing. Uji widget untuk state izin. Laporkan perilaku di perangkat fisik.

### Prompt 3 — Parser
> Baca `docs/07_QRIS_PARSER_SPEC.md`. Implementasikan `crc16.dart`, `tlv.dart`, `qris_parser.dart`
> sebagai pure Dart, berbasis **byte UTF-8**, tanpa `throw`. Hasil sealed `QrisSuccess`/`QrisFailure`.
> Wajib lulus F01–F10 di `docs/19_TEST_QR_FIXTURES.md` dan fuzz 10.000 input. Jangan menyentuh UI.

### Prompt 4 — Review dan fallback
> Hubungkan scanner ke parser dan layar review. Tampilkan hanya field yang ada. Nominal statis =
> input, dinamis = read-only. Tambahkan jalur galeri (`analyzeImage`) dan tempel payload di Demo
> Settings, lengkap dengan label sumber. Jangan menampilkan badge verifikasi.

### Prompt 5 — Konversi
> Implementasikan `GoldConversionCalculator` dan `QuoteValidator` sesuai
> `docs/08_GOLD_CONVERSION_DEMO_TRANSACTION.md`: integer, `ceilDiv`, dua harga (display & buyback),
> quote 5 menit, biaya QR terpisah. Tambahkan property test "quote selalu menutup biaya" dan "ceil
> minimal", serta "angka tampil = unit tersimpan".

### Prompt 6 — State dan transaksi
> Implementasikan repository, codec, dan state machine sesuai `docs/10` dan `docs/11`: satu blob
> JSON, snapshot `_prev` sebelum write, readback, lock `isCommitting`, dedupe `attemptId`, hanya
> `completed_demo` disimpan. Uji crash matrix dan kegagalan tulis. Tanpa network.

### Prompt 7 — Receipt, history, reset
> Bangun result/receipt dari record tersimpan, history + detail, reset dengan konfirmasi, dan tambah
> saldo demo. Pastikan receipt tetap benar setelah restart. Uji persistensi dan cap 200 record.

### Prompt 8 — QA dan bukti
> Audit implementasi terhadap `docs/12_TESTING_QA_PLAN.md`. Jangan menambah fitur. Hasilkan: output
> `flutter analyze`, semua test, hasil fuzz, dan bukti `aapt dump permissions` tanpa `INTERNET`.
> Laporkan lulus/gagal dengan bukti, dan perbaiki hanya dalam scope.

### Prompt 9 — Rilis
> Verifikasi kesiapan rilis. Jalankan `flutter build apk --release`, laporkan path artefak, nama
> paket, ukuran, dan warning yang tersisa. Jangan mengklaim sudah diuji di perangkat jika belum.

### Prompt 10 — Rehearsal
> Jalankan naskah `docs/13_LIVE_DEMO_SCRIPT.md` di perangkat, termasuk mode pesawat, fallback galeri,
> fallback tempel, saldo kurang, dan gagal paksa. Laporkan durasi dan titik gesekan.

## 4. Checklist review manusia

- [ ] Tidak ada network/HTTP/analytics; manifest release tanpa `INTERNET`.
- [ ] Tidak ada `google_fonts`; font dari asset.
- [ ] `lib/domain` tidak mengimpor Flutter.
- [ ] Parser berbasis byte; F03 lulus.
- [ ] Tidak ada `double` untuk uang/emas.
- [ ] Quote dan potongan memakai angka yang sama.
- [ ] Hanya `completed_demo` tersimpan; `processing` tidak pernah dipersist.
- [ ] Konfirmasi idempoten (lock + dedupe).
- [ ] Receipt dibangun dari record, bukan state memori.
- [ ] Tidak ada data merchant karangan; tanpa badge verifikasi.
- [ ] Semua teks dari `copy_id.dart`; tidak ada varian disclosure baru.
- [ ] Test dijalankan dan hasilnya dilampirkan.

## 5. Tanda AI keluar jalur

- Menambah `dio`/`http`/`firebase` "untuk nanti".
- Membuat "API service" atau repository remote.
- Menggunakan `double` untuk rupiah/gram.
- Menyimpan `pending` transaction "agar aman".
- Menambahkan login, onboarding, atau dark mode.
- Mengubah harga default atau saldo awal tanpa persetujuan.
- Membuat copy disclosure sendiri yang berbeda dari `18_UI_COPY_ID.md`.
- Mengklaim "sudah diuji" tanpa output perintah.
