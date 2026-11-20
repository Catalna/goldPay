/// Canonical UI copy — mirrors docs/18_UI_COPY_ID.md.
///
/// Never write user-facing strings in widgets. If a string is missing here,
/// add it to the doc first, then to this file.
abstract final class CopyId {
  // 0. Brand (never rebrand — D-02)
  static const String appName = 'GoldPay';
  static const String badgeDemo = 'DEMO';

  // 1. Disclosure
  static const String disclaimerShort =
      'Prototype. Tidak melakukan pembayaran sungguhan.';
  static const String disclaimerBanner =
      'DEMO — merchant belum menerima pembayaran.';
  static const String disclaimerReceipt =
      'Tidak ada emas yang dijual dan tidak ada dana yang ditransfer. '
      'Merchant belum dibayar.';
  static const String disclaimerPrice =
      'Harga simulasi — bukan harga Pegadaian.';
  static const String disclaimerConcept =
      'GoldPay adalah konsep prototipe dan tidak berafiliasi dengan Pegadaian.';

  // 2. Navigation and buttons
  static const String navScan = 'Scan QRIS';
  static const String navScanTab = 'Scan';
  static const String navHomeTab = 'Beranda';
  static const String navHistory = 'Riwayat';
  static const String navSettings = 'Pengaturan demo';
  static const String navSettingsTab = 'Pengaturan';
  static const String navBack = 'Kembali';
  static const String navRescan = 'Scan ulang';
  static const String navEnterAmount = 'Masukkan nominal';
  static const String navContinue = 'Lanjut';
  static const String navConfirm = 'Simulasikan pembayaran';
  static const String navCancel = 'Batalkan';
  static const String navRefreshQuote = 'Perbarui penawaran';
  static const String navHome = 'Ke beranda';
  static const String navViewHistory = 'Lihat riwayat';
  static const String navAddGold = 'Tambah saldo demo';
  static const String navReset = 'Reset data demo';
  static const String navRetry = 'Coba lagi';

  // 3. Labels
  static const String labelBalance = 'Saldo emas (demo)';
  static const String labelBalanceRupiah = 'Perkiraan nilai';
  static const String labelPriceDisplay = 'Harga emas simulasi';
  static const String labelPriceBuyback = 'Harga buyback simulasi';
  static const String labelAmount = 'Nominal QRIS';
  static const String labelQrFee = 'Biaya dari QR (tip/kenyamanan)';
  static const String labelTotal = 'Total yang harus dibayar';
  static const String labelGoldUsed = 'Emas terjual';
  static const String labelGoldValue = 'Nilai emas';
  static const String labelGoldPriceUsed = 'Harga konversi';
  static const String labelRounding = 'Pembulatan ke atas';
  static const String labelBalanceBefore = 'Saldo sebelum';
  static const String labelBalanceAfter = 'Sisa saldo';
  static const String labelMerchant = 'Merchant';
  static const String labelMerchantIssuer = 'Penerbit QR (dari data QR)';
  static const String labelCity = 'Kota';
  static const String labelQrType = 'Jenis QR';
  static const String labelTerminal = 'Terminal';
  static const String labelTransactionId = 'ID transaksi';
  static const String labelTime = 'Waktu';
  static const String labelStatus = 'Status';
  static const String labelSource = 'Sumber';
  static const String labelCrc = 'Integritas data (CRC)';
  static const String labelQrAmountLocked =
      'Nominal dari QR — tidak dapat diubah';
  static const String labelConfigVersion = 'Versi konfigurasi';
  static const String labelHistorySection = 'Riwayat transaksi';

  // 4. Fallback values
  static const String valueMerchantUnknown = 'Nama merchant tidak tersedia';
  static const String valueCityUnknown = 'Kota tidak tersedia';
  static const String valueIssuerUnknown = 'Penerbit tidak dikenali';
  static const String valueQrTypeStatic = 'Statis (nominal diisi manual)';
  static const String valueQrTypeDynamic = 'Dinamis (nominal dari QR)';
  static const String valueQrTypeUnknown = 'Tidak diketahui';
  static const String valueCrcValid = 'CRC cocok (bukan bukti keaslian)';
  static const String valueCrcInvalid =
      'CRC tidak cocok — data mungkin berubah';
  static const String valueSourceCamera = 'Kamera';
  static const String valueSourcePaste = 'Tempel manual';
  static const String valueSourceGallery = 'Galeri';

  // 5. Transaction status
  static const String statusProcessing = 'Memproses transaksi demo…';
  static const String statusCompleted = 'Transaksi demo berhasil';
  static const String statusFailed = 'Transaksi demo gagal';
  static const String statusQuoteExpired = 'Penawaran kedaluwarsa';
  static const String statusInsufficient = 'Saldo demo tidak cukup';

  // 6. Parser errors
  static const String errorEmptyPayload =
      'QR tidak berisi data. Coba pindai ulang.';
  static const String errorPayloadTooLarge =
      'Data QR terlalu panjang untuk diproses.';
  static const String errorMalformedTlv = 'Struktur data QR tidak dikenali.';
  static const String errorTruncatedValue =
      'Data QR tidak lengkap atau terpotong.';
  static const String errorDuplicateCriticalTag =
      'Data QR memiliki informasi ganda yang membingungkan.';
  static const String errorUnsupportedFormat =
      'QR ini bukan QRIS yang didukung.';
  static const String errorUnsupportedCurrency =
      'Mata uang pada QR tidak didukung (hanya IDR).';
  static const String errorInvalidAmount = 'Nominal pada QR tidak valid.';
  static const String errorAmountOutOfRange =
      'Nominal di luar batas demo (Rp1.000 – Rp1.000.000).';

