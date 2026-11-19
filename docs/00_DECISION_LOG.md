# 00 — Decision Log (locked)

> **Status: LOCKED.** Dokumen ini adalah otoritas tunggal untuk keputusan teknis dan produk.
> Jika dokumen lain bertentangan dengan file ini, file ini yang menang.
> Jangan mengubah keputusan di sini tanpa menambah entri baru dengan nomor berikutnya.

Semua implementasi (manusia atau AI) **wajib membaca file ini sebelum menulis kode**.

## 1. Nama dan posisi produk

| ID | Keputusan | Alasan |
|---|---|---|
| D-01 | Nama kerja tetap **GoldPay**. Tidak ada afiliasi dengan Pegadaian. | Nama sudah dipakai di seluruh dokumen. Cek ketersediaan merek (DJKI) & nama Play Store sebelum rilis publik — bukan blocker pengembangan. |
| D-02 | Kata "Pegadaian" dan "Tring!" **tidak boleh** muncul di nama aplikasi, label APK, `applicationId`, ikon, atau deskripsi store. Hanya boleh di narasi lisan/dokumen konsep. | Menghindari kesan aplikasi resmi. |
| D-03 | Tidak memakai logo, warna brand, atau aset Pegadaian. Tema memakai palet sendiri di `09_UI_UX_SCREEN_SPEC.md`. | Alasan yang sama. |

## 2. Platform dan batasan teknis

| ID | Keputusan | Alasan |
|---|---|---|
| D-04 | Flutter + Dart, **Android saja**. `minSdk 23`, `targetSdk` versi stabil saat build. | `mobile_scanner` butuh Android modern; iOS tidak dipakai untuk demo. |
| D-05 | Sepenuhnya offline. **Tidak ada backend, tidak ada network call, tidak ada analytics.** | Menjaga kejujuran demo dan kesederhanaan. |
| D-06 | **APK release tidak memiliki permission `INTERNET`.** Permission dihapus di manifest release dengan `tools:node="remove"`. | Membuktikan klaim "tidak bisa membayar" secara teknis, bukan hanya naratif. |
| D-07 | Tidak memakai `google_fonts`. Font **Plus Jakarta Sans di-bundle** sebagai asset (`assets/fonts/`). | `google_fonts` mengunduh font saat runtime → melanggar D-05 dan berisiko gagal di venue tanpa internet. |
| D-08 | Bahasa aplikasi: **Indonesia saja**. Locale `id_ID`, panggil `initializeDateFormatting('id_ID')` di `main()`. | Menghindari format Rp/tanggal yang salah. |
| D-09 | Dark mode di luar scope MVP. | Fokus ke satu tampilan yang dipoles. |

## 3. Satuan, uang, dan pembulatan

| ID | Keputusan | Alasan |
|---|---|---|
| D-10 | Uang selalu **integer Rupiah**. Tidak ada `double` sebagai sumber kebenaran. | Menghindari galat pembulatan. |
| D-11 | Emas disimpan sebagai **integer unit**, `1 unit = 0,0001 g` (100 µg). `1 g = 10.000 unit`. | Presisi tampilan (4 desimal) sama persis dengan presisi penyimpanan → angka yang tampil = angka yang dipotong. |
| D-12 | Pembulatan emas dilakukan **ceil ke unit** saat quote dibuat. Jumlah yang didebit = jumlah yang ditampilkan. | Quote harus selalu menutup biaya; tidak boleh ada sisa tersembunyi. |
| D-13 | Tidak ada satuan mikrogram dan tidak ada desimal internal tambahan. | Satu satuan untuk semua layer. |
| D-14 | Batas nominal: `minPaymentIdr = 1.000`, `maxPaymentIdr = 1.000.000`, dan tidak boleh melebihi ekuivalen saldo. | Cukup untuk demo, mencegah angka tidak masuk akal. |

## 4. Harga dan biaya (model ekonomi demo)

