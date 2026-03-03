# viikshana

A new Flutter project.

## Running the app

**With a real API** (e.g. production):
```bash
flutter run --dart-define=VIIKSHANA_API_BASE_URL=https://api.viikshana.com
```

**Without the API** (e.g. local dev, no backend) — use an empty home feed:
```bash
flutter run --dart-define=VIIKSHANA_API_BASE_URL=
```

**Local backend on your PC + Android emulator** — On the emulator, `localhost` is the device, not your PC. Use your host machine's address:
```bash
flutter run --dart-define=VIIKSHANA_API_BASE_URL=http://10.0.2.2:3000
```
(Replace `3000` with your backend port. For a real device on the same LAN, use your PC IP, e.g. `http://192.168.1.5:3000`.)

**If bottom nav icons show as broken boxes**, do a clean build so the Material font is included:
```bash
flutter clean
flutter pub get
flutter run --dart-define=VIIKSHANA_API_BASE_URL=
```

### Android TV emulator

Flutter marks the AOSP TV emulator as unsupported, so use **build APK + adb install**:

1. Start your TV emulator (e.g. AOSP TV on x86 — `emulator-5558`).
2. Build and install:
```bash
flutter build apk --debug
adb -s emulator-5558 install build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5558 shell am start -n com.example.viikshana/.MainActivity
```
3. Use the emulator's D-pad/remote to move focus and select items (sidebar, etc.).

To find your TV device id: `flutter devices` or `adb devices`.

## Testing

```bash
flutter test
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
