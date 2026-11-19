# 10 — Data Model dan Penyimpanan Lokal

> Keputusan terkait: `00_DECISION_LOG.md` D-10 … D-14, D-29 … D-36.

## 1. Prinsip

1. Hanya data yang dibutuhkan demo yang disimpan.
2. Uang = `int` rupiah. Emas = `int` unit `0,0001 g`.
3. Waktu disimpan ISO-8601 **UTC**; ditampilkan dalam waktu lokal (`id_ID`).
4. Payload QR mentah **tidak pernah** disimpan.
5. Setiap state punya `schemaVersion`; hook migrasi disiapkan sejak versi 1.
6. Satu penulisan atomik untuk saldo + transaksi (tidak ada dua key terpisah).

## 2. Entitas

### 2.1 `DemoState` (persisted, satu blob)

```dart
class DemoState {
  final int schemaVersion;        // 1
  final String appVersion;        // mis. "1.0.0+1" — untuk diagnosa hari-H
  final int balanceUnits;         // 12_500 = 1,2500 g
  final String pricingConfigVersion;
  final List<DemoTransaction> transactions;   // maks 200, terbaru di index 0
  final DateTime lastUpdatedAt;   // UTC
}
```

`pricingConfig` **tidak** disimpan sebagai objek hidup; nilainya di-snapshot ke setiap transaksi.
Dengan begitu, mengubah config demo tidak mengubah history lama.

### 2.2 `DemoTransaction` (persisted, hanya status `completed_demo`)

```dart
class DemoTransaction {
  final String id;                  // uuid v4
  final String attemptId;           // uuid v4, untuk dedupe
  final DateTime createdAt;         // UTC
  final String status;              // "completed_demo" (satu-satunya nilai persisted)

  final int paymentAmountIdr;
  final int qrFeeIdr;
  final int totalIdr;

  final int goldPriceDisplayIdrPerGram;   // snapshot
  final int goldBuybackPriceIdrPerGram;   // snapshot
  final int goldUnits;
  final int goldValueIdr;
  final int roundingIdr;

  final int balanceBeforeUnits;
  final int balanceAfterUnits;

  final String? merchantName;
  final String? merchantCity;
  final String? merchantIssuerGui;
  final String qrKind;              // static | dynamic | unknown
  final bool crcValid;
  final List<String> warningCodes;  // kode saja, bukan teks
  final String source;              // camera | paste | gallery

  final String pricingConfigVersion;
  final String disclosureVersion;
}
```

Catatan:

- `attemptId` disimpan agar commit berikutnya bisa menolak duplikat.
- `balanceBeforeUnits` + `balanceAfterUnits` membuat receipt tetap konsisten meski state di-reset.
- `warningCodes` disimpan sebagai kode (`CRC_MISMATCH`), teks diambil dari `18_UI_COPY_ID.md`.
- Tidak ada `rawPayload`, `merchantPan`, `merchantId`, nama file, atau path gambar.

### 2.3 Entitas sementara (tidak dipersist)

- `QrisParseResult` — hidup hanya selama sesi checkout.
- `ConversionQuote` — hidup di controller; hilang saat app ditutup (dan itu benar).
- `PaymentDraft` — hasil scan + nominal.

## 3. JSON contoh

```json
{
  "schemaVersion": 1,
  "appVersion": "1.0.0+1",
  "balanceUnits": 11479,
  "pricingConfigVersion": "demo-2026-01",
  "lastUpdatedAt": "2026-11-19T07:12:44.512Z",
  "transactions": [
    {
      "id": "5f0f2a9e-6a7d-4c0a-9c0e-1d3b8a7e2f11",
      "attemptId": "a0d1f7c2-3d55-4a11-8c2f-9b1e6d4a0c33",
      "createdAt": "2026-11-19T07:12:44.508Z",
      "status": "completed_demo",
      "paymentAmountIdr": 150000,
      "qrFeeIdr": 0,
      "totalIdr": 150000,
      "goldPriceDisplayIdrPerGram": 1500000,
      "goldBuybackPriceIdrPerGram": 1470000,
      "goldUnits": 1021,
      "goldValueIdr": 150087,
      "roundingIdr": 87,
      "balanceBeforeUnits": 12500,
      "balanceAfterUnits": 11479,
      "merchantName": "Warung Bu Tini",
      "merchantCity": "Jakarta",
      "merchantIssuerGui": "ID.CO.BANKCONTOH.WWW",
      "qrKind": "dynamic",
      "crcValid": true,
      "warningCodes": [],
      "source": "camera",
      "pricingConfigVersion": "demo-2026-01",
      "disclosureVersion": "demo-2026-01"
    }
  ]
}
```

