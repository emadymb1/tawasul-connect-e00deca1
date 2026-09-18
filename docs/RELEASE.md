# Tawasul — build and release guide

Everything below runs on your own machine with the Flutter SDK installed
(Flutter 3.22 or newer). Nothing in this repository is built or run for you.

## 1. First-time setup

The repository holds the Dart source (`flutter_app/lib`) and `pubspec.yaml`.
The native Android/iOS folders are generated once:

```bash
cd flutter_app
flutter create . --platforms=android,ios --org fi.fiksutilitoimisto --project-name tawasul
flutter pub get
flutter analyze
```

`flutter create .` never overwrites `lib/` or `pubspec.yaml`.

## 2. Icons and splash screen

The supplied brand mark lives at `assets/icon/app_icon.png`. The previous mark
is preserved as `assets/icon/app_icon_previous.png`. Generate the launcher
icons and native splash:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The Flutter loading screen continues from the native splash with a gentle
fade-and-scale logo animation while the signed-in session is restored.

## 3. Localised installed app name

The source translations are stored under `native_names/`. After generating the
Android and iOS folders, copy these files into the native projects:

- Android: copy `native_names/android/values/strings.xml` to
  `android/app/src/main/res/values/strings.xml`, and `values-ar/strings.xml` to
  `android/app/src/main/res/values-ar/strings.xml`. Set the application label in
  `AndroidManifest.xml` to `@string/app_name`.
- iOS: add both `native_names/ios/en.lproj/InfoPlist.strings` and
  `native_names/ios/ar.lproj/InfoPlist.strings` to the Runner target in Xcode,
  then add Arabic and English under Runner → Info → Localizations.

This displays “Tawasul School OS” on English phones and “نظام تواصل المدرسي”
on Arabic phones.

## 4. Server address

The API base URL is compiled in and can be overridden:

```bash
flutter run --dart-define=TAWASUL_BASE_URL="https://se.fiksutilitoimisto.fi/modules/Rest%20API/api.php/v2"
```

## 5. Permissions to declare

- Android: `INTERNET` (added by Flutter) and, for Android 13+,
  `POST_NOTIFICATIONS` in `android/app/src/main/AndroidManifest.xml`:
  `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`
- iOS: notification permission is requested at runtime; no plist entry needed
  beyond the default.

## 6. Release builds

```bash
# Android
flutter build appbundle --release \
  --dart-define=TAWASUL_BASE_URL="https://se.fiksutilitoimisto.fi/modules/Rest%20API/api.php/v2"

# iOS (on macOS, with signing set up in Xcode)
flutter build ipa --release \
  --dart-define=TAWASUL_BASE_URL="https://se.fiksutilitoimisto.fi/modules/Rest%20API/api.php/v2"
```

Android signing: create `android/key.properties` with your keystore details and
wire it in `android/app/build.gradle` as per the Flutter deployment docs.

## 7. Store metadata (draft)

- **English name:** Tawasul School OS
- **Arabic name:** نظام تواصل المدرسي
- **Short description (AR):** بوابة المدرسة للطلاب وأولياء الأمور والمعلمين والإدارة.
- **Short description (EN):** The school portal for students, parents, teachers and staff.
- **Full description (AR):** الجدول الدراسي، الواجبات، الدرجات، الحضور، السلوك،
  التقارير، الفواتير، الرسائل، الإشعارات، التقويم، المكتبة، الأنشطة، الرحلات
  والدعم الفني — كل ذلك من خادم مدرستك مباشرة.
- **Full description (EN):** Timetable, homework, grades, attendance, behaviour,
  reports, invoices, messages, notifications, calendar, library, activities,
  trips and the help desk — all live from your school server.
- **Category:** Education. **Content rating:** Everyone.
- **Privacy policy:** required by both stores; it must state that data is held
  on the school's own server and that sign-in is per user.
- Screenshots: sign-in, student dashboard, parent portal, teacher dashboard
  (the four designs supplied), in Arabic and English.

## 8. Notes

- Offline: the last successful response of every screen is stored on the
  device (3 days) and shown with an "offline" banner when the server cannot
  be reached. Writes are never queued offline — they fail and can be retried.
- Permissions: any area the server answers with 403 is hidden automatically.
- Back button: opened pages return normally; portal tabs retrace their history.
  Back from the main tab asks for confirmation before closing the app.
- Notifications: while the app is open it polls the server's notification list
  every three minutes and raises a device notification for new items. There is
  no Firebase; if you later want notifications while the app is closed, that
  needs a push service and a server-side hook.
