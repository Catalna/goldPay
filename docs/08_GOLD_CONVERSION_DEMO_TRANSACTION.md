# 08 — Konversi Emas dan Transaksi Demo

> Semua harga adalah **konfigurasi demo**. Bukan harga Pegadaian, bukan harga pasar, tidak
> diperbarui dari jaringan. Keputusan terkait: `00_DECISION_LOG.md` D-10 … D-18.

## 1. Konfigurasi

```dart
class DemoPricingConfig {
  final String version;                       // "demo-2026-01"
  final int goldPriceDisplayIdrPerGram;       // 1_500_000  (acuan, ditampilkan)
  final int goldBuybackPriceIdrPerGram;       // 1_470_000  (dipakai konversi)
  final int convenienceFeeIdr;                // 0          (tidak dibebankan ke pengguna)
  final int initialBalanceUnits;              // 12_500     (= 1,2500 g)
  final int minPaymentIdr;                    // 1_000
  final int maxPaymentIdr;                    // 1_000_000
}
```

Nilai awal: `version = "demo-2026-01"`, harga 1.500.000 / 1.470.000 (spread 200 bps),
saldo awal 1,2500 g, fee 0.

**Harga ditampilkan sebagai dua baris** — "Harga emas simulasi" dan "Harga buyback simulasi" —
supaya pengguna melihat bahwa konversi memakai harga buyback, bukan harga acuan.

## 2. Satuan

- Uang: `int` rupiah. Tidak ada sen, tidak ada `double`.
- Emas: `int` unit, **1 unit = 0,0001 g** (100 µg). `1 g = 10.000 unit`.
- Saldo awal 1,2500 g = `12_500` unit.
- Karena presisi penyimpanan sama dengan presisi tampilan (4 desimal), **angka yang tampil selalu
  sama dengan angka yang dipotong**.

## 3. Rumus

```
totalIdr        = paymentAmountIdr + qrFeeIdr + convenienceFeeIdr
goldUnits       = ceilDiv(totalIdr * 10_000, goldBuybackPriceIdrPerGram)
goldValueIdr    = goldUnits * goldBuybackPriceIdrPerGram ~/ 10_000
roundingIdr     = goldValueIdr - totalIdr        // 0 … harga per unit
balanceAfter    = balanceUnits - goldUnits
```

```dart
int ceilDiv(int a, int b) => (a + b - 1) ~/ b;   // a >= 0, b > 0
```

Catatan:

- `ceilDiv` dihitung dari nol setiap kali quote dibuat. Jangan menyimpan hasil antara sebagai
  `double`.
- `roundingIdr` selalu ≥ 0 dan < nilai 1 unit (≈ Rp147). Ditampilkan sebagai "Pembulatan ke atas".
- Batas atas aman dari overflow: `1.000.000 × 10.000 = 10^10`, jauh di bawah `2^63`.
- `goldUnits` minimal 1. Jika hasil ceil = 0 (hanya mungkin bila total 0), quote ditolak.

## 4. Contoh yang benar-benar membulat

Konfigurasi di atas, saldo 12.500 unit.

| Kasus | Nominal | Biaya QR | Total | `total×10.000` | ÷ 1.470.000 | Unit (ceil) | Gram | Nilai emas | Pembulatan | Sisa |
|---|---|---|---|---|---|---|---|---|---|---|
| F01/F02 | 150.000 | 0 | 150.000 | 1.500.000.000 | 1.020,408… | **1.021** | 0,1021 g | 150.087 | +87 | 1,1479 g |
| F04 | 100.000 | 5.000 | 105.000 | 1.050.000.000 | 714,285… | **715** | 0,0715 g | 105.105 | +105 | 1,1785 g |
| Minimum | 1.000 | 0 | 1.000 | 10.000.000 | 6,802… | **7** | 0,0007 g | 1.029 | +29 | — |
| Maksimum | 1.000.000 | 0 | 1.000.000 | 10.000.000.000 | 6.802,72… | **6.803** | 0,6803 g | 1.000.041 | +41 | — |

Contoh pertama **wajib** dipakai di unit test karena membuktikan perilaku ceiling; contoh lama
(0,1005 g) kebetulan tidak membulat sehingga tidak menguji apa pun.

## 5. Objek quote

```dart
class ConversionQuote {
  final String quoteId;                 // uuid v4
  final DateTime createdAt;             // UTC
  final DateTime validUntil;            // createdAt + 5 menit
  final String pricingConfigVersion;

  final int paymentAmountIdr;
  final int qrFeeIdr;                   // dari parser (tip/convenience)
  final int convenienceFeeIdr;          // 0
  final int totalIdr;

  final int goldPriceDisplayIdrPerGram;
  final int goldBuybackPriceIdrPerGram;

  final int goldUnits;                  // ceil, yang akan dipotong
  final int goldValueIdr;               // nilai emas yang dijual
  final int roundingIdr;                // pembulatan ke atas

  final int balanceBeforeUnits;
  final int balanceAfterUnits;

  final String disclosureVersion;       // "demo-2026-01"
}
```

