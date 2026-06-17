# ZenAuth

A secure, offline-first two-factor authentication (2FA) app built with Flutter.
ZenAuth generates time-based one-time passwords (TOTP) for your accounts and
keeps the secrets encrypted on-device, behind a biometric and/or passcode lock.

> Also referred to in-app as **Universal Auth** — a unified authenticator for all
> your TOTP accounts.

---

## ✨ Features

- **TOTP code generation** — RFC 6238 compliant (HMAC-SHA1, 6/8 digits, 30s
  period), with a live countdown timer per account.
- **Add accounts two ways**
  - Scan a QR code with the camera (`otpauth://` URIs).
  - Enter a setup key manually.
- **App lock**
  - **Biometric lock** (Face ID / fingerprint) via the device's native auth.
  - **In-app passcode** (6-digit PIN) shown on cold start and every time the app
    returns from the background. Can be set, changed, and disabled.
- **Encrypted backup & restore**
  - Export an **AES-256, password-protected** backup file.
  - Save it to **any drive** (Google Drive, OneDrive, Dropbox, Files, …) through
    the system share/save sheet — no per-provider login required.
  - Restore by picking the file from any drive and entering the password.
  - Backups include accounts **and** your passcode + settings.
- **Theming** — System / Light / Dark, applied live and persisted.
- **Authentication & onboarding** — Firebase email/password sign-in with a
  one-time welcome flow.

---

## 📸 Screenshots

> _Add screenshots here (home, add account, passcode lock, settings, backup)._

---

## 🧱 Tech Stack

| Concern | Library |
| --- | --- |
| UI | Flutter (Material 3) |
| State management / DI / routing | [`get`](https://pub.dev/packages/get) (GetX) |
| Auth | `firebase_auth`, `firebase_core` |
| Secure secret storage | `flutter_secure_storage` (EncryptedSharedPreferences) |
| Onboarding flag / local KV | `hive`, `hive_flutter`, `shared_preferences` |
| TOTP / crypto | `crypto`, `base32`, `convert` |
| QR scanning | `mobile_scanner` |
| Biometrics | `local_auth` |
| Backup encryption | `encrypt` (AES) + PBKDF2 (built on `crypto`) |
| Share / file picking | `share_plus`, `file_picker`, `path_provider` |

---

## 🏗️ Architecture

ZenAuth follows a lightweight **MVC + service** layering, wired together with
GetX dependency injection and reactive (`.obs`) state:

- **Models** — plain data classes (`AuthenticatorAccount`, `SettingsModel`,
  `OtpAccountModel`, …).
- **Controllers** — `GetxController`s holding reactive state and business logic.
- **Services** — stateless/singleton helpers for crypto, storage, biometrics,
  and backups.
- **Screens / Widgets** — the view layer, rebuilt reactively via `Obx`.

Key permanent services (registered in [`main.dart`](lib/main.dart)):

- `SettingsController` — persisted user settings (theme, biometrics, passcode flag).
- `SecureStoragePassCodeService` — encrypted storage for the app passcode.
- `AppLockController` — observes the app lifecycle and shows the passcode lock
  on launch / resume when enabled.

---

## 📂 Project Structure

```
lib/
├── main.dart                       # App entry, DI setup, GetMaterialApp + themes
├── firebase_options.dart
├── Models/                         # Data models
│   ├── AuthenticatorAccountModel.dart
│   ├── OtpAccountModel.dart
│   ├── SettingsModel.dart
│   └── ...
├── Controllers/                    # GetX controllers
│   ├── HomeController.dart
│   ├── SettingsController.dart
│   ├── AppLockController.dart      # Passcode lock on launch/resume
│   ├── AppPasscodeController.dart  # Set / change / verify passcode
│   ├── BackupController.dart       # Backup & restore orchestration
│   ├── QrScannerController.dart
│   └── ...
├── Services/                       # Business / platform services
│   ├── TOTPGenerator.dart          # RFC 6238 code generation
│   ├── SecureStorageService.dart   # Accounts + passcode secure storage
│   ├── BiometricService.dart
│   └── BackupService.dart          # AES-256 encrypt/decrypt backups
├── Screens/
│   ├── WelcomeScreen/  Loginpage/  Signuppage/  SplashScreenPage/
│   ├── Homepage/                   # Account list + live codes
│   ├── AddAuthAccounts/            # QR scan + manual entry
│   └── SettingsPage/
│       ├── AppPasscodeView/        # Passcode keypad + options
│       ├── BackupRestore/          # Backup & restore screen
│       └── ThemeSelection/         # Theme picker
├── Widgets/                        # Reusable widgets (AccountCard, …)
└── util/
    ├── AppTheme.dart               # Light/Dark ThemeData + theme options
    ├── AuthWrapperClass/           # Biometric gate wrapper
    └── helperClasses/HiveHelper.dart
```

---

## 🔐 Security Model

- **TOTP** — secrets never leave the device for code generation; codes follow
  RFC 6238 (HMAC-SHA1, configurable digits/period).
- **At-rest storage** — account secrets and the app passcode are stored via
  `flutter_secure_storage` using Android **EncryptedSharedPreferences**.
- **App lock** — optional biometric unlock and/or a 6-digit passcode that gates
  the app on cold start and on resume from background.
- **Backups** — encrypted with **AES-256-CBC**; the key is derived from the
  user's password using **PBKDF2-HMAC-SHA256** (120k iterations, random salt).
  The password is **not recoverable** — without it the backup cannot be decrypted.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (this repo is pinned via [FVM](https://fvm.app/); see `.fvmrc`).
- A configured Firebase project (the app uses Firebase Auth).
- Android SDK / Xcode for the target platform.

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Configure Firebase (generates lib/firebase_options.dart)
#    Requires the FlutterFire CLI: https://firebase.flutter.dev/docs/cli
flutterfire configure

# 3. Run the app
flutter run
```

> Using FVM? Prefix commands with `fvm`, e.g. `fvm flutter run`.

### Building

- **Android `minSdkVersion` is 23** (required by EncryptedSharedPreferences) —
  see [`android/app/build.gradle.kts`](android/app/build.gradle.kts).
- After adding/updating native plugins, do a **full rebuild** (`flutter clean`
  then `flutter run`) — hot restart will not register new platform plugins.

---

## 🗄️ Backup File Format

Backups are UTF-8 JSON envelopes with a `.zenauth` extension:

```json
{
  "app": "zenauth",
  "format": 1,
  "kdf": "pbkdf2-hmac-sha256",
  "iterations": 120000,
  "salt": "<base64>",
  "iv": "<base64>",
  "cipher": "aes-256-cbc",
  "data": "<base64 ciphertext>"
}
```

The ciphertext decrypts to:

```json
{
  "accounts": [ { "id": "...", "issuer": "...", "secret": "...", "digits": 6, "period": 30 } ],
  "passcode": "<string or null>",
  "settings": { "isBiometricsEnabled": false, "isPasscodeSet": true, "currentTheme": "Dark" }
}
```

---

## ⚠️ Notes & Limitations

- **Backup password is unrecoverable.** If lost, the backup cannot be restored.
- Restore **merges** accounts (same `id` is overwritten, new ones are added) and
  **replaces** the passcode/settings on the device.
- Dark mode covers Material surfaces, app bars, buttons, the passcode screen, and
  default text. A few screens still use accent/branding colors that are intentionally
  fixed.
- Some Settings entries (About / FAQ / Contact) are placeholders and not yet wired
  to screens.

---

## 📄 License

This project is currently unlicensed / private. Add a license here if you intend
to distribute it.
