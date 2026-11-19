# 09 — UI/UX dan Spesifikasi Layar

> Tujuan: aplikasi terlihat seperti produk finansial yang sengaja dirancang, bukan template AI.
> Semua teks memakai `18_UI_COPY_ID.md` — jangan mengarang copy di widget.

## 1. Design token

### 1.1 Warna

| Token | Hex | Pemakaian |
|---|---|---|
| `primary` | `#0F6B4F` | Tombol utama, header, indikator aktif |
| `primaryDark` | `#0A4B38` | Pressed state, header gelap |
| `primarySoft` | `#D7F0E6` | Latar badge/chip, highlight ringan |
| `gold` | `#C9973A` | Aksen saldo emas, ikon, garis grafik |
| `goldSoft` | `#F6E7C8` | Latar kartu saldo emas |
| `goldInk` | `#6B4A12` | **Teks** di atas latar emas |
| `ink` | `#0E1512` | Teks utama |
| `inkMuted` | `#46524C` | Teks sekunder |
| `border` | `#E1E8E5` | Garis kartu, divider |
| `surface` | `#F6F8F7` | Latar halaman |
| `card` | `#FFFFFF` | Permukaan kartu |
| `success` | `#177A4C` | Status sukses |
| `warning` | `#B4690E` | Warning (CRC, tip) |
| `danger` | `#B3261E` | Error, aksi destruktif |
| `info` | `#1F5FA8` | Info netral |

Aturan kontras (sudah dihitung):

- Putih di atas `primary` ≈ **6,5:1** → aman untuk teks normal.
- `ink` di atas `surface` ≈ **16:1** → aman.
- `gold` di atas putih ≈ **2,6:1** → **jangan** untuk teks. Untuk teks emas pakai `goldInk` (≈ 7:1).
- Error tidak boleh dibedakan hanya dari warna; selalu ada ikon + teks.

### 1.2 Tipografi

Font: **Plus Jakarta Sans** (OFL), di-bundle di `assets/fonts/`. Tidak memakai `google_fonts` (D-07).

| Token | Ukuran / line-height | Weight | Pemakaian |
|---|---|---|---|
| `display` | 34 / 40 | 700 | Saldo emas di Home |
| `h1` | 24 / 30 | 700 | Judul layar |
| `h2` | 20 / 26 | 600 | Judul kartu |
| `body` | 16 / 24 | 400 | Teks umum |
| `bodyStrong` | 16 / 24 | 600 | Nilai penting |
| `caption` | 13 / 18 | 400 | Label, disclaimer |
| `mono` | 16 / 22 | 600 | ID transaksi (tabular figures) |

Angka uang dan gram memakai `FontFeature.tabularFigures()` agar tidak "bergeser" saat berubah.
Skala teks harus tetap rapi pada `textScaleFactor` 1,3 (diuji).

### 1.3 Spasi, radius, elevasi

- Spasi: `4, 8, 12, 16, 24, 32` (kelipatan 4).
- Padding halaman: 20 kiri/kanan; jarak antar-blok 24.
- Radius: `12` kartu, `16` bottom sheet, `999` chip/tombol bulat.
- Elevasi: 0. Pemisahan memakai border `1px border` dan latar `surface` — hindari bayangan tebal.
- Tinggi tombol utama: **52**; target sentuh minimum **48 × 48**.

### 1.4 Motion

- Durasi 150–250 ms, `Curves.easeOutCubic`. Tanpa bounce/elastic.
- Transisi angka saldo: `TweenAnimationBuilder` 400 ms, hanya sekali setelah transaksi.
- Hormati `MediaQuery.disableAnimations` → semua durasi 0.
- Tidak ada animasi loop di luar indikator processing.

## 2. Kerangka layar

### 2.1 Home

