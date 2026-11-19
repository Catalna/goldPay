# 14 — Regulatory, Risiko, dan Batas Demo

> Dokumen ini **bukan** nasihat hukum. Tujuannya mencegah klaim berlebihan dan menyiapkan pertanyaan
> yang benar sebelum presentasi.

## 1. Disclosure prototipe

GoldPay adalah konsep prototipe, bukan produk resmi Pegadaian, bukan aplikasi Pegadaian, dan tidak
berafiliasi dengan Pegadaian. Tidak ada emas yang dijual, tidak ada pembayaran yang dimulai, tidak
ada settlement QRIS, dan tidak ada merchant yang menerima dana.

Kalimat wajib:
`disclaimer.banner` di semua layar transaksi, `disclaimer.receipt` di struk, `disclaimer.concept` di
Home. Lihat `18_UI_COPY_ID.md`.

## 2. Kenapa alur ini secara struktural bukan "bayar pakai emas"

Di Indonesia, QRIS dibayar dalam rupiah oleh penyelenggara jasa pembayaran berlisensi. Emas bukan
alat pembayaran. Maka konsep ini **selalu dua kaki**:

1. Menjual emas pada harga buyback.
2. Menggunakan rupiah hasil penjualan untuk membayar QRIS.

Karena penjualan emas tidak settle seketika, merchant hanya bisa dibayar T+0 jika ada pihak yang
menalangi. Detail opsi ada di `17_BUSINESS_CASE_AND_SETTLEMENT.md` §3.

**Jangan** mempresentasikan GoldPay sebagai "uang emas" atau "emas sebagai alat pembayaran".

## 3. Area regulasi yang perlu divalidasi

Status di bawah adalah **area yang harus diperiksa**, bukan kesimpulan. Verifikasi versi terbaru
sebelum dikutip.

| Area | Yang perlu dipastikan | Status |
|---|---|---|
| Perizinan pembayaran | Peran sebagai PJP/akuisisi QRIS, atau kemitraan dengan PJP berizin | Belum divalidasi |
| Penyelenggaraan QRIS | Keanggotaan, aturan peserta, tanggung jawab settlement | Belum divalidasi |
| Perdagangan emas | Izin dan pengawasan perdagangan emas/bulion; status pengawasan dapat berubah | Belum divalidasi |
| Perlindungan konsumen | Disclosure harga, biaya, pembatalan, penyelesaian sengketa | Belum divalidasi |
| Privasi data | UU PDP 27/2022 untuk produk produksi (demo tidak mengumpulkan data pribadi) | Tidak relevan untuk demo |
| Anti pencucian uang | KYC/AML jika ada akun dan nilai transaksi nyata | Tidak relevan untuk demo |

Jangan menyatakan "sudah compliant" berdasarkan prototipe ini.

## 4. Risiko dan mitigasi

| Risiko | Dampak | Mitigasi di prototipe |
|---|---|---|
| Pengguna mengira merchant dibayar | Sangat tinggi | Banner DEMO di semua layar, copy receipt eksplisit |
| Data QR disalahartikan sebagai verifikasi merchant | Tinggi | Tanpa badge terverifikasi; CRC dijelaskan sebagai integritas |
| CRC dianggap autentikasi | Tinggi | Teks `value.crcValid` menyebut "bukan bukti keaslian" |
| Payload tidak didukung | Sedang | Error spesifik + Scan ulang + fallback |
| Pembulatan tidak cocok | Sedang | Unit integer, ceil, tampil = potong, property test |
| Tap ganda | Sedang | Lock + dedupe `attemptId` + satu penulisan |
| Storage rusak | Sedang | Snapshot `_prev` + layar pemulihan |
| Izin kamera ditolak | Sedang | Penjelasan + pengaturan + galeri/tempel |
| Tampak seperti aplikasi resmi | Tinggi | Tanpa logo/aset Pegadaian; disclaimer konsep |
| Harga demo dianggap harga nyata | Tinggi | Label "Harga simulasi" di setiap kemunculan |
| QR merchant asli tersimpan | Sedang | Payload tidak pernah dipersist |
| Demo dianggap bukti kelayakan regulasi | Tinggi | Bagian §2 dan §3 di dokumen ini |

## 5. Perilaku demo yang aman

1. Jangan memanggil API pembayaran, membuka tautan dari QR, atau membuka aplikasi lain dari payload.
2. Jangan meminta PIN, OTP, nomor kartu, atau kredensial apa pun.
3. Jangan mensimulasikan konektivitas bank/PJP yang menyiratkan otorisasi nyata.
4. Struk selalu menyatakan tidak ada dana ditransfer.
5. Reset data demo eksplisit dan dikendalikan pengguna.
6. Build rilis tanpa permission `INTERNET` — bukti teknis, bukan janji.

## 6. Produk yang bertanggung jawab

Emas bagi banyak nasabah adalah tabungan jangka panjang. Fitur ini mempermudah likuidasi untuk
konsumsi, sehingga perlu guardrail:

- Konfirmasi menyebut "Anda akan menjual emas", bukan hanya "Bayar".
- Tampilkan sisa emas dan nilainya setelah transaksi.
- Tidak ada gamifikasi, poin, atau notifikasi yang mendorong penjualan.
- Di produk nyata: batas harian/bulanan, ringkasan dampak, dan edukasi.
- Pertimbangkan alternatif non-likuidasi (mis. pembiayaan) sebagai bagian dari riset produk.

Bagian ini layak menjadi satu slide saat presentasi — penguji sering menilai kesadaran risiko.

## 7. Privasi

Demo:

- Tidak mengumpulkan nama, nomor telepon, email, atau akun.
- Tidak mengirim data ke jaringan.
- Tidak menyimpan payload QR, PAN merchant, atau gambar.
- State hanya berisi saldo demo dan ringkasan transaksi.

Produk nyata akan memerlukan: dasar pemrosesan yang sah, persetujuan, retensi terbatas, hak subjek
data, dan penilaian dampak privasi.

## 8. Pertanyaan yang akan diajukan (dan sikap yang benar)

| Pertanyaan | Sikap |
|---|---|
| "Ini legal?" | "Belum divalidasi. Ini prototipe tanpa dana dan tanpa data pribadi." |
| "Merchant dapat uang?" | "Tidak. Kami tidak punya izin internet di APK ini." |
| "Siapa yang bayar dulu?" | "Partner PJP dengan skema talangan — asumsi, belum kontrak." |
| "Kalau harga emas berubah?" | "Quote dikunci 5 menit; risiko di luar spread ditanggung pemberi harga." |
| "Apakah ini mendorong orang menjual tabungan?" | "Itu risiko yang kami akui; ada guardrail dan batas di produk nyata." |

## 9. Arah produksi (bukan scope MVP)

Kemitraan PJP, harga buyback resmi dengan lock, otentikasi kuat, persetujuan, orkestrasi dua kaki
dengan rekonsiliasi, strategi reversal/refund, pemantauan operasional, kontrol fraud, penilaian
keamanan, dan tinjauan hukum. Semua itu di luar prototipe ini.