  // 7. Parser warnings
  static const String warningCrcMismatch =
      'CRC tidak cocok. Data tetap ditampilkan, tetapi mungkin telah berubah.';
  static const String warningCrcMissing =
      'QR tidak memuat pemeriksaan integritas (CRC).';
  static const String warningCrcNotLast =
      'Pemeriksaan integritas QR tidak berada di posisi yang benar.';
  static const String warningTipPromptIgnored =
      'QR meminta tip. Demo tidak menambahkan tip.';
  static const String warningTipIncomplete =
      'QR memuat aturan biaya yang tidak lengkap; biaya tambahan diabaikan.';
  static const String warningMissingMerchantName =
      'QR tidak memuat nama merchant.';
  static const String warningUnknownTagPresent =
      'QR memuat data tambahan yang tidak ditampilkan.';
  static const String warningDuplicateNonCriticalTag =
      'QR memuat informasi ganda; hanya yang pertama dipakai.';
  static const String warningNonAsciiValue =
      'QR memuat karakter khusus; sebagian teks mungkin tidak tampil sempurna.';
  static const String warningUnexpectedCountry = 'Negara pada QR bukan ID.';
  static const String warningDynamicWithoutAmount =
      'QR berjenis dinamis tetapi tidak memuat nominal.';

  // 8. Quote and validation
  static const String quoteValidUntil = 'Penawaran berlaku sampai {time}';
  static const String quoteExpiredBody =
      'Harga dapat berubah. Perbarui penawaran untuk melanjutkan.';
  static const String quoteInsufficientBody =
      'Kekurangan {rupiah} ({gram}) dari saldo demo Anda.';
  static const String quoteRoundingNote =
      'Emas dibulatkan ke atas ke 0,0001 g terdekat agar menutup total pembayaran.';
  static const String quoteConfirmIntro =
      'Anda akan menjual emas untuk membayar nominal ini.';
  static const String validationAmountRequired =
      'Masukkan nominal terlebih dahulu.';
  static const String validationAmountMin = 'Nominal minimum Rp1.000.';
  static const String validationAmountMax = 'Nominal maksimum Rp1.000.000.';
  static const String validationAmountInteger =
      'Nominal harus berupa angka bulat rupiah.';
  static const String validationGoldInvalid =
      'Masukkan jumlah gram yang valid (maksimal 4 desimal).';

  // 9. Dialogs
  static const String dialogResetTitle = 'Reset data demo?';
  static const String dialogResetBody =
      'Saldo demo kembali ke nilai awal dan seluruh riwayat transaksi dihapus. '
      'Tindakan ini tidak dapat dibatalkan.';
  static const String dialogResetConfirm = 'Ya, reset';
  static const String dialogAddGoldTitle = 'Tambah saldo demo';
  static const String dialogAddGoldBody =
      'Saldo demo hanya untuk keperluan demonstrasi dan tidak memiliki nilai uang.';
  static const String dialogAddGoldField = 'Jumlah emas (gram)';
  static const String dialogAddGoldConfirm = 'Tambah';
  static const String dialogPermissionTitle = 'Izin kamera diperlukan';
  static const String dialogPermissionBody =
      'GoldPay memakai kamera hanya untuk membaca kode QR. '
      'Gambar tidak disimpan dan tidak dikirim ke mana pun.';
  static const String dialogPermissionSettings = 'Buka pengaturan';

  // 10. Demo settings
  static const String settingsSectionFallback = 'Fallback demonstrasi';
  static const String settingsPasteLabel = 'Tempel payload QR';
  static const String settingsPasteHint =
      'Tempel isi teks QR di sini (hanya untuk demo).';
  static const String settingsPasteAction = 'Gunakan payload';
  static const String settingsGalleryAction = 'Pilih gambar QR';
  static const String settingsFailureToggle =
      'Paksa gagal transaksi berikutnya';
  static const String settingsFailureHint =
      'Untuk menguji alur gagal. Saldo tidak akan berkurang.';
  static const String settingsDevOnly = 'Kontrol demo — bukan fitur pengguna';
  static const String settingsGalleryError = 'Gambar tidak dapat dibaca.';
  static const String settingsSectionBalance = 'Saldo demo';
  static const String settingsSectionData = 'Data demo';
  static const String settingsSectionInfo = 'Info demo';
  static const String settingsAppVersion = 'Versi aplikasi';
  static const String settingsTxCount = 'Transaksi tersimpan';

  // 11. States
  static const String historyEmpty = 'Belum ada transaksi demo';

  // 12. Scanner
  static const String scannerTitle = 'Scan QRIS';
  static const String scannerHint = 'Arahkan ke kode QRIS merchant';
  static const String scannerTorch = 'Flash';
  static const String scannerProcessing = 'Membaca QR…';
  static const String scannerDeniedBody =
      'Kamera tidak dapat dipakai. Berikan izin kamera, atau pakai tempel '
      'payload di Pengaturan demo.';
  static const String scannerErrorBody =
      'Kamera gagal dibuka. Coba lagi atau pakai tempel payload di '
      'Pengaturan demo.';
  static const String scannerPasteFallback = 'Tempel payload manual';

  // 13. Screen titles
  static const String screenReviewTitle = 'Periksa QR';
  static const String screenQuoteTitle = 'Konfirmasi';
  static const String screenResultTitle = 'Hasil transaksi demo';
  static const String screenReceiptTitle = 'Detail transaksi';
  static const String screenHistoryTitle = 'Riwayat';
  static const String screenSettingsTitle = 'Pengaturan demo';

  // 14. Result
  static const String resultCompletedBody =
      'Emas yang disimulasikan terjual. Merchant belum menerima dana.';
  static const String resultFailedBody =
      'Tidak ada saldo yang dipotong dan tidak ada transaksi yang disimpan.';
}