```
┌────────────────────────────────────┐
│ GoldPay        [DEMO]      ⚙  ⟳    │  AppBar transparan
│ Prototype. Tidak melakukan         │  disclaimer.short (caption)
│ pembayaran sungguhan.              │
│ ┌────────────────────────────────┐ │
│ │ Saldo emas (demo)              │ │  kartu goldSoft
│ │ 1,2500 g                       │ │  display
│ │ ≈ Rp1.837.500                  │ │  body, inkMuted
│ │ Harga buyback simulasi         │ │
│ │ Rp1.470.000/g                  │ │
│ └────────────────────────────────┘ │
│ ┌────────────────────────────────┐ │
│ │      Scan QRIS                 │ │  tombol primary 52
│ └────────────────────────────────┘ │
│ Riwayat                    Lihat → │
│ ┌────────────────────────────────┐ │
│ │ DEMO — merchant belum menerima │ │  disclaimer.banner
│ │ pembayaran.                    │ │
│ └────────────────────────────────┘ │
│ GoldPay adalah konsep prototipe…   │  disclaimer.concept
└────────────────────────────────────┘
```

State: loading (skeleton kartu), siap, storage error (kartu peringatan + tombol pemulihan).

### 2.2 Scanner

```
┌────────────────────────────────────┐
│ ✕            Scan QRIS             │
│                                    │
│      ┌──────────────────┐          │
│      │                  │          │  overlay 260×260, corner bracket
│      │   [kamera]       │          │
│      └──────────────────┘          │
│   Arahkan ke kode QRIS merchant    │
│                                    │
│            [ ⚡ Flash ]            │
│  DEMO — merchant belum dibayar.    │
└────────────────────────────────────┘
```

State: meminta izin, izin ditolak (penjelasan + "Buka pengaturan"), kamera aktif, memproses
(spinner + kamera berhenti), error kamera. Satu decode → hentikan kamera segera.

### 2.3 Review / Nominal

