# 05 — Menjalankan di Ponsel Android Fisik

> Demo dinilai dari perangkat fisik, bukan emulator. Semua langkah di bawah dilakukan sekali di awal,
> lalu diulang pada checklist pre-flight (`13_LIVE_DEMO_SCRIPT.md`).

## 1. Kebutuhan

- Ponsel Android 10+ dengan kamera dan autofocus.
- `minSdk 24` (proyek, D-46), Android 10+ disarankan untuk hasil kamera terbaik.
- Kabel data yang benar-benar mendukung transfer data.
- Flutter + Android Platform-Tools.
- USB debugging diaktifkan oleh pemilik perangkat.

## 2. Aktifkan opsi pengembang

1. Settings → About phone.
2. Ketuk **Build number** 7×.
3. Masukkan PIN jika diminta.
4. Settings → Developer options → **USB debugging** aktif.

## 3. Hubungkan

1. Sambungkan kabel, buka kunci layar.
2. Pilih mode USB **File transfer** (bukan charging only).
3. Terima dialog "Allow USB debugging?" hanya untuk komputer sendiri.

```powershell
adb devices
flutter devices
```

Yang diharapkan: status `device`, bukan `unauthorized` atau `offline`.

Jika bermasalah:

```powershell
adb kill-server
adb start-server
adb devices
```

## 4. Jalankan

```powershell
flutter run -d <device-id>
```

- `r` = hot reload, `R` = hot restart.
- Hot reload tidak mengulang inisialisasi plugin kamera; setelah perubahan terkait scanner, lakukan
  hot restart atau jalankan ulang.

## 5. Izin kamera

- Permintaan izin muncul saat pengguna menekan **Scan**, bukan saat aplikasi dibuka.
- Rasional singkat ditampilkan sebelum dialog sistem.
- Jika ditolak: layar penjelasan + tombol **Buka pengaturan**.
- Jika ditolak permanen: hanya jalur pengaturan yang ditampilkan, plus fallback galeri/tempel.
- Kamera harus berhenti saat aplikasi ke background atau route ditinggalkan.

## 6. Checklist perangkat

- [ ] Izin kamera pada pemakaian pertama.
- [ ] Preview kamera muncul < 1,5 detik.
- [ ] Satu QR menghasilkan satu hasil (tidak berulang).
- [ ] QR statis → input nominal; QR dinamis → nominal read-only.
- [ ] Torch berfungsi (jika ada).
- [ ] Back/cancel mematikan kamera (indikator kamera hilang).
- [ ] Background → foreground: kamera pulih tanpa layar hitam.
- [ ] Scan QR cetak 6 cm dan QR di layar.
- [ ] Fallback galeri dan tempel berfungsi serta berlabel sumber.
- [ ] Transaksi mengubah saldo satu kali.
- [ ] Restart aplikasi: saldo & history tetap.
- [ ] Mode pesawat: seluruh alur tetap berjalan.
- [ ] Text scale 1,3 tidak memotong teks.

## 7. Build APK

```powershell
flutter build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

Install:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

## 8. Bukti tanpa akses jaringan

Ini bagian yang sering ditanyakan. Jalankan salah satu:

```powershell
apkanalyzer manifest permissions build\app\outputs\flutter-apk\app-release.apk
```

atau

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\<versi>\aapt.exe" dump permissions build\app\outputs\flutter-apk\app-release.apk
```

Tidak boleh ada `android.permission.INTERNET`. Simpan output-nya sebagai bukti saat presentasi.

## 9. Kondisi presentasi

- Nyalakan **mode pesawat** saat demo untuk membuktikan alur offline.
- Kecerahan layar maksimum; matikan adaptive brightness.
- Aktifkan DND; tutup aplikasi kamera/e-wallet lain.
- Jangan biarkan layar mati di tengah demo (atur screen timeout panjang).
- Cetak QR cadangan (lihat `19_TEST_QR_FIXTURES.md`), kertas matte.

## 10. Troubleshooting

| Gejala | Penyebab umum | Tindakan |
|---|---|---|
| Perangkat tidak muncul | kabel/mode USB/driver | ganti kabel, mode file transfer, driver OEM |
| `unauthorized` | dialog belum diterima | buka kunci, terima, cabut-pasang |
| `offline` | adb macet | `adb kill-server` lalu `start-server` |
| Instal gagal | signature berbeda | uninstall versi lama, instal ulang |
| Kamera hitam | izin/lifecycle | periksa izin, restart app |
| Fokus lambat | jarak/ cahaya | 15–40 cm, tambah cahaya |
| QR tidak terbaca | terlalu kecil/glare | pakai versi `_print.png`, matte |
| Saldo tidak berubah | commit gagal | lihat layar gagal; cek storage |
| Data hilang setelah update | package ID berubah | pertahankan `applicationId` |
