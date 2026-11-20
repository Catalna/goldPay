# 18 — UI Copy (Bahasa Indonesia, canonical)

> **Aturan:** file ini adalah satu-satunya sumber teks yang tampil ke pengguna.
> Jangan mengarang variasi kalimat di kode. Semua string diimplementasi sebagai konstanta
> (mis. `lib/core/constants/copy_id.dart`) dan diuji dengan golden test.
>
> **Kenapa ketat:** seluruh kredibilitas demo bergantung pada satu kalimat disclosure.
> Versi sebelumnya punya 5 variasi berbeda untuk kalimat yang sama.

## 1. Disclosure (wajib, jangan divariasikan)

| Key | Teks | Muncul di |
|---|---|---|
| `app.name` | `GoldPay` | AppBar beranda, judul aplikasi |
| `badge.demo` | `DEMO` | Badge kecil di beranda, riwayat, dan kartu transaksi |
| `disclaimer.short` | `Prototype. Tidak melakukan pembayaran sungguhan.` | Home (bawah AppBar) |
| `disclaimer.banner` | `DEMO — merchant belum menerima pembayaran.` | Home, Scanner, Review, Quote, Processing, Result, History |
| `disclaimer.receipt` | `Tidak ada emas yang dijual dan tidak ada dana yang ditransfer. Merchant belum dibayar.` | Receipt & detail transaksi |
| `disclaimer.price` | `Harga simulasi — bukan harga Pegadaian.` | Home (kartu harga), Quote, Receipt |
| `disclaimer.concept` | `GoldPay adalah konsep prototipe dan tidak berafiliasi dengan Pegadaian.` | Home (footer) + halaman Tentang |

## 2. Navigasi dan tombol

| Key | Teks |
|---|---|
| `nav.scan` | `Scan QRIS` |
| `nav.scanTab` | `Scan` |
| `nav.homeTab` | `Beranda` |
| `nav.history` | `Riwayat` |
| `nav.settings` | `Pengaturan demo` |
| `nav.settingsTab` | `Pengaturan` |
| `nav.back` | `Kembali` |
| `nav.rescan` | `Scan ulang` |
| `nav.enterAmount` | `Masukkan nominal` |
| `nav.continue` | `Lanjut` |
| `nav.confirm` | `Simulasikan pembayaran` |
| `nav.cancel` | `Batalkan` |
| `nav.refreshQuote` | `Perbarui penawaran` |
| `nav.home` | `Ke beranda` |
| `nav.viewHistory` | `Lihat riwayat` |
| `nav.addGold` | `Tambah saldo demo` |
| `nav.reset` | `Reset data demo` |
| `nav.retry` | `Coba lagi` |

## 3. Label

| Key | Teks |
|---|---|
| `label.balance` | `Saldo emas (demo)` |
| `label.balanceRupiah` | `Perkiraan nilai` |
| `label.priceDisplay` | `Harga emas simulasi` |
| `label.priceBuyback` | `Harga buyback simulasi` |
| `label.amount` | `Nominal QRIS` |
| `label.qrFee` | `Biaya dari QR (tip/kenyamanan)` |
| `label.total` | `Total yang harus dibayar` |
| `label.goldUsed` | `Emas terjual` |
| `label.goldValue` | `Nilai emas` |
| `label.goldPriceUsed` | `Harga konversi` |
| `label.rounding` | `Pembulatan ke atas` |
| `label.balanceBefore` | `Saldo sebelum` |
| `label.balanceAfter` | `Sisa saldo` |
| `label.merchant` | `Merchant` |
| `label.merchantIssuer` | `Penerbit QR (dari data QR)` |
| `label.city` | `Kota` |
| `label.qrType` | `Jenis QR` |
| `label.terminal` | `Terminal` |
| `label.transactionId` | `ID transaksi` |
| `label.time` | `Waktu` |
| `label.status` | `Status` |
| `label.source` | `Sumber` |
| `label.crc` | `Integritas data (CRC)` |
| `label.qrAmountLocked` | `Nominal dari QR — tidak dapat diubah` |
| `label.configVersion` | `Versi konfigurasi` |
| `label.historySection` | `Riwayat transaksi` |

## 4. Nilai fallback

