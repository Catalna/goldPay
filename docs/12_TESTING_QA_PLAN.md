# 12 — Testing dan QA Plan

> Target: setiap klaim di dokumen lain punya bukti uji. "Sepertinya jalan" bukan bukti.

## 1. Unit test — parser (`test/domain/qris/`)

Wajib memakai fixture di `19_TEST_QR_FIXTURES.md`.

| Kasus | Harapan |
|---|---|
| F01 | `static`, nominal null, nama & kota terbaca, CRC valid |
| F02 | `dynamic`, nominal 150000, read-only (di level checkout) |
| F03 | nama `Café Kenangan` utuh; `5914` dibaca sebagai 14 byte |
| F04 | `qrFeeIdr == 5000`, total 105000 |
| F05 | `UNSUPPORTED_CURRENCY` |
| F06 | sukses + warning `CRC_MISMATCH` |
| F07 | `INVALID_AMOUNT` |
| F08 | warning `MISSING_MERCHANT_NAME` |
| F09 | `TRUNCATED_VALUE` |
| F10 | `UNSUPPORTED_FORMAT` |
| Kosong / spasi | `EMPTY_PAYLOAD` |
| 1.024 byte | diproses |
| 1.025 byte | `PAYLOAD_TOO_LARGE` |
| Duplikat tag 54 | `DUPLICATE_CRITICAL_TAG` |
| Duplikat tag 59 | warning, ambil yang pertama |
| Tag 63 di tengah | warning `CRC_NOT_LAST`, `crcValid == false` |
| Tanpa tag 63 | warning `CRC_MISSING` |
| Nested > 2 level | `MALFORMED_TLV` |
| Nama 64+ karakter / karakter kontrol / bidi | disanitasi, tidak crash |

### Nominal

`0`, `0.00`, `150000`, `1500.00`, `1500.50`, `1e3`, `1,000`, `" 100"`, `"100."`, `".5"`, 14 digit.

### Tip

| `55` | `56` / `57` | Harapan |
|---|---|---|
| `01` | — | fee 0 + `TIP_PROMPT_IGNORED` |
| `02` | `56=2500` | fee 2500 |
| `03` | `57=05` | fee = ceil(nominal × 5%) |
| `03` | `57=2.5` | fee = ceil(nominal × 2,5%) |
| `02` | tidak ada 56 | fee 0 + `TIP_INCOMPLETE` |
| tidak ada | ada 57 | fee 0 + `TIP_INCOMPLETE` |

### CRC

- Vektor uji tetap: payload F01 → `82C5`; F02 → `555C`.
- Ubah satu byte → `crcValid == false`.

### Fuzz

10.000 string acak (campuran ASCII, UTF-8 multibyte, byte acak yang di-decode malformed), panjang
0–2.000 karakter. Asersi: **tidak ada exception**, hasil selalu `QrisSuccess` atau `QrisFailure`.

## 2. Unit test — kalkulator dan validator (`test/domain/pricing/`)

| Kasus | Harapan |
|---|---|
| 150.000, buyback 1.470.000 | 1.021 unit, nilai 150.087, pembulatan 87 |
| 105.000 | 715 unit, nilai 105.105, pembulatan 105 |
| 1.000 | 7 unit |
| 1.000.000 | 6.803 unit |
| Saldo tepat sama dengan kebutuhan | lolos |
| Saldo 1 unit kurang | ditolak, `shortfallIdr` benar |
| Harga buyback 0 / negatif | konfigurasi invalid |
| Harga display < buyback | konfigurasi invalid |
| Nominal < min / > max | ditolak |
| `qrFeeIdr` negatif | ditolak |
| Quote lewat `validUntil` | `expired` |

**Property test (wajib):**

1. Untuk 10.000 nominal acak: `goldUnits * buyback ~/ 10000 >= total` (quote selalu menutup biaya).
2. Untuk 10.000 nominal acak: `(goldUnits - 1) * buyback ~/ 10000 < total` (ceil minimal, tidak
   membuang emas pengguna).
3. `formatGold(units) == formatGold(dariNilaiTersimpan)` — angka tampil = angka potong.

## 3. Unit test — repository (`test/data/`)

| Kasus | Harapan |
|---|---|
| Commit sukses | saldo turun sekali, 1 record |
| `attemptId` duplikat | ditolak, tidak ada potongan kedua |
| Gagal tulis `_prev` | commit batal |
| Gagal tulis `main` | saldo tidak berubah |
| Readback tidak cocok | gagal, tidak menampilkan sukses |
| `main` rusak | pulih dari `_prev`, satu transaksi terakhir hilang |
| Keduanya rusak | status pemulihan, tidak crash |
| 201 transaksi | tersimpan 200 terbaru |
| Restart | state identik |
| Reset | saldo awal, history kosong, `_prev` ikut ditulis |
| Tambah saldo | saldo naik, history tetap |

## 4. Widget test

