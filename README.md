# VAMOS OPS Mobile

Aplikasi staff Flutter yang terhubung ke API VAMOS OPS. State, dependency injection, dan navigation menggunakan GetX dengan boundary `provider → repository → controller → view`.

## Struktur

- `lib/app/data/providers` — komunikasi HTTP melalui `GetConnect`.
- `lib/app/data/repositories` — kontrak data agar controller dapat diuji tanpa network.
- `lib/app/modules/staff/controllers` — state reaktif dan orchestration use case.
- `lib/app/modules/staff/bindings` — dependency injection per route.
- `lib/app/routes` — named route.
- `lib/vamos_app.dart` — presentation/widget staff.

## Menjalankan

Pastikan PostgreSQL dan dashboard API sudah berjalan. Untuk HP fisik pada Wi-Fi yang sama, proyek ini secara default memakai API laptop pada `192.168.1.4`:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.4:3000/api/v1
```

Uji `http://192.168.1.4:3000/api/health` dari browser HP terlebih dahulu. Android emulator menggunakan alias `10.0.2.2` untuk host komputer:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

iOS simulator dapat memakai `http://localhost:3000/api/v1`.

## Verifikasi

```bash
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.1.4:3000/api/v1
```