Setelah `validUntil` lewat, quote menjadi `expired`. Konfirmasi ditolak sampai pengguna menekan
"Perbarui penawaran" (quote baru, `quoteId` baru).

## 6. Validasi quote

Quote ditolak (tanpa mengubah saldo) jika:

1. `paymentAmountIdr <= 0`.
2. `paymentAmountIdr < minPaymentIdr` atau `> maxPaymentIdr`.
3. `qrFeeIdr < 0` atau `convenienceFeeIdr != 0`.
4. `goldBuybackPriceIdrPerGram <= 0` atau `goldPriceDisplayIdrPerGram < goldBuybackPriceIdrPerGram`.
5. `goldUnits > balanceUnits` (saldo tidak cukup).
6. `validUntil` sudah lewat.
7. Hasil konversi bukan bilangan valid (dijaga oleh tipe `int`, tetapi tetap diperiksa).

Kekurangan saldo ditampilkan dalam dua bentuk:

```
shortfallUnits = goldUnits - balanceUnits
shortfallIdr   = ceilDiv(shortfallUnits * goldBuybackPriceIdrPerGram, 10_000)
```

Tombol konfirmasi **nonaktif** (bukan hanya memunculkan snackbar) dan alasannya tertulis.

## 7. Alur transaksi

1. Pengguna melihat quote + disclosure + sisa saldo setelah transaksi.
2. Tombol berbunyi `nav.confirm` ("Simulasikan pembayaran"), didahului kalimat "Anda akan menjual emas".
3. `attemptId = uuid()` dibuat, `isCommitting = true` (lock sinkron).
4. Validasi ulang: saldo saat ini, quote belum kedaluwarsa, `attemptId` belum ada di state.
5. Tampilkan `status.processing` (delay kosmetik 800–1.500 ms, **tanpa** network).
6. Commit atomik (§8 `10_DATA_MODEL_LOCAL_STORAGE.md`): tulis `_prev` → tulis state baru.
7. Jika commit sukses: buat `DemoTransaction` status `completed_demo`, update state reaktif, tampilkan
   hasil yang **dibangun dari record tersimpan** (bukan dari variabel UI).
8. Jika commit gagal: tampilkan `status.failed`, **tidak ada** potongan saldo, tidak ada record.
9. `isCommitting = false` di `finally`.

Aturan tambahan:

- Tekan ganda diabaikan oleh lock; bukan oleh `debounce` UI.
- Tombol back dinonaktifkan selama `processing_demo`.
- Ganti QR ("Scan ulang") membatalkan draft dan mengosongkan quote.

## 8. Kegagalan yang disimulasikan

Toggle "Paksa gagal transaksi berikutnya" (Demo Settings) membuat langkah 6 gagal secara
deterministik:

- Saldo tidak berubah.
- History tidak bertambah.
- Pengguna melihat `status.failed` + tombol "Coba lagi" yang mengembalikan ke **`quoted`**
  (re-quote), bukan ke `draft`.

Kegagalan penyimpanan nyata (mis. storage penuh) diperlakukan sama: tidak pernah menampilkan sukses.

## 9. Struktur receipt dan history

Setiap record `completed_demo` menyimpan (lihat `10_DATA_MODEL_LOCAL_STORAGE.md`):

- ID transaksi dan `attemptId`.
- Waktu (UTC) — ditampilkan dalam waktu lokal.
- Nominal QRIS, biaya dari QR, total.
- Harga display & buyback saat transaksi (snapshot, bukan referensi ke config).
- Unit emas, gram, nilai emas, pembulatan.
- Saldo sebelum dan sesudah.
- Nama merchant / kota / penerbit (jika ada), jenis QR, status CRC, daftar warning (kode saja).
- Versi config dan versi disclosure.

Tidak disimpan: payload QR mentah, PAN merchant, nama file gambar, atau data pribadi apa pun.

## 10. Reset dan tambah saldo

| Aksi | Efek | Konfirmasi |
|---|---|---|
| Reset data demo | Saldo → `initialBalanceUnits`, history dihapus | Dialog eksplisit |
| Tambah saldo demo | Menambah unit ke saldo, **tidak** menghapus history | Dialog dengan input gram |

"Tambah saldo demo" ada agar demo bisa diulang berkali-kali tanpa kehilangan riwayat. Penambahan
saldo **tidak** dicatat sebagai transaksi merchant; jika dicatat, gunakan penanda "saldo demo
ditambahkan" dan jangan pernah tampil sebagai pembayaran.

## 11. Kalimat yang dilarang

- "Emas Anda telah dijual" → gunakan "Emas yang disimulasikan terjual".
- "Pembayaran berhasil" / "Lunas" / "Merchant menerima dana".
- "Harga hari ini" → gunakan "Harga simulasi".

Semua teks final ada di `18_UI_COPY_ID.md`.
