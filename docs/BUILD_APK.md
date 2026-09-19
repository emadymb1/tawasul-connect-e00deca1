# Getting the APK on your phone

There are two ways. Nothing is built inside Lovable — this project is a Flutter
app and Lovable's environment has no Flutter/Android toolchain.

## A. Automatic build on GitHub (no computer setup)

1. Push this project to GitHub (Lovable → GitHub).
2. Open the repository → **Actions** → **Build Android APK** → **Run workflow**.
3. Wait ~10 minutes. Open the finished run and download the artifact
   `tawasul-release-apk`. It contains `app-release.apk`.
4. Copy it to your phone and open it. Allow "install unknown apps" once.

The workflow lives at `.github/workflows/android-apk.yml`. It generates the
Android folder, icons, splash, Arabic/English app name, and builds the release
APK with your server URL baked in.

Note: the APK is signed with the debug key (fine for your own phone,
not for Google Play). For Play, add a keystore and switch to
`flutter build appbundle`.

## B. On your own machine

```bash
cd flutter_app
flutter create . --platforms=android,ios --org fi.fiksutilitoimisto --project-name tawasul
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build apk --release \
  --dart-define=TAWASUL_BASE_URL="https://se.fiksutilitoimisto.fi/modules/Rest%20API/api.php/v2"
```

The file appears at
`flutter_app/build/app/outputs/flutter-apk/app-release.apk`.

For a smaller download, split per phone architecture:

```bash
flutter build apk --release --split-per-abi
```