```
┌────────────────────────────────────┐
│ ←  Periksa QR                      │
│ ┌────────────────────────────────┐ │
│ │ Warung Bu Tini                 │ │  h2
│ │ Jakarta · ID.CO.BANKCONTOH.WWW │ │  caption
│ │ Dinamis (nominal dari QR)      │ │  chip
│ │ ✓ CRC cocok (bukan bukti       │ │  info, bukan hijau "verified"
│ │   keaslian)                    │ │
│ └────────────────────────────────┘ │
│ Nominal QRIS                       │
│ Rp150.000                          │  read-only untuk dynamic
│ Nominal dari QR — tidak dapat      │  caption
│ diubah                             │
│ ┌────────────────────────────────┐ │
│ │        Lanjut                  │ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

Untuk QR statis: field input uang dengan keyboard numerik, format otomatis `Rp150.000`, validasi
inline. Tombol nonaktif sampai valid.

### 2.4 Quote / Konfirmasi

```
┌────────────────────────────────────┐
│ ←  Konfirmasi                      │
│ ┌────────────────────────────────┐ │
│ │ Nominal QRIS        Rp150.000  │ │
│ │ Biaya dari QR             Rp0  │ │  hanya jika ada
│ │ Total               Rp150.000  │ │  bodyStrong
│ ├────────────────────────────────┤ │
│ │ Harga buyback   Rp1.470.000/g  │ │
│ │ Emas terjual        0,1021 g   │ │
│ │ Nilai emas         Rp150.087   │ │
│ │ Pembulatan ke atas     Rp87    │ │
│ ├────────────────────────────────┤ │
│ │ Saldo sebelum       1,2500 g   │ │
│ │ Sisa saldo          1,1479 g   │ │
│ └────────────────────────────────┘ │
│ Anda akan menjual emas untuk       │  bodyStrong, goldInk
│ membayar nominal ini.              │
│ Penawaran berlaku sampai 14.17     │  countdown
│ ┌────────────────────────────────┐ │
│ │   Simulasikan pembayaran       │ │
│ └────────────────────────────────┘ │
│            Batalkan                │
│ DEMO — merchant belum dibayar.     │
└────────────────────────────────────┘
```

State: valid, saldo tidak cukup (tombol nonaktif + kekurangan), kedaluwarsa (tombol diganti
"Perbarui penawaran"), konfigurasi tidak valid (layar error).

### 2.5 Processing

Layar penuh, latar `primary` gelap, indikator melingkar, teks `status.processing`, tanpa logo bank,
tanpa klaim jaringan. Tombol back dinonaktifkan.

### 2.6 Result / Receipt

```
┌────────────────────────────────────┐
│ ✓ Transaksi demo berhasil          │
│ DEMO — merchant belum membayar.    │
│ ┌────────────────────────────────┐ │
│ │ Nominal            Rp150.000   │ │
│ │ Emas terjual        0,1021 g   │ │
│ │ Sisa saldo          1,1479 g   │ │
│ │ Merchant   Warung Bu Tini      │ │
│ │ ID    5f0f2a9e-…               │ │  mono
│ │ Waktu 19 Nov 2026, 14.12       │ │
│ │ Sumber kamera                  │ │
│ └────────────────────────────────┘ │
│ [ Ke beranda ]  [ Lihat riwayat ]  │
│ Tidak ada emas yang dijual dan     │
│ tidak ada dana yang ditransfer.    │
└────────────────────────────────────┘
```

Gagal: ikon `danger`, `status.failed`, tombol "Coba lagi" (ke quote baru) dan "Batalkan".

### 2.7 History

Daftar kartu: nama merchant (atau fallback), waktu, nominal, gram, badge DEMO. Urut terbaru dulu.
Empty state: ilustrasi garis sederhana + "Belum ada transaksi demo" + tombol Scan. Header memuat
`disclaimer.banner`.

### 2.8 Detail transaksi

Sama dengan receipt, ditambah baris status CRC, warning (jika ada), harga display & buyback,
pembulatan, dan versi config. Tidak ada tombol "Ulangi pembayaran".

### 2.9 Demo Settings

Dikelompokkan dengan header `settings.devOnly`:

1. Fallback: tempel payload, pilih gambar, toggle paksa gagal.
2. Saldo: tambah saldo demo.
3. Data: reset (danger).
4. Info: versi app, versi config, jumlah transaksi tersimpan.

## 3. Aturan global

- `disclaimer.banner` tampil di semua layar transaksi (Home, Scanner, Review, Quote, Processing,
  Result, History, Detail).
- Tidak ada badge "terverifikasi", "aman", "resmi", atau logo pihak ketiga.
- Kamera hanya diminta saat pengguna menekan Scan, bukan saat app dibuka.
- Semua tombol punya label teks; ikon saja hanya untuk back/close dengan `tooltip` + `semanticLabel`.
- Jangan menampilkan payload QR, PAN merchant, atau ID merchant di UI.

## 4. Aksesibilitas

1. `Semantics` pada kartu saldo: "Saldo emas demo, 1 koma 2500 gram, perkiraan 1 juta 837 ribu 500 rupiah".
2. Tombol utama punya `semanticLabel` yang sama dengan teksnya.
3. Error diumumkan lewat `SemanticsService.announce` saat muncul.
4. Uji `textScaleFactor` 1,0 dan 1,3 tanpa clipping.
5. Uji layar 5" (320 dp) dan 6,7" (412 dp).
6. Jalur tempel/galeri juga berfungsi sebagai alternatif aksesibilitas kamera.
7. Fokus urutan logis; dialog reset mengembalikan fokus ke pemicu.

## 5. Yang harus dihindari

- Gradien pelangi, glassmorphism, glow, atau bayangan berlapis.
- Ilustrasi 3D generik dan ikon campur beberapa set.
- Angka saldo dengan animasi berlebihan atau efek "counting" lama.
- Warna emas untuk teks di atas putih (kontras gagal).
- Copy puitis ("Perjalanan emas Anda dimulai") — gunakan bahasa faktual.
