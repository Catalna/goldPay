# 01 — Product Requirements Document (PRD)

## 1. Ringkasan produk

GoldPay adalah konsep fitur untuk pengalaman Pegadaian Tring!: pengguna membayar QRIS merchant
dengan mengonversi sebagian emas digital dalam satu alur checkout. Prototipe ini adalah aplikasi
Flutter Android mandiri untuk mendemonstrasikan konsep tersebut.

**Prototipe ini bukan aplikasi resmi Pegadaian, tidak berafiliasi dengan Pegadaian, tidak menjual
emas, dan tidak melakukan pembayaran.**

## 2. Problem statement

Pemilik emas digital yang ingin membayar merchant harus menjual emas, menunggu dana masuk ke
rekening/e-wallet, lalu membayar. Tiga langkah dan satu penantian itu membuat orang batal di tengah.

GoldPay menguji apakah satu alur — scan → nominal → quote → konfirmasi — cukup untuk membuat saldo
emas terasa seperti alat bayar, tanpa menyembunyikan biaya atau risiko.

**Batasan prototipe:** tidak ada emas terjual, tidak ada dana berpindah, tidak ada notifikasi ke
merchant, dan aplikasi tidak memiliki akses jaringan pada build rilis.

## 3. Tujuan produk

- Mendemonstrasikan checkout QRIS dengan pemindaian kamera nyata di perangkat fisik.
- Membaca hanya field yang benar-benar ada di payload; tidak pernah mengarang data merchant.
- Membedakan perilaku QR statis (nominal manual) dan dinamis (nominal read-only).
- Menghitung konversi emas dengan presisi integer dan pembulatan yang dapat diaudit.
- Mencatat transaksi demo secara lokal dan menurunkan saldo demo **tepat satu kali**.
- Menyediakan receipt dan history yang jujur, termasuk disclosure yang konsisten.
- Menghasilkan demo yang stabil dan dapat diulang dalam 60–90 detik.

## 4. Non-goals

- Penjualan emas nyata, pembayaran QRIS nyata, settlement, refund, reversal, notifikasi merchant.
- API Pegadaian/Tring!, integrasi PJP, bank, atau e-wallet.
- Login, KYC, akun, data keuangan pribadi.
- Harga pasar langsung, price feed, atau jaminan harga.
- Smart liquidity, split payment, cashback, portofolio, fitur investasi lain.
- Verifikasi identitas merchant atau kelayakan pembayaran QRIS.
- Dark mode, iOS, tablet layout khusus, multi-bahasa.

## 5. Persona

**A — Pemilik emas digital.** Ingin memahami berapa gram yang dipakai dan berapa sisa tabungannya.
Butuh transparansi harga, biaya, dan pembulatan.

**B — Juri/evaluator kompetisi.** Butuh demo cepat, kredibel, terlihat "hidup", dan jujur soal
batasan. Akan bertanya soal settlement, monetisasi, dan legalitas.

**C — Developer/mahasiswa.** Butuh arsitektur yang bisa diuji, langkah kecil, dan aturan yang
mencegah AI menghasilkan monolit tak terbaca.

**D — Penguji compliance/mitra.** Akan mencari klaim berlebihan, data pribadi yang tersimpan, dan
bukti bahwa aplikasi tidak dapat memindahkan uang.

## 6. Jobs to be done

- "Saat melihat QRIS, saya ingin tahu berapa gram emas yang akan terpakai."
- "Saat QR sudah berisi nominal, saya ingin melihatnya tanpa bisa mengubahnya."
- "Saat QR tidak berisi nominal, saya ingin mengisinya sendiri dengan aman."
- "Saat konfirmasi, saya ingin melihat sisa emas saya, bukan hanya potongannya."
- "Saya ingin tahu dengan jelas bahwa merchant belum dibayar."

## 7. Prinsip pengalaman

1. Kamera dulu, cepat, satu tangan.
2. Jangan menebak: field yang tidak ada ditampilkan sebagai tidak tersedia.
3. Transparan: nominal, biaya dari QR, harga buyback, gram, pembulatan, sisa saldo.
4. Konfirmasi eksplisit, menyebut konsekuensi ("Anda akan menjual emas").
5. Disclosure DEMO terlihat di setiap layar transaksi.
6. Error ramah, selalu ada jalan keluar (Scan ulang, galeri, tempel).
7. Lokal sepenuhnya: tanpa jaringan, tanpa data pribadi.
8. Tidak ada gamifikasi yang mendorong likuidasi emas.

## 8. Kebutuhan fungsional

