# 13 — Live Demo Script

> Tujuan: menunjukkan pemindaian QR nyata, parsing jujur, konversi emas, dan transaksi demo lokal —
> tanpa pernah menyiratkan merchant dibayar.

## 1. Sebelum hari-H (H-1)

- [ ] APK release terpasang di ponsel presentasi.
- [ ] Uji `aapt dump permissions` → tidak ada `INTERNET` (buktikan jika ditanya).
- [ ] Latihan penuh 2×, ukur durasi (target 60–90 detik).
- [ ] Cetak F01 dan F02 (versi `_print.png`) di kertas matte, minimal 6 × 6 cm.
- [ ] Simpan F01/F02 di galeri ponsel sebagai cadangan.
- [ ] Catat payload F01/F02 di catatan ponsel (fallback tempel).
- [ ] Pastikan saldo demo cukup untuk minimal 3 transaksi.
- [ ] Siapkan satu sesi "saldo tidak cukup" dan satu "gagal paksa" untuk pertanyaan penguji.

## 2. Pre-flight (T-15 menit)

| Waktu | Tindakan |
|---|---|
| T-15 | Charge > 60%; matikan hemat baterai |
| T-12 | Nyalakan **mode pesawat** (bukti offline; alur tetap jalan) |
| T-10 | Nyalakan layar penuh, kecerahan maksimum, DND aktif |
| T-8 | Buka app, reset data demo, konfirmasi saldo 1,2500 g |
| T-5 | Uji satu scan pada QR cetak di lokasi sebenarnya |
| T-3 | Tutup aplikasi lain (khususnya kamera/e-wallet) |
| T-1 | Buka Home, jangan biarkan layar mati |

Jika pada T-5 pemindaian gagal 2×, langsung pindah ke QR yang lebih besar/layar lebih terang, dan
siapkan narasi fallback.

## 3. Naskah (60–90 detik)

| Detik | Tindakan | Kalimat |
|---|---|---|
| 0–8 | Home | "GoldPay mengeksplorasi bagaimana emas digital bisa dipakai untuk bayar QRIS dalam satu alur." |
| 8–15 | Tunjuk saldo & harga | "Ini saldo emas demo 1,25 gram dan harga simulasi — bukan harga Pegadaian." |
| 15–22 | Tekan Scan QRIS | "Saya pindai QRIS merchant biasa." |
| 22–32 | Scan | "Aplikasi hanya membaca data yang ada di QR. Ini bukan verifikasi merchant dan bukan pembayaran." |
| 32–42 | Review | "Nama dan penerbit berasal dari payload. Kalau tidak ada, aplikasi bilang tidak tersedia — tidak mengarang." |
| 42–52 | Nominal | "QR ini statis, jadi saya isi nominalnya." *(atau: "QR ini sudah membawa nominal, jadi tidak bisa diubah.")* |
| 52–65 | Quote | "Aplikasi menghitung emas dengan harga buyback simulasi, termasuk pembulatan ke atas dan sisa saldo." |
| 65–72 | Konfirmasi | "Saya konfirmasi — aplikasi menyebut jelas bahwa ini penjualan emas yang disimulasikan." |
| 72–80 | Processing → Result | "Semua terjadi lokal. Tidak ada data keluar." |
| 80–90 | Home + History | "Saldo berkurang, riwayat tercatat. Merchant belum dibayar — ini prototipe." |

## 4. Kalimat yang harus diucapkan

- "Data QR terbaca" — bukan "merchant terverifikasi".
- "Harga simulasi" — bukan "harga hari ini".
- "Transaksi demo berhasil" — bukan "pembayaran berhasil".
- "Tidak ada emas yang dijual dan tidak ada dana yang ditransfer."

## 5. Fallback berurutan

| Kondisi | Tindakan | Yang dikatakan |
|---|---|---|
| Kamera buram / tidak fokus | Ganti ke QR cetak lebih besar, cahaya lebih terang | "Saya gunakan QR yang lebih besar." |
| Kamera gagal total | Demo Settings → **Pilih gambar QR** | "Saya pakai gambar QR dari galeri; sumbernya akan terlihat di aplikasi." |
| Galeri gagal | Demo Settings → **Tempel payload** | "Saya masukkan payload QR secara manual untuk melanjutkan demo." |
| Aplikasi crash | Buka ulang; state harus bertahan | "Data tersimpan lokal; saya lanjutkan." |
| Saldo habis | Demo Settings → **Tambah saldo demo** (jangan reset) | "Saya tambah saldo demo agar bisa lanjut." |
| Penguji minta lihat error | Scan F05/F07/F09/F10 | "Ini contoh penanganan QR yang tidak didukung." |

Jangan pernah menyembunyikan bahwa sumbernya galeri/tempel. UI sudah menampilkannya; mengelak akan
merusak kredibilitas.

## 6. Jika penguji bertanya

Jawaban lengkap ada di `17_BUSINESS_CASE_AND_SETTLEMENT.md` §8. Ringkas:

- **Merchant dibayar?** Tidak. Prototipe; APK tidak punya izin internet.
- **Monetisasi?** Spread buyback, bukan biaya tambahan ke pengguna.
- **Siapa menalangi?** Partner PJP (asumsi, belum dikontrak).
- **Legal?** Belum divalidasi; demo tidak menyentuh dana/data pribadi.

## 7. Setelah demo

- [ ] Reset data demo (jangan tinggalkan saldo/riwayat orang lain).
- [ ] Matikan mode pesawat.
- [ ] Catat kejadian tak terduga (untuk perbaikan berikutnya).
- [ ] Jangan menunjukkan layar sukses ke merchant atau orang lain tanpa penjelasan.

## 8. Pantangan

1. Jangan memindai QRIS asli di depan kasir lalu berpura-pura membayar.
2. Jangan memakai kata "lunas", "berhasil dibayar", "dana masuk".
3. Jangan menampilkan logo bank/PJP fiktif.
4. Jangan mengklaim integrasi Pegadaian.
5. Jangan meminta PIN, OTP, atau data akun siapa pun.
