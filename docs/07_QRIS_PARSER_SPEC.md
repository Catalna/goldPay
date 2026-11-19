# 07 — QRIS Payload Parser Specification

> **Bukan** validator jaringan QRIS, bukan autentikasi merchant, bukan inisiasi pembayaran.
> Parser hanya membaca struktur data yang ada di payload. Keputusan terkait ada di
> `00_DECISION_LOG.md` (D-19 … D-28).

## 1. Kontrak modul

```dart
sealed class QrisParseResult {
  const QrisParseResult();
}

final class QrisSuccess extends QrisParseResult {
  final QrKind kind;                 // static | dynamic | unknown
  final int? amountIdr;              // null jika tidak ada nominal
  final int qrFeeIdr;                // tip/convenience dari tag 55/56/57, 0 jika tidak ada
  final String? merchantName;        // tag 59, sudah disanitasi
  final String? merchantCity;        // tag 60
  final String? merchantIssuerGui;   // sub-tag 00 pada template 26–51
  final String? terminalLabel;       // sub-tag 07 pada tag 62
  final bool crcValid;
  final List<QrisWarning> warnings;
}

final class QrisFailure extends QrisParseResult {
  final QrisErrorCode code;
  final String detailForDev;         // tidak pernah ditampilkan ke pengguna
}
```

Aturan:

1. **Tidak pernah `throw`** untuk input dari pengguna. Semua kegagalan menjadi `QrisFailure`.
2. Fungsi murni: `QrisParseResult parseQris(String payload)`. Tanpa I/O, tanpa `BuildContext`.
3. `detailForDev` hanya untuk log debug; UI memakai copy dari `18_UI_COPY_ID.md`.
4. Parser **tidak** memutuskan min/max nominal aplikasi — itu tugas quote validator.

## 2. Encoding dan panjang (kritis)

- Payload dari kamera adalah **String UTF-8**.
- Panjang TLV dihitung dalam **byte UTF-8**, bukan karakter.
  `"Café Kenangan"` = 13 karakter, **14 byte** → tag `5914`.
- Implementasi: encode payload ke `Uint8List` sekali, lalu seluruh parsing bekerja pada byte.
  Jangan memakai `String.substring` untuk offset TLV.
- Setelah slice nilai, decode dengan `utf8.decode(bytes, allowMalformed: true)`. Jika muncul
  karakter pengganti `U+FFFD`, tambahkan warning `NON_ASCII_VALUE` (jangan gagal).
- Batas payload: **1.024 byte** → `PAYLOAD_TOO_LARGE`.
- Nilai kosong (length `00`) untuk tag yang ditampilkan → dianggap tidak ada + warning.

> Bukti kenapa ini penting: fixture `F03` di `19_TEST_QR_FIXTURES.md`. Parser berbasis
> `String.length` akan kehilangan offset dan gagal.

## 3. Grammar TLV

```
payload  := element+
element  := tag length value
tag      := 2 digit ASCII
length   := 2 digit desimal ASCII (00–99)
value    := length byte
```

Aturan validasi:

| Kondisi | Hasil |
|---|---|
| Tag bukan 2 digit | `MALFORMED_TLV` |
| Length bukan 2 digit numerik | `MALFORMED_TLV` |
| `offset + length` melewati akhir payload | `TRUNCATED_VALUE` |
| Sisa < 4 byte di akhir | `TRUNCATED_VALUE` |
| Kedalaman nested > 2 (root + 1 level) | `MALFORMED_TLV` |
| Tag kritis duplikat (`00`, `01`, `53`, `54`, `58`) | `DUPLICATE_CRITICAL_TAG` |
| Tag non-kritis duplikat | warning `DUPLICATE_NON_CRITICAL_TAG`, ambil yang pertama |

Tag `63` (CRC) **harus** berada di akhir payload. Jika tidak, warning `CRC_NOT_LAST` dan CRC
tidak diverifikasi.

## 4. Tag yang dibaca

| Tag | Arti | Aksi |
|---|---|---|
| `00` | Payload Format Indicator | Harus `01`; nilai lain → `UNSUPPORTED_FORMAT` |
| `01` | Point of Initiation | `11` → static, `12` → dynamic, lainnya → `unknown` |
| `26`–`51` | Merchant Account Information | Parse nested TLV; ambil sub `00` (GUI), `01` (PAN merchant), `02` (merchant ID), `03` (criteria). Sub lain opaque |
| `52` | Merchant Category Code | Simpan (tidak ditampilkan di MVP) |
| `53` | Currency | Harus `360` (IDR); selain itu `UNSUPPORTED_CURRENCY` |
| `54` | Amount | Lihat §5 |
| `55` | Tip/Convenience Indicator | `01` prompt, `02` fixed, `03` percentage |
| `56` | Convenience Fee Fixed | Dipakai jika `55 = 02` |
| `57` | Convenience Fee Percentage | Dipakai jika `55 = 03` |
| `58` | Country | Harus `ID`; nilai lain → warning `UNEXPECTED_COUNTRY` |
| `59` | Merchant Name | Tampilkan setelah sanitasi (§7) |
| `60` | Merchant City | Tampilkan setelah sanitasi |
| `61` | Postal Code | Simpan, tidak ditampilkan |
| `62` | Additional Data | Baca sub `01` (bill number), `05` (reference label), `07` (terminal label), `08` (purpose). Lainnya opaque |
| `63` | CRC | Verifikasi (§6) |
| lainnya | Unknown | Simpan opaque, warning `UNKNOWN_TAG_PRESENT` |