| ID | Keputusan | Alasan |
|---|---|---|
| D-15 | Harga emas dimodelkan dengan **dua angka**: `goldPriceDisplayIdrPerGram` (harga acuan, ditampilkan) dan `goldBuybackPriceIdrPerGram` (harga yang dipakai konversi). Spread default **200 bps**. Contoh: 1.500.000 / 1.470.000. | Emas nyata punya spread buyback, bukan "fee" fiktif. Ini yang akan ditanyakan orang Pegadaian. |
| D-16 | `convenienceFeeIdr` yang dibebankan ke pengguna = **0** di MVP. MDR merchant tidak dimodelkan. | Pengguna tidak boleh merasa lebih mahal daripada bayar tunai. Ekonomi sesungguhnya ada di spread (lihat `17_BUSINESS_CASE_AND_SETTLEMENT.md`). |
| D-17 | Biaya tip/convenience **yang tertulis di QR** (tag 55/56/57) tetap dihitung dan ditampilkan sebagai baris terpisah, bukan disembunyikan. | Nominal harus benar terhadap isi QR. |
| D-18 | Quote berlaku **5 menit**. Setelah itu status `expired` dan pengguna wajib "Perbarui penawaran". | Menunjukkan kesadaran risiko harga, murah diimplementasi. |

## 5. Alur QRIS

| ID | Keputusan | Alasan |
|---|---|---|
| D-19 | QR **dinamis** (nominal ada di payload): nominal **read-only**, tidak bisa diedit. QR **statis** (tanpa nominal): input manual wajib. | Menghindari aplikasi menampilkan nominal yang tidak diminta merchant. |
| D-20 | Nominal tag 54: maksimal 13 karakter, maksimal 2 desimal, hanya digit dan satu titik. Untuk IDR, desimal bukan nol → `INVALID_AMOUNT` (ditolak, **tidak** dibulatkan diam-diam). | Uang tidak boleh ditebak. |
| D-21 | QR tanpa nama merchant → label "Nama merchant tidak tersedia". Tidak pernah mengarang nama, kota, atau kategori. | Kejujuran data. |
| D-22 | Penerbit QR diambil dari sub-tag `00` pada template 26–51 (GUI), mis. `ID.CO.BANKCONTOH.WWW` → tampil sebagai "Penerbit QR (dari data QR)". Tanpa badge "terverifikasi". | Informasi ini benar-benar ada di payload dan membuat demo kredibel tanpa klaim palsu. |
| D-23 | CRC-16/CCITT-FALSE **diimplementasi**. Ketidakcocokan CRC = **warning**, bukan blocker. | Banyak QRIS nyata di lapangan CRC-nya tidak valid; demo tidak boleh gagal karenanya. |

## 6. Parser

| ID | Keputusan | Alasan |
|---|---|---|
| D-24 | Parser adalah **pure Dart**, tidak pernah `throw` untuk input pengguna, hasilnya sealed result. | Parse gagal adalah kondisi normal, bukan exception. |
| D-25 | Panjang TLV dihitung dalam **byte UTF-8**, bukan `String.length`. | `String.length` di Dart menghitung code unit UTF-16 → offset rusak untuk karakter non-ASCII. |
| D-26 | Batas payload **1.024 byte**. Lebih dari itu → `PAYLOAD_TOO_LARGE`. Kedalaman template maksimal 2 level. | Mencegah input jahat/aneh. |
| D-27 | Tag yang dibaca: `00, 01, 26–51 (sub 00/01/02/03), 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62 (sub 01/05/07/08), 63`. Tag lain disimpan sebagai opaque, tidak ditafsirkan. | Cakupan jelas, tidak menebak. |
| D-28 | Payload mentah **tidak pernah** disimpan ke state, history, atau log rilis. | Privasi merchant & pengguna. |

## 7. Transaksi dan penyimpanan

