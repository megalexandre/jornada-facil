# Jornada Fácil

## Compilar APK

```bash
flutter clean && flutter pub get && flutter build apk --debug --dart-define-from-file=config/prod.json
```

~/Android/Sdk/emulator/emulator -avd Pixel_4 -memory 8192 -no-snapshot -no-audio -gpu swiftshader_indirect -cores 4
