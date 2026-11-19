# 17 — Business Case, Settlement Path, dan FAQ

> Semua angka di dokumen ini **ilustratif** dan diberi label asumsi. Tidak ada angka yang boleh
> muncul di aplikasi demo tanpa label "simulasi".

## 1. Ringkasan

GoldPay menguji satu ide: saldo emas digital dipakai langsung untuk membayar QRIS tanpa pengguna
harus menjual emas, menunggu dana masuk rekening, lalu membayar. Nilai produknya bukan pada
"scan QR" (itu sudah biasa), melainkan pada **menghilangkan 2 langkah dan 1 penantian**.

Karena itu, seluruh kelayakan konsep bergantung pada satu hal yang tidak terlihat di layar:
**siapa yang membayar merchant hari ini, sementara emas baru terjual besok.**

## 2. Kenapa alurnya harus dua kaki

Di Indonesia, emas bukan alat pembayaran. QRIS dibayar dalam rupiah oleh penyelenggara jasa
pembayaran (PJP) berlisensi. Maka alur sesungguhnya selalu:

```
[1] Jual emas (harga buyback)  →  [2] Rupiah tersedia  →  [3] Bayar QRIS ke merchant
        settle T+1/T+2                butuh T+0
```

Demo menyembunyikan langkah 1–3 di belakang satu tombol. Di produk nyata, langkah 1–3 tidak bisa
disembunyikan — harus ada pihak yang menalangi (float) agar merchant menerima dana T+0.

**Ini pertanyaan pertama yang akan diajukan penguji/Pegadaian. Dokumen ini menjawabnya secara
eksplisit, bukan menghindarinya.**

## 3. Opsi jalur pendanaan (funding path)

| Opsi | Cara kerja | Siapa menanggung float | Waktu merchant dibayar | Kompleksitas | Catatan |
|---|---|---|---|---|---|
| **A. Pegadaian menjadi PJP / uang elektronik** | Pegadaian (atau entitas berizin) menerbitkan sarana pembayaran sendiri; emas dijual ke kas internal, rupiah langsung dikreditkan ke sarana tersebut | Pegadaian (neraca sendiri) | Instan | Sangat tinggi | Paling kuat secara strategis, paling berat secara lisensi & modal |
| **B. Kemitraan PJP + talangan** | Partner PJP membayar merchant; GoldPay melunasi partner setelah emas terjual | Partner PJP (dengan jaminan/limit kredit) | Instan | Sedang | **Paling realistis untuk pilot**; butuh kontrak, limit, dan rekonsiliasi harian |
| **C. Top-up e-wallet otomatis** | Emas dijual → dana masuk e-wallet pengguna → e-wallet membayar QRIS | Tidak ada (pengguna menunggu) | T+1 atau lebih | Rendah | Ini **bukan** single-flow yang dijanjikan; hanya otomasi 2 langkah |

**Keputusan konsep:** demo mempresentasikan **Opsi B**. Opsi A disebut sebagai arah jangka panjang;
Opsi C disebut sebagai pembanding (dan alasan produk ini ada). Jangan mengklaim Opsi A atau B sudah
dimiliki — itu asumsi yang belum divalidasi (`00_DECISION_LOG.md` §10).

## 4. Ekonomi per transaksi (ilustratif)

Asumsi: transaksi Rp150.000; spread buyback 200 bps; harga emas acuan Rp1.500.000/g; buyback
Rp1.470.000/g; biaya float 12%/tahun; biaya operasional/support Rp200/transaksi.

| Komponen | Nilai | Catatan |
|---|---|---|
| Nilai transaksi | Rp150.000 | — |
| Pendapatan spread (200 bps) | **+Rp3.000** | Selisih harga acuan vs buyback, bukan biaya tambahan ke pengguna |
| Bagi hasil MDR | Rp0 | Sebagai pembayar, GoldPay tidak otomatis mendapat MDR; hanya jika ada perjanjian bagi hasil dengan akuirer |
| Biaya float (1 hari) | −Rp49 | Rp150.000 × 12% ÷ 365 |
| Biaya operasional/support | −Rp200 | Asumsi |
| **Kontribusi bersih (sebelum kepatuhan & akuisisi)** | **≈ Rp2.750** | ≈ 1,8% dari nilai transaksi |

Implikasi:
- Model ini **tidak** membutuhkan biaya tambahan ke pengguna. Kalau aplikasi membebankan "fee 0,5%"
  ke pengguna, itu tanda model ekonominya belum dipahami.
- Sensitivitas terbesar ada pada **spread** dan **biaya float**, bukan pada volume semata.
- Tiket kecil (mis. Rp10.000) tetap menghasilkan spread kecil, tetapi biaya operasional tetap → ada
  ambang tiket minimum yang perlu dikaji. Demo memakai `minPaymentIdr = 1.000` hanya untuk
  kelancaran uji, bukan rekomendasi bisnis.

## 5. Risiko harga dan harga kunci

| Risiko | Penjelasan | Mitigasi yang masuk akal |
|---|---|---|
| Harga emas bergerak antara quote dan eksekusi | Pengguna melihat harga A, emas terjual di harga B | Quote lock 5 menit (sudah diimplementasi di demo) + eksekusi segera setelah konfirmasi |
| Spread tidak menutup pergerakan harga | Jika harga turun > spread dalam 5 menit, transaksi merugi | Lock dari trading desk, atau netting arus (jual & beli antar pengguna saling menutup) |
| Likuiditas emas tidak tersedia saat ramai | Permintaan jual melebihi stok pembeli | Batas harian per pengguna, antrean, atau penjualan ke pasar grosir |
| Settlement gagal di sisi partner | Merchant sudah dibayar, emas gagal terjual | Rekonsiliasi harian, dana cadangan, dan prosedur reversal |

