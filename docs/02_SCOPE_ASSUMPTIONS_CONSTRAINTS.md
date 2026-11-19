# 02 — Scope, Asumsi, dan Batasan

> Semua keputusan di sini final dan selaras dengan `00_DECISION_LOG.md`.

## 1. Termasuk dalam scope

- Aplikasi Flutter Android mandiri, offline.
- Pemindaian QR dengan kamera nyata pada perangkat fisik.
- Parser EMV/QRIS subset terdokumentasi (byte-based, bounds-checked, CRC soft-fail).
- Tiga jalur masukan QR: kamera, gambar dari galeri, tempel payload manual.
- Tampilan data merchant hanya dari field yang berhasil di-parse.
- QR statis: input nominal manual. QR dinamis: nominal read-only.
- Biaya tip/convenience dari QR (tag 55/56/57) dihitung dan ditampilkan.
- Konversi emas dengan satuan integer `0,0001 g`, pembulatan ke atas, harga buyback simulasi.
- Quote berlaku 5 menit dengan status kedaluwarsa.
- Konfirmasi eksplisit, transaksi demo lokal, potong saldo tepat sekali.
- Receipt, history, detail transaksi, reset, tambah saldo demo.
- Toggle kegagalan simulasi.
- Persistensi lokal dengan pemulihan snapshot.
- Build APK release tanpa permission `INTERNET`.
- Dokumentasi, fixture QR, dan prosedur demo.

## 2. Di luar scope

- API Pegadaian atau Tring!, aset/logo/merk resmi.
- Inisiasi pembayaran QRIS, akuisisi, otorisasi, settlement, refund, reversal, notifikasi merchant.
- Penjualan emas nyata, penarikan dana, transfer bank, akses akun emas.
- Harga pasar langsung, price feed, jaminan harga.
- Login, KYC, identitas, akun keuangan, basis data remote.
- Smart liquidity, split funding, rekomendasi, cashback, fitur investasi.
- Verifikasi merchant, deteksi fraud, klaim keaslian QR.
- iOS, tablet layout khusus, dark mode, multi-bahasa.

## 3. Ditolak secara sadar (dan alasannya)

| Hal | Alasan |
|---|---|
| SQLite/Isar | 200 record kecil cukup di satu blob JSON; menambah dependency dan kompleksitas migrasi |
| Satuan mikrogram | Presisi tampilan 4 desimal; unit `0,0001 g` membuat tampilan = potongan |
| `google_fonts` | Mengunduh font saat runtime → melanggar offline dan klaim tanpa jaringan |
| `riverpod_generator` | Codegen menambah langkah build tanpa manfaat untuk skala demo |
| UI input tip | Bukan inti konsep; QR yang meminta tip diberi catatan, tip tidak ditambahkan |
| Dark mode | Menambah permukaan QA tanpa menambah nilai demo |
| Animasi kompleks | Mengalihkan perhatian dari angka dan disclosure |

## 4. Asumsi

- Pengembang memakai Windows 10/11, Flutter stable, dan Android phone dengan USB debugging.
- Versi paket diperiksa saat setup (`flutter pub add`), bukan disalin dari dokumen.
- `mobile_scanner` mendukung kamera dan `analyzeImage` pada perangkat target (`minSdk 23`).
- Saldo dan harga adalah angka sintetis yang jelas berlabel simulasi.
- Pengguna demo memahami bahwa QR scan bukan pembayaran.
- Satu operator menguasai prosedur reset dan fallback.

## 5. Batasan

- Payload QRIS tidak seragam; dukungan dibatasi pada tag yang terdokumentasi.
- Nama merchant/kota bisa kosong, salah ketik, atau tidak ada di payload.
- CRC adalah integritas data, bukan autentikasi.
- Izin kamera dan USB debugging di bawah kendali pengguna perangkat.
- Kualitas kamera, fokus, dan pencahayaan bervariasi.
- QRIS nyata hanya dipakai untuk demonstrasi parsing; tidak ada pembayaran yang dicoba.
- Angka ekonomi di `17_BUSINESS_CASE_AND_SETTLEMENT.md` adalah ilustrasi, bukan proyeksi.

## 6. Aturan kontrol scope

Sebuah usulan fitur hanya diterima jika memenuhi salah satu:

1. Membuat alur inti (scan → nominal → quote → konfirmasi → saldo/history) lebih benar, lebih jujur,
   atau lebih tahan gagal; **atau**
2. Menghilangkan risiko kegagalan demo (fallback, reset, fixture); **atau**
3. Membuktikan klaim yang sudah dibuat (mis. tanpa permission internet, tanpa data pribadi).

Selain itu: tunda. Jangan menambah fitur untuk "terlihat lebih kaya".
