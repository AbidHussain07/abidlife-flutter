# ABIDLIFE

A genuine Flutter Android application for notes, tasks, habits, personal money and calm cross-module insights.

## Stack

- Flutter + Material 3
- Riverpod for application state
- SQLite (`sqflite`) with repository classes
- Flutter Quill Delta JSON for persistent WYSIWYG rich text
- AES-256-GCM + PBKDF2 and Android secure storage for private note bodies
- Android local notifications with timezone-aware recurrence
- Image Picker + native image compression

There is no sample seed data. A fresh installation opens with empty states.

## Local build

```bash
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

## Codemagic

Push this directory to a Git repository, connect it in Codemagic, and select `android-debug` from `codemagic.yaml`. The APK appears in the build artifacts. For a signed release, add the `android-signing` variable group documented in `codemagic.yaml`.

## Private note test PIN

No notes are pre-created. Create a note, save it, long-press the card, and choose **Lock with PIN**. The title remains visible while its Delta body is encrypted at rest.