- Home: saldo, harga, disclosure terlihat.
- Tombol Scan membuka route scanner.
- Izin ditolak: penjelasan + tombol pengaturan.
- QR statis: tombol Lanjut nonaktif sampai nominal valid.
- QR dinamis: field nominal tidak bisa diedit.
- Quote: semua baris angka tampil; tombol konfirmasi ada.
- Saldo kurang: tombol nonaktif + kekurangan tampil.
- Quote kedaluwarsa: tombol berubah menjadi "Perbarui penawaran".
- Processing: tap berulang tidak menambah transaksi.
- Result: disclosure receipt tampil.
- History: item dan empty state.
- Reset: dialog muncul, batal tidak mengubah apa pun.
- Semantics: kartu saldo punya label terbaca; error diumumkan.
- `textScaleFactor` 1,0 dan 1,3 tanpa overflow (gunakan `tester.takeException()`).

## 5. Golden test — copy

Snapshot teks `copy_id.dart` terhadap `18_UI_COPY_ID.md`. Tujuan: mencegah variasi kalimat
disclosure tanpa sengaja. Jika teks berubah, golden harus diperbarui secara sadar.

## 6. Integration test

- Kamera → parser → review → quote → konfirmasi → result (dengan payload disuntikkan).
- Fallback tempel dan galeri menghasilkan `source` yang benar.
- Restart aplikasi: saldo dan history bertahan.
- Reset setelah transaksi: state kembali awal.
- Lifecycle: background/foreground saat scanner terbuka.

## 7. Manual di perangkat fisik

- [ ] Izin kamera pada pemakaian pertama.
- [ ] Fokus pada berbagai jarak (15–40 cm) dan pencahayaan.
- [ ] QR cetak 6 cm dan QR di layar.
- [ ] Torch berfungsi (jika didukung).
- [ ] Back/cancel menghentikan kamera (tidak ada indikator kamera aktif).
- [ ] Rotasi/background tidak merusak scanner.
- [ ] Text scale 1,3 dan layar kecil.
- [ ] Restart perangkat, data tetap ada.
- [ ] Install ulang APK (signature sama) tidak menghapus data.
- [ ] Mode pesawat: seluruh alur tetap berjalan.

## 8. Keamanan dan privasi

- [ ] `aapt dump permissions build/app/outputs/flutter-apk/app-release.apk` **tidak** memuat
      `android.permission.INTERNET`.
- [ ] Tidak ada dependency `http`, `dio`, `firebase`, `analytics`, `google_fonts`.
- [ ] Tidak ada payload QR di log (`adb logcat` diperiksa manual).
- [ ] Tidak ada URL/aplikasi yang dibuka dari isi QR.
- [ ] Tidak ada data pribadi di state JSON.
- [ ] Tidak ada klaim "terverifikasi"/"lunas".

## 9. Kinerja

- Parse < 16 ms (ukur dengan `Stopwatch` di debug, catat di laporan).
- Commit < 100 ms.
- Tidak ada jank saat membuka scanner (frame > 32 ms dicatat).

## 10. Matriks perangkat

| Perangkat | Android | Fokus uji |
|---|---|---|
| Target utama (demo) | 10–14 | Semua alur, kamera, fallback |
| Layar kecil 5" (320 dp) | 10+ | Layout, text scale |
| Layar besar 6,7" | 12+ | Layout, scanner |

## 11. Perintah verifikasi

```powershell
flutter analyze
flutter test
flutter test test/domain/qris
flutter test test/domain/pricing
flutter build apk --release
```

Verifikasi permission (pilih salah satu):

```powershell
# build-tools aapt
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<versi>\aapt.exe" dump permissions build\app\outputs\flutter-apk\app-release.apk

# atau apkanalyzer
apkanalyzer manifest permissions build\app\outputs\flutter-apk\app-release.apk
```

Keduanya **tidak boleh** mencantumkan `INTERNET`.

## 12. Checklist rilis

- [x] `flutter analyze` bersih — 19 Nov 2026: `No issues found!`.
- [x] Seluruh unit/widget test lulus — `flutter test`: 81 test.
- [x] Fuzz 10.000 input lulus — `test/domain/qris/qris_parser_test.dart`.
- [x] Fixture F01–F10 sesuai harapan — `flutter test test/domain/qris`.
- [x] Verifikasi tanpa permission `INTERNET` lulus — `aapt dump permissions` hanya
      mencantumkan `CAMERA`, `ACCESS_NETWORK_STATE`, dan
      `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
- [x] Restart & reset terverifikasi di perangkat — saldo 1,1479 g dan 1 transaksi bertahan
      setelah force-stop; reset mengembalikan 1,2500 g dan 0 transaksi.
- [x] APK release terpasang di perangkat demo — `app-release.apk` 65,9 MB, `id.goldpay.concept`.
- [ ] QR cetak cadangan tersedia dan terbaca — PNG cetak ada, belum dipindai di perangkat.
- [ ] Naskah demo dilatih 2× — belum dilakukan.
- [x] Tidak ada aset/logo pihak ketiga di app — ikon launcher dibuat sendiri, font
      Plus Jakarta Sans berlisensi OFL, tanpa logo Pegadaian maupun merchant.
