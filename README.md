# viikshana

A new Flutter project.

## Running the app

**With a real API** (requires `https://viikshana.com` reachable):
```bash
flutter run
```

**Without the API** (e.g. local dev, no backend) — use an empty home feed:
```bash
flutter run --dart-define=VIIKSHANA_API_BASE_URL=
```

**Local backend on your PC + Android emulator** — On the emulator, `localhost` is the device, not your PC. Point to your machine with:
```bash
flutter run --dart-define=VIIKSHANA_API_BASE_URL=https://viikshana.com
```
(Replace `3000` with your backend port. Use `10.0.2.2` for Android emulator; for a real device use your PC’s LAN IP, e.g. `http://192.168.1.5:3000`.)

**If bottom nav icons show as broken boxes**, do a clean build so the Material font is included:
```bash
flutter clean
flutter pub get
flutter run --dart-define=VIIKSHANA_API_BASE_URL=
```

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
