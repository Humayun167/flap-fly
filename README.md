# Flap & Fly

A Flutter-based arcade game inspired by classic tap-to-fly gameplay.

## Features

- Tap-to-fly game mechanics
- Multiple difficulty levels
- Sound effects and sound controls
- Locally saved high score
- Smooth gameplay animations
- In-app coin packs

## Getting Started

### Requirements

- Flutter SDK compatible with Dart 3
- Android Studio or VS Code with Flutter support
- An Android device, emulator, or supported web browser

### Run locally

```bash
flutter pub get
flutter run
```

### Run tests

```bash
flutter test
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web
flutter build web
```

## Project Structure

```text
lib/
|-- audio/       # Sound management
|-- models/      # Game configuration and data models
|-- screens/     # Game and shop screens
|-- services/    # Purchase services
`-- widgets/     # Reusable game widgets

assets/
|-- audio/       # Sound assets
`-- images/      # Image and app-icon assets
```

## Privacy

See the [Privacy Policy](PRIVACY_POLICY.md).

## Security

Release signing credentials and local configuration are not included in this
repository. Never commit `.env` files, `android/key.properties`, keystores,
passwords, API secrets, or other private credentials.

## Built With

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)