**Jangan** menganggap template tertentu (mis. selalu `26`) sebagai identitas merchant. Template
bisa berada di `26`–`51` tergantung akuirer. Jangan pula menganggap sub `02` adalah "ID merchant
terverifikasi" — hanya data yang ditampilkan sebagai informasi.

### Penerbit QR dari GUI

Sub-tag `00` berisi GUI, contoh `ID.CO.BANKCONTOH.WWW`. Tampilkan:

- `merchantIssuerGui` apa adanya (aman, karena memang ada di payload), **atau**
- nama pendek dari tabel kosmetik (`ID.CO.GOPAY.` → "GoPay", `ID.CO.SHOPEEPAY.` → "ShopeePay",
  `ID.CO.DANA.` → "DANA", dst.).

Jika tidak dikenali → `value.issuerUnknown`. Tidak ada badge "terverifikasi".

## 5. Nominal (tag 54)

Validasi sintaks (parser):

```
^[0-9]{1,13}(\.[0-9]{1,2})?$
```

- Hanya digit, satu titik opsional, maksimal 2 desimal, total maksimal 13 karakter angka.
- `0`, `0.00`, atau nilai kosong → `AMOUNT_OUT_OF_RANGE`.
- Untuk IDR: desimal **harus** nol (`.00` atau tanpa desimal). `1500.50` → `INVALID_AMOUNT`.
  **Dilarang** membulatkan atau memotong desimal secara diam-diam.
- Konversi ke `int` rupiah hanya setelah validasi lolos.
- Batas aplikasi (`minPaymentIdr` / `maxPaymentIdr`) **tidak** diperiksa di sini.

Contoh hasil: `150000` → 150000; `1500.00` → 1500; `1500.5` → gagal; `1e3` → gagal; `1,000` → gagal.

## 6. CRC

Implementasi **wajib**, algoritma:

- CRC-16/CCITT-FALSE: polynomial `0x1021`, init `0xFFFF`, tanpa refleksi, xorout `0x0000`.
- Dihitung atas **semua byte** payload termasuk header tag CRC (`"6304"`), yaitu
  `bytes[0 .. len-5]`, dan dibandingkan dengan 4 karakter hex terakhir (case-insensitive).
- Nilai CRC disimpan sebagai 4 karakter hex uppercase.

Kebijakan: **soft-fail**.

| Kondisi | Hasil |
|---|---|
| CRC cocok | `crcValid = true` |
| CRC tidak cocok | `crcValid = false` + warning `CRC_MISMATCH`, parsing tetap lanjut |
| Tag 63 tidak ada | `crcValid = false` + warning `CRC_MISSING` |
| Tag 63 bukan di akhir | warning `CRC_NOT_LAST`, `crcValid = false` |

CRC adalah bukti integritas data, **bukan** bukti keaslian merchant atau kelayakan pembayaran.

## 7. Sanitasi nilai tampilan

Untuk `59`, `60`, dan label terminal:

1. Trim spasi di awal/akhir.
2. Hapus karakter kontrol C0/C1 dan karakter bidi override (`U+202A`–`U+202E`, `U+2066`–`U+2069`).
3. Ganti baris baru/tab dengan satu spasi, lalu rapatkan spasi ganda.
4. Batasi 64 karakter untuk tampilan (potong dengan elipsis di UI, bukan di parser).
5. Jangan render sebagai HTML; jangan jadikan URL yang bisa diklik.
6. Jangan pernah memakai nilai QR untuk navigasi, membuka aplikasi lain, atau memicu aksi.

## 8. Static, dynamic, dan kebijakan nominal

| Kondisi | `kind` | Perilaku checkout |
|---|---|---|
| Tag `01 = 11` | `static` | Nominal **wajib** diisi pengguna |
| Tag `01 = 12` + tag 54 valid | `dynamic` | Nominal **read-only**, diambil dari QR |
| Tag `01 = 12` tanpa tag 54 | `unknown` + warning `DYNAMIC_WITHOUT_AMOUNT` | Nominal diisi pengguna |
| Tag `01` tidak dikenal, ada tag 54 | `unknown` | Nominal read-only (ikuti adanya tag 54) |
| Tag `01` tidak dikenal, tanpa tag 54 | `unknown` | Nominal diisi pengguna |