| ID | Kebutuhan | Prioritas |
|---|---|---|
| FR-01 | Home menampilkan saldo emas demo, nilai perkiraan, dan harga simulasi | Must |
| FR-02 | Pengguna dapat membuka scanner kamera | Must |
| FR-03 | Scanner membaca QR nyata dan berhenti setelah satu hasil | Must |
| FR-04 | Parser mendukung subset EMV/QRIS yang terdokumentasi dan melaporkan data tak didukung | Must |
| FR-05 | QR statis memungkinkan input nominal manual | Must |
| FR-06 | Nominal dari QR dinamis ditampilkan **read-only** | Must |
| FR-07 | Quote menghitung gram, nilai emas, pembulatan, dan sisa saldo dari config demo | Must |
| FR-08 | Konfirmasi memvalidasi quote, saldo, dan masa berlaku | Must |
| FR-09 | Transaksi sukses memotong saldo tepat sekali dan menyimpan satu record | Must |
| FR-10 | Receipt dan history menampilkan data transaksi + disclosure | Must |
| FR-11 | Reset demo dengan konfirmasi eksplisit | Should |
| FR-12 | Scanner menangani izin ditolak, QR invalid, payload tak didukung, dan scan ganda | Must |
| FR-13 | Mode demo dapat memaksa kegagalan transaksi berikutnya tanpa memotong saldo | Should |
| FR-14 | Tidak ada request jaringan atau permintaan pembayaran | Must |
| FR-15 | Demo Settings: tempel payload QR sebagai fallback | Must |
| FR-16 | Demo Settings: pilih gambar QR dari galeri (`analyzeImage`) | Must |
| FR-17 | Quote berlaku 5 menit; setelah itu wajib "Perbarui penawaran" | Must |
| FR-18 | Biaya tip/convenience dari QR (tag 55/56/57) ditampilkan sebagai baris terpisah | Should |
| FR-19 | Tambah saldo demo tanpa menghapus history | Should |
| FR-20 | APK release tidak memiliki permission `INTERNET` | Must |

Catatan: FR-15/16 bukan "nice to have". Tanpa keduanya, rencana fallback di
`13_LIVE_DEMO_SCRIPT.md` tidak dapat dijalankan.

## 9. Kebutuhan non-fungsional

- **Ketahanan:** tidak crash untuk payload malformed (diuji fuzz 10.000 input).
- **Kinerja:** parse < 16 ms, quote < 2 ms, commit < 100 ms di perangkat kelas menengah.
- **Privasi:** payload QR tidak disimpan; tidak ada data pribadi; tidak ada jaringan.
- **Aksesibilitas:** kontras, target sentuh 48 dp, label screen reader, teks tidak terpotong pada
  skala 1,3.
- **Persistensi:** saldo dan history bertahan setelah restart.
- **Konsistensi:** saldo dan history tidak pernah berbeda (satu penulisan atomik).
- **Keterujian:** parser, kalkulator, dan state machine diuji tanpa Flutter.
- **Transparansi:** DEMO disclosure di semua layar transaksi.
- **Offline:** alur utama berfungsi tanpa internet setelah instalasi.

## 10. Kriteria penerimaan

- Aplikasi berjalan di perangkat Android fisik; kamera memindai QR nyata.
- Fixture F01–F10 menghasilkan perilaku sesuai `19_TEST_QR_FIXTURES.md`.
- Nama merchant dengan karakter non-ASCII tidak merusak parsing (uji byte UTF-8).
- QR statis meminta nominal; QR dinamis menampilkan nominal read-only.
- Quote menampilkan nominal, biaya QR, harga buyback, gram, pembulatan, dan sisa saldo.
- Angka gram yang tampil **sama persis** dengan unit yang tersimpan dan dipotong.
- Konfirmasi ganda menghasilkan **satu** transaksi.
- Batal/gagal tidak mengubah saldo dan tidak menambah history.
- Quote kedaluwarsa setelah 5 menit dan tidak dapat dikonfirmasi.
- Saldo tidak cukup memblokir konfirmasi dengan penjelasan kekurangan.
- Transaksi muncul di history dan detail setelah restart aplikasi.
- Reset memulihkan saldo awal dan menghapus history setelah konfirmasi.
- APK release terbukti tidak memiliki permission `INTERNET`.
- Tidak ada teks yang menyiratkan merchant sudah dibayar.

## 11. Metrik kesiapan demo

- 10.000 input acak ke parser tanpa crash.
- 5 pemindaian berturut-turut pada kondisi pencahayaan berbeda tanpa crash.
- 5 transaksi demo sukses dengan perubahan saldo yang benar.
- 1 sesi dengan saldo tidak cukup, 1 sesi gagal paksa, 1 sesi quote kedaluwarsa — semua tanpa
  potongan saldo.
- 1 uji restart: saldo dan history identik.
- 2 kali dry-run penuh di lokasi presentasi (lampu & jarak sebenarnya).
- Juri dapat menyelesaikan alur utama tanpa intervensi developer dalam 60–90 detik.

## 12. Asumsi produk

- Harga emas dan spread adalah konfigurasi demo.
- Format QRIS bervariasi; dukungan sengaja dibatasi pada subset terdokumentasi.
- Parser hanya membaca struktur; tidak memverifikasi merchant.
- Demo tidak mewakili kelayakan regulasi atau kesepakatan mitra pembayaran.
- Ekonomi nyata dan jalur settlement dibahas di `17_BUSINESS_CASE_AND_SETTLEMENT.md`.

## 13. Definisi siap demo

MVP siap ketika seluruh kriteria penerimaan lolos di perangkat target, APK release terpasang bersih,
izin kamera berfungsi pada pemakaian pertama, QR cetak cadangan tersedia, dan operator demo sudah
melatih prosedur reset serta fallback.