| ID | Keputusan | Alasan |
|---|---|---|
| D-29 | Hanya transaksi **`completed_demo`** yang dipersist ke history. `cancelled` dan `failed_demo` tidak dipersist. | History = catatan transaksi, bukan log debug. |
| D-30 | Status `processing_demo` **tidak pernah** dipersist. | Tidak boleh ada record "pending selamanya" setelah app dimatikan. |
| D-31 | Setelah gagal, retry kembali ke **`quoted`** (re-quote), bukan `draft`. | Saldo dan waktu bisa berubah. |
| D-32 | Idempotensi diimplementasi dengan: lock sinkron (`isCommitting`), satu penulisan state atomik, dan penolakan jika `attemptId` sudah ada di daftar transaksi. | "Idempotency key" tanpa dedupe store tidak berarti apa-apa di aplikasi lokal. |
| D-33 | Storage: **SharedPreferences**, satu blob JSON `goldpay_state_v1` + snapshot sebelumnya `goldpay_state_prev_v1`. Maksimal **200 transaksi** (yang terlama dibuang). | Cukup untuk demo, tanpa dependency database. |
| D-34 | Urutan commit: tulis snapshot lama ke `_prev` → tulis state baru → update state reaktif → tampilkan sukses. Tidak pernah sukses sebelum write selesai. | Menjaga konsistensi saldo & history. |
| D-35 | Reset demo: konfirmasi eksplisit, menghapus history, mengembalikan saldo awal. Tidak ada reset tersembunyi. | Kontrol pengguna. |
| D-36 | "Tambah saldo demo" tersedia terpisah dari reset, agar demo bisa diulang tanpa menghapus history. | Kebutuhan operasional hari-H. |

## 8. Arsitektur dan UI

| ID | Keputusan | Alasan |
|---|---|---|
| D-37 | **Layer-first**: `lib/domain` (pure Dart), `lib/data`, `lib/features/<fitur>/{presentation,application}`. Tidak ada `features/*/domain`. | Satu rumah untuk parser/kalkulator; menghindari duplikasi. |
| D-38 | State management: `flutter_riverpod` dengan `Notifier`/`AsyncNotifier` manual. Tidak memakai codegen (`riverpod_generator`). | Lebih sedikit tooling, lebih mudah direview. |
| D-39 | Navigasi: `go_router`. State draft/quote disimpan di controller, bukan di route arguments. | Menghindari payload besar di URL. |
| D-40 | Error domain memakai `sealed class Result<T>`; UI memetakan ke copy di `18_UI_COPY_ID.md`. | Parse gagal bukan exception; copy konsisten. |
| D-41 | Scanner: `mobile_scanner`, `DetectionSpeed.noDuplicates`, `autoStart: false`, satu `MobileScannerController` per fitur, `WidgetsBindingObserver` untuk lifecycle, kamera dihentikan saat route ditinggalkan. | Mencegah callback ganda dan kamera hitam. |

## 9. Fitur penunjang demo (wajib)

| ID | Keputusan | Alasan |
|---|---|---|
| D-42 | Demo Settings menyediakan **tempel payload manual**. | Fallback hari-H jika kamera gagal. |
| D-43 | Demo Settings menyediakan **pilih gambar QR dari galeri** (`analyzeImage`). | Fallback kedua + jalur aksesibilitas. |
| D-44 | Demo Settings menyediakan toggle **"Paksa gagal transaksi berikutnya"**. Deterministik, tanpa network. | Memenuhi FR kegagalan simulasi dan lolos QA. |
| D-45 | Fallback wajib diberi label "Sumber: tempel manual / galeri", bukan menyamar sebagai scan kamera. | Kejujuran demo. |
| D-46 | `minSdk 24` (menggantikan 23 di D-04), mengikuti minimum Flutter 3.50 stable; `compileSdk`/`targetSdk` 36. | Flutter tool menolak/meng-upgrade `minSdk 23` otomatis; 24 tetap mencakup perangkat demo. **Butuh persetujuan pemilik produk.** |

---

## 10. Asumsi produk yang BELUM tervalidasi

Bagian ini **tidak memblokir pengembangan** dan tidak boleh dipresentasikan sebagai fakta.

1. Adanya mitra PJP/akuisisi yang mau membayar merchant T+0 sementara penjualan emas settle T+1/T+2.
2. Sumber harga buyback yang sah dan dapat dikunci selama 5 menit.
3. Pegadaian bersedia membuka API penjualan emas untuk alur pembayaran.
4. Status lisensi dan tanggung jawab hukum alur dua kaki (jual emas + bayar QRIS).
5. Beban biaya float dan siapa yang menanggungnya.
6. Kepatuhan UU PDP 27/2022 — demo tidak mengumpulkan data pribadi, tetapi produk produksi akan.
7. Permintaan pasar: apakah pengguna mau melikuidasi tabungan emas untuk konsumsi harian.

Rujukan pembahasan: `14_REGULATORY_RISK_DEMO_BOUNDARIES.md` dan `17_BUSINESS_CASE_AND_SETTLEMENT.md`.