Aturan tambahan: jika `kind == dynamic` dan pengguna mengubah nominal, itu **bug**, bukan fitur.

## 9. Tip / convenience fee

| `55` | Sumber biaya | Perhitungan |
|---|---|---|
| `01` | Prompt tip | `qrFeeIdr = 0` + warning `TIP_PROMPT_IGNORED` (MVP tidak punya UI tip) |
| `02` | Tag `56` (fixed) | `qrFeeIdr = ceil(nilaiTag56)` dalam rupiah |
| `03` | Tag `57` (persentase) | `qrFeeIdr = ceil(amountIdr × pctHundredths ÷ 10.000)` |
| tidak ada | — | `qrFeeIdr = 0`; jika `56`/`57` muncul tanpa `55` → warning `TIP_INCOMPLETE` |
| `02` tanpa `56`, atau `03` tanpa `57` | — | `qrFeeIdr = 0` + warning `TIP_INCOMPLETE` |

Persentase di tag `57` dibaca sebagai persen dengan maksimal 2 desimal → simpan sebagai
`pctHundredths` (contoh `"5"` → 500, `"2.5"` → 250).

Contoh (fixture F04): nominal 100.000, `55=03`, `57=05` → fee = `ceil(100.000 × 500 ÷ 10.000)`
= 5.000 → total 105.000.

## 10. Kode error dan warning

### Error (memblokir checkout)

| Kode | Kapan |
|---|---|
| `EMPTY_PAYLOAD` | String kosong setelah trim |
| `PAYLOAD_TOO_LARGE` | > 1.024 byte |
| `MALFORMED_TLV` | Tag/length tidak valid, kedalaman berlebih, format bukan `01` |
| `TRUNCATED_VALUE` | Panjang melebihi data tersedia |
| `DUPLICATE_CRITICAL_TAG` | Tag kritis muncul lebih dari sekali |
| `UNSUPPORTED_FORMAT` | Bukan EMV/QRIS (mis. URL biasa) |
| `UNSUPPORTED_CURRENCY` | Tag 53 ≠ `360` |
| `INVALID_AMOUNT` | Sintaks nominal salah atau desimal bukan nol pada IDR |
| `AMOUNT_OUT_OF_RANGE` | Nominal 0 atau melebihi 13 digit |

### Warning (tidak memblokir)

`CRC_MISMATCH`, `CRC_MISSING`, `CRC_NOT_LAST`, `TIP_PROMPT_IGNORED`, `TIP_INCOMPLETE`,
`MISSING_MERCHANT_NAME`, `UNKNOWN_TAG_PRESENT`, `DUPLICATE_NON_CRITICAL_TAG`,
`NON_ASCII_VALUE`, `UNEXPECTED_COUNTRY`, `DYNAMIC_WITHOUT_AMOUNT`.

Semua kode punya teks pengguna di `18_UI_COPY_ID.md`. Jangan menampilkan nama kode ke pengguna.

## 11. Algoritma

1. Trim, cek kosong, cek batas ukuran, encode ke byte.
2. Parse TLV root dengan bounds check; kumpulkan tag + nilai byte.
3. Deteksi duplikat sesuai §3.
4. Parse nested untuk `26`–`51` dan `62` (maksimal satu level).
5. Validasi tag `00`, `53`, `58`.
6. Baca `01` → tentukan `kind`; baca `54` → nominal (atau null).
7. Hitung `qrFeeIdr` dari `55/56/57`.
8. Verifikasi CRC; set `crcValid` + warning bila perlu.
9. Sanitasi `59`, `60`, dan label terminal.
10. Kembalikan `QrisSuccess` atau `QrisFailure`.

## 12. Yang dilarang

- Menyimpan payload mentah ke state, history, atau log rilis.
- Menampilkan "Merchant terverifikasi", "Pembayaran valid", atau sejenisnya.
- Membuka URL/aplikasi dari isi QR.
- Memakai `double` untuk nominal.
- Menganggap payload yang lolos CRC sebagai merchant yang benar-benar bisa menerima pembayaran.

Log debug (hanya build debug) boleh menampilkan **metadata** — panjang payload, jumlah tag, dan status
CRC — bukan payload penuh atau potongannya.

## 13. Uji wajib

Semua kasus di `19_TEST_QR_FIXTURES.md` (F01–F10) plus:

- Payload kosong, spasi saja, 1.024 byte, 1.025 byte.
- Nested template dengan tag tidak dikenal.
- Tag 63 di tengah payload.
- Nominal: `0`, `0.00`, `150000`, `1500.00`, `1500.50`, `1e3`, `1,000`, ` 100`, `100.`, `.5`, 14 digit.
- Nama merchant 64 karakter, karakter kontrol, dan karakter bidi.
- Fuzz 10.000 string acak: tidak boleh `throw`, harus menghasilkan `QrisFailure` atau sukses yang wajar.
