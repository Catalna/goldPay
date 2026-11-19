# 19 — Test QR Fixtures

> Semua payload di bawah **sintetis** dan tidak terhubung ke merchant nyata. CRC dihitung dengan
> CRC-16/CCITT-FALSE sesuai EMV QRCPS. Jangan pernah memakai payload ini untuk mencoba pembayaran
> sungguhan di aplikasi lain.

Gambar QR siap pakai ada di `assets/test_qris/`:
- `Fxx_*.png` — ukuran layar (box 14 px).
- `Fxx_*_print.png` — versi cetak (box 24 px), cetak minimal **6 × 6 cm**, kertas matte.

## 1. Ringkasan

| Fixture | Isi | Ekspektasi parser | Dipakai untuk |
|---|---|---|---|
| F01 | Statis, tanpa nominal | Sukses, `static`, nama & kota terbaca, CRC valid | Alur utama (input nominal manual) |
| F02 | Dinamis, nominal Rp150.000 | Sukses, `dynamic`, nominal read-only, CRC valid | Alur utama (nominal dari QR) |
| F03 | Nama merchant non-ASCII (`Café Kenangan`) | Sukses, panjang TLV dihitung per byte UTF-8 | Uji `String.length` vs byte |
| F04 | Dinamis + tip 5% (tag 55=03, 57=05) | Sukses, `qrFeeIdr = 5.000`, total 105.000 | Uji biaya dari QR |
| F05 | Mata uang USD (tag 53=840) | Gagal `UNSUPPORTED_CURRENCY` | Alur error |
| F06 | Payload valid, CRC dirusak | Sukses + warning `CRC_MISMATCH` | Uji CRC soft-fail |
| F07 | Nominal desimal `1500.50` | Gagal `INVALID_AMOUNT` | Uji larangan pembulatan diam-diam |
| F08 | Tanpa nama & kota merchant | Sukses + warning `MISSING_MERCHANT_NAME` | Uji label fallback |
| F09 | TLV terpotong (panjang deklarasi melebihi data) | Gagal `TRUNCATED_VALUE` | Uji parser defensif |
| F10 | URL biasa | Gagal `UNSUPPORTED_FORMAT` | Uji QR non-QRIS |

## 2. Payload

### F01 — statis tanpa nominal
```text
00020101021126720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01630482C5
```

### F02 — dinamis, nominal Rp150.000
```text
00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR0154061500006304555C
```

### F03 — nama merchant non-ASCII (14 byte, 13 karakter)
```text
00020101021126720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Café Kenangan6007Jakarta61051234562110707KASIR016304E595
```
Catatan: `5914` menyatakan **14 byte UTF-8**, sedangkan `"Café Kenangan".length` di Dart bernilai
**13**. Fixture ini gagal jika parser memakai `String.length`.

### F04 — dinamis + tip persentase 5%
```text
00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01540610000055020357020563046ADF
```

### F05 — mata uang USD
```text
00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153038405802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01540510.006304DEFF
```

### F06 — CRC dirusak (karakter terakhir diubah)
```text
00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR01540615000063045550
```

### F07 — nominal desimal pada IDR
```text
00020101021226720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID5914Warung Bu Tini6007Jakarta61051234562110707KASIR0154071500.5063048154
```

### F08 — tanpa nama dan kota merchant
```text
00020101021126720020ID.CO.BANKCONTOH.WWW01189360001401234567890215ID10234567890120303UMI5204541153033605802ID630436FA
```

### F09 — TLV terpotong
```text
00020101021126560016ID.CO.BANKCONTOH.WWW019993600014012345
```

### F10 — URL biasa
```text
https://example.com/promo?utm=demo
```

## 3. Angka yang harus keluar di demo

Asumsi konfigurasi demo (`00_DECISION_LOG.md` D-15):

- `goldPriceDisplayIdrPerGram` = 1.500.000
- `goldBuybackPriceIdrPerGram` = 1.470.000
- `balanceUnits` awal = 12.500 unit (= 1,2500 g)
- `convenienceFeeIdr` = 0

| Fixture | Nominal | Biaya QR | Total | Unit emas (ceil) | Gram | Nilai emas | Pembulatan | Sisa saldo |
|---|---|---|---|---|---|---|---|---|
| F01 (input 150.000) | 150.000 | 0 | 150.000 | 1.021 | 0,1021 g | 150.087 | +87 | 1,1479 g |
| F02 | 150.000 | 0 | 150.000 | 1.021 | 0,1021 g | 150.087 | +87 | 1,1479 g |
| F04 | 100.000 | 5.000 | 105.000 | 715 | 0,0715 g | 105.105 | +105 | 1,1785 g |

Rumus: `goldUnits = ceil(totalIdr × 10.000 ÷ buybackPriceIdrPerGram)`.

## 4. Membuat ulang fixture

Jika payload diubah, CRC harus dihitung ulang. Skrip referensi (Python 3):

```python
def tlv(tag, value):
    b = value.encode("utf-8")
    return f"{tag}{len(b):02d}{value}"

def crc16_ccitt_false(data: bytes) -> int:
    crc = 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc

def finish(body: str) -> str:
    with_crc_tag = body + "6304"
    return with_crc_tag + f"{crc16_ccitt_false(with_crc_tag.encode('utf-8')):04X}"
```

Membuat PNG (opsional):

```powershell
python -m pip install qrcode pillow
python -c "import qrcode; qrcode.make(open('payload.txt').read().strip(), box_size=14, border=4).save('qr.png')"
```

## 5. Aturan penggunaan saat demo

1. Gunakan **F01 atau F02** sebagai QR utama di hari-H.
2. Siapkan **F02 versi cetak** dan versi layar sebagai cadangan.
3. Jangan gunakan F05–F10 saat sesi utama; gunakan hanya jika penguji meminta bukti penanganan error.
4. Jika kamera gagal total, gunakan **tempel payload** (F01/F02) dan sampaikan terus terang bahwa
   sumbernya tempel manual, bukan scan kamera.
