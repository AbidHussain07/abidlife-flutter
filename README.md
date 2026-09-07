# ABIDLIFE — Flutter Android Project

A calm, beautiful home for your **Notes · Tasks · Habits · Money** — plus a smart
**Insights** dashboard that ties them all together.

> Local-first · Your data stays on your device · v1.0

This repository contains a **complete, buildable Flutter Android project**. It is
NOT a web wrapper, NOT a PWA, and NOT a Next.js project. It is a genuine Flutter
application written in Dart, ready to be built into an APK by Flutter / Codemagic.

---

## Features

| Section   | Highlights |
|-----------|------------|
| **Insights** | Greeting header, 2×2 stat grid, quick actions, smart insights (streak, week task %, spending MoM, note activity), this-week habits heatmap, recent notes carousel, accounts mini-strip, theme switcher |
| **Notes**    | Markdown editor with toolbar (bold, italic, heading, bullet list, numbered list, checklist, image), pin, archive, tags, color, PIN lock, autosave, image embeds from gallery or camera |
| **Tasks**    | Title + notes, priority (none/low/medium/high), category, due date + due time, recurrence (none/daily/weekly/monthly with weekday picker), reminder toggle, done toggle with completion timestamp |
| **Habits**   | Icon + color picker, daily or specific-days frequency, reminder toggle, today check-off, current/best streak, 30-day completion rate, monthly calendar with done/missed/rest legend, week strip on every card |
| **Money**    | Multiple accounts (Mom, Dad, savings…), per-account balance, INR formatting with paise precision, income/expense keypad, 12 categories with icons, Today/Yesterday/Custom date, monthly + weekly stats, transaction edit/delete, account edit/delete |

Cross-cutting:

- Local-first storage via **sqflite** (no server, no cloud, no sign-in)
- Material 3 theming with **light + dark + system** modes
- Haptic feedback on every interactive surface
- Animated screen transitions, toasts, bottom-nav pill
- Onboarding flow shown once (can be replayed from Settings)
- Notification permission flow for task reminders
- Plus Jakarta Sans typography via `google_fonts`

---

## Project structure

```
abidlife/
├── pubspec.yaml
├── codemagic.yaml                 # CI/CD for building the APK on Codemagic
├── analysis_options.yaml
├── README.md
├── lib/
│   ├── main.dart                  # Entry point + notification init
│   ├── app.dart                   # MaterialApp + theme binding
│   ├── data/
│   │   ├── database.dart          # sqflite open + migrations
│   │   ├── schema.dart            # Table names + column constants
│   │   ├── models.dart            # Note, Task, Habit, HabitLog, Account, Txn
│   │   └── data_provider.dart     # ChangeNotifier state container
│   ├── theme/
│   │   ├── app_colors.dart        # Light/dark palette tokens
│   │   └── app_theme.dart         # Material 3 ThemeData
│   ├── ui/
│   │   ├── ui.dart                # Shared helpers (buzz, tint, palette…)
│   │   └── widgets/               # BottomNav, Sheet, Overlay, PinPad, etc.
│   ├── screens/
│   │   ├── app_shell.dart         # Scaffold + nav + toasts + splash
│   │   ├── onboarding.dart
│   │   ├── insights_screen.dart
│   │   ├── notes/                 # notes_screen + note_editor
│   │   ├── tasks/                 # tasks_screen + task_editor
│   │   ├── habits/                # habits_screen + habit_detail
│   │   └── money/                 # money_screen + account_view + txn_keypad
│   └── utils/
│       ├── date_utils.dart
│       ├── format.dart            # INR formatting
│       └── habit_utils.dart       # streaks, completion rate, scheduling
├── android/
│   ├── settings.gradle
│   ├── build.gradle
│   ├── gradle.properties
│   ├── gradle/wrapper/gradle-wrapper.properties
│   └── app/
│       ├── build.gradle
│       └── src/main/
│           ├── AndroidManifest.xml
│           ├── kotlin/com/abidlife/app/MainActivity.kt
│           └── res/               # styles, colors, launcher icons, splash
├── test/
│   ├── habit_utils_test.dart
│   ├── format_test.dart
│   └── data_provider_test.dart
└── assets/
    ├── images/.gitkeep
    └── icon.svg                   # ABIDLIFE brand mark
```

---

## Building the APK

You do **NOT** need this repository's sandbox to build the APK. You have two
options:

### Option A — Codemagic (recommended, no local setup)

1. Push this project to a Git repository (GitHub / GitLab / Bitbucket).
2. Sign in to <https://codemagic.io> and create a new project pointing to the repo.
3. Codemagic will automatically detect the included `codemagic.yaml` and use it.
4. Click **Start new build**. Codemagic will:
   - Install Flutter `stable`
   - Run `flutter pub get`
   - Run `flutter analyze` and `flutter test` (non-fatal)
   - Build `flutter build apk --release` for arm, arm64 and x64
5. Download the resulting APK from the Artifacts section.

### Option B — Local Flutter install

```bash
# 1. Install Flutter 3.22+ from https://docs.flutter.dev/get-started/install
flutter doctor

# 2. Fetch dependencies
cd abidlife
flutter pub get

# 3. (Optional) Run tests + static analysis
flutter test
flutter analyze

# 4. Build a release APK
flutter build apk --release

# 5. Install on a connected device
flutter install
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## Minimum requirements

- Flutter `>=3.22.0` (stable channel)
- Dart `>=3.4.0`
- Android `minSdkVersion 21` (Android 5.0+)
- Target SDK `34` (Android 14)
- Java 17 (bundled with Android Gradle Plugin 8.x)

---

## Permissions used

| Permission | Why |
|------------|-----|
| `RECEIVE_BOOT_COMPLETED` | Re-arm task reminders after device restart |
| `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` | Fire task reminders at the exact due time |
| `VIBRATE` | Haptic feedback on buttons |
| `POST_NOTIFICATIONS` | Android 13+ notification permission for reminders |
| `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` | Pick images for note attachments (Android 13+) |
| `READ_EXTERNAL_STORAGE` (legacy) | Pick images on Android 12 and below |
| `CAMERA` | Take a photo directly inside a note |

No network permission is required for the core app — it is fully local-first.
The `INTERNET` permission is included only because `google_fonts` fetches
typography on first launch; if you bundle fonts yourself you can remove it.

---

## License

This source is provided to the project owner for the ABIDLIFE app. All rights
reserved.
