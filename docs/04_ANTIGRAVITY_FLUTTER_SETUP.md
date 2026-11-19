# 04 — Setup Antigravity, Flutter, dan Proyek

> Langkah dan versi tooling berubah. Konfirmasi ke dokumentasi resmi saat setup; jangan menyalin
> versi paket dari dokumen ini.

## 1. Yang perlu dipasang

- Antigravity IDE (sumber resmi).
- Flutter **stable**.
- Android Studio (untuk SDK Manager, platform-tools, build-tools; IDE tetap Antigravity).
- Git.
- Ponsel Android + kabel data (bukan kabel charge-only).
- Font **Plus Jakarta Sans** (OFL) — unduh dari Google Fonts, simpan `LICENSE` bersama font.

## 2. Windows

1. Ekstrak Flutter ke path tanpa spasi, mis. `C:\src\flutter`.
2. Tambahkan `C:\src\flutter\bin` ke PATH, buka terminal baru.
3. Pasang Android SDK Platform, Build-Tools, Platform-Tools, Command-line Tools.
4. Terima lisensi dan periksa:

```powershell
flutter --version
dart --version
flutter doctor -v
flutter doctor --android-licenses
```

Jangan memiliki dua SDK Flutter berbeda di PATH.

## 3. Membuat proyek

Bangun aplikasi **di folder repo ini** (dokumen, fixture, dan `AGENTS.md` sudah ada):

```powershell
cd C:\Users\<NAMA>\goldPay
flutter create --org id.goldpay.concept --project-name goldpay_demo .
```

- `flutter create .` menambahkan file platform tanpa menghapus `docs/`, `assets/`, atau `AGENTS.md`.
- `--org` menentukan `applicationId`. Jangan pakai `com.example` untuk APK yang dibagikan.
- Nama paket dan label APK tidak boleh memuat "Pegadaian" atau "Tring!" (`00_DECISION_LOG.md` D-02).
- Jika `flutter create .` menolak folder tidak kosong, buat di subfolder `app/` lalu pindahkan
  `pubspec.yaml`, `lib/`, `android/` ke root — tetapi jangan memindahkan `docs/`.

## 4. Git

Inisialisasi **di dalam folder proyek**:

```powershell
git init
git add .
git commit -m "chore: scaffold GoldPay demo"
```

Pastikan `.gitignore` ada sebelum commit pertama (lihat `AGENTS.md` untuk daftar minimum). Jangan
menginisialisasi repo di folder home — semua file pengguna akan ikut terlacak.

## 5. Dependency

```powershell
flutter pub add flutter_riverpod go_router mobile_scanner intl shared_preferences uuid
```

**Jangan** menambahkan:

| Paket | Alasan |
|---|---|
| `google_fonts` | Mengunduh font saat runtime; melanggar offline & klaim tanpa jaringan |
| `http`, `dio`, `firebase_*` | Tidak ada network di produk ini |
| `riverpod_generator`, `build_runner` | Tidak perlu codegen untuk skala demo |
| `flutter_svg` | Tidak ada aset SVG |

Setelah menambah:

```powershell
flutter pub get
flutter analyze
flutter test
```

Commit `pubspec.lock`.

## 6. Font dan aset

Struktur:

```text
assets/
├── fonts/
│   ├── PlusJakartaSans-Regular.ttf
│   ├── PlusJakartaSans-SemiBold.ttf
│   ├── PlusJakartaSans-Bold.ttf
│   └── OFL.txt
└── test_qris/            # sudah tersedia (F01–F10, versi layar & cetak)
```

`pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/test_qris/
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
```

## 7. Konfigurasi Android

`android/app/build.gradle.kts` (atau `.gradle`):

```kotlin
android {
    defaultConfig {
        minSdk = 23
        // targetSdk & compileSdk mengikuti nilai stabil saat build
    }
}
```

`android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />

    <!-- Klaim "tidak bisa membayar" dibuktikan secara teknis. -->
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />

    <application android:label="GoldPay">
        <!-- ... -->
    </application>
</manifest>
```

Catatan: Flutter menyuntikkan `INTERNET` pada manifest debug/profile. Baris `tools:node="remove"`
memastikan manifest **release** tidak memilikinya. Verifikasi setelah build (`12_TESTING_QA_PLAN.md`
§11).

## 8. Inisialisasi aplikasi

`main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(
    ProviderScope(
      overrides: [
        demoRepositoryProvider.overrideWithValue(PrefsDemoRepository()),
      ],
      child: const GoldPayApp(),
    ),
  );
}
```

`MaterialApp`:

```dart
MaterialApp.router(
  locale: const Locale('id_ID'),
  supportedLocales: const [Locale('id_ID')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: buildTheme(),
  routerConfig: router,
)
```

## 9. Menjalankan

```powershell
flutter devices
flutter run -d <device-id>
```

Jika perangkat tidak muncul, ikuti `05_PHYSICAL_ANDROID_DEVICE_SETUP.md`.

## 10. Verifikasi awal

```powershell
flutter analyze
flutter test
flutter build apk --release
apkanalyzer manifest permissions build\app\outputs\flutter-apk\app-release.apk
```

Output `apkanalyzer` tidak boleh memuat `android.permission.INTERNET`.

## 11. Troubleshooting

| Masalah | Periksa |
|---|---|
| `flutter` tidak dikenal | PATH, buka terminal baru |
| Lisensi Android | `flutter doctor --android-licenses` |
| SDK tidak ditemukan | lokasi SDK di Android Studio, `flutter config --android-sdk` |
| Gradle gagal | kompatibilitas Flutter/Gradle/JDK, baca error pertama |
| Paket gagal resolve | jaringan, pub cache, versi kompatibel |
| Perangkat tidak terdeteksi | `adb devices`, driver OEM, mode USB |
| Kamera hitam | izin, lifecycle, aplikasi lain memegang kamera |
| Scanner mati setelah navigasi | controller di-dispose; mulai ulang di `initState`/`didChangeAppLifecycleState` |
| APK masih punya INTERNET | cek merge manifest; build ulang dengan `flutter clean` |

## 12. Referensi

- https://docs.flutter.dev/get-started/install
- https://docs.flutter.dev/platform-integration/android/setup
- https://developer.android.com/studio
- https://pub.dev/
- Plus Jakarta Sans (SIL Open Font License)