| Key | Teks |
|---|---|
| `value.merchantUnknown` | `Nama merchant tidak tersedia` |
| `value.cityUnknown` | `Kota tidak tersedia` |
| `value.issuerUnknown` | `Penerbit tidak dikenali` |
| `value.qrTypeStatic` | `Statis (nominal diisi manual)` |
| `value.qrTypeDynamic` | `Dinamis (nominal dari QR)` |
| `value.qrTypeUnknown` | `Tidak diketahui` |
| `value.crcValid` | `CRC cocok (bukan bukti keaslian)` |
| `value.crcInvalid` | `CRC tidak cocok — data mungkin berubah` |
| `value.sourceCamera` | `Kamera` |
| `value.sourcePaste` | `Tempel manual` |
| `value.sourceGallery` | `Galeri` |

## 5. Status transaksi

| Key | Teks |
|---|---|
| `status.processing` | `Memproses transaksi demo…` |
| `status.completed` | `Transaksi demo berhasil` |
| `status.failed` | `Transaksi demo gagal` |
| `status.quoteExpired` | `Penawaran kedaluwarsa` |
| `status.insufficient` | `Saldo demo tidak cukup` |
| `history.empty` | `Belum ada transaksi demo` |

## 6. Error parser (petakan per kode di `07_QRIS_PARSER_SPEC.md`)

| Kode | Teks |
|---|---|
| `EMPTY_PAYLOAD` | `QR tidak berisi data. Coba pindai ulang.` |
| `PAYLOAD_TOO_LARGE` | `Data QR terlalu panjang untuk diproses.` |
| `MALFORMED_TLV` | `Struktur data QR tidak dikenali.` |
| `TRUNCATED_VALUE` | `Data QR tidak lengkap atau terpotong.` |
| `DUPLICATE_CRITICAL_TAG` | `Data QR memiliki informasi ganda yang membingungkan.` |
| `UNSUPPORTED_FORMAT` | `QR ini bukan QRIS yang didukung.` |
| `UNSUPPORTED_CURRENCY` | `Mata uang pada QR tidak didukung (hanya IDR).` |
| `INVALID_AMOUNT` | `Nominal pada QR tidak valid.` |
| `AMOUNT_OUT_OF_RANGE` | `Nominal di luar batas demo (Rp1.000 – Rp1.000.000).` |

Semua error di atas disertai tombol `nav.rescan` dan `nav.cancel`.

## 7. Warning parser (tidak memblokir)

| Kode | Teks |
|---|---|
| `CRC_MISMATCH` | `CRC tidak cocok. Data tetap ditampilkan, tetapi mungkin telah berubah.` |
| `CRC_MISSING` | `QR tidak memuat pemeriksaan integritas (CRC).` |
| `CRC_NOT_LAST` | `Pemeriksaan integritas QR tidak berada di posisi yang benar.` |
| `TIP_PROMPT_IGNORED` | `QR meminta tip. Demo tidak menambahkan tip.` |
| `TIP_INCOMPLETE` | `QR memuat aturan biaya yang tidak lengkap; biaya tambahan diabaikan.` |
| `MISSING_MERCHANT_NAME` | `QR tidak memuat nama merchant.` |
| `UNKNOWN_TAG_PRESENT` | `QR memuat data tambahan yang tidak ditampilkan.` |
| `DUPLICATE_NON_CRITICAL_TAG` | `QR memuat informasi ganda; hanya yang pertama dipakai.` |
| `NON_ASCII_VALUE` | `QR memuat karakter khusus; sebagian teks mungkin tidak tampil sempurna.` |
| `UNEXPECTED_COUNTRY` | `Negara pada QR bukan ID.` |
| `DYNAMIC_WITHOUT_AMOUNT` | `QR berjenis dinamis tetapi tidak memuat nominal.` |

## 8. Quote dan validasi

| Key | Teks |
|---|---|
| `quote.validUntil` | `Penawaran berlaku sampai {time}` |
| `quote.expiredBody` | `Harga dapat berubah. Perbarui penawaran untuk melanjutkan.` |
| `quote.insufficientBody` | `Kekurangan {rupiah} ({gram}) dari saldo demo Anda.` |
| `quote.roundingNote` | `Emas dibulatkan ke atas ke 0,0001 g terdekat agar menutup total pembayaran.` |
| `quote.confirmIntro` | `Anda akan menjual emas untuk membayar nominal ini.` |
| `validation.amountRequired` | `Masukkan nominal terlebih dahulu.` |
| `validation.amountMin` | `Nominal minimum Rp1.000.` |
| `validation.amountMax` | `Nominal maksimum Rp1.000.000.` |
| `validation.amountInteger` | `Nominal harus berupa angka bulat rupiah.` |
| `validation.goldInvalid` | `Masukkan jumlah gram yang valid (maksimal 4 desimal).` |