## 4. Satuan dan format

| Nilai | Penyimpanan | Tampilan |
|---|---|---|
| Rupiah | `int` (150000) | `Rp150.000` |
| Emas | `int` unit (1021) | `0,1021 g` |
| Waktu | ISO-8601 UTC | `19 Nov 2026, 14.12` |

Konversi tampilan hanya di layer `core/formatters`. Jangan memakai `double` di mana pun.

## 5. Storage

`shared_preferences` dengan dua key:

| Key | Isi |
|---|---|
| `goldpay_state_v1` | State aktif (JSON) |
| `goldpay_state_prev_v1` | Snapshot state **sebelum** penulisan terakhir (untuk pemulihan) |

Tidak ada key terpisah untuk saldo dan history. Tidak ada SQLite di MVP.

Batas ukuran: 200 transaksi × ±700 byte ≈ 140 KB — masih wajar untuk `SharedPreferences`. Saat
melebihi 200, transaksi terlama dibuang (history tetap "terbaru dulu").

## 6. Prosedur commit (atomic-by-ordering)

```
1. state  = load()                       // jika gagal → lihat §7
2. validasi quote terhadap state         // saldo, duplikat attemptId, config
3. next   = state.copyWith(balance - goldUnits, transactions: [tx, ...])
4. write(_prev, encode(state))           // snapshot lama lebih dulu
5. write(main, encode(next))             // penulisan utama
6. readback(main) == encode(next) ?      // verifikasi bila API memungkinkan
7. update state reaktif
8. tampilkan sukses
```

Aturan:

- Langkah 8 **tidak boleh** terjadi sebelum 5–6 selesai.
- Jika langkah 4 gagal → batalkan, jangan menulis main.
- Jika langkah 5 gagal → `_prev` masih berisi state lama; tampilkan gagal.
- Jika langkah 6 berbeda → anggap gagal; coba tulis ulang sekali, lalu tampilkan gagal.
- `_prev` **bukan** backup transaksi terakhir; ia adalah state sebelum transaksi terakhir. Memulihkan
  `_prev` berarti kehilangan satu transaksi terakhir — ini disengaja dan aman (saldo & history tetap
  konsisten satu sama lain).

## 7. Pemulihan dan korupsi

| Kondisi | Perilaku |
|---|---|
| `main` tidak ada | Muat state awal (first run) |
| `main` JSON rusak | Coba `_prev`; jika berhasil, tulis ulang `main` dan tampilkan info "data dipulihkan" |
| `main` dan `_prev` rusak | Tampilkan layar pemulihan: penjelasan + tombol Reset demo (tidak menghapus data diam-diam) |
| `schemaVersion` lebih tinggi dari app | Tampilkan "perbarui aplikasi"; jangan menulis apa pun |
| `schemaVersion` lebih rendah | Jalankan migrasi ke versi saat ini, lalu tulis ulang |

Migrasi disiapkan sebagai `List<Migration>` kosong di versi 1. Jangan membuat field baru tanpa
menaikkan `schemaVersion`.

## 8. Reset dan tambah saldo

- Reset: `DemoState(schemaVersion: 1, balanceUnits: initialBalanceUnits, transactions: [])`, tulis
  ke `main` dan `_prev`, **tanpa** increment schema version.
- Tambah saldo: `balanceUnits += addUnits`, `lastUpdatedAt` diperbarui, history tidak berubah.
  Tidak membuat record transaksi. Tampilkan snackbar singkat, bukan layar sukses.

## 9. Yang tidak boleh disimpan

- Payload QR mentah atau potongannya.
- PAN merchant (`sub 01`), merchant ID (`sub 02`), MCC, postal code.
- Nama file/gambar QR, path galeri, izin kamera.
- Lokasi, perangkat, atau identifier apa pun.
- Log berisi payload penuh (termasuk di `flutter logs`).

## 10. Uji penyimpanan

1. Commit sukses → saldo turun tepat sekali, history bertambah satu.
2. Simulasi gagal tulis `main` → saldo tidak berubah, tidak ada record.
3. Simulasi gagal tulis `_prev` → commit dibatalkan.
4. Rusak `main` → pulih dari `_prev`, satu transaksi terakhir hilang, aplikasi tidak crash.
5. Rusak keduanya → layar pemulihan, reset berfungsi.
6. 201 transaksi → hanya 200 terbaru tersimpan.
7. Restart aplikasi → saldo dan history identik.
8. `attemptId` duplikat → commit ditolak, tidak ada potongan kedua.