## 6. Kenapa bukan sekadar "jual emas lalu transfer"?

| Alternatif | Langkah | Waktu | Gesekan |
|---|---|---|---|
| Jual emas → tarik ke rekening → bayar QRIS | 3–4 langkah, 2 aplikasi | T+1 atau lebih | Tinggi; pengguna sering batal di tengah |
| Top-up e-wallet dari dana hasil jual emas | 3 langkah | Menit–jam | Sedang; tetap ada perpindahan dana |
| Kartu/e-money berbasis saldo emas (jika ada) | 1 langkah | Instan | Butuh infrastruktur penerbit |
| **GoldPay (konsep)** | 1 alur, 1 aplikasi | Instan (dengan float) | Rendah, tetapi bergantung pada mitra pembayaran |

Pembeda yang jujur: **bukan teknologinya**, melainkan kemitraan settlement + likuiditas buyback.
Tanpa keduanya, GoldPay hanya mempercantik alur 3 langkah yang sudah ada.

## 7. Guardrail produk yang bertanggung jawab

Emas bagi banyak nasabah adalah tabungan jangka panjang, bukan dompet harian. Menjadikannya mudah
dicairkan untuk konsumsi membawa risiko yang harus diakui:

1. **Konfirmasi yang sadar**: tombol "Simulasikan pembayaran" selalu didahului kalimat "Anda akan
   menjual emas" + sisa emas setelah transaksi.
2. **Tampilkan sisa, bukan hanya potongan**: pengguna melihat dampak jangka panjang.
3. **Batas harian/bulanan** (di produk nyata) untuk mencegah likuidasi beruntun.
4. **Tidak ada gamifikasi/poin** yang mendorong penjualan emas.
5. **Edukasi singkat** bahwa emas umumnya untuk tujuan jangka panjang.
6. **Akses setara**: jalur tempel/galeri juga berfungsi sebagai aksesibilitas, bukan hanya fallback.

Bagian ini sebaiknya disebut **satu slide** saat presentasi — penguji sering menilai kesadaran risiko,
bukan hanya fitur.

## 8. FAQ penguji (jawaban singkat)

**1. Merchant-nya benar-benar dibayar?**
Tidak. Ini prototipe. Tidak ada dana berpindah, tidak ada emas terjual, dan APK rilis bahkan tidak
memiliki permission internet (D-06).

**2. Bagaimana monetisasinya?**
Spread buyback (ilustratif 200 bps), bukan biaya tambahan ke pengguna. Lihat §4.

**3. Siapa yang membayar merchant lebih dulu?**
Partner PJP dengan skema talangan (Opsi B). Ini asumsi yang belum dikontrak.

**4. Kalau harga emas turun saat pengguna checkout?**
Quote dikunci 5 menit; pergerakan di luar spread adalah risiko yang harus ditanggung pihak yang
memberi harga. Demo menunjukkan mekanisme kedaluwarsa quote.

**5. Kenapa pengguna tidak pakai e-wallet saja?**
Karena dana di e-wallet harus diisi dulu. GoldPay menguji apakah saldo emas bisa langsung menjadi
alat bayar — dengan biaya float sebagai harga dari kenyamanan itu.

**6. Ini legal?**
Belum divalidasi. Prototipe ini tidak menyentuh dana atau data pribadi. Validasi lisensi dan
tanggung jawab hukum ada di `14_REGULATORY_RISK_DEMO_BOUNDARIES.md`.

**7. Datanya aman?**
Demo tidak mengumpulkan data pribadi, tidak mengirim apa pun ke jaringan, dan tidak menyimpan
payload QR. Riwayat hanya tersimpan lokal di perangkat.

**8. Apa langkah berikutnya yang paling penting?**
Bukan fitur, melainkan **(a)** kesepakatan mitra settlement, **(b)** sumber harga buyback yang bisa
dikunci, dan **(c)** validasi compliance. Ketiganya bukan pekerjaan tim aplikasi.

## 9. Metrik pilot (bukan metrik demo)

Demo diukur dengan "apakah alur selesai 60–90 detik tanpa intervensi". Pilot diukur dengan:

- Activation: pengguna yang menyelesaikan transaksi pertama / yang membuka fitur.
- Repeat 30 hari: apakah orang memakainya lagi (sinyal kebutuhan nyata).
- Average ticket vs ambang ekonomi.
- Cancel rate di layar quote (sinyal kejutan harga).
- Waktu dari konfirmasi ke merchant menerima dana.
- Insiden rekonsiliasi per 1.000 transaksi.
- Porsi pengguna yang saldo emasnya turun di bawah ambang edukasi (sinyal risiko likuidasi).

## 10. Yang harus divalidasi, dan dengan siapa

| Pertanyaan | Pihak |
|---|---|
| Apakah penjualan emas bisa dieksekusi dalam hitungan detik? | Trading/treasury |
| Siapa yang memberi harga buyback dan berapa lama bisa dikunci? | Pricing |
| Bisa/tidak menjadi PJP, atau harus bermitra? | Compliance/legal |
| Batas talangan dan biaya modal | Finance/partner PJP |
| Kewajiban disclosure & perlindungan konsumen | Compliance |
| Penerimaan pengguna terhadap likuidasi tabungan | Product research |