## 9. Dialog dan konfirmasi

| Key | Teks |
|---|---|
| `dialog.reset.title` | `Reset data demo?` |
| `dialog.reset.body` | `Saldo demo kembali ke nilai awal dan seluruh riwayat transaksi dihapus. Tindakan ini tidak dapat dibatalkan.` |
| `dialog.reset.confirm` | `Ya, reset` |
| `dialog.addGold.title` | `Tambah saldo demo` |
| `dialog.addGold.body` | `Saldo demo hanya untuk keperluan demonstrasi dan tidak memiliki nilai uang.` |
| `dialog.addGold.field` | `Jumlah emas (gram)` |
| `dialog.addGold.confirm` | `Tambah` |
| `dialog.permission.title` | `Izin kamera diperlukan` |
| `dialog.permission.body` | `GoldPay memakai kamera hanya untuk membaca kode QR. Gambar tidak disimpan dan tidak dikirim ke mana pun.` |
| `dialog.permission.settings` | `Buka pengaturan` |

## 10. Pengaturan demo

| Key | Teks |
|---|---|
| `settings.section.fallback` | `Fallback demonstrasi` |
| `settings.pasteLabel` | `Tempel payload QR` |
| `settings.pasteHint` | `Tempel isi teks QR di sini (hanya untuk demo).` |
| `settings.pasteAction` | `Gunakan payload` |
| `settings.galleryAction` | `Pilih gambar QR` |
| `settings.failureToggle` | `Paksa gagal transaksi berikutnya` |
| `settings.failureHint` | `Untuk menguji alur gagal. Saldo tidak akan berkurang.` |
| `settings.devOnly` | `Kontrol demo — bukan fitur pengguna` |
| `settings.galleryError` | `Gambar tidak dapat dibaca.` |
| `settings.section.balance` | `Saldo demo` |
| `settings.section.data` | `Data demo` |
| `settings.section.info` | `Info demo` |
| `settings.appVersion` | `Versi aplikasi` |
| `settings.txCount` | `Transaksi tersimpan` |

## 11. Scanner

| Key | Teks |
|---|---|
| `scanner.title` | `Scan QRIS` |
| `scanner.hint` | `Arahkan ke kode QRIS merchant` |
| `scanner.torch` | `Flash` |
| `scanner.processing` | `Membaca QR…` |
| `scanner.deniedBody` | `Kamera tidak dapat dipakai. Berikan izin kamera, atau pakai tempel payload di Pengaturan demo.` |
| `scanner.errorBody` | `Kamera gagal dibuka. Coba lagi atau pakai tempel payload di Pengaturan demo.` |
| `scanner.pasteFallback` | `Tempel payload manual` |

## 12. Judul layar

| Key | Teks |
|---|---|
| `screen.reviewTitle` | `Periksa QR` |
| `screen.quoteTitle` | `Konfirmasi` |
| `screen.resultTitle` | `Hasil transaksi demo` |
| `screen.receiptTitle` | `Detail transaksi` |
| `screen.historyTitle` | `Riwayat` |
| `screen.settingsTitle` | `Pengaturan demo` |

## 13. Hasil transaksi

| Key | Teks |
|---|---|
| `result.completedBody` | `Emas yang disimulasikan terjual. Merchant belum menerima dana.` |
| `result.failedBody` | `Tidak ada saldo yang dipotong dan tidak ada transaksi yang disimpan.` |

## 14. Aturan penulisan

1. Format rupiah: `Rp150.000` (tanpa spasi, tanpa desimal).
2. Format gram: `0,1021 g` (koma desimal, 4 digit).
3. Tanggal: `19 Nov 2026, 14.05` (locale `id_ID`).
4. Jangan memakai kata "berhasil dibayar", "lunas", "terverifikasi", atau "merchant menerima dana".
5. Jangan memakai "uang" untuk saldo demo — gunakan "saldo demo" / "emas".
6. Semua kalimat disclosure memakai titik di akhir dan tidak disingkat.
